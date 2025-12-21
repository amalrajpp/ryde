import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

Future<void> addUserDataToSecondaryApp(Map<String, dynamic> userData) async {
  try {
    // 1. Get the Secondary App Instance
    final secondaryApp = Firebase.app('parcelApp');
    final parcelFirestore = FirebaseFirestore.instanceFor(app: secondaryApp);
    Map<String, dynamic> secondaryAppData = Map.from(userData);

    // 3. Extract lat/lng from the existing 'location' map
    // (Defaulting to 0.0 if missing to prevent crashes)

    final FirebaseAuth _auth = FirebaseAuth.instance;
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;
    User? user = _auth.currentUser;
    DocumentSnapshot doc = await _firestore
        .collection('users')
        .doc(user!.uid)
        .get();

    // 2. Get data map
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    if (data['location'] != null) {
      GeoPoint location = data['location'] as GeoPoint;
      secondaryAppData['location'] = location;
    }

    String uniqueShortId = await _generateUniqueShortId(parcelFirestore);
    secondaryAppData['shortId'] = uniqueShortId;
    secondaryAppData['fullName'] =
        userData['firstName'] + " " + userData['lastName'];
    secondaryAppData['role'] = 'user';
    secondaryAppData['isActive'] = true;
    secondaryAppData['isDeleted'] = false;
    secondaryAppData['currentRideId'] = null;
    secondaryAppData['walletBalance'] = 0;
    secondaryAppData['deletedAt'] = null;
    await _firestore
        .collection('users')
        .doc(user.uid)
        .set(secondaryAppData, SetOptions(merge: true));
    await parcelFirestore
        .collection('users') // Assuming collection name is 'drivers'
        .doc(
          user.uid,
        ) // ⚠️ Replace this with: FirebaseAuth.instance.currentUser!.uid
        .set(secondaryAppData);
    print(secondaryAppData);
    debugPrint("✅ Data added to Secondary App successfully!");
  } catch (e) {
    debugPrint("❌ Error adding data: $e");
  }
}

// --- Helper Function to Generate Unique ID ---
Future<String> _generateUniqueShortId(FirebaseFirestore firestore) async {
  final random = Random();

  while (true) {
    // Generate random 4-digit number (1000 to 9999)
    String shortId = (1000 + random.nextInt(9000)).toString();

    // Check if this ID already exists in the 'agents' collection
    final QuerySnapshot result = await firestore
        .collection('users')
        .where('shortId', isEqualTo: shortId)
        .get();

    // If result is empty, the ID is unique. Return it.
    if (result.docs.isEmpty) {
      return shortId;
    }
    // If not empty, the loop runs again to generate a new ID.
  }
}
