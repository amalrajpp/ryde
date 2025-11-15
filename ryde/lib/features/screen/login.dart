import 'package:flutter/material.dart';
import 'package:ryde/features/screen/signup.dart';

class GetStartedPage extends StatelessWidget {
  const GetStartedPage({super.key});

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

          const Text("Or"),

          const SizedBox(height: 20),

          // ---------------------- GOOGLE LOGIN BUTTON ----------------------
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
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
