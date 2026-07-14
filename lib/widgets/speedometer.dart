import 'package:flutter/material.dart';

class Speedometer extends StatelessWidget {
  final double speedMph;
  final double maxSpeed;
  final bool isSpeeding;
  final double warningThreshold; // Percentage of max speed to start warning
  final double dangerThreshold; // Percentage of max speed to trigger danger

  const Speedometer({
    super.key,
    required this.speedMph,
    this.maxSpeed = 80.0,
    this.isSpeeding = false,
    this.warningThreshold = 0.8,
    this.dangerThreshold = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final speedPercentage = (speedMph / maxSpeed).clamp(0.0, 1.0);
    final isWarning = speedPercentage >= warningThreshold && !isSpeeding;
    final isDanger = speedPercentage >= dangerThreshold || isSpeeding;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            // Outer ring - background
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey[200],
                border: Border.all(color: Colors.grey[400]!, width: 2),
              ),
            ),
            // Speed arc
            CustomPaint(
              size: const Size(200, 200),
              painter: SpeedometerPainter(
                speedPercentage: speedPercentage,
                isWarning: isWarning,
                isDanger: isDanger,
                warningThreshold: warningThreshold,
                dangerThreshold: dangerThreshold,
              ),
            ),
            // Speed text
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${speedMph.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: isDanger ? Colors.red : 
                           isWarning ? Colors.orange : 
                           Colors.black,
                  ),
                ),
                const Text(
                  'mph',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Status text
        if (isDanger)
          const Text(
            'SPEEDING!',
            style: TextStyle(
              color: Colors.red,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        if (isWarning && !isDanger)
          const Text(
            'Approaching Limit',
            style: TextStyle(
              color: Colors.orange,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        // Speed limit indicator
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '0',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                '${maxSpeed.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class SpeedometerPainter extends CustomPainter {
  final double speedPercentage;
  final bool isWarning;
  final bool isDanger;
  final double warningThreshold;
  final double dangerThreshold;

  SpeedometerPainter({
    required this.speedPercentage,
    required this.isWarning,
    required this.isDanger,
    required this.warningThreshold,
    required this.dangerThreshold,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;
    final startAngle = -pi / 2; // Start at top
    final endAngle = pi / 2; // End at bottom
    final sweepAngle = endAngle - startAngle;

    // Draw background arc
    final backgroundPaint = Paint()
      ..color = Colors.grey[300]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20
      ..strokeCap = StrokeCap.round;
    
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      backgroundPaint,
    );

    // Draw warning arc
    if (speedPercentage > 0) {
      final warningPaint = Paint()
        ..color = isDanger ? Colors.red : isWarning ? Colors.orange : Colors.blue
        ..style = PaintingStyle.stroke
        ..strokeWidth = 20
        ..strokeCap = StrokeCap.round;
      
      final currentAngle = startAngle + sweepAngle * speedPercentage;
      
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        currentAngle - startAngle,
        false,
        warningPaint,
      );
    }

    // Draw warning threshold indicator
    final warningPaint = Paint()
      ..color = Colors.orange
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    final warningAngle = startAngle + sweepAngle * warningThreshold;
    final warningX = center.dx + radius * cos(warningAngle);
    final warningY = center.dy + radius * sin(warningAngle);
    
    canvas.drawLine(
      Offset(warningX, warningY),
      Offset(warningX - 10 * cos(warningAngle), warningY - 10 * sin(warningAngle)),
      warningPaint,
    );

    // Draw danger threshold indicator
    final dangerPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    final dangerAngle = startAngle + sweepAngle * dangerThreshold;
    final dangerX = center.dx + radius * cos(dangerAngle);
    final dangerY = center.dy + radius * sin(dangerAngle);
    
    canvas.drawLine(
      Offset(dangerX, dangerY),
      Offset(dangerX - 10 * cos(dangerAngle), dangerY - 10 * sin(dangerAngle)),
      dangerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
