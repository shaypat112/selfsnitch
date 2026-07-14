import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/safety_alert.dart';

class AlertCard extends StatelessWidget {
  final SafetyAlert alert;
  final VoidCallback? onAcknowledge;
  final VoidCallback? onDismiss;

  const AlertCard({
    super.key,
    required this.alert,
    this.onAcknowledge,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getAlertColor(alert.type);
    final icon = _getAlertIcon(alert.type);

    return Card(
      color: color.withOpacity(0.1),
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        alert.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      Text(
                        DateFormat.yMMMd().add_jm().format(alert.timestamp),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                if (alert.status == AlertStatus.active)
                  IconButton(
                    icon: const Icon(Icons.check_circle, color: Colors.green),
                    onPressed: onAcknowledge,
                    tooltip: 'Acknowledge',
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              alert.message,
              style: const TextStyle(fontSize: 14),
            ),
            if (alert.location != null) ...[
              const SizedBox(height: 8),
              Text(
                'Location: ${alert.location!.latitude.toStringAsFixed(4)}, ${alert.location!.longitude.toStringAsFixed(4)}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
            if (alert.speedMph != null) ...[
              const SizedBox(height: 4),
              Text(
                'Speed: ${alert.speedMph!.toStringAsFixed(0)} mph',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
            if (alert.status == AlertStatus.acknowledged) ...[
              const SizedBox(height: 8),
              const Text(
                'Acknowledged',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.green,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            if (onDismiss != null) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: onDismiss,
                  child: const Text('Dismiss'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getAlertColor(AlertType type) {
    switch (type) {
      case AlertType.speeding:
        return Colors.red;
      case AlertType.dangerZoneEntered:
        return Colors.orange;
      case AlertType.dangerZoneApproaching:
        return Colors.orange[800]!;
      case AlertType.geofenceExit:
        return Colors.purple;
      case AlertType.sos:
        return Colors.red[900]!;
      case AlertType.lowBattery:
        return Colors.yellow[800]!;
      case AlertType.nightDriving:
        return Colors.blue[800]!;
      case AlertType.custom:
        return Colors.blue;
    }
  }

  IconData _getAlertIcon(AlertType type) {
    switch (type) {
      case AlertType.speeding:
        return Icons.speed;
      case AlertType.dangerZoneEntered:
      case AlertType.dangerZoneApproaching:
        return Icons.warning_amber;
      case AlertType.geofenceExit:
        return Icons.exit_to_app;
      case AlertType.sos:
        return Icons.sos;
      case AlertType.lowBattery:
        return Icons.battery_alert;
      case AlertType.nightDriving:
        return Icons.nightlight_round;
      case AlertType.custom:
        return Icons.notification_important;
    }
  }
}
