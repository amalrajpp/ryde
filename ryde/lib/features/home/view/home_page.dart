import 'package:flutter/material.dart';
// Add these 3 Firebase imports
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:ryde/features/account/views/account_page.dart';
import 'package:ryde/features/account/views/history.dart';
import 'package:ryde/features/ride/views/ride_booking.dart';

import 'package:ryde/features/home/view/home_content.dart';
import 'package:ryde/features/home/viewmodel/home_viewmodel.dart';
import 'package:ryde/features/home/widgets/bottom_navbar.dart';
// recent_rides_card is used inside home content; import removed here to avoid unused import warning

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  /// When set, HomePage will suppress auto-resume until this DateTime.
  /// Use [suppressAutoResume] to set a temporary suppression when returning
  /// from the booking screen so we don't immediately navigate back again.
  static DateTime? _suppressAutoResumeUntil;

  static void suppressAutoResume(Duration duration) {
    _suppressAutoResumeUntil = DateTime.now().add(duration);
  }

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final HomeViewModel vm = HomeViewModel();

  final List<Widget> screens = const [
    HomeContentScreen(), // index 0
    AccountModuleHistoryPage(), // index 1
    AccountModulePage(),
  ];

  @override
  void initState() {
    super.initState();
    // 1. Trigger the FCM setup when the Home Page loads
    _setupFCM();
    // 2. Check for any active booking and resume if present
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkActiveBookingAndResume();
    });
  }

  Future<void> _checkActiveBookingAndResume() async {
    // If a recent navigation set suppression (for example user just returned
    // from the booking screen), skip auto-resume for a short window.
    if (HomePage._suppressAutoResumeUntil != null &&
        DateTime.now().isBefore(HomePage._suppressAutoResumeUntil!)) {
      debugPrint(
        'Auto-resume suppressed until ${HomePage._suppressAutoResumeUntil}',
      );
      return;
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint('No user logged in, skipping booking resume check');
      return;
    }

    try {
      final qs = await FirebaseFirestore.instance
          .collection('booking')
          .where('customer_id', isEqualTo: user.uid)
          .orderBy('created_at', descending: true)
          .limit(1)
          .get();

      if (qs.docs.isEmpty) {
        debugPrint('No bookings found for user');
        return;
      }

      final doc = qs.docs.first;
      final data = doc.data();
      final status = (data['status'] ?? '').toString().toLowerCase();

      debugPrint('Found booking ${doc.id} with status: $status');

      // Check if booking was created recently (within last 24 hours)
      final createdAt = data['created_at'] as Timestamp?;
      if (createdAt != null) {
        final createdTime = createdAt.toDate();
        final now = DateTime.now();
        final hoursSinceCreation = now.difference(createdTime).inHours;

        // If booking is older than 24 hours, don't auto-resume
        if (hoursSinceCreation > 24) {
          debugPrint(
            'Booking is too old (${hoursSinceCreation}h), not resuming',
          );
          return;
        }
      }

      // IMPROVED LOGIC: Only auto-resume if driver is assigned or ride is active
      // Don't auto-resume 'pending' or 'created' bookings that have no driver
      const activeWithDriver = [
        'accepted',
        'started',
        'in_progress',
        'ongoing',
      ];

      // For pending/created status, only resume if driver was assigned
      if (status == 'pending' || status == 'created') {
        final driverId = data['driver_id'];
        if (driverId == null) {
          debugPrint(
            'Booking is $status but no driver assigned, not auto-resuming',
          );
          return;
        }
      }

      if (activeWithDriver.contains(status) ||
          (status == 'pending' && data['driver_id'] != null) ||
          (status == 'created' && data['driver_id'] != null)) {
        debugPrint('Resuming active booking ${doc.id}');
        // Navigate to booking screen to resume
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                RideBookingScreen(bookingId: doc.id, bookingData: data),
          ),
        );
      } else {
        debugPrint('Booking status $status does not qualify for auto-resume');
      }
    } catch (e) {
      debugPrint('Error checking active booking: $e');
    }
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
      debugPrint('User granted permission');

      // B. Get the current FCM token
      String? token = await messaging.getToken();
      debugPrint("FCM Token: $token");

      // C. Save the token to Firestore
      await _saveTokenToFirestore(token);

      // D. Listen for token refreshes (e.g., app reinstall, data clear)
      messaging.onTokenRefresh.listen((newToken) {
        _saveTokenToFirestore(newToken);
      });
    } else {
      debugPrint('User declined or has not accepted permission');
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
        debugPrint("FCM Token updated in Firestore for user: ${user.uid}");
      } catch (e) {
        debugPrint("Error updating FCM token: $e");
      }
    } else {
      debugPrint("No user logged in, cannot save FCM token.");
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
