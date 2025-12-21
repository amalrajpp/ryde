import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:get/get.dart';
import 'package:ryde/features/auth/controllers/auth_controller.dart';
import 'package:ryde/features/home/view/home_page.dart';
import 'package:ryde/features/auth/views/signup.dart';

class GetStartedPage extends StatefulWidget {
  const GetStartedPage({super.key});

  @override
  State<GetStartedPage> createState() => _GetStartedPageState();
}

class _GetStartedPageState extends State<GetStartedPage> {
  final AuthController _authController = Get.put(AuthController());

  Future<void> loginWithGoogle() async {
    _authController.setGoogleSignInLoading(true);
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(scopes: ['email']);

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        return; // cancelled
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);
      final userCredential = await FirebaseAuth.instance.signInWithCredential(
        credential,
      );
      final user = userCredential.user;
      if (user == null) return;

      // Extract name parts from the Google account display name
      String gFirst = '';
      String gLast = '';
      if (user.displayName != null && user.displayName!.isNotEmpty) {
        final parts = user.displayName!.trim().split(' ');
        gFirst = parts.first;
        if (parts.length > 1) gLast = parts.sublist(1).join(' ');
      }

      // Persist profile info to Firestore using the same field names as profile.dart
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'firstName': gFirst,
        'lastName': gLast,
        'photoUrl': user.photoURL ?? googleUser.photoUrl ?? '',
        'phone': user.phoneNumber ?? '',
        'email': user.email ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)); // merge avoids overwrite

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Google login successful")));
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Google login failed: $e")));
      // ignore: avoid_print
      print(e);
    } finally {
      _authController.setGoogleSignInLoading(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // ---------------------- TOP IMAGE WITH GRADIENT ----------------------
          Stack(
            children: [
              Image.asset(
                "assets/images/get-started.png",
                width: double.infinity,
                height: 430,
                fit: BoxFit.cover,
              ),

              // Gradient fade at bottom
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.0),
                        Colors.white.withOpacity(0.3),
                        Colors.white.withOpacity(0.7),
                        Colors.white,
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ---------------------- TEXTS ----------------------
          const Text(
            "Let’s get started",
            style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 8),

          Text(
            "Sign up or log in to find out the best\ncar for you",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
          ),

          const SizedBox(height: 30),

          // ---------------------- SIGN UP BUTTON ----------------------
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SignUpPage()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  "Sign Up",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          Padding(
            padding: const EdgeInsets.only(left: 8.0, right: 8.8),
            child: Row(
              children: [
                Expanded(
                  child: Divider(color: Colors.grey.shade300, thickness: 1),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Text("Or"),
                ),
                Expanded(
                  child: Divider(color: Colors.grey.shade300, thickness: 1),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ---------------------- GOOGLE LOGIN BUTTON ----------------------
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Obx(
              () => GestureDetector(
                onTap: _authController.isGoogleSignInLoading.value
                    ? null
                    : loginWithGoogle,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.grey.shade300),
                    color: _authController.isGoogleSignInLoading.value
                        ? Colors.grey.shade100
                        : Colors.white,
                  ),
                  child: _authController.isGoogleSignInLoading.value
                      ? const Center(
                          child: SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.network(
                              "https://developers.google.com/identity/images/g-logo.png",
                              height: 22,
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              "Log In with Google",
                              style: TextStyle(fontSize: 15),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 25),

          // ---------------------- LOGIN TEXT ----------------------
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Don’t have an account?",
                style: TextStyle(color: Colors.grey.shade900),
              ),
              const SizedBox(width: 5),
              const Text(
                "Log in",
                style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
