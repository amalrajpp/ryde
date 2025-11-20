import 'dart:async';
import 'dart:convert'; // NEW: For JSON decoding
import 'dart:io'; // NEW: For making HTTP requests without extra packages
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ryde/services/place_service.dart';
import 'package:uuid/uuid.dart';
import 'package:geolocator/geolocator.dart';

class RideOption {
  final String id;
  final String driverName;
  final double rating;
  final double price;
  final String time;
  final String seats;
  final String carImage;
  final String driverImage;
  final String carDescription;
  final LatLng driverLocation; // NEW: Needed for routing

  RideOption({
    required this.id,
    required this.driverName,
    required this.rating,
    required this.price,
    required this.time,
    required this.seats,
    required this.carImage,
    required this.driverImage,
    required this.carDescription,
    required this.driverLocation,
  });
}

class RideBookingScreen extends StatefulWidget {
  const RideBookingScreen({super.key});

  @override
  State<RideBookingScreen> createState() => _RideBookingScreenState();
}

class _RideBookingScreenState extends State<RideBookingScreen> {
  final Completer<GoogleMapController> _mapController = Completer();

  // 1. SETUP KEYS
  final String _googleApiKey = "AIzaSyDfOLxaH9E5-hZ0RlPdclHVWv51Nx7hamk";
  late PlaceService _placeService;
  final _uuid = const Uuid();
  String _sessionToken = '123456';

  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _toController = TextEditingController();

  List<PlacePrediction> _fromSuggestions = [];
  List<PlacePrediction> _toSuggestions = [];
  bool _isFromFieldFocused = false;

  // 2. LOCATION & ROUTING STATE
  LatLng? _fromLatLng; // Stores actual coordinates of pickup
  LatLng? _toLatLng; // Stores actual coordinates of dropoff
  double _tripDistanceKm = 0.0; // Calculated distance
  Set<Polyline> _polylines = {}; // Stores the road line

  // 3. UI STATE
  bool _showRideList = false;
  String? _selectedRideId;

  // 4. MAP & DRIVER STATE
  Set<Marker> _markers = {};
  BitmapDescriptor? _carIcon;
  StreamSubscription? _driverSubscription;

  static const CameraPosition _kInitialPosition = CameraPosition(
    target: LatLng(37.7749, -122.4194),
    zoom: 14.4746,
  );

  @override
  void initState() {
    super.initState();
    _placeService = PlaceService(_googleApiKey);
    _sessionToken = _uuid.v4();

    _fromController.addListener(() {
      _onSearchChanged(_fromController.text, isFrom: true);
    });
    _toController.addListener(() {
      _onSearchChanged(_toController.text, isFrom: false);
    });

    _determinePosition();
    _createCarMarker();
    _listenToDrivers();
  }

  @override
  void dispose() {
    _driverSubscription?.cancel();
    _fromController.dispose();
    _toController.dispose();
    super.dispose();
  }

  // --- 1. MAP HELPERS ---
  Future<void> _createCarMarker() async {
    final icon = await _getBytesFromCanvas(100, 100);
    setState(() => _carIcon = BitmapDescriptor.fromBytes(icon));
  }

  Future<Uint8List> _getBytesFromCanvas(int width, int height) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    final Paint paint = Paint()..color = Colors.black;
    final Radius radius = Radius.circular(width / 2);
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(0.0, 0.0, width.toDouble(), height.toDouble()),
        topLeft: radius,
        topRight: radius,
        bottomLeft: radius,
        bottomRight: radius,
      ),
      paint,
    );
    TextPainter painter = TextPainter(textDirection: TextDirection.ltr);
    painter.text = TextSpan(
      text: String.fromCharCode(Icons.directions_car.codePoint),
      style: TextStyle(
        fontSize: 65.0,
        fontFamily: Icons.directions_car.fontFamily,
        color: Colors.white,
      ),
    );
    painter.layout();
    painter.paint(
      canvas,
      Offset(
        (width * 0.5) - painter.width * 0.5,
        (height * 0.5) - painter.height * 0.5,
      ),
    );
    final img = await pictureRecorder.endRecording().toImage(width, height);
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  }

  void _listenToDrivers() {
    _driverSubscription = FirebaseFirestore.instance
        .collection('drivers')
        .where('status', isEqualTo: 'online')
        .snapshots()
        .listen((snapshot) {
          final Set<Marker> newMarkers = {};
          for (var doc in snapshot.docs) {
            final data = doc.data();
            final location = data['location'] as Map<String, dynamic>;
            if (location['lat'] != null && location['lng'] != null) {
              final lat = (location['lat'] as num).toDouble();
              final lng = (location['lng'] as num).toDouble();
              newMarkers.add(
                Marker(
                  markerId: MarkerId(doc.id),
                  position: LatLng(lat, lng),
                  icon: _carIcon ?? BitmapDescriptor.defaultMarker,
                  rotation: (location['heading'] as num?)?.toDouble() ?? 0.0,
                  anchor: const Offset(0.5, 0.5),
                  onTap: () {
                    // Optional: Tap marker to select driver logic
                  },
                ),
              );
            }
          }
          if (mounted) setState(() => _markers = newMarkers);
        });
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return Future.error('Location services are disabled.');
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied)
        return Future.error('Location permissions are denied');
    }
    if (permission == LocationPermission.deniedForever)
      return Future.error('Location permissions are permanently denied.');

    Position position = await Geolocator.getCurrentPosition();

    // Set current location as "From" initially
    setState(() {
      _fromLatLng = LatLng(position.latitude, position.longitude);
    });

    final GoogleMapController controller = await _mapController.future;
    controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(position.latitude, position.longitude),
          zoom: 16,
        ),
      ),
    );
  }

  // --- 2. SEARCH & PLACE DETAILS LOGIC ---
  void _onSearchChanged(String input, {required bool isFrom}) async {
    if (input.isEmpty) {
      setState(() {
        if (isFrom)
          _fromSuggestions = [];
        else
          _toSuggestions = [];
      });
      return;
    }
    try {
      final suggestions = await _placeService.getSuggestions(
        input,
        _sessionToken,
      );
      setState(() {
        if (isFrom) {
          _fromSuggestions = suggestions;
          _isFromFieldFocused = true;
        } else {
          _toSuggestions = suggestions;
          _isFromFieldFocused = false;
        }
      });
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  // NEW: Fetch LatLng from Place ID to enable routing and pricing
  Future<void> _getPlaceDetails(
    String placeId,
    String description,
    bool isFrom,
  ) async {
    final String _googleApiKey = "AIzaSyDfOLxaH9E5-hZ0RlPdclHVWv51Nx7hamk";
    final String url =
        "https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&fields=geometry&key=$_googleApiKey";

    try {
      final HttpClientRequest request = await HttpClient().getUrl(
        Uri.parse(url),
      );
      final HttpClientResponse response = await request.close();
      final String responseBody = await response.transform(utf8.decoder).join();
      final json = jsonDecode(responseBody);

      if (json['result'] != null) {
        final lat = json['result']['geometry']['location']['lat'];
        final lng = json['result']['geometry']['location']['lng'];
        final LatLng coords = LatLng(lat, lng);

        setState(() {
          if (isFrom) {
            _fromLatLng = coords;
            _fromController.text = description;
            _fromSuggestions = [];
          } else {
            _toLatLng = coords;
            _toController.text = description;
            _toSuggestions = [];
          }
          FocusScope.of(context).unfocus();
        });
      }
    } catch (e) {
      debugPrint("Error fetching place details: $e");
    }
  }

  Future<void> _drawRoute(LatLng driverLoc) async {
    if (_fromLatLng == null) {
      print("ERROR: From Location is null");
      return;
    }

    // Print for debugging
    print("FETCHING DIRECTIONS...");
    print("Origin: ${_fromLatLng!.latitude},${_fromLatLng!.longitude}");
    print("Destination: ${driverLoc.latitude},${driverLoc.longitude}");
    final String _googleApiKey = "AIzaSyDfOLxaH9E5-hZ0RlPdclHVWv51Nx7hamk";
    final String url =
        "https://maps.googleapis.com/maps/api/directions/json?origin=${_fromLatLng!.latitude},${_fromLatLng!.longitude}&destination=${driverLoc.latitude},${driverLoc.longitude}&mode=driving&key=$_googleApiKey";

    try {
      final HttpClientRequest request = await HttpClient().getUrl(
        Uri.parse(url),
      );
      final HttpClientResponse response = await request.close();
      final String responseBody = await response.transform(utf8.decoder).join();
      final json = jsonDecode(responseBody);

      // CHECK API STATUS
      if (json['status'] != 'OK') {
        print("---------------------------------------");
        print("DIRECTIONS API ERROR: ${json['status']}");
        print("ERROR MESSAGE: ${json['error_message']}");
        print("---------------------------------------");

        // Show snackbar to user for visibility
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Map Error: ${json['status']}")),
          );
        }
        return;
      }

      if (json['routes'] != null && json['routes'].isNotEmpty) {
        final String polylinePoints =
            json['routes'][0]['overview_polyline']['points'];
        final List<LatLng> decodedPoints = _decodePolyline(polylinePoints);

        setState(() {
          _polylines.clear(); // Clear previous lines
          _polylines.add(
            Polyline(
              polylineId: const PolylineId("user_to_driver"),
              color: Colors.blue, // Make sure color is visible
              width: 6,
              points: decodedPoints,
              geodesic: true,
            ),
          );
        });

        print("ROUTE DRAWN with ${decodedPoints.length} points");

        // Adjust Camera to fit route
        final GoogleMapController controller = await _mapController.future;
        LatLngBounds bounds = _boundsFromLatLngList(decodedPoints);
        controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
      }
    } catch (e) {
      print("EXCEPTION FETCHING DIRECTIONS: $e");
    }
  }

  // Helper: Decode Google Polyline String
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

  // Helper: Create Bounds for camera
  LatLngBounds _boundsFromLatLngList(List<LatLng> list) {
    double? minLat, maxLat, minLng, maxLng;
    for (final latLng in list) {
      if (minLat == null || latLng.latitude < minLat) minLat = latLng.latitude;
      if (maxLat == null || latLng.latitude > maxLat) maxLat = latLng.latitude;
      if (minLng == null || latLng.longitude < minLng)
        minLng = latLng.longitude;
      if (maxLng == null || latLng.longitude > maxLng)
        maxLng = latLng.longitude;
    }
    return LatLngBounds(
      southwest: LatLng(minLat!, minLng!),
      northeast: LatLng(maxLat!, maxLng!),
    );
  }

  // --- 4. PRICING LOGIC ---
  void _calculateDistanceAndPrice() {
    if (_fromLatLng != null && _toLatLng != null) {
      double distanceInMeters = Geolocator.distanceBetween(
        _fromLatLng!.latitude,
        _fromLatLng!.longitude,
        _toLatLng!.latitude,
        _toLatLng!.longitude,
      );
      _tripDistanceKm = distanceInMeters / 1000;
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    // Check if both fields are filled and we have coordinates
    final bool isFindNowEnabled =
        _fromLatLng != null &&
        _toLatLng != null &&
        _fromController.text.isNotEmpty &&
        _toController.text.isNotEmpty;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // 1. GOOGLE MAP
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: _showRideList ? screenHeight * 0.5 : screenHeight * 0.6,
            child: GoogleMap(
              mapType: MapType.normal,
              initialCameraPosition: _kInitialPosition,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              compassEnabled: false,
              markers: _markers,
              polylines: _polylines, // NEW: Polylines added
              onMapCreated: (controller) => _mapController.complete(controller),
            ),
          ),

          // 2. TOP NAVIGATION
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.black),
                        onPressed: () {
                          if (_showRideList) {
                            setState(() {
                              _showRideList = false;
                              _polylines.clear(); // Clear route when going back
                            });
                          } else {
                            Navigator.pop(context);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 20),
                    Text(
                      _showRideList ? "Select Ride" : "Ride",
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 3. BOTTOM SHEET
          Align(
            alignment: Alignment.bottomCenter,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              height: _showRideList ? screenHeight * 0.55 : screenHeight * 0.40,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 20,
                    spreadRadius: 5,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              child: _showRideList
                  ? _buildRideSelectionList()
                  : _buildSearchForm(isFindNowEnabled),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchForm(bool isButtonEnabled) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 30, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "From",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 10),
          _buildLocationField(
            controller: _fromController,
            placeholder: "From location",
            prefixIcon: Icons.location_on_outlined,
            suffixIcon: Icons.my_location,
            onFocus: () => setState(() => _isFromFieldFocused = true),
          ),
          if (_isFromFieldFocused && _fromSuggestions.isNotEmpty)
            _buildSuggestionList(_fromSuggestions, true),

          const SizedBox(height: 20),
          const Text(
            "To",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 10),
          _buildLocationField(
            controller: _toController,
            placeholder: "To location",
            prefixIcon: Icons.location_on_outlined,
            suffixIcon: Icons.map_outlined,
            onFocus: () => setState(() => _isFromFieldFocused = false),
          ),
          if (!_isFromFieldFocused && _toSuggestions.isNotEmpty)
            _buildSuggestionList(_toSuggestions, false),

          const Spacer(),

          // FIND NOW BUTTON
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              // NEW: Disable button if fields are not valid
              onPressed: isButtonEnabled
                  ? () {
                      _calculateDistanceAndPrice(); // Calculate before showing list
                      setState(() {
                        _showRideList = true;
                      });
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                disabledBackgroundColor:
                    Colors.grey.shade300, // Grey when disabled
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text(
                "Find Now",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildRideSelectionList() {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.only(top: 12, bottom: 8),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('drivers')
                .where('status', isEqualTo: 'online')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError)
                return const Center(child: Text("Error loading drivers"));
              if (!snapshot.hasData)
                return const Center(child: CircularProgressIndicator());

              final docs = snapshot.data!.docs;
              if (docs.isEmpty)
                return const Center(child: Text("No drivers nearby"));

              return ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 10),
                itemCount: docs.length,
                separatorBuilder: (context, index) =>
                    Divider(color: Colors.grey[200], height: 1),
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  final docId = docs[index].id;
                  final vehicle =
                      data['vehicle'] as Map<String, dynamic>? ?? {};

                  // NEW: Get Driver Location for routing
                  final locMap = data['location'] as Map<String, dynamic>;
                  LatLng dLoc = LatLng(locMap['lat'], locMap['lng']);

                  // NEW: Calculate Price Based on Trip Distance
                  // Base Fare: $50 + ($2.50 * KM)
                  double calculatedPrice = 50.0 + (_tripDistanceKm * 2.5);

                  final ride = RideOption(
                    id: docId,
                    driverName: data['driverName'] ?? "Unknown Driver",
                    rating: (data['rating'] as num?)?.toDouble() ?? 5.0,
                    price: calculatedPrice, // Use Calculated Price
                    time:
                        "${(5 + Random().nextInt(10))} min", // Mock arrival time
                    seats: "4 Seats",
                    driverImage: 'https://i.pravatar.cc/150?u=$docId',
                    carImage:
                        'https://purepng.com/public/uploads/large/purepng.com-black-suvcarvehicletransportsuvblack-suv-96152466918460tva.png',
                    carDescription:
                        "${vehicle['color'] ?? ''} ${vehicle['model'] ?? 'Car'}"
                            .trim(),
                    driverLocation: dLoc,
                  );

                  final isSelected = _selectedRideId == ride.id;

                  return InkWell(
                    onTap: () {
                      setState(() => _selectedRideId = ride.id);
                      // NEW: Draw Route when driver is tapped
                      _drawRoute(ride.driverLocation);
                    },
                    child: Container(
                      color: isSelected
                          ? Colors.blue.withOpacity(0.05)
                          : Colors.transparent,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: Colors.grey[200],
                            backgroundImage: NetworkImage(ride.driverImage),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      ride.driverName,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Icon(
                                      Icons.star,
                                      size: 16,
                                      color: Colors.orange[700],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      ride.rating.toStringAsFixed(1),
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  ride.carDescription,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[500],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Text(
                                      "\$${ride.price.toInt()}",
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF3B82F6),
                                      ),
                                    ),
                                    _buildVerticalDivider(),
                                    Text(
                                      ride.time,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    _buildVerticalDivider(),
                                    Text(
                                      ride.seats,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            width: 80,
                            height: 50,
                            child: Image.network(
                              ride.carImage,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 10, 24, 30),
          child: SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: _selectedRideId == null
                  ? null
                  : () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Ride Booked! ID: $_selectedRideId"),
                        ),
                      );
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                disabledBackgroundColor: Colors.grey[300],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text(
                "Select Ride",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      height: 12,
      width: 1,
      color: Colors.grey[300],
      margin: const EdgeInsets.symmetric(horizontal: 10),
    );
  }

  Widget _buildSuggestionList(List<PlacePrediction> suggestions, bool isFrom) {
    return Container(
      height: 150,
      margin: const EdgeInsets.only(top: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ListView.builder(
        padding: EdgeInsets.zero,
        itemCount: suggestions.length,
        itemBuilder: (context, index) {
          final place = suggestions[index];
          return ListTile(
            dense: true,
            title: Text(
              place.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            leading: const Icon(Icons.place, size: 20, color: Colors.grey),
            onTap: () {
              // NEW: Call helper to get coords
              _getPlaceDetails(place.placeId, place.description, isFrom);
            },
          );
        },
      ),
    );
  }

  Widget _buildLocationField({
    required TextEditingController controller,
    required String placeholder,
    required IconData prefixIcon,
    required IconData suffixIcon,
    required VoidCallback onFocus,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F9),
        borderRadius: BorderRadius.circular(30),
      ),
      child: TextField(
        controller: controller,
        onTap: onFocus,
        onChanged: (value) =>
            onFocus(), // Keeps state updating for button enable/disable
        decoration: InputDecoration(
          hintText: placeholder,
          hintStyle: const TextStyle(color: Colors.grey),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
          prefixIcon: Icon(prefixIcon, color: Colors.grey[600]),
          suffixIcon: Icon(suffixIcon, color: Colors.black87),
        ),
      ),
    );
  }
}
