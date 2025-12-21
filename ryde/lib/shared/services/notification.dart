/*
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class SendNotificationScreen extends StatefulWidget {
  final String driverId; // Example: "8TlDHLuhZRUChairmm5dCebUspL2"

  const SendNotificationScreen({super.key, required this.driverId});

  @override
  State<SendNotificationScreen> createState() => _SendNotificationScreenState();
}

class _SendNotificationScreenState extends State<SendNotificationScreen> {
  String? fcmToken;
  bool isLoading = true;

  final TextEditingController _titleController = TextEditingController(
    text: "New Update",
  );
  final TextEditingController _bodyController = TextEditingController(
    text: "You have a new message!",
  );

  final String serverUrl = "http://192.168.20.8:3000/send-single";

  @override
  void initState() {
    super.initState();
    fetchDriverFCM();
  }

  Future<void> fetchDriverFCM() async {
    final doc = await FirebaseFirestore.instance
        .collection("drivers")
        .doc(widget.driverId)
        .get();

    if (doc.exists) {
      setState(() {
        fcmToken = doc.data()?["fcmToken"];
        isLoading = false;
      });
    } else {
      setState(() {
        fcmToken = null;
        isLoading = false;
      });
    }
  }

  Future<void> sendNotification() async {
    if (fcmToken == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("FCM Token not found for this driver")),
      );
      return;
    }

    final response = await http.post(
      Uri.parse(serverUrl),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "token": fcmToken,
        "title": _titleController.text,
        "body": _bodyController.text,
      }),
    );

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("Response: ${response.body}")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Send Notification")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Driver ID:",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(widget.driverId),
                  const SizedBox(height: 20),

                  Text(
                    "Driver FCM Token:",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    fcmToken ?? "No FCM Token Found",
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 30),
                  Text("Notification Title"),
                  TextField(controller: _titleController),

                  const SizedBox(height: 20),
                  Text("Notification Body"),
                  TextField(controller: _bodyController),

                  const SizedBox(height: 40),

                  Center(
                    child: ElevatedButton(
                      onPressed: sendNotification,
                      child: const Text("Send Notification"),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
*/

import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class VehicleTypeNotificationScreen extends StatefulWidget {
  const VehicleTypeNotificationScreen({super.key});

  @override
  State<VehicleTypeNotificationScreen> createState() =>
      _VehicleTypeNotificationScreenState();
}

class _VehicleTypeNotificationScreenState
    extends State<VehicleTypeNotificationScreen> {
  String selectedVehicleType = "bike";

  final TextEditingController _titleController = TextEditingController(
    text: "New Update",
  );
  final TextEditingController _bodyController = TextEditingController(
    text: "This is a notification for your vehicle type.",
  );

  final String serverUrl = "http://192.168.20.4:3000/send-multiple";

  Future<void> sendNotificationToVehicleType() async {
    // Fetch all drivers with specific vehicle type
    final querySnapshot = await FirebaseFirestore.instance
        .collection("drivers")
        .where("vehicle.vehicle_type", isEqualTo: selectedVehicleType)
        .get();

    // Extract all FCM tokens
    List<String> tokens = [];
    for (var doc in querySnapshot.docs) {
      if (doc.data()["fcmToken"] != null) {
        tokens.add(doc.data()["fcmToken"]);
      }
    }

    if (tokens.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("No users found for $selectedVehicleType")),
      );
      return;
    }

    // Send request to Node server
    final response = await http.post(
      Uri.parse(serverUrl),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "tokens": tokens,
        "title": _titleController.text,
        "body": _bodyController.text,
      }),
    );

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("Response: ${response.body}")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Notify by Vehicle Type")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Select Vehicle Type",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            DropdownButton<String>(
              value: selectedVehicleType,
              items: ["bike", "car", "auto"].map((type) {
                return DropdownMenuItem(value: type, child: Text(type));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedVehicleType = value!;
                });
              },
            ),

            const SizedBox(height: 20),
            const Text("Notification Title"),
            TextField(controller: _titleController),

            const SizedBox(height: 20),
            const Text("Notification Body"),
            TextField(controller: _bodyController),

            const SizedBox(height: 40),

            Center(
              child: ElevatedButton(
                onPressed: sendNotificationToVehicleType,
                child: Text("Send to All $selectedVehicleType Drivers"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
