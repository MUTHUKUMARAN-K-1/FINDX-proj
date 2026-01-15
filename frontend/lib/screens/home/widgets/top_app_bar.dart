import 'dart:async';
import 'package:flutter/material.dart';
import 'package:frontend/services/location_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

class TopAppBar extends StatefulWidget implements PreferredSizeWidget {
  const TopAppBar({super.key});

  @override
  State<TopAppBar> createState() => _TopAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _TopAppBarState extends State<TopAppBar> {
  String _currentLocation = 'Fetching location...';
  Timer? _retryTimer;
  int _retryCount = 0;
  static const int _maxRetries = 10; // Try for 20 seconds total

  @override
  void initState() {
    super.initState();
    _updateLocation();
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    super.dispose();
  }

  void _updateLocation() {
    final locationService = LocationService();

    // Check if location is already available
    if (locationService.isInitialized && locationService.placeName != null) {
      if (mounted) {
        setState(() {
          _currentLocation = locationService.placeName!;
        });
      }
      return;
    }

    // If not, trigger initialization and retry
    _retryCount++;
    if (_retryCount <= _maxRetries) {
      _retryTimer?.cancel();
      _retryTimer = Timer(const Duration(seconds: 2), () {
        if (mounted) {
          final updated = LocationService();
          if (updated.placeName != null && updated.placeName!.isNotEmpty) {
            setState(() {
              _currentLocation = updated.placeName!;
            });
          } else if (_retryCount < _maxRetries) {
            // Keep retrying
            _updateLocation();
          } else {
            // Max retries reached - try once more with async initialization
            _tryAsyncInitialization();
          }
        }
      });
    }
  }

  Future<void> _tryAsyncInitialization() async {
    try {
      final locationService = LocationService();
      final success = await locationService.initializeAndSaveLocation();
      if (mounted) {
        if (success && locationService.placeName != null) {
          setState(() {
            _currentLocation = locationService.placeName!;
          });
        } else {
          setState(() {
            _currentLocation = 'Tap to enable location';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _currentLocation = 'Tap to enable location';
        });
      }
    }
  }

  void _onLocationTap() async {
    if (_currentLocation == 'Tap to enable location' ||
        _currentLocation == 'Fetching location...' ||
        _currentLocation == 'Location unavailable') {
      // Try to initialize location
      final locationService = LocationService();
      final success = await locationService.initializeAndSaveLocation();
      if (mounted) {
        if (success && locationService.placeName != null) {
          setState(() {
            _currentLocation = locationService.placeName!;
          });
        }
      }
    } else {
      // Location is available - open heatmap
      if (mounted) {
        final locationService = LocationService();
        final position = locationService.currentPosition;
        if (position != null) {
          context.push(
            '/heatmap?lat=${position.latitude}&lng=${position.longitude}',
          );
        } else {
          context.push('/heatmap');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconBgColor = isDark ? colorScheme.surface : Colors.grey.shade100;

    return AppBar(
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          // Profile Avatar
          GestureDetector(
            onTap: () => context.push('/profile'),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [colorScheme.primary, colorScheme.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Center(
                child: Icon(Icons.person, color: Colors.white, size: 24),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Location info - tappable
          Expanded(
            child: GestureDetector(
              onTap: _onLocationTap,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current Location',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        _currentLocation == 'Tap to enable location'
                            ? Icons.location_off
                            : Icons.location_on,
                        size: 14,
                        color: _currentLocation == 'Tap to enable location'
                            ? Colors.orange
                            : colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          _currentLocation,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: _currentLocation == 'Tap to enable location'
                                ? Colors.orange
                                : colorScheme.onSurface,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.keyboard_arrow_down,
                        size: 18,
                        color: colorScheme.primary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      actions: [
        // Search button
        GestureDetector(
          onTap: () => context.push('/search'),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.search, color: colorScheme.onSurface, size: 22),
          ),
        ),
        const SizedBox(width: 8),
        // Notifications button
        GestureDetector(
          onTap: () => context.push('/notifications'),
          child: Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.notifications_outlined,
                  color: colorScheme.onSurface,
                  size: 22,
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? colorScheme.surface : Colors.white,
                      width: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
      ],
      backgroundColor: colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
    );
  }
}
