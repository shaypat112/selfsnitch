import 'package:flutter/material.dart';
import '../models/danger_zone.dart';

class DangerIndicator extends StatelessWidget {
  final List<DangerZone> currentDangers;
  final bool isRerouting;

  const DangerIndicator({
    super.key,
    required this.currentDangers,
    this.isRerouting = false,
  });

  @override
  Widget build(BuildContext context) {
    if (currentDangers.isEmpty && !isRerouting) {
      return const SizedBox.shrink();
    }

    return Card(
      color: currentDangers.isNotEmpty ? Colors.red[100] : Colors.blue[100],
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  currentDangers.isNotEmpty ? Icons.warning_amber : Icons.route,
                  color: currentDangers.isNotEmpty ? Colors.red : Colors.blue,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  currentDangers.isNotEmpty
                      ? 'Danger Zone!'
                      : 'Rerouting...',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: currentDangers.isNotEmpty ? Colors.red : Colors.blue,
                  ),
                ),
              ],
            ),
            if (currentDangers.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...currentDangers.map((danger) => Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getDangerColor(danger.type),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        danger.type.toString().split('.').last,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        danger.name,
                        style: const TextStyle(fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              )).toList(),
            ],
            if (isRerouting && currentDangers.isEmpty) ...[
              const SizedBox(height: 8),
              const Text(
                'Finding safer route...',
                style: TextStyle(fontSize: 14),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getDangerColor(DangerType type) {
    switch (type) {
      case DangerType.schoolZone:
        return Colors.orange;
      case DangerType.highCrime:
        return Colors.red;
      case DangerType.poorLighting:
        return Colors.yellow[800]!;
      case DangerType.construction:
        return Colors.orange[800]!;
      case DangerType.accidentProne:
        return Colors.red[800]!;
      case DangerType.highTraffic:
        return Colors.purple;
      case DangerType.custom:
        return Colors.blue;
    }
  }
}
