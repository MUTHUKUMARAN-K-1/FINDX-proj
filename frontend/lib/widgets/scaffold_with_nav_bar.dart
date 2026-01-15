import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/services/location_service.dart';

class ScaffoldWithNavBar extends StatefulWidget {
  const ScaffoldWithNavBar({required this.navigationShell, Key? key})
    : super(key: key ?? const ValueKey<String>('ScaffoldWithNavBar'));

  final StatefulNavigationShell navigationShell;

  @override
  State<ScaffoldWithNavBar> createState() => _ScaffoldWithNavBarState();
}

class _ScaffoldWithNavBarState extends State<ScaffoldWithNavBar> {
  String _currentLocation = 'Fetching location...';

  @override
  void initState() {
    super.initState();
    _updateLocation();
  }

  Future<void> _updateLocation() async {
    final locationService = LocationService();
    if (locationService.isInitialized && locationService.placeName != null) {
      setState(() {
        _currentLocation = locationService.placeName!;
      });
    } else {
      // Try to initialize if not already done
      await locationService.initializeAndSaveLocation();
      if (locationService.placeName != null) {
        setState(() {
          _currentLocation = locationService.placeName!;
        });
      } else {
        setState(() {
          _currentLocation = 'Location not available';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Current Location',
              style: TextStyle(fontSize: 12, color: Colors.white70),
            ),
            Text(
              _currentLocation,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      body: widget.navigationShell,
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chat'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        currentIndex: widget.navigationShell.currentIndex,
        onTap: (int index) {
          _onTap(context, index);
        },
      ),
    );
  }

  void _onTap(BuildContext context, int index) {
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }
}
