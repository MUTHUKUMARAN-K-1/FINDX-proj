import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:frontend/models/item.dart';

class MapScreen extends StatelessWidget {
  final List<Item> items;

  const MapScreen({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Map'),
      ),
      body: GoogleMap(
        initialCameraPosition: const CameraPosition(
          target: LatLng(0, 0),
          zoom: 2,
        ),
        markers: items
            .map(
              (item) => Marker(
                markerId: MarkerId(item.id),
                position: LatLng(item.latitude, item.longitude),
                infoWindow: InfoWindow(
                  title: item.description,
                ),
              ),
            )
            .toSet(),
      ),
    );
  }
}
