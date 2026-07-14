import 'package:flutter/material.dart';

class SOSButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isActive;
  final String? label;

  const SOSButton({
    super.key,
    required this.onPressed,
    this.isActive = true,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: isActive ? onPressed : null,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? Colors.red : Colors.grey[400],
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.5),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: const Center(
              child: Text(
                'SOS',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
        if (label != null) ...[
          const SizedBox(height: 8),
          Text(
            label!,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ],
    );
  }
}
