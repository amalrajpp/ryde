import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ryde/features/home/view/home_page.dart';
import 'package:ryde/features/onboarding/views/on_boarding_screen.dart';

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // 🔄 1. Waiting for auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // 🔐 2. User NOT logged in → Go to Login Page
        if (!snapshot.hasData) {
          return OnboardingPages(); // your login page widget
        }

        // 🏠 3. User LOGGED IN → Go to Home Page
        return HomePage();
      },
    );
  }
}
