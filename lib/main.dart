import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

void main() {
  runApp(const SelfSnitchApp());
}

class SelfSnitchApp extends StatelessWidget {
  const SelfSnitchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: 'SelfSnitch', home: const MapScreen());
  }
}

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  // Charlotte, NC
  static final LatLng charlotte = LatLng(35.2271, -80.8431);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SelfSnitch')),
      body: FlutterMap(
        options: MapOptions(initialCenter: charlotte, initialZoom: 12),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.selfsnitch',
          ),
        ],
      ),
    );
  }
}
