import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:get/get.dart';
import 'package:ryde/features/auth/controllers/auth_controller.dart';
import 'package:ryde/features/home/view/home_page.dart';
import 'package:ryde/features/auth/views/signup.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool showPassword = false;
  final AuthController _authController = Get.put(AuthController());

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  // ---------------- EMAIL LOGIN ----------------
  Future<void> loginWithEmail() async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      // After successful sign-in, ensure Firestore user doc contains
      // firstName, lastName, photoUrl, phone and email (merge to avoid overwrite)
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        String authFirst = '';
        String authLast = '';
        if (user.displayName != null && user.displayName!.isNotEmpty) {
          final parts = user.displayName!.trim().split(' ');
          authFirst = parts.first;
          if (parts.length > 1) authLast = parts.sublist(1).join(' ');
        }

        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'firstName': authFirst,
          'lastName': authLast,
          'photoUrl': user.photoURL ?? '',
          'phone': user.phoneNumber ?? '',
          'email': user.email ?? emailController.text.trim(),
          'updatedAt': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Login successful")));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Login failed: $e")));
    }
  }

  // ---------------- GOOGLE LOGIN (v6.2.1) ----------------
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

      // GoogleSignInAccount may have a photo url accessible via googleUser
      // but Firebase User also exposes photoURL. Prefer Firebase's.
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'firstName': gFirst,
        'lastName': gLast,
        'photoUrl': user.photoURL ?? googleUser.photoUrl ?? '',
        // Phone number is not always available from Google sign-in; use Firebase user phoneNumber if present.
        'phone': user.phoneNumber ?? '',
        'email': user.email ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)); // merge avoids overwrite
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
      );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Google login successful")));
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
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---------------- TOP IMAGE WITH GRADIENT ----------------
            Stack(
              children: [
                Image.asset(
                  "assets/images/get-started.png",
                  width: double.infinity,
                  height: 260,
                  fit: BoxFit.cover,
                ),

                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.0),
                          Colors.white.withOpacity(0.4),
                          Colors.white.withOpacity(0.9),
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

            const SizedBox(height: 10),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                "Welcome 👋",
                style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(height: 20),

            // ---------------- EMAIL FIELD ----------------
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                "Email",
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: TextField(
                controller: emailController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.email_outlined),
                  hintText: "Enter email",
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 15),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide(
                      color: Colors.blue.shade300,
                      width: 1.2,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            // ---------------- PASSWORD FIELD ----------------
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                "Password",
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: TextField(
                controller: passwordController,
                obscureText: !showPassword,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.lock_outline),
                  hintText: "Enter password",
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  contentPadding: const EdgeInsets.symmetric(vertical: 15),
                  suffixIcon: IconButton(
                    icon: Icon(
                      showPassword ? Icons.visibility : Icons.visibility_off,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      setState(() => showPassword = !showPassword);
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 25),

            // ---------------- SIGN UP BUTTON ----------------
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: loginWithEmail,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 8,
                    shadowColor: Colors.blue.shade200,
                  ),
                  child: const Text(
                    "Log In",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ---------------- OR SEPARATOR ----------------
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

            // ---------------- GOOGLE LOGIN BUTTON ----------------
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: Obx(
                () => GestureDetector(
                  onTap: _authController.isGoogleSignInLoading.value
                      ? null
                      : loginWithGoogle,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 13),
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
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                              ),
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

            // ---------------- FOOTER TEXT ----------------
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Don't have an account?",
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                  const SizedBox(width: 5),
                  GestureDetector(
                    child: const Text(
                      "Sign Up",
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SignUpPage(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),
          ],
        ),
      ),
    );
  }
}
