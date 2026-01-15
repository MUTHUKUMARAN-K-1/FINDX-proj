import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Widget that shows an offline indicator banner
class OfflineIndicator extends StatefulWidget {
  final Widget child;

  const OfflineIndicator({super.key, required this.child});

  @override
  State<OfflineIndicator> createState() => _OfflineIndicatorState();
}

class _OfflineIndicatorState extends State<OfflineIndicator> {
  bool _isOffline = false;
  late StreamSubscription<List<ConnectivityResult>> _subscription;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    _subscription = Connectivity().onConnectivityChanged.listen((results) {
      setState(() {
        _isOffline =
            results.isEmpty || results.contains(ConnectivityResult.none);
      });
    });
  }

  Future<void> _checkConnectivity() async {
    final results = await Connectivity().checkConnectivity();
    setState(() {
      _isOffline = results.isEmpty || results.contains(ConnectivityResult.none);
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Offline banner
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: _isOffline ? 36 : 0,
          child: _isOffline
              ? Container(
                  width: double.infinity,
                  color: Colors.red.shade600,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.wifi_off, color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'You\'re offline',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),
        // Main content
        Expanded(child: widget.child),
      ],
    );
  }
}

/// Empty state widget for various screens
class EmptyStateWidget extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color? iconColor;

  const EmptyStateWidget({
    super.key,
    required this.title,
    required this.message,
    required this.icon,
    this.actionLabel,
    this.onAction,
    this.iconColor,
  });

  /// Factory for no items found
  factory EmptyStateWidget.noItems() {
    return const EmptyStateWidget(
      title: 'No items yet',
      message: 'Lost or found something? Report it here!',
      icon: Icons.inventory_2_outlined,
    );
  }

  /// Factory for no search results
  factory EmptyStateWidget.noSearchResults() {
    return const EmptyStateWidget(
      title: 'No results found',
      message: 'Try different keywords or filters',
      icon: Icons.search_off,
    );
  }

  /// Factory for no chats
  factory EmptyStateWidget.noChats() {
    return const EmptyStateWidget(
      title: 'No conversations yet',
      message: 'Start chatting when you find a match!',
      icon: Icons.chat_bubble_outline,
    );
  }

  /// Factory for no notifications
  factory EmptyStateWidget.noNotifications() {
    return const EmptyStateWidget(
      title: 'No notifications',
      message: 'We\'ll notify you when something happens',
      icon: Icons.notifications_none,
    );
  }

  /// Factory for no matches
  factory EmptyStateWidget.noMatches() {
    return const EmptyStateWidget(
      title: 'No matches found',
      message: 'Our AI couldn\'t find similar items yet',
      icon: Icons.compare_arrows,
    );
  }

  /// Factory for error state
  factory EmptyStateWidget.error({String? message, VoidCallback? onRetry}) {
    return EmptyStateWidget(
      title: 'Something went wrong',
      message: message ?? 'Please try again later',
      icon: Icons.error_outline,
      iconColor: Colors.red,
      actionLabel: 'Retry',
      onAction: onRetry,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon with background
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: (iconColor ?? colorScheme.primary).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 64,
                color: iconColor ?? colorScheme.primary.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 24),

            // Title
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // Message
            Text(
              message,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),

            // Action button
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.refresh),
                label: Text(actionLabel!),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Confirmation dialog helper
class ConfirmationDialog {
  static Future<bool> show({
    required BuildContext context,
    required String title,
    required String message,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    Color? confirmColor,
    bool isDangerous = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            if (isDangerous)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.warning_amber, color: Colors.red),
              ),
            if (isDangerous) const SizedBox(width: 12),
            Expanded(child: Text(title)),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(cancelLabel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  confirmColor ?? (isDangerous ? Colors.red : null),
              foregroundColor: isDangerous ? Colors.white : null,
            ),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  /// Delete confirmation shorthand
  static Future<bool> confirmDelete(BuildContext context, {String? itemName}) {
    return show(
      context: context,
      title: 'Delete ${itemName ?? 'Item'}?',
      message: 'This action cannot be undone.',
      confirmLabel: 'Delete',
      isDangerous: true,
    );
  }
}
