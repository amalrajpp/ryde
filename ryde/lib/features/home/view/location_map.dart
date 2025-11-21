import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LocationMap extends StatefulWidget {
  final double height;

  const LocationMap({super.key, required this.height});

  @override
  State<LocationMap> createState() => _LocationMapState();
}

class _LocationMapState extends State<LocationMap> {
  GoogleMapController? _mapController;
  LatLng? _currentLatLng;

  Set<Marker> _markers = {};
  final Map<int, BitmapDescriptor> _markerCache = {}; // cache icons

  static const CameraPosition initialCameraPosition = CameraPosition(
    target: LatLng(20.5937, 78.9629),
    zoom: 5,
  );

  @override
  void initState() {
    super.initState();
    _checkAndGetLocation();
    _listenToDrivers();
  }

  @override
  void dispose() {
    super.dispose();
  }

  // ---------------------------
  // Canvas-based marker generator
  // ---------------------------
  /// Generates a circular marker with a car icon and a small numbered badge.
  /// [diameter] recommended 100..160 for good resolution on map.
  Future<Uint8List> _createCarMarkerBytes(int number, {int diameter = 140}) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, diameter.toDouble(), diameter.toDouble()));

    final double center = diameter / 2;
    final Paint circlePaint = Paint()..color = const Color(0xFFDBECFF); // light blue background
    final Paint badgePaint = Paint()..color = const Color(0xFF3B82F6); // blue badge

    // Draw outer circle
    canvas.drawCircle(Offset(center, center), center, circlePaint);

    // Draw car icon using Icon font
    final double carIconSize = diameter * 0.45;
    final TextPainter carPainter = TextPainter(textDirection: TextDirection.ltr);
    carPainter.text = TextSpan(
      text: String.fromCharCode(Icons.directions_car.codePoint),
      style: TextStyle(
        fontFamily: Icons.directions_car.fontFamily,
        fontSize: carIconSize,
        color: Colors.black87,
      ),
    );
    carPainter.layout();
    final Offset carOffset = Offset(center - carPainter.width / 2, center - carPainter.height / 2);
    carPainter.paint(canvas, carOffset);

    // Draw small badge circle (top-right)
    final double badgeRadius = diameter * 0.16; // badge radius
    final Offset badgeCenter = Offset(center + diameter * 0.26 - badgeRadius, center - diameter * 0.26 + badgeRadius);
    canvas.drawCircle(badgeCenter, badgeRadius, badgePaint);

    // Draw number inside badge
    final TextPainter numberPainter = TextPainter(textDirection: TextDirection.ltr);
    numberPainter.text = TextSpan(
      text: number.toString(),
      style: TextStyle(
        color: Colors.white,
        fontSize: badgeRadius * 1.0,
        fontWeight: FontWeight.bold,
      ),
    );
    numberPainter.layout();
    final Offset numberOffset = Offset(badgeCenter.dx - numberPainter.width / 2, badgeCenter.dy - numberPainter.height / 2);
    numberPainter.paint(canvas, numberOffset);

    // Convert to image
    final ui.Picture picture = recorder.endRecording();
    final ui.Image img = await picture.toImage(diameter, diameter);
    final ByteData? pngBytes = await img.toByteData(format: ui.ImageByteFormat.png);
    return pngBytes!.buffer.asUint8List();
  }

  Future<BitmapDescriptor> _createDriverMarker(int index) async {
    if (_markerCache.containsKey(index)) return _markerCache[index]!;
    final bytes = await _createCarMarkerBytes(index, diameter: 140);
    final descriptor = BitmapDescriptor.fromBytes(bytes);
    _markerCache[index] = descriptor;
    return descriptor;
  }

  // ---------------------------
  // Listen to Firestore drivers
  // ---------------------------
  void _listenToDrivers() {
    FirebaseFirestore.instance
        .collection('drivers')
        .where('status', isEqualTo: 'online')
        .snapshots()
        .listen((snapshot) async {
      final Set<Marker> newMarkers = {};
      for (int i = 0; i < snapshot.docs.length; i++) {
        final doc = snapshot.docs[i];
        final data = doc.data();
        final loc = data['location'] as Map<String, dynamic>?;

        if (loc == null) continue;
        final double lat = (loc['lat'] as num).toDouble();
        final double lng = (loc['lng'] as num).toDouble();

        // create marker icon (cached)
        final BitmapDescriptor icon = await _createDriverMarker(i + 1);

        newMarkers.add(
          Marker(
            markerId: MarkerId('driver_${doc.id}'),
            position: LatLng(lat, lng),
            icon: icon,
            anchor: const Offset(0.5, 0.5),
            infoWindow: InfoWindow(
              title: data['driverName'] ?? 'Driver',
              snippet: data['vehicle'] != null
                  ? "${data['vehicle']['model'] ?? ''} ${data['vehicle']['color'] ?? ''}".trim()
                  : null,
            ),
            onTap: () {
              // optional: handle tap (select driver etc.)
            },
          ),
        );
      }

      if (mounted) setState(() => _markers = newMarkers);
    });
  }

  // ---------------------------
  // Get current user location
  // ---------------------------
  Future<void> _checkAndGetLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.deniedForever) return;

    final Position pos = await Geolocator.getCurrentPosition();
    _currentLatLng = LatLng(pos.latitude, pos.longitude);

    if (_mapController != null && _currentLatLng != null) {
      _mapController!.animateCamera(CameraUpdate.newLatLngZoom(_currentLatLng!, 16));
    }

    if (mounted) setState(() {});
  }

  // ---------------------------
  // Build
  // ---------------------------
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: GoogleMap(
        initialCameraPosition: initialCameraPosition,
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        markers: _markers,
        zoomControlsEnabled: false,
        onMapCreated: (controller) async {
          _mapController = controller;
          await _checkAndGetLocation();
        },
      ),
    );
  }
}
