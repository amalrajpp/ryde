import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ryde/features/screen/chat.dart';

class RideTrackingScreen extends StatefulWidget {
  final String bookingId;
  final Map<String, dynamic> bookingData;

  const RideTrackingScreen({
    super.key,
    required this.bookingId,
    required this.bookingData,
  });

  @override
  State<RideTrackingScreen> createState() => _RideTrackingScreenState();
}

class _RideTrackingScreenState extends State<RideTrackingScreen> {
  final Completer<GoogleMapController> _mapController = Completer();
  final String _googleApiKey =
      "AIzaSyDfOLxaH9E5-hZ0RlPdclHVWv51Nx7hamk"; // Ideally move this to a secure config

  // --- MAP STATE ---
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  BitmapDescriptor? _driverIcon;
  BitmapDescriptor? _pickupIcon;
  BitmapDescriptor? _dropoffIcon;

  // --- DATA STATE ---
  LatLng? _driverLocation;
  late LatLng _pickupLatLng;
  late LatLng _dropoffLatLng;
  late String _pickupAddress;
  late String _dropoffAddress;

  // --- UI STATE ---
  String _currentStatus = "created";
  String _timeString = "-- min";
  String _distanceString = "-- km";
  String _statusMessage = "Connecting...";

  StreamSubscription? _driverSubscription;
  StreamSubscription? _bookingSubscription;

  @override
  void initState() {
    super.initState();
    _parseBookingData();
    _loadCustomMarkers();
    _listenToBookingStatus();
    _listenToDriverLocation();
  }

  @override
  void dispose() {
    _driverSubscription?.cancel();
    _bookingSubscription?.cancel();
    super.dispose();
  }

  void _parseBookingData() {
    // UPDATED: Accessing data based on your specific structure
    final route = widget.bookingData['route'] as Map<String, dynamic>? ?? {};

    // Safely parse lat/lng as doubles
    double pLat = (route['pickup_lat'] as num?)?.toDouble() ?? 0.0;
    double pLng = (route['pickup_lng'] as num?)?.toDouble() ?? 0.0;
    double dLat = (route['dropoff_lat'] as num?)?.toDouble() ?? 0.0;
    double dLng = (route['dropoff_lng'] as num?)?.toDouble() ?? 0.0;

    _pickupLatLng = LatLng(pLat, pLng);
    _dropoffLatLng = LatLng(dLat, dLng);
    _pickupAddress = route['pickup_address'] ?? "Pickup Location";
    _dropoffAddress = route['dropoff_address'] ?? "Dropoff Location";
    _currentStatus = widget.bookingData['status'] ?? 'created';
  }

  // --- MARKERS & ICONS ---
  Future<void> _loadCustomMarkers() async {
    final carBytes = await _getBytesFromCanvas(
      Icons.directions_car,
      Colors.black,
      90,
    );
    final pickupBytes = await _getBytesFromCanvas(
      Icons.my_location,
      Colors.blue,
      70,
    );
    final dropoffBytes = await _getBytesFromCanvas(
      Icons.location_on,
      Colors.red,
      90,
    );

    if (mounted) {
      setState(() {
        _driverIcon = BitmapDescriptor.fromBytes(carBytes);
        _pickupIcon = BitmapDescriptor.fromBytes(pickupBytes);
        _dropoffIcon = BitmapDescriptor.fromBytes(dropoffBytes);
      });
    }
  }

  Future<Uint8List> _getBytesFromCanvas(
    IconData icon,
    Color color,
    int width,
  ) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    final Paint paint = Paint()..color = color;
    TextPainter painter = TextPainter(textDirection: TextDirection.ltr);
    painter.text = TextSpan(
      text: String.fromCharCode(icon.codePoint),
      style: TextStyle(
        fontSize: width.toDouble(),
        fontFamily: icon.fontFamily,
        color: color,
      ),
    );
    painter.layout();
    painter.paint(canvas, const Offset(0, 0));
    final img = await pictureRecorder.endRecording().toImage(width, width);
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  }

  // --- LISTENERS ---
  void _listenToBookingStatus() {
    _bookingSubscription = FirebaseFirestore.instance
        .collection('booking')
        .doc(widget.bookingId)
        .snapshots()
        .listen((snapshot) {
          if (snapshot.exists) {
            final newStatus = snapshot.data()?['status'] ?? 'created';
            if (newStatus != _currentStatus) {
              setState(() => _currentStatus = newStatus);
              if (_driverLocation != null) _updateMapState(_driverLocation!);
            }
          }
        });
  }

  void _listenToDriverLocation() {
    final String driverId = widget.bookingData['driver_id'];
    _driverSubscription = FirebaseFirestore.instance
        .collection('drivers')
        .doc(driverId)
        .snapshots()
        .listen((snapshot) {
          if (snapshot.exists && snapshot.data() != null) {
            final loc = snapshot.data()!['location'];
            if (loc != null) {
              final newPos = LatLng(loc['lat'], loc['lng']);
              setState(() => _driverLocation = newPos);
              _updateMapState(newPos);
            }
          }
        });
  }

  // --- MAP LOGIC ---
  void _updateMapState(LatLng driverPos) {
    bool isPhase2 = _currentStatus == 'ongoing';
    LatLng targetLatLng = isPhase2 ? _dropoffLatLng : _pickupLatLng;

    setState(() {
      _statusMessage = isPhase2
          ? "Heading to Destination"
          : "Driver is on the way";
    });

    Set<Marker> newMarkers = {};

    // Driver Marker
    newMarkers.add(
      Marker(
        markerId: const MarkerId('driver'),
        position: driverPos,
        icon: _driverIcon ?? BitmapDescriptor.defaultMarker,
        rotation: 0,
        anchor: const Offset(0.5, 0.5),
        flat: true,
      ),
    );

    // Target Marker
    newMarkers.add(
      Marker(
        markerId: MarkerId(isPhase2 ? 'dropoff' : 'pickup'),
        position: targetLatLng,
        icon: isPhase2
            ? (_dropoffIcon ??
                  BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueRed,
                  ))
            : (_pickupIcon ??
                  BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueBlue,
                  )),
      ),
    );

    setState(() => _markers = newMarkers);
    _getRealTimeRoute(driverPos, targetLatLng, isPhase2);
  }

  Future<void> _getRealTimeRoute(
    LatLng origin,
    LatLng destination,
    bool isPhase2,
  ) async {
    final String url =
        "https://maps.googleapis.com/maps/api/directions/json?origin=${origin.latitude},${origin.longitude}&destination=${destination.latitude},${destination.longitude}&mode=driving&key=$_googleApiKey";

    try {
      final HttpClientRequest request = await HttpClient().getUrl(
        Uri.parse(url),
      );
      final HttpClientResponse response = await request.close();
      final String responseBody = await response.transform(utf8.decoder).join();
      final json = jsonDecode(responseBody);

      if (json['status'] == 'OK' && json['routes'].isNotEmpty) {
        final route = json['routes'][0];
        final points = _decodePolyline(route['overview_polyline']['points']);
        final leg = route['legs'][0];

        if (mounted) {
          setState(() {
            _timeString = leg['duration']['text'];
            _distanceString = leg['distance']['text'];

            _polylines.clear();
            _polylines.add(
              Polyline(
                polylineId: const PolylineId("route"),
                points: points,
                color: isPhase2 ? Colors.green : Colors.black,
                width: 4,
                geodesic: true,
              ),
            );
          });
        }
      }
    } catch (e) {
      debugPrint("API Error: $e");
    }
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;
    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;
      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;
      points.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return points;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _pickupLatLng,
              zoom: 14,
            ),
            onMapCreated: (c) => _mapController.complete(c),
            markers: _markers,
            polylines: _polylines,
            zoomControlsEnabled: false,
            myLocationButtonEnabled: false,
          ),
          Positioned(
            top: 50,
            left: 20,
            child: InkWell(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8)],
                ),
                child: const Icon(Icons.arrow_back, color: Colors.black),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: _buildTrackingSheet(),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackingSheet() {
    // UPDATED: Mapping based on your specific 'booking' structure
    final vehicle =
        widget.bookingData['vehicle'] as Map<String, dynamic>? ?? {};
    final double price =
        (widget.bookingData['price'] as num?)?.toDouble() ?? 0.0;
    final String vehicleDesc = vehicle['description'] ?? "Vehicle";
    final String vehicleType = vehicle['type'] ?? "Car";

    // Check if plate exists in case you add it later, otherwise fallback to Type
    final String plateInfo = vehicle['plate'] ?? vehicleType.toUpperCase();

    bool isPickupPhase = _currentStatus != 'ongoing';

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 20,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _statusMessage,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    RichText(
                      text: TextSpan(
                        text: _timeString,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        children: [
                          TextSpan(
                            text: " ($_distanceString)",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                _buildProgressIndicator(isPickupPhase),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(height: 1),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey[200],
                    image: const DecorationImage(
                      image: NetworkImage("https://i.pravatar.cc/150?img=11"),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            widget.bookingData['driver_name'] ?? "Driver",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange[50],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              children: const [
                                Icon(
                                  Icons.star,
                                  size: 12,
                                  color: Colors.orange,
                                ),
                                SizedBox(width: 2),
                                Text(
                                  "4.9",
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // UPDATED: Uses 'description' field (e.g. "Black Model 3")
                      Text(
                        vehicleDesc,
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          plateInfo, // Displays vehicle type or plate if available
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Inside _buildTrackingSheet...
            Row(
              children: [
                Expanded(
                  // Call Button (Placeholder logic)
                  child: _buildActionButton(
                    Icons.call,
                    "Call",
                    Colors.green,
                    () {},
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  // --- UPDATED MESSAGE BUTTON ---
                  child: _buildActionButton(
                    Icons.message,
                    "Message",
                    Colors.blue,
                    () {
                      // Get current User ID (The Passenger)
                      final String currentUserId =
                          FirebaseAuth.instance.currentUser?.uid ??
                          "unknown_user";

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatScreen(
                            orderId: widget.bookingId,
                            senderId: currentUserId, // Sender is ME (The User)
                            receiverId: widget
                                .bookingData['driver_id'], // Receiver is DRIVER
                            receiverName:
                                widget.bookingData['driver_name'] ?? "Driver",
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FB),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.payments_outlined, color: Colors.black54),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        "Payment Method",
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      Text(
                        "Cash",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // UPDATED: Price mapping
                  Text(
                    "₹${price.toStringAsFixed(0)}",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (isPickupPhase)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: TextButton(
                  // UPDATED: Logic for Confirmation Dialog
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext ctx) {
                        return AlertDialog(
                          title: const Text("Cancel Ride"),
                          content: const Text(
                            "Are you sure you want to cancel this ride?",
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.of(ctx).pop(); // Close Dialog (No)
                              },
                              child: const Text("No"),
                            ),
                            TextButton(
                              onPressed: () async {
                                Navigator.of(ctx).pop(); // Close Dialog (Yes)

                                try {
                                  // Update backend
                                  await FirebaseFirestore.instance
                                      .collection('booking')
                                      .doc(widget.bookingId)
                                      .update({'status': 'cancelled'});

                                  if (mounted) {
                                    Navigator.pop(context); // Close Screen
                                  }
                                } catch (e) {
                                  debugPrint("Error cancelling ride: $e");
                                }
                              },
                              child: const Text(
                                "Yes",
                                style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  child: const Text(
                    "Cancel Ride",
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(bool isPickupPhase) {
    return Row(
      children: [
        _buildDot(true, "created"),
        _buildLine(true),
        _buildDot(!isPickupPhase, "On Trip"),
        _buildLine(false),
        _buildDot(false, "Done"),
      ],
    );
  }

  Widget _buildDot(bool isActive, String label) {
    return Column(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: isActive ? Colors.black : Colors.grey[300],
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }

  Widget _buildLine(bool isActive) {
    return Container(
      width: 20,
      height: 2,
      color: isActive ? Colors.black : Colors.grey[300],
    );
  }

  Widget _buildActionButton(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap, // <--- ADD THIS PARAMETER
  ) {
    return InkWell(
      onTap: onTap, // <--- USE IT HERE
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
