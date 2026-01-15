import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/blocs/auth/auth_bloc.dart';
import 'package:frontend/providers/theme_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:location/location.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isLocationSharingEnabled = false;
  bool _isPushNotificationsEnabled = true;
  bool _isEmailNotificationsEnabled = false;
  Location location = Location();

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isLocationSharingEnabled = prefs.getBool('locationSharing') ?? false;
      _isPushNotificationsEnabled = prefs.getBool('pushNotifications') ?? true;
      _isEmailNotificationsEnabled =
          prefs.getBool('emailNotifications') ?? false;
    });
  }

  Future<void> _savePreference(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> _toggleLocationSharing(bool value) async {
    if (value) {
      // Request permission
      bool serviceEnabled = await location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await location.requestService();
        if (!serviceEnabled) {
          _showSnackBar('Location service disabled');
          return;
        }
      }

      PermissionStatus permissionGranted = await location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await location.requestPermission();
        if (permissionGranted != PermissionStatus.granted) {
          _showSnackBar('Location permission denied');
          return;
        }
      }

      await location.enableBackgroundMode(enable: true);
    } else {
      await location.enableBackgroundMode(enable: false);
    }

    setState(() => _isLocationSharingEnabled = value);
    await _savePreference('locationSharing', value);
    _showSnackBar(
      value ? 'Location sharing enabled' : 'Location sharing disabled',
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthBloc>().add(AuthLoggedOut());
              context.go('/');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Settings',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Privacy Section
          _buildSectionHeader('Privacy & Location'),
          _buildSettingCard(
            child: Column(
              children: [
                _buildSwitchTile(
                  title: 'Share Location',
                  subtitle: 'Allow background location for nearby alerts',
                  icon: Icons.location_on_outlined,
                  value: _isLocationSharingEnabled,
                  onChanged: _toggleLocationSharing,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Notifications Section
          _buildSectionHeader('Notifications'),
          _buildSettingCard(
            child: Column(
              children: [
                _buildSwitchTile(
                  title: 'Push Notifications',
                  subtitle: 'Get notified when items are found nearby',
                  icon: Icons.notifications_outlined,
                  value: _isPushNotificationsEnabled,
                  onChanged: (value) async {
                    setState(() => _isPushNotificationsEnabled = value);
                    await _savePreference('pushNotifications', value);
                  },
                ),
                const Divider(height: 1),
                _buildSwitchTile(
                  title: 'Email Notifications',
                  subtitle: 'Receive updates via email',
                  icon: Icons.email_outlined,
                  value: _isEmailNotificationsEnabled,
                  onChanged: (value) async {
                    setState(() => _isEmailNotificationsEnabled = value);
                    await _savePreference('emailNotifications', value);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Appearance Section
          _buildSectionHeader('Appearance'),
          _buildSettingCard(
            child: Consumer<ThemeProvider>(
              builder: (context, themeProvider, child) {
                return _buildSwitchTile(
                  title: 'Dark Mode',
                  subtitle: 'Use dark theme',
                  icon: Icons.dark_mode_outlined,
                  value: themeProvider.isDarkMode,
                  onChanged: (value) async {
                    await themeProvider.setDarkMode(value);
                    _showSnackBar(
                      value ? 'Dark mode enabled' : 'Light mode enabled',
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 24),

          // Support Section
          _buildSectionHeader('Support'),
          _buildSettingCard(
            child: Column(
              children: [
                _buildTapTile(
                  title: 'Help & FAQ',
                  icon: Icons.help_outline,
                  onTap: () => _showSnackBar('Help center coming soon'),
                ),
                const Divider(height: 1),
                _buildTapTile(
                  title: 'Privacy Policy',
                  icon: Icons.privacy_tip_outlined,
                  onTap: () => _showSnackBar('Privacy policy coming soon'),
                ),
                const Divider(height: 1),
                _buildTapTile(
                  title: 'Terms of Service',
                  icon: Icons.description_outlined,
                  onTap: () => _showSnackBar('Terms of service coming soon'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Account Section
          _buildSectionHeader('Account'),
          _buildSettingCard(
            child: Column(
              children: [
                _buildTapTile(
                  title: 'Sign Out',
                  icon: Icons.logout,
                  iconColor: Colors.red,
                  textColor: Colors.red,
                  onTap: _showLogoutDialog,
                ),
                const Divider(height: 1),
                _buildTapTile(
                  title: 'Delete Account',
                  icon: Icons.delete_outline,
                  iconColor: Colors.red,
                  textColor: Colors.red,
                  onTap: () =>
                      _showSnackBar('Contact support to delete account'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // App Version
          Center(
            child: Column(
              children: [
                Text(
                  'FindX',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Version 1.0.0',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
                const SizedBox(height: 12),
                // Powered by Gemini badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF4285F4),
                        Color(0xFF9B72CB),
                        Color(0xFFD96570),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.auto_awesome,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Powered by Gemini AI',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildSettingCard({required Widget child}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
        border: isDark
            ? Border.all(color: Colors.white.withOpacity(0.1))
            : null,
      ),
      child: child,
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: Theme.of(context).colorScheme.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildTapTile({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    Color? iconColor,
    Color? textColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(
              icon,
              color:
                  iconColor ?? Theme.of(context).colorScheme.onSurfaceVariant,
              size: 22,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: textColor ?? Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
