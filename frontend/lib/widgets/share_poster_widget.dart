import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:frontend/models/item.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Widget for generating shareable poster and sharing to social
class SharePosterWidget extends StatefulWidget {
  final Item item;
  final VoidCallback? onShare;

  const SharePosterWidget({super.key, required this.item, this.onShare});

  @override
  State<SharePosterWidget> createState() => _SharePosterWidgetState();
}

class _SharePosterWidgetState extends State<SharePosterWidget> {
  final GlobalKey _posterKey = GlobalKey();
  bool _isSharing = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Poster preview
        RepaintBoundary(key: _posterKey, child: _buildPoster()),
        const SizedBox(height: 20),
        // Share buttons
        Row(
          children: [
            Expanded(
              child: _buildShareButton(
                icon: Icons.share,
                label: 'Share',
                color: const Color(0xFF6366F1),
                onTap: () => _shareToAll(context),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildShareButton(
                icon: Icons.camera_alt,
                label: 'Instagram',
                color: const Color(0xFFE1306C),
                onTap: () => _shareToInstagram(context),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildShareButton(
                icon: Icons.message,
                label: 'WhatsApp',
                color: const Color(0xFF25D366),
                onTap: () => _shareToWhatsApp(context),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPoster() {
    final item = widget.item;
    final isLost = item.isLost;
    final color = isLost ? const Color(0xFFEF4444) : const Color(0xFF22C55E);

    // Parse title
    String title = '';
    if (item.description.contains('|||')) {
      title = item.description.split('|||').first.trim();
    } else {
      title = item.description.split('\n').first;
    }

    return Container(
      width: 350,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.05),
            Colors.white,
            color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.3), width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isLost ? Icons.search : Icons.check_circle,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  isLost ? 'LOST ITEM' : 'FOUND ITEM',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Image
          if (item.imageUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Image.network(
                  item.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      Icon(Icons.image, size: 60, color: Colors.grey.shade400),
                ),
              ),
            ),
          const SizedBox(height: 16),

          // Title
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),

          // Location
          if (item.placeName != null && item.placeName!.isNotEmpty)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.location_on, size: 18, color: color),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    item.placeName!,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          const SizedBox(height: 16),

          // Category tags
          if (item.category != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                item.category!,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          const SizedBox(height: 20),

          // App branding
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFFA855F7)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.search, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 8),
              Text(
                'FindX',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF6366F1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isLost ? 'Help me find this item!' : 'Did you lose this item?',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShareButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: _isSharing ? null : onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<Uint8List?> _capturePoster() async {
    try {
      final boundary =
          _posterKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) return null;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      print('❌ Error capturing poster: $e');
      return null;
    }
  }

  Future<File?> _saveToTemp(Uint8List bytes) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final file = File(
        '${tempDir.path}/findx_poster_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(bytes);
      return file;
    } catch (e) {
      print('❌ Error saving poster: $e');
      return null;
    }
  }

  Future<void> _shareToAll(BuildContext context) async {
    setState(() => _isSharing = true);
    try {
      final bytes = await _capturePoster();
      if (bytes == null) throw Exception('Failed to capture poster');

      final file = await _saveToTemp(bytes);
      if (file == null) throw Exception('Failed to save poster');

      final isLost = widget.item.isLost;
      final text = isLost
          ? '🔍 Help me find my ${widget.item.category ?? "item"}! Spotted at ${widget.item.placeName ?? "unknown location"}. Contact via FindX app!'
          : '✅ Found item: ${widget.item.category ?? "item"} at ${widget.item.placeName ?? "unknown location"}. If this is yours, contact via FindX app!';

      await Share.shareXFiles(
        [XFile(file.path)],
        text: text,
        subject: isLost ? 'Lost Item Alert' : 'Found Item Alert',
      );

      widget.onShare?.call();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to share: $e')));
      }
    } finally {
      setState(() => _isSharing = false);
    }
  }

  Future<void> _shareToInstagram(BuildContext context) async {
    // Instagram story sharing - uses same mechanism
    await _shareToAll(context);
  }

  Future<void> _shareToWhatsApp(BuildContext context) async {
    // WhatsApp sharing - uses same mechanism
    await _shareToAll(context);
  }
}

/// Show share poster as bottom sheet
void showSharePosterSheet(
  BuildContext context,
  Item item, {
  VoidCallback? onShare,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            '📢 Share Item',
            style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Spread the word to help find your item!',
            style: GoogleFonts.inter(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 20),
          SharePosterWidget(item: item, onShare: onShare),
          const SizedBox(height: 20),
        ],
      ),
    ),
  );
}
