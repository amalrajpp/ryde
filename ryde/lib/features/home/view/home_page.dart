import 'package:flutter/material.dart';
// Add these 3 Firebase imports
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'package:ryde/addata.dart';
import 'package:ryde/features/car-screen/view/popularCarpage.dart';
import 'package:ryde/features/home/view/home_content.dart';
import 'package:ryde/features/home/viewmodel/home_viewmodel.dart';
import 'package:ryde/features/home/widgets/bottom_navbar.dart';
import 'package:ryde/features/screen/chat.dart';
import 'package:ryde/features/screen/history.dart';
import 'package:ryde/features/screen/profile.dart';
import 'package:ryde/services/notification.dart';
import '../widgets/home_header.dart';
import '../widgets/search_bar.dart';
import 'location_map.dart';
import '../widgets/recent_rides_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final HomeViewModel vm = HomeViewModel();

  final List<Widget> screens = const [
    HomeContentScreen(), // index 0
    HistoryScreen(), // index 1
    //SendNotificationScreen(driverId: "8TlDHLuhZRUChairmm5dCebUspL2"),
    VehicleTypeNotificationScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // 1. Trigger the FCM setup when the Home Page loads
    _setupFCM();
  }

  /// Requests permission, gets the token, and updates Firestore
  Future<void> _setupFCM() async {
    // A. Request Notification Permission (Required for iOS & Android 13+)
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');

      // B. Get the current FCM token
      String? token = await messaging.getToken();
      print("FCM Token: $token");

      // C. Save the token to Firestore
      await _saveTokenToFirestore(token);

      // D. Listen for token refreshes (e.g., app reinstall, data clear)
      messaging.onTokenRefresh.listen((newToken) {
        _saveTokenToFirestore(newToken);
      });
    } else {
      print('User declined or has not accepted permission');
    }
  }

  /// Helper to update the user's document in the 'users' collection
  Future<void> _saveTokenToFirestore(String? token) async {
    if (token == null) return;

    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'fcmToken': token, // The field name for the token
          'lastTokenUpdate':
              FieldValue.serverTimestamp(), // Optional: track when it was updated
        });
        print("FCM Token updated in Firestore for user: ${user.uid}");
      } catch (e) {
        print("Error updating FCM token: $e");
      }
    } else {
      print("No user logged in, cannot save FCM token.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: screens[vm.navIndex], // Screen switching
      bottomNavigationBar: BottomNavBar(
        selectedIndex: vm.navIndex,
        onTap: (index) {
          setState(() {
            vm.onNavTap(index);
          });
        },
      ),
    );
  }
}
