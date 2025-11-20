import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class LocationMap extends StatefulWidget {
  final double height; // fixed height

  const LocationMap({super.key, required this.height});

  @override
  State<LocationMap> createState() => _LocationMapState();
}

class _LocationMapState extends State<LocationMap> {
  GoogleMapController? _mapController;

  static const CameraPosition initialCameraPosition = CameraPosition(
    target: LatLng(20.5937, 78.9629), // default India view
    zoom: 5,
  );

  LatLng? _currentLatLng;

  @override
  void initState() {
    super.initState();
    _checkAndGetLocation();
  }

  Future<void> _checkAndGetLocation() async {
    // Check if location services are ON
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    // Check permission
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    // Get current location
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    _currentLatLng = LatLng(position.latitude, position.longitude);
     print("My Latitude: ${position.latitude}");
     print("My Longitude: ${position.longitude}");

    // If map is ready → move camera
    if (_mapController != null && _currentLatLng != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(_currentLatLng!, 16),
      );
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: GoogleMap(
        initialCameraPosition: initialCameraPosition,
        myLocationEnabled: true,          // shows BLUE DOT
        myLocationButtonEnabled: true,    // shows GPS button
        onMapCreated: (controller) async {
          _mapController = controller;

          // After map is ready → fetch location again & move camera
          await _checkAndGetLocation();

          if (_currentLatLng != null) {
            controller.animateCamera(
              CameraUpdate.newLatLngZoom(_currentLatLng!, 16),
            );
          }
        },
      ),
    );
  }
}
