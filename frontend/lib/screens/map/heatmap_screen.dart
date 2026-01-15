import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:location/location.dart';

/// Live heatmap showing all lost and found items
class HeatmapScreen extends StatefulWidget {
  final double? initialLat;
  final double? initialLng;

  const HeatmapScreen({super.key, this.initialLat, this.initialLng});

  @override
  State<HeatmapScreen> createState() => _HeatmapScreenState();
}

class _HeatmapScreenState extends State<HeatmapScreen> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  StreamSubscription? _itemsSubscription;

  // Filter state
  String _filter = 'all'; // 'all', 'lost', 'found'

  // User location
  LocationData? _userLocation;
  bool _isLoadingLocation = true;

  // Default center (Chennai, India)
  static const LatLng _defaultCenter = LatLng(13.0827, 80.2707);

  @override
  void initState() {
    super.initState();
    _getUserLocation();
    _subscribeToItems();
  }

  @override
  void dispose() {
    _itemsSubscription?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _getUserLocation() async {
    try {
      final location = Location();

      bool serviceEnabled = await location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await location.requestService();
        if (!serviceEnabled) {
          setState(() => _isLoadingLocation = false);
          return;
        }
      }

      PermissionStatus permissionGranted = await location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await location.requestPermission();
        if (permissionGranted != PermissionStatus.granted) {
          setState(() => _isLoadingLocation = false);
          return;
        }
      }

      final locationData = await location.getLocation();
      setState(() {
        _userLocation = locationData;
        _isLoadingLocation = false;
      });

      // Move camera to user location
      if (_mapController != null && locationData.latitude != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(locationData.latitude!, locationData.longitude!),
            12,
          ),
        );
      }
    } catch (e) {
      print('❌ Location error: $e');
      setState(() => _isLoadingLocation = false);
    }
  }

  void _subscribeToItems() {
    _itemsSubscription = FirebaseFirestore.instance
        .collection('items')
        .snapshots()
        .listen((snapshot) {
          _updateMarkers(snapshot.docs);
        });
  }

  void _updateMarkers(List<QueryDocumentSnapshot> docs) {
    final markers = <Marker>{};

    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final lat = (data['latitude'] as num?)?.toDouble();
      final lng = (data['longitude'] as num?)?.toDouble();
      final isLost = data['isLost'] as bool? ?? true;

      // Apply filter
      if (_filter == 'lost' && !isLost) continue;
      if (_filter == 'found' && isLost) continue;

      if (lat != null && lng != null && lat != 0.0 && lng != 0.0) {
        final description = data['description'] as String? ?? 'Unknown item';
        final title = description.split('\n').first;
        final category = data['category'] as String? ?? 'Other';

        markers.add(
          Marker(
            markerId: MarkerId(doc.id),
            position: LatLng(lat, lng),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              isLost ? BitmapDescriptor.hueRed : BitmapDescriptor.hueGreen,
            ),
            infoWindow: InfoWindow(
              title: '${isLost ? "🔴 Lost" : "🟢 Found"}: $title',
              snippet: category,
              onTap: () => context.push('/item/${doc.id}'),
            ),
          ),
        );
      }
    }

    setState(() => _markers = markers);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Determine initial camera position
    LatLng initialPosition = _defaultCenter;
    if (widget.initialLat != null && widget.initialLng != null) {
      initialPosition = LatLng(widget.initialLat!, widget.initialLng!);
    } else if (_userLocation?.latitude != null) {
      initialPosition = LatLng(
        _userLocation!.latitude!,
        _userLocation!.longitude!,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lost & Found Map'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          // Filter button
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() => _filter = value);
              // Re-fetch and filter markers
              FirebaseFirestore.instance.collection('items').get().then((
                snapshot,
              ) {
                _updateMarkers(snapshot.docs);
              });
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'all',
                child: Row(
                  children: [
                    Icon(
                      Icons.all_inclusive,
                      color: _filter == 'all' ? colorScheme.primary : null,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'All Items',
                      style: TextStyle(
                        fontWeight: _filter == 'all' ? FontWeight.bold : null,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'lost',
                child: Row(
                  children: [
                    Icon(
                      Icons.search_off,
                      color: _filter == 'lost' ? Colors.red : null,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Lost Only',
                      style: TextStyle(
                        fontWeight: _filter == 'lost' ? FontWeight.bold : null,
                        color: _filter == 'lost' ? Colors.red : null,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'found',
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: _filter == 'found' ? Colors.green : null,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Found Only',
                      style: TextStyle(
                        fontWeight: _filter == 'found' ? FontWeight.bold : null,
                        color: _filter == 'found' ? Colors.green : null,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: initialPosition,
              zoom: 12,
            ),
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            onMapCreated: (controller) {
              _mapController = controller;
            },
          ),

          // Legend at bottom
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Lost legend
                  Row(
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Lost (${_markers.where((m) => m.icon.toString().contains('hueRed')).length})',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  Container(width: 1, height: 20, color: Colors.grey.shade300),
                  // Found legend
                  Row(
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Found (${_markers.where((m) => m.icon.toString().contains('hueGreen')).length})',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // My location button
          Positioned(
            right: 16,
            bottom: 80,
            child: FloatingActionButton.small(
              heroTag: 'my_location',
              backgroundColor: Colors.white,
              onPressed: () {
                if (_userLocation?.latitude != null) {
                  _mapController?.animateCamera(
                    CameraUpdate.newLatLngZoom(
                      LatLng(
                        _userLocation!.latitude!,
                        _userLocation!.longitude!,
                      ),
                      14,
                    ),
                  );
                } else {
                  _getUserLocation();
                }
              },
              child: _isLoadingLocation
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(Icons.my_location, color: colorScheme.primary),
            ),
          ),
        ],
      ),
    );
  }
}
