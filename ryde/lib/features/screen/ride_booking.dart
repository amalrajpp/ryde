import 'package:flutter/material.dart';

class RideBookingScreen extends StatelessWidget {
  const RideBookingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Height of the screen to calculate relative sizes
    final double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Stack(
        children: [
          // 1. BLANK MAP AREA (Placeholder)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: screenHeight * 0.6, // Map takes top 60% roughly
            child: Container(
              color: const Color(
                0xFFEAF2F8,
              ), // Light bluish-grey map placeholder
              child: const Center(
                child: Text(
                  "Map Area",
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),

          // 2. TOP NAVIGATION (Back Button & Title)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.black),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                    ),
                    const SizedBox(width: 20),
                    const Text(
                      "Ride",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 3. LOCATION BUTTON (Green FAB)
          Positioned(
            right: 20,
            // Position it slightly above where the bottom sheet starts
            bottom: (screenHeight * 0.45) + 30,
            child: Container(
              width: 50,
              height: 50,
              decoration: const BoxDecoration(
                color: Color(0xFF5ECC71), // Green color from image
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.my_location, color: Colors.white),
            ),
          ),

          // 4. BOTTOM SHEET (Input Fields)
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: screenHeight * 0.40, // Takes up roughly bottom 48%
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 20,
                    spreadRadius: 5,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 30, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // "From" Section
                    const Text(
                      "From",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildLocationField(
                      placeholder: "From location",
                      prefixIcon: Icons.location_on_outlined,
                      suffixIcon: Icons.my_location, // Target icon
                    ),

                    const SizedBox(height: 20),

                    // "To" Section
                    const Text(
                      "To",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildLocationField(
                      placeholder: "To location",
                      prefixIcon: Icons.location_on_outlined,
                      suffixIcon: Icons.map_outlined, // Map fold icon
                    ),

                    const Spacer(),

                    // "Find Now" Button
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(
                            0xFF3B82F6,
                          ), // Bright Blue
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text(
                          "Find Now",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper widget to build the rounded text fields
  Widget _buildLocationField({
    required String placeholder,
    required IconData prefixIcon,
    required IconData suffixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F9), // Very light grey background
        borderRadius: BorderRadius.circular(30),
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: placeholder,
          hintStyle: const TextStyle(color: Colors.grey),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
          prefixIcon: Icon(prefixIcon, color: Colors.grey[600]),
          suffixIcon: Icon(suffixIcon, color: Colors.black87),
        ),
      ),
    );
  }
}
