import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DriverSeeder extends StatefulWidget {
  const DriverSeeder({super.key});

  @override
  State<DriverSeeder> createState() => _DriverSeederState();
}

class _DriverSeederState extends State<DriverSeeder> {
  bool _isLoading = false;
  String _statusMessage = 'Ready to seed data';

  // Android Emulator Default Location (Googleplex)
  static const double centerLat = 37.4219983;
  static const double centerLng = -122.084;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Mock Data Pools
  final List<String> _names = [
    "James Wilson",
    "Sarah Parker",
    "Michael Chang",
    "Emily Davis",
    "David Kim",
    "Robert Johnson",
    "Maria Garcia",
    "William Chen",
  ];

  final List<Map<String, String>> _cars = [
    {"make": "Toyota", "model": "Prius", "color": "White"},
    {"make": "Honda", "model": "Civic", "color": "Silver"},
    {"make": "Tesla", "model": "Model 3", "color": "Black"},
    {"make": "Hyundai", "model": "Elantra", "color": "Blue"},
    {"make": "Ford", "model": "Fusion", "color": "Grey"},
  ];

  /// Generates a random location within ~2km of the center
  Map<String, double> _getRandomLocation() {
    final random = Random();
    // ~111km per degree. 0.02 degrees is approx 2.2km
    double latOffset = (random.nextDouble() - 0.5) * 0.04;
    double lngOffset = (random.nextDouble() - 0.5) * 0.04;

    return {
      "lat": centerLat + latOffset,
      "lng": centerLng + lngOffset,
      "heading": random.nextDouble() * 360, // Random heading 0-360
    };
  }

  Future<void> _seedDrivers() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Generating drivers...';
    });

    try {
      final batch = _firestore.batch();
      final random = Random();

      // Create 5 random drivers
      for (int i = 0; i < 5; i++) {
        // Create a new document reference
        final docRef = _firestore.collection('drivers').doc();

        final name = _names[random.nextInt(_names.length)];
        final car = _cars[random.nextInt(_cars.length)];
        final loc = _getRandomLocation();

        final driverData = {
          "id": docRef.id,
          "driverName": name,
          "rating": 4.0 + random.nextDouble(), // Rating 4.0 - 5.0
          "totalRides": random.nextInt(2000) + 50,
          "status": "online",
          "vehicle": {
            "make": car["make"],
            "model": car["model"],
            "color": car["color"],
            "plate": "ABC-${random.nextInt(8999) + 1000}",
          },
          "location": {
            "lat": loc["lat"],
            "lng": loc["lng"],
            "heading": loc["heading"],
          },
          "createdAt": FieldValue.serverTimestamp(),
        };

        batch.set(docRef, driverData);
      }

      await batch.commit();

      setState(() {
        _statusMessage = 'Successfully added 5 drivers!';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _clearDrivers() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Clearing drivers...';
    });

    try {
      // Note: This only deletes drivers in the 'drivers' collection
      // In a production app, be careful with delete operations!
      final snapshot = await _firestore.collection('drivers').get();
      final batch = _firestore.batch();

      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      setState(() {
        _statusMessage = 'All drivers removed.';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Driver Data Seeder",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              "Location: Mountain View (Emulator Default)",
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 20),
            if (_isLoading)
              const CircularProgressIndicator()
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: _seedDrivers,
                    icon: const Icon(Icons.add),
                    label: const Text("Add 5 Drivers"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: _clearDrivers,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text("Clear All"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 16),
            Text(
              _statusMessage,
              style: TextStyle(
                color: _statusMessage.contains("Error")
                    ? Colors.red
                    : Colors.green,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
