import 'package:flutter/material.dart';

class LocationMap extends StatelessWidget {
  final String imagePath;

  const LocationMap({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.asset(
        imagePath,
        height: 260,
        width: double.infinity,
        fit: BoxFit.cover,
      ),
    );
  }
}