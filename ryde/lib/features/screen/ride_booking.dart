import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:ryde/services/place_service.dart'; // Ensure this path is correct in your project
import 'package:uuid/uuid.dart';
import 'package:geolocator/geolocator.dart'; // IMPORT ADDED

class RideBookingScreen extends StatefulWidget {
  const RideBookingScreen({super.key});

  @override
  State<RideBookingScreen> createState() => _RideBookingScreenState();
}

class _RideBookingScreenState extends State<RideBookingScreen> {
  final Completer<GoogleMapController> _mapController = Completer();

  // 1. SETUP KEYS AND CONTROLLERS
  // Note: For security, restrict this key in Google Cloud Console
  final String _googleApiKey = "AIzaSyDfOLxaH9E5-hZ0RlPdclHVWv51Nx7hamk";
  late PlaceService _placeService;
  final _uuid = const Uuid();
  String _sessionToken = '123456';

  // Controllers for text fields
  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _toController = TextEditingController();

  // State for suggestions
  List<PlacePrediction> _fromSuggestions = [];
  List<PlacePrediction> _toSuggestions = [];
  bool _isFromFieldFocused = false;

  static const CameraPosition _kInitialPosition = CameraPosition(
    target: LatLng(37.7749, -122.4194), // Default fallback
    zoom: 14.4746,
  );

  @override
  void initState() {
    super.initState();
    _placeService = PlaceService(_googleApiKey);

    // Generate a fresh session token for this user session
    _sessionToken = _uuid.v4();

    // Listen to text changes
    _fromController.addListener(() {
      _onSearchChanged(_fromController.text, isFrom: true);
    });
    _toController.addListener(() {
      _onSearchChanged(_toController.text, isFrom: false);
    });

    // NEW: Get current location immediately on startup
    _determinePosition();
  }

  // NEW: Function to handle permissions and get location
  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // 1. Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    // 2. Check permissions
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied.');
    }

    // 3. Get current position
    Position position = await Geolocator.getCurrentPosition();

    // 4. Move the map camera
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

  // Fetch predictions
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
      // Handle error silently or show snackbar
      debugPrint("Error fetching places: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      // Resize to avoid keyboard covering bottom sheet details
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // 1. GOOGLE MAP
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: screenHeight * 0.6,
            child: GoogleMap(
              mapType: MapType.normal,
              initialCameraPosition: _kInitialPosition,
              // NEW: Enable the blue dot on the map
              myLocationEnabled: true,
              // We keep this false because we have a custom button below
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              compassEnabled: false,
              onMapCreated: (GoogleMapController controller) {
                _mapController.complete(controller);
              },
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
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(width: 20),
                    const Text(
                      "Ride",
                      style: TextStyle(
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

          // 3. LOCATION BUTTON (UPDATED with GestureDetector)
          Positioned(
            right: 20,
            bottom: (screenHeight * 0.45) + 50,
            child: GestureDetector(
              // NEW: Tapping this now re-centers the map
              onTap: _determinePosition,
              child: Container(
                width: 50,
                height: 50,
                decoration: const BoxDecoration(
                  color: Color(0xFF5ECC71),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.my_location, color: Colors.white),
              ),
            ),
          ),

          // 4. BOTTOM SHEET
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              // Increased height slightly to accommodate list when typing
              height: screenHeight * 0.50,
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
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 30, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // "From" Section
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

                    // Show "From" Suggestions if active
                    if (_isFromFieldFocused && _fromSuggestions.isNotEmpty)
                      _buildSuggestionList(_fromSuggestions, _fromController),

                    const SizedBox(height: 20),

                    // "To" Section
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
                      onFocus: () =>
                          setState(() => _isFromFieldFocused = false),
                    ),

                    // Show "To" Suggestions if active
                    if (!_isFromFieldFocused && _toSuggestions.isNotEmpty)
                      _buildSuggestionList(_toSuggestions, _toController),

                    const Spacer(),

                    // "Find Now" Button
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: () {
                          // Perform search action
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3B82F6),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text(
                          "Find Now",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper to build the list of suggestions
  Widget _buildSuggestionList(
    List<PlacePrediction> suggestions,
    TextEditingController controller,
  ) {
    return Container(
      height: 150, // Limit height
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
              // When tapped, fill the text field and clear suggestions
              controller.text = place.description;
              FocusScope.of(context).unfocus(); // Hide keyboard
              setState(() {
                if (_isFromFieldFocused)
                  _fromSuggestions = [];
                else
                  _toSuggestions = [];
              });
              // TODO: Use place.placeId to get LatLng if needed
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
        onChanged: (value) => onFocus(), // Ensure we know which field is active
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
