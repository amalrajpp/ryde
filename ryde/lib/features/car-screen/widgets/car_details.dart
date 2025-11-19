import 'package:flutter/material.dart';

class CarDetailRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final String? title;
  final Color? textColor;

  const CarDetailRow({
    super.key,
    required this.icon,
    required this.text,
    this.title,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 24, color: Colors.grey),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null)
                  Text(
                    title!,
                    style: TextStyle(fontSize: 18, color: Colors.grey[700]),
                  ),
                Text(
                  text,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: textColor ?? Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
