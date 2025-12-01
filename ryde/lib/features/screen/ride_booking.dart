import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math'; // Used for generic calculations
import 'dart:ui' as ui;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ryde/services/place_service.dart'; // Ensure this path matches your project
import 'package:uuid/uuid.dart';
import 'package:geolocator/geolocator.dart';

// --- RIDE OPTION MODEL ---
class RideOption {
  final String id;
  final String driverName;
  final double rating;
  final double price;
  final String time; // ETA
  final String seats;
  final String carImage;
  final String driverImage;
  final String carDescription;
  final String vehicleNumber; // License Plate
  final LatLng driverLocation;
  final String vehicleType;

  // Display Fields
  final String displayTitle;
  final bool isGeneric;

  // Parcel Capabilities
  final String maxWeight;
  final String maxDim;

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
    required this.vehicleType,
    this.vehicleNumber = "",
    this.displayTitle = "",
    this.isGeneric = false,
    this.maxWeight = "",
    this.maxDim = "",
  });
}

// --- MAIN SCREEN ---
class RideBookingScreen extends StatefulWidget {
  const RideBookingScreen({super.key});

  @override
  State<RideBookingScreen> createState() => _RideBookingScreenState();
}

class _RideBookingScreenState extends State<RideBookingScreen> {
  final Completer<GoogleMapController> _mapController = Completer();

  // ⚠️ SECURITY WARNING: Restrict this key in Google Cloud Console!
  final String _googleApiKey = "AIzaSyDfOLxaH9E5-hZ0RlPdclHVWv51Nx7hamk";

  late PlaceService _placeService;
  final _uuid = const Uuid();
  String _sessionToken = '123456';

  // Location Controllers
  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _toController = TextEditingController();

  // --- REVIEW & DETAILS CONTROLLERS ---
  final TextEditingController _senderNameController = TextEditingController(
    text: "AMALRAJ PP",
  );
  final TextEditingController _senderPhoneController = TextEditingController(
    text: "7907676509",
  );
  final TextEditingController _senderBuildingController =
      TextEditingController();
  final TextEditingController _senderUnitController = TextEditingController();
  final TextEditingController _senderInstructionController =
      TextEditingController();
  String _senderOption = "Meet at curb";

  final TextEditingController _receiverNameController = TextEditingController();
  final TextEditingController _receiverPhoneController =
      TextEditingController();
  final TextEditingController _receiverBuildingController =
      TextEditingController();
  final TextEditingController _receiverUnitController = TextEditingController();
  final TextEditingController _receiverInstructionController =
      TextEditingController();
  String _receiverOption = "Meet at curb";

  List<PlacePrediction> _fromSuggestions = [];
  List<PlacePrediction> _toSuggestions = [];
  bool _isFromFieldFocused = false;

  // Location & Routing
  LatLng? _fromLatLng;
  LatLng? _toLatLng;
  double _tripDistanceKm = 0.0;
  int _tripDurationMins = 0;
  int _driverArrivalMins = 0;
  Set<Polyline> _polylines = {};
  List<LatLng> _routePoints = [];

  // UI State
  bool _isSearching = false;
  bool _isLoading = false;

  // -- UI STATES --
  bool _showReviewScreen = false;
  bool _isEditingPickup = false;
  bool _isEditingDropoff = false;
  bool _isFindingDriver =
      false; // Displays the loader while waiting for driver acceptance

  bool _showRideList = false;
  RideOption? _selectedVehicleType;

  // This will be populated ONLY when a driver accepts the request
  RideOption? _assignedDriver;

  bool _isBookingSuccess = false;
  bool _isTracking = false;

  // Map & Driver State
  Set<Marker> _markers = {};
  BitmapDescriptor? _carIcon;

  // Streams
  StreamSubscription? _driverSubscription; // Listens to all drivers on map
  StreamSubscription?
  _bookingSubscription; // Listens to the specific booking status

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
    _bookingSubscription?.cancel(); // Cancel the booking listener
    _fromController.dispose();
    _toController.dispose();
    _senderNameController.dispose();
    _senderPhoneController.dispose();
    _senderBuildingController.dispose();
    _senderUnitController.dispose();
    _senderInstructionController.dispose();
    _receiverNameController.dispose();
    _receiverPhoneController.dispose();
    _receiverBuildingController.dispose();
    _receiverUnitController.dispose();
    _receiverInstructionController.dispose();
    super.dispose();
  }

  // --- 1. MODIFIED: CREATE RIDE REQUEST (Broadcast) ---
  // Returns the DocumentReference so we can listen to it.
  Future<DocumentReference?> _createRideRequest() async {
    if (_selectedVehicleType == null ||
        _fromLatLng == null ||
        _toLatLng == null)
      return null;

    try {
      final FirebaseAuth _auth = FirebaseAuth.instance;
      final uid = _auth.currentUser?.uid ?? "guest_user";

      // We create a booking with 'pending' status.
      // We do NOT save driver_id yet. We wait for a driver to update it.
      print("booking ride for ${_selectedVehicleType!.vehicleType}");
      DocumentReference ref = await FirebaseFirestore.instance
          .collection('bookings')
          .add({
            'created_at': FieldValue.serverTimestamp(),
            'status': 'pending', // Waiting for driver
            'customer_id': uid,
            'driver_id': null,
            'price': _selectedVehicleType!.price,
            'vehicle_type': _selectedVehicleType!
                .vehicleType, // Important for driver filtering
            'route': {
              'pickup_address': _fromController.text,
              'dropoff_address': _toController.text,
              'pickup_lat': _fromLatLng!.latitude,
              'pickup_lng': _fromLatLng!.longitude,
              'dropoff_lat': _toLatLng!.latitude,
              'dropoff_lng': _toLatLng!.longitude,
              'distance_km': _tripDistanceKm,
              'duration_mins': _tripDurationMins,
            },
            'pickup_details': {
              'name': _senderNameController.text,
              'phone': _senderPhoneController.text,
              'building': _senderBuildingController.text,
              'unit': _senderUnitController.text,
              'instructions': _senderInstructionController.text,
              'option': _senderOption,
            },
            'dropoff_details': {
              'name': _receiverNameController.text,
              'phone': _receiverPhoneController.text,
              'building': _receiverBuildingController.text,
              'unit': _receiverUnitController.text,
              'instructions': _receiverInstructionController.text,
              'option': _receiverOption,
            },
          });
      print(ref);
      return ref;
    } catch (e) {
      debugPrint("Error creating request: $e");
      return null;
    }
  }

  // --- 2. NEW: LISTEN FOR DRIVER ACCEPTANCE ---
  void _listenForDriverAcceptance(DocumentReference bookingRef) {
    _bookingSubscription = bookingRef.snapshots().listen((snapshot) {
      if (!snapshot.exists) return;

      final data = snapshot.data() as Map<String, dynamic>;
      final String status = data['status'] ?? 'pending';

      // Check if a driver has accepted
      if (status == 'accepted' && data['driver_id'] != null) {
        _bookingSubscription?.cancel(); // Stop listening once found

        // Extract driver details written by the Driver App
        final driverData = data['driver_details'] ?? {};

        // Create the Assigned Driver object from the live data
        final matchedDriver = RideOption(
          id: data['driver_id'],
          driverName: driverData['name'] ?? "Ryde Driver",
          rating: (driverData['rating'] as num?)?.toDouble() ?? 5.0,
          price:
              (data['price'] as num?)?.toDouble() ??
              _selectedVehicleType!.price,
          time: "Arriving",
          seats: "",
          carImage: _selectedVehicleType?.carImage ?? 'assets/images/car.png',
          driverImage:
              driverData['image'] ??
              'https://i.pravatar.cc/150?u=${data['driver_id']}',
          carDescription: driverData['car_model'] ?? "Vehicle",
          vehicleNumber: driverData['plate_number'] ?? "",
          driverLocation: LatLng(
            (data['driver_location_lat'] as num?)?.toDouble() ??
                _fromLatLng!.latitude,
            (data['driver_location_lng'] as num?)?.toDouble() ??
                _fromLatLng!.longitude,
          ),
          vehicleType: data['vehicle_type'] ?? 'car',
          displayTitle: "On the way",
        );

        setState(() {
          _assignedDriver = matchedDriver;
          _isFindingDriver = false; // Remove loading screen
          // Update route to show driver approaching
          _drawRoute(_assignedDriver!.driverLocation);
          _refitMapWithDelay();
        });
      }
    });
  }

  // --- INDIAN FARE CALCULATION ---
  double _calculateIndianFare(
    String vehicleType,
    double distanceKm,
    int timeMins,
  ) {
    double baseFare = 0;
    double perKm = 0;
    double perMin = 0;
    double minFare = 0;

    String type = vehicleType.toLowerCase();

    if (type.contains('bike') || type.contains('motorcycle')) {
      baseFare = 20.0;
      perKm = 6.0;
      perMin = 1.0;
      minFare = 30.0;
    } else if (type.contains('auto') || type.contains('rickshaw')) {
      baseFare = 30.0;
      perKm = 15.0;
      perMin = 1.5;
      minFare = 40.0;
    } else if (type.contains('car')) {
      baseFare = 50.0;
      perKm = 18.0;
      perMin = 2.0;
      minFare = 80.0;
    } else {
      baseFare = 200.0;
      perKm = 25.0;
      perMin = 3.0;
      minFare = 500.0;
    }
    double total = baseFare + (distanceKm * perKm) + (timeMins * perMin);
    return total < minFare ? minFare : total;
  }

  // --- MAP HELPERS ---
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
            if (data['location'] != null) {
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
                  ),
                );
              }
            }
          }
          if (mounted) setState(() => _markers = newMarkers);
        }, onError: (e) => print("Error listening to drivers: $e"));
  }

  Future<String> _getAddressFromLatLng(double lat, double lng) async {
    try {
      final String url =
          "https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lng&key=$_googleApiKey";
      final HttpClientRequest request = await HttpClient().getUrl(
        Uri.parse(url),
      );
      final HttpClientResponse response = await request.close();
      final String responseBody = await response.transform(utf8.decoder).join();
      final json = jsonDecode(responseBody);
      if (json['status'] == 'OK' &&
          json['results'] != null &&
          json['results'].isNotEmpty) {
        return json['results'][0]['formatted_address'];
      }
    } catch (e) {
      print("Error fetching address: $e");
    }
    return "Current Location";
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return Future.error('Location services are disabled.');
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied)
        return Future.error('Location permissions are denied');
    }
    if (permission == LocationPermission.deniedForever)
      return Future.error('Location permissions are permanently denied.');

    Position position = await Geolocator.getCurrentPosition();
    String currentAddress = await _getAddressFromLatLng(
      position.latitude,
      position.longitude,
    );

    setState(() {
      _fromLatLng = LatLng(position.latitude, position.longitude);
      _fromController.text = currentAddress;
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

  void _onSearchChanged(String input, {required bool isFrom}) async {
    if (!isFrom && input.isEmpty) {
      setState(() => _toSuggestions = []);
      return;
    }
    if (isFrom && !_isFromFieldFocused) return;
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
        if (isFrom)
          _fromSuggestions = suggestions;
        else
          _toSuggestions = suggestions;
      });
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  Future<void> _getPlaceDetails(
    String placeId,
    String description,
    bool isFrom,
  ) async {
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
          _isSearching = false;
          FocusScope.of(context).unfocus();
        });
      }
    } catch (e) {
      debugPrint("Error fetching place details: $e");
    }
  }

  // --- ROUTE & TRIP LOGIC ---
  Future<void> _drawRoute(LatLng targetLoc) async {
    if (_fromLatLng == null) return;
    // If we have an assigned driver, draw from Driver to Pickup
    // If not, draw from Pickup to Dropoff (for route preview)

    LatLng origin = _assignedDriver != null ? targetLoc : _fromLatLng!;
    LatLng dest = _assignedDriver != null ? _fromLatLng! : targetLoc;

    // NOTE: For better UX, if driver is assigned, origin=Driver, dest=Pickup
    // If just booking, origin=Pickup, dest=Dropoff.
    // The previous logic passed 'driverLoc', which implies we are showing driver path.

    final String url =
        "https://maps.googleapis.com/maps/api/directions/json?origin=${origin.latitude},${origin.longitude}&destination=${dest.latitude},${dest.longitude}&mode=driving&key=$_googleApiKey";
    try {
      final HttpClientRequest request = await HttpClient().getUrl(
        Uri.parse(url),
      );
      final HttpClientResponse response = await request.close();
      final String responseBody = await response.transform(utf8.decoder).join();
      final json = jsonDecode(responseBody);
      if (json['status'] != 'OK') return;

      if (json['routes'] != null && json['routes'].isNotEmpty) {
        final String polylinePoints =
            json['routes'][0]['overview_polyline']['points'];
        final List<LatLng> decodedPoints = _decodePolyline(polylinePoints);
        int durationSeconds = 600;
        if (json['routes'][0]['legs'] != null) {
          durationSeconds =
              json['routes'][0]['legs'][0]['duration']['value'] ?? 600;
        }

        setState(() {
          _driverArrivalMins = (durationSeconds / 60).ceil();
          _routePoints = decodedPoints;
          _polylines.clear();
          _polylines.add(
            Polyline(
              polylineId: const PolylineId("route"),
              color: Colors.black,
              width: 5,
              points: decodedPoints,
              geodesic: true,
            ),
          );
        });
        _fitBounds(decodedPoints);
      }
    } catch (e) {
      print("EXCEPTION FETCHING DIRECTIONS: $e");
    }
  }

  Future<void> _fitBounds(List<LatLng> points) async {
    if (points.isEmpty) return;
    final GoogleMapController controller = await _mapController.future;
    LatLngBounds bounds = _boundsFromLatLngList(points);
    controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
  }

  void _refitMapWithDelay() {
    if (_routePoints.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fitBounds(_routePoints);
      });
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

  Future<void> _getTripDetails() async {
    if (_fromLatLng == null || _toLatLng == null) return;
    setState(() => _isLoading = true);
    final String url =
        "https://maps.googleapis.com/maps/api/directions/json?origin=${_fromLatLng!.latitude},${_fromLatLng!.longitude}&destination=${_toLatLng!.latitude},${_toLatLng!.longitude}&mode=driving&key=$_googleApiKey";

    try {
      final HttpClientRequest request = await HttpClient().getUrl(
        Uri.parse(url),
      );
      final HttpClientResponse response = await request.close();
      final String responseBody = await response.transform(utf8.decoder).join();
      final json = jsonDecode(responseBody);

      if (json['status'] == 'OK' &&
          json['routes'] != null &&
          json['routes'].isNotEmpty) {
        final leg = json['routes'][0]['legs'][0];
        final int distanceMeters = leg['distance']['value'];
        final int durationSeconds = leg['duration']['value'];

        setState(() {
          _tripDistanceKm = distanceMeters / 1000;
          _tripDurationMins = (durationSeconds / 60).ceil();
          final String polylinePoints =
              json['routes'][0]['overview_polyline']['points'];
          final List<LatLng> decodedPoints = _decodePolyline(polylinePoints);
          _routePoints = decodedPoints;
          _polylines.clear();
          _polylines.add(
            Polyline(
              polylineId: const PolylineId("trip_route"),
              color: Colors.black,
              width: 5,
              points: decodedPoints,
            ),
          );
        });
        _fitBounds(_routePoints);
      }
    } catch (e) {
      print("Error fetching trip details: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // --- SHEET HEIGHT LOGIC ---
  double _getSheetHeight(double screenHeight) {
    if (_isFindingDriver) return screenHeight * 0.35; // Loading state
    if (_isEditingPickup || _isEditingDropoff) return screenHeight * 0.90;
    if (_showReviewScreen) return screenHeight * 0.55;
    if (_isTracking) return screenHeight * 0.60;
    if (_isBookingSuccess) return screenHeight * 0.60;
    if (_assignedDriver != null) return screenHeight * 0.70;
    if (_showRideList) return screenHeight * 0.65;
    if (_isSearching) return screenHeight * 0.85;
    return screenHeight * 0.40;
  }

  void _resetApp() {
    _bookingSubscription?.cancel(); // Stop listening
    setState(() {
      _isTracking = false;
      _isBookingSuccess = false;
      _assignedDriver = null;
      _selectedVehicleType = null;
      _showRideList = false;
      _showReviewScreen = false;
      _isEditingPickup = false;
      _isEditingDropoff = false;
      _isFindingDriver = false;
      _polylines.clear();
      _routePoints.clear();
      _fromController.clear();
      _toController.clear();
      _fromLatLng = null;
      _toLatLng = null;
      _tripDistanceKm = 0.0;
      _tripDurationMins = 0;

      // Clear details forms
      _senderBuildingController.clear();
      _senderUnitController.clear();
      _receiverNameController.clear();
      _receiverPhoneController.clear();
      _receiverBuildingController.clear();
      _receiverUnitController.clear();
    });
    _determinePosition();
  }

  List<String> _getAllowedVehicleTypes() {
    return ['bike', 'auto', 'car', 'tempo'];
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final double bottomPadding = _getSheetHeight(screenHeight);

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
            height: screenHeight,
            child: GoogleMap(
              mapType: MapType.normal,
              initialCameraPosition: _kInitialPosition,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              compassEnabled: false,
              padding: EdgeInsets.only(bottom: bottomPadding),
              markers: _markers,
              polylines: _polylines,
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
                          if (_isEditingPickup)
                            setState(() => _isEditingPickup = false);
                          else if (_isEditingDropoff)
                            setState(() => _isEditingDropoff = false);
                          else if (_isFindingDriver) {
                            // User cancelled while searching
                            setState(() => _isFindingDriver = false);
                            _bookingSubscription?.cancel();
                            // Optional: Update firestore to 'cancelled' here
                          } else if (_showReviewScreen)
                            setState(() {
                              _showReviewScreen = false;
                              _polylines.clear();
                            });
                          else if (_isTracking)
                            _resetApp();
                          else if (_isBookingSuccess)
                            _resetApp();
                          else if (_assignedDriver != null)
                            setState(() {
                              _assignedDriver = null;
                              _isBookingSuccess = false;
                              _showRideList = true;
                              _bookingSubscription?.cancel();
                            });
                          else if (_showRideList)
                            setState(() {
                              _showRideList = false;
                              _showReviewScreen = true;
                              _selectedVehicleType = null;
                            });
                          else if (_isSearching)
                            setState(() {
                              _isSearching = false;
                              FocusScope.of(context).unfocus();
                            });
                          else
                            Navigator.pop(context);
                        },
                      ),
                    ),
                    const SizedBox(width: 20),
                    Text(
                      _isEditingPickup
                          ? "Pick-up details"
                          : _isEditingDropoff
                          ? "Drop-off details"
                          : _showReviewScreen
                          ? "Review delivery"
                          : _isFindingDriver
                          ? "Connecting..."
                          : _isTracking
                          ? ""
                          : (_isBookingSuccess
                                ? ""
                                : (_assignedDriver != null
                                      ? "Driver Found"
                                      : (_showRideList
                                            ? "Choose Vehicle"
                                            : "Ride"))),
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
              height: _getSheetHeight(screenHeight),
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
              child: _isEditingPickup
                  ? _buildContactDetailsSheet(isPickup: true)
                  : _isEditingDropoff
                  ? _buildContactDetailsSheet(isPickup: false)
                  : _showReviewScreen
                  ? _buildReviewOrderSheet()
                  : _isFindingDriver
                  ? _buildFindingDriverSheet()
                  : _isTracking
                  ? _buildTrackingSheet()
                  : _isBookingSuccess
                  ? _buildSuccessSheet()
                  : _assignedDriver != null
                  ? _buildRideDetailsSheet()
                  : _showRideList
                  ? _buildRideSelectionList()
                  : _buildSearchForm(isFindNowEnabled),
            ),
          ),

          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildFindingDriverSheet() {
    return SizedBox(
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 50,
            height: 50,
            child: CircularProgressIndicator(
              strokeWidth: 4,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            "Requesting ${_selectedVehicleType?.displayTitle ?? 'Ride'}...",
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            "Waiting for a driver to accept...",
            style: TextStyle(color: Colors.grey),
          ),
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

              final allDocs = snapshot.data!.docs;
              final allowedTypes = _getAllowedVehicleTypes();

              Map<String, List<QueryDocumentSnapshot>> groupedDrivers = {};
              for (var doc in allDocs) {
                final data = doc.data() as Map<String, dynamic>;
                final vehicle = data['vehicle'] as Map<String, dynamic>? ?? {};
                String type = (vehicle['vehicle_type'] ?? '')
                    .toString()
                    .toLowerCase();
                if (allowedTypes.contains(type)) {
                  if (!groupedDrivers.containsKey(type))
                    groupedDrivers[type] = [];
                  groupedDrivers[type]!.add(doc);
                }
              }

              if (groupedDrivers.isEmpty) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.no_transfer, size: 40, color: Colors.grey),
                    const SizedBox(height: 10),
                    Text(
                      "No vehicles available",
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                );
              }

              List<RideOption> vehicleOptions = [];
              // Logic to display ESTIMATED options based on nearest driver
              groupedDrivers.forEach((type, drivers) {
                double minDistance = double.infinity;
                QueryDocumentSnapshot? nearestDriverDoc;

                for (var driverDoc in drivers) {
                  final data = driverDoc.data() as Map<String, dynamic>;
                  final locMap = data['location'] as Map<String, dynamic>;
                  double dist = Geolocator.distanceBetween(
                    locMap['lat'],
                    locMap['lng'],
                    _fromLatLng!.latitude,
                    _fromLatLng!.longitude,
                  );
                  if (dist < minDistance) {
                    minDistance = dist;
                    nearestDriverDoc = driverDoc;
                  }
                }

                if (nearestDriverDoc != null) {
                  final data = nearestDriverDoc!.data() as Map<String, dynamic>;
                  final vehicle =
                      data['vehicle'] as Map<String, dynamic>? ?? {};
                  final locMap = data['location'] as Map<String, dynamic>;
                  int timeMins = (minDistance / 400).ceil();
                  double price = _calculateIndianFare(
                    type,
                    _tripDistanceKm,
                    _tripDurationMins,
                  );

                  String displayTitle = "Ride";
                  String carImage = 'assets/images/car.png';
                  String maxWeight = "";
                  String maxDim = "";

                  if (type == 'bike') {
                    displayTitle = "Moto";
                    carImage = 'assets/images/bike.png';
                    maxWeight = "Max 10kg";
                    maxDim = "40x40x40cm";
                  } else if (type == 'auto') {
                    displayTitle = "Auto";
                    carImage = 'assets/images/auto.png';
                    maxWeight = "Max 30kg";
                    maxDim = "60x60x60cm";
                  } else if (type == 'car') {
                    displayTitle = "Premier";
                    carImage = 'assets/images/car.png';
                    maxWeight = "Max 50kg";
                    maxDim = "100x100cm";
                  } else if (type == 'tempo') {
                    displayTitle = "Tempo";
                    carImage = 'assets/images/car.png';
                    maxWeight = "Max 200kg";
                    maxDim = "150x150cm";
                  }

                  String plate = vehicle['plate_number'] ?? 'KA 05 MX 1234';

                  vehicleOptions.add(
                    RideOption(
                      id: nearestDriverDoc!.id,
                      driverName: data['driverName'] ?? "Driver",
                      rating: (data['rating'] as num?)?.toDouble() ?? 5.0,
                      price: price,
                      time: "$timeMins min away",
                      seats: "",
                      carImage: carImage,
                      driverImage:
                          'https://i.pravatar.cc/150?u=${nearestDriverDoc.id}',
                      carDescription:
                          "${vehicle['color'] ?? ''} ${vehicle['model'] ?? ''}",
                      vehicleNumber: plate,
                      driverLocation: LatLng(locMap['lat'], locMap['lng']),
                      vehicleType: type,
                      displayTitle: displayTitle,
                      isGeneric: true,
                      maxWeight: maxWeight,
                      maxDim: maxDim,
                    ),
                  );
                }
              });

              return ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                itemCount: vehicleOptions.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final option = vehicleOptions[index];
                  final isSelected =
                      _selectedVehicleType?.vehicleType == option.vehicleType;

                  return GestureDetector(
                    onTap: () => setState(() => _selectedVehicleType = option),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? Colors.black
                              : Colors.grey.shade200,
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: isSelected
                            ? []
                            : [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 70,
                            height: 60,
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Image.asset(
                              option.carImage,
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      option.displayTitle,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      option.time,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.green,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  children: [
                                    _buildSpecBadge(
                                      Icons.fitness_center,
                                      option.maxWeight,
                                    ),
                                    _buildSpecBadge(
                                      Icons.aspect_ratio,
                                      option.maxDim,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                "₹${option.price.toInt()}",
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (isSelected)
                                const Icon(
                                  Icons.check_circle,
                                  color: Colors.black,
                                  size: 20,
                                ),
                            ],
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
              // --- 3. MODIFIED: Book Button Logic ---
              onPressed: _selectedVehicleType == null
                  ? null
                  : () async {
                      setState(() {
                        _isFindingDriver = true;
                        _assignedDriver = null;
                      });

                      // Create the Pending Request
                      final bookingRef = await _createRideRequest();

                      if (bookingRef != null) {
                        // Wait for a driver to accept
                        _listenForDriverAcceptance(bookingRef);
                      } else {
                        // Error handling
                        setState(() => _isFindingDriver = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Failed to create booking"),
                          ),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                disabledBackgroundColor: Colors.grey[300],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: Text(
                _selectedVehicleType == null
                    ? "Choose a ride"
                    : "Book ${_selectedVehicleType!.displayTitle}",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSpecBadge(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[800],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewOrderSheet() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.black, width: 1.5),
                    ),
                    child: const Center(
                      child: Text(
                        "Delivery details",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Trip details",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.black,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.inventory_2_outlined,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                        Container(width: 2, height: 60, color: Colors.black),
                        Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: Colors.black,
                            shape: BoxShape.rectangle,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _senderNameController.text.isEmpty
                                          ? "Sender"
                                          : _senderNameController.text,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      "${_fromController.text.split(',')[0]}...",
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 13,
                                      ),
                                    ),
                                    Text(
                                      "$_senderOption • ${_senderInstructionController.text.isNotEmpty ? 'Instructions added' : 'Add instructions...'}",
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              TextButton(
                                onPressed: () =>
                                    setState(() => _isEditingPickup = true),
                                style: TextButton.styleFrom(
                                  backgroundColor: Colors.grey[100],
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                child: const Text(
                                  "Edit",
                                  style: TextStyle(color: Colors.black),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 35),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _receiverNameController.text.isEmpty
                                          ? "Add recipient details"
                                          : _receiverNameController.text,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      "${_toController.text.split(',')[0]}...",
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 13,
                                      ),
                                    ),
                                    Text(
                                      "$_receiverOption • ${_receiverInstructionController.text.isNotEmpty ? 'Instructions added' : 'Add instructions...'}",
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              TextButton(
                                onPressed: () =>
                                    setState(() => _isEditingDropoff = true),
                                style: TextButton.styleFrom(
                                  backgroundColor: Colors.grey[100],
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                child: Text(
                                  _receiverNameController.text.isEmpty
                                      ? "Add"
                                      : "Edit",
                                  style: const TextStyle(color: Colors.black),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(height: 40),
                Row(
                  children: [
                    const Text(
                      "Pick-up time",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Icon(Icons.info_outline, size: 18, color: Colors.grey[600]),
                  ],
                ),
                const SizedBox(height: 15),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black, width: 1.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.flash_on, size: 28),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Courier",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            "Pick-up in 3 min",
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: () {
                if (_receiverNameController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Please add recipient details"),
                    ),
                  );
                  return;
                }
                setState(() {
                  _showReviewScreen = false;
                  _showRideList = true;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Confirm details",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    " • ₹${(_tripDistanceKm * 15 + 40).toStringAsFixed(2)}",
                    style: const TextStyle(fontSize: 18, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContactDetailsSheet({required bool isPickup}) {
    final nameCtrl = isPickup ? _senderNameController : _receiverNameController;
    final phoneCtrl = isPickup
        ? _senderPhoneController
        : _receiverPhoneController;
    final buildingCtrl = isPickup
        ? _senderBuildingController
        : _receiverBuildingController;
    final unitCtrl = isPickup ? _senderUnitController : _receiverUnitController;
    final instrCtrl = isPickup
        ? _senderInstructionController
        : _receiverInstructionController;
    String currentOption = isPickup ? _senderOption : _receiverOption;
    String addressText = isPickup ? _fromController.text : _toController.text;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                Text(
                  isPickup ? "Your details" : "Who's receiving the package?",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: "Enter name",
                      suffixIcon: Icon(
                        Icons.person_outline,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Image.network(
                            'https://flagcdn.com/w40/in.png',
                            width: 24,
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.keyboard_arrow_down, size: 16),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: TextField(
                          controller: phoneCtrl,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            prefixText: "+91 ",
                            hintText: "00000 00000",
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 40),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            addressText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Shop or building name",
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: TextField(
                              controller: buildingCtrl,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                hintText: "Shop or buildi...",
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      flex: 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Unit/floor",
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: TextField(
                              controller: unitCtrl,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                hintText: "E.g. Unit 1A",
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 25),
                Text(
                  isPickup ? "Pick-up options" : "Drop-off options",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    ChoiceChip(
                      label: const Text(
                        "Meet at curb",
                        style: TextStyle(color: Colors.white),
                      ),
                      selected: currentOption == "Meet at curb",
                      selectedColor: Colors.black,
                      backgroundColor: Colors.grey[200],
                      onSelected: (val) => setState(
                        () => isPickup
                            ? _senderOption = "Meet at curb"
                            : _receiverOption = "Meet at curb",
                      ),
                      avatar: const Icon(
                        Icons.directions_car,
                        color: Colors.white,
                        size: 18,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                      showCheckmark: false,
                    ),
                    const SizedBox(width: 10),
                    ChoiceChip(
                      label: const Text(
                        "Meet at door",
                        style: TextStyle(color: Colors.black),
                      ),
                      selected: currentOption == "Meet at door",
                      selectedColor: Colors.black,
                      backgroundColor: Colors.grey[200],
                      onSelected: (val) => setState(
                        () => isPickup
                            ? _senderOption = "Meet at door"
                            : _receiverOption = "Meet at door",
                      ),
                      avatar: const Icon(
                        Icons.person,
                        color: Colors.black,
                        size: 18,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                      showCheckmark: false,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  "Some delivery protection alternatives may vary between delivery options.",
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
                const SizedBox(height: 25),
                const Text(
                  "Instructions for driver",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextField(
                    controller: instrCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText:
                          "Add instructions for the driver.\nExample: I'll meet you at the gate...",
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  _isEditingPickup = false;
                  _isEditingDropoff = false;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                "Save and continue",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTrackingSheet() {
    final ride = _assignedDriver!;
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              text: "Arriving in ",
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              children: [
                TextSpan(
                  text: "$_driverArrivalMins Mins",
                  style: const TextStyle(color: Color(0xFF4CAF50)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFEBF5FF),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              children: [
                Column(
                  children: [
                    CircleAvatar(
                      radius: 35,
                      backgroundImage: NetworkImage(ride.driverImage),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      ride.driverName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                SizedBox(
                  width: 120,
                  height: 70,
                  child: Image.asset(ride.carImage, fit: BoxFit.contain),
                ),
              ],
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: _resetApp,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0085FF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text(
                "Back Home",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
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
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 10),
          _buildLocationField(
            controller: _fromController,
            placeholder: "From",
            prefixIcon: Icons.location_on_outlined,
            suffixIcon: Icons.my_location,
            onFocus: () => setState(() {
              _isFromFieldFocused = true;
              _isSearching = true;
            }),
          ),
          if (_isFromFieldFocused && _fromSuggestions.isNotEmpty)
            Expanded(child: _buildSuggestionList(_fromSuggestions, true)),
          if (!(_isFromFieldFocused && _fromSuggestions.isNotEmpty)) ...[
            const SizedBox(height: 20),
            const Text(
              "To",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 10),
            _buildLocationField(
              controller: _toController,
              placeholder: "To",
              prefixIcon: Icons.location_on_outlined,
              suffixIcon: Icons.map_outlined,
              onFocus: () => setState(() {
                _isFromFieldFocused = false;
                _isSearching = true;
              }),
            ),
            if (!_isFromFieldFocused && _toSuggestions.isNotEmpty)
              Expanded(child: _buildSuggestionList(_toSuggestions, false)),
          ],
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: isButtonEnabled
                  ? () async {
                      await _getTripDetails();
                      setState(() {
                        _showReviewScreen = true;
                        _isSearching = false;
                        FocusScope.of(context).unfocus();
                      });
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                disabledBackgroundColor: Colors.grey.shade300,
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
        ],
      ),
    );
  }

  Widget _buildSuccessSheet() {
    return Padding(
      padding: const EdgeInsets.all(30.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: const BoxDecoration(
              color: Color(0xFF4CAF50),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, color: Colors.white, size: 60),
          ),
          const SizedBox(height: 30),
          const Text(
            "Booking placed\nsuccessfully",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: () => setState(() {
                _isBookingSuccess = false;
                _isTracking = true;
                _refitMapWithDelay();
              }),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text(
                "Go Track",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRideDetailsSheet() {
    final ride = _assignedDriver!;
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Driver Found!",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            CircleAvatar(
              radius: 45,
              backgroundImage: NetworkImage(ride.driverImage),
            ),
            const SizedBox(height: 10),
            Text(
              ride.driverName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.star, color: Colors.orange[700], size: 18),
                Text(
                  " ${ride.rating.toStringAsFixed(1)}",
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              ride.carDescription,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            // LICENSE PLATE BADGE
            const SizedBox(height: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.yellow[100],
                border: Border.all(color: Colors.black12),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                ride.vehicleNumber.toUpperCase(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFEBF5FF),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  _buildInfoRow(
                    "Ride Price",
                    "₹${ride.price.toInt()}",
                    isPrice: true,
                  ),
                  const SizedBox(height: 15),
                  _buildInfoRow("ETA", ride.time, isPrice: false),
                ],
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isBookingSuccess = true;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  "Let's Go",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () {
                _resetApp();
              },
              child: SizedBox(
                width: double.infinity,
                height: 55,
                child: TextButton(
                  onPressed: _resetApp,
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.red[50],
                    foregroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    "Cancel Ride",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {required bool isPrice}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 16, color: Colors.grey[800])),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isPrice ? Colors.green : Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildSuggestionList(List<PlacePrediction> suggestions, bool isFrom) {
    return Container(
      margin: const EdgeInsets.only(top: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          const BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ListView.builder(
        padding: EdgeInsets.zero,
        itemCount: suggestions.length,
        itemBuilder: (context, index) {
          final place = suggestions[index];
          return ListTile(
            dense: true,
            title: Text(place.description),
            leading: const Icon(Icons.place, size: 20, color: Colors.grey),
            onTap: () =>
                _getPlaceDetails(place.placeId, place.description, isFrom),
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
        onChanged: (value) => onFocus(),
        decoration: InputDecoration(
          hintText: placeholder,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
          prefixIcon: Icon(prefixIcon, color: Colors.grey[600]),
          suffixIcon: Icon(suffixIcon, color: Colors.black87),
        ),
      ),
    );
  }
}
