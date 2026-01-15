import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:frontend/models/item.dart';
import 'package:frontend/services/storage_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

/// Status options for items
enum ItemStatusOption { active, claimed, returned, expired }

extension ItemStatusOptionExtension on ItemStatusOption {
  String get label {
    switch (this) {
      case ItemStatusOption.active:
        return 'Active';
      case ItemStatusOption.claimed:
        return 'Claimed';
      case ItemStatusOption.returned:
        return 'Returned';
      case ItemStatusOption.expired:
        return 'Expired';
    }
  }

  String get description {
    switch (this) {
      case ItemStatusOption.active:
        return 'Item is still being searched for';
      case ItemStatusOption.claimed:
        return 'Someone has claimed this item';
      case ItemStatusOption.returned:
        return 'Item has been returned to owner';
      case ItemStatusOption.expired:
        return 'Listing is no longer active';
    }
  }

  IconData get icon {
    switch (this) {
      case ItemStatusOption.active:
        return Icons.search;
      case ItemStatusOption.claimed:
        return Icons.pending;
      case ItemStatusOption.returned:
        return Icons.check_circle;
      case ItemStatusOption.expired:
        return Icons.timer_off;
    }
  }

  Color get color {
    switch (this) {
      case ItemStatusOption.active:
        return const Color(0xFF6366F1);
      case ItemStatusOption.claimed:
        return const Color(0xFFF59E0B);
      case ItemStatusOption.returned:
        return const Color(0xFF22C55E);
      case ItemStatusOption.expired:
        return Colors.grey;
    }
  }
}

/// Dialog for updating item status
class ItemStatusUpdateDialog extends StatefulWidget {
  final Item item;
  final Function(ItemStatusOption, String?, File?)? onUpdate;

  const ItemStatusUpdateDialog({super.key, required this.item, this.onUpdate});

  @override
  State<ItemStatusUpdateDialog> createState() => _ItemStatusUpdateDialogState();
}

class _ItemStatusUpdateDialogState extends State<ItemStatusUpdateDialog> {
  ItemStatusOption? _selectedStatus;
  final TextEditingController _noteController = TextEditingController();
  File? _proofImage;
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.edit_note, color: colorScheme.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Update Status',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Status options
            ...ItemStatusOption.values.map(
              (status) => _buildStatusOption(status),
            ),

            // Proof image for returned status
            if (_selectedStatus == ItemStatusOption.returned) ...[
              const SizedBox(height: 16),
              Text(
                '📸 Upload proof of return (optional)',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickProofImage,
                child: Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colorScheme.outline.withOpacity(0.3),
                      width: 2,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: _proofImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.file(
                            _proofImage!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                        )
                      : Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_a_photo,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Add proof photo',
                                style: GoogleFonts.inter(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ),
            ],

            // Notes
            if (_selectedStatus != null) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _noteController,
                decoration: InputDecoration(
                  hintText: 'Add a note (optional)',
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHighest.withOpacity(
                    0.5,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                maxLines: 2,
              ),
            ],

            const SizedBox(height: 24),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSubmitting
                        ? null
                        : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _selectedStatus == null || _isSubmitting
                        ? null
                        : _submitUpdate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          _selectedStatus?.color ?? colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Update'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusOption(ItemStatusOption status) {
    final isSelected = _selectedStatus == status;

    return GestureDetector(
      onTap: () => setState(() => _selectedStatus = status),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? status.color.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? status.color : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: status.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(status.icon, color: status.color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    status.label,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      color: isSelected ? status.color : null,
                    ),
                  ),
                  Text(
                    status.description,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected) Icon(Icons.check_circle, color: status.color),
          ],
        ),
      ),
    );
  }

  Future<void> _pickProofImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      setState(() => _proofImage = File(image.path));
    }
  }

  Future<void> _submitUpdate() async {
    if (_selectedStatus == null) return;

    setState(() => _isSubmitting = true);

    try {
      String? proofUrl;
      if (_proofImage != null) {
        final storage = StorageService();
        proofUrl = await storage.uploadImage(_proofImage!);
      }

      // Update Firestore
      await FirebaseFirestore.instance
          .collection('items')
          .doc(widget.item.id)
          .update({
            'status': _selectedStatus!.name,
            'statusNote': _noteController.text.isNotEmpty
                ? _noteController.text
                : null,
            'statusProofUrl': proofUrl,
            'statusUpdatedAt': Timestamp.now(),
          });

      // Add to status history
      await FirebaseFirestore.instance
          .collection('items')
          .doc(widget.item.id)
          .collection('status_history')
          .add({
            'status': _selectedStatus!.name,
            'note': _noteController.text,
            'proofUrl': proofUrl,
            'timestamp': Timestamp.now(),
          });

      widget.onUpdate?.call(
        _selectedStatus!,
        _noteController.text,
        _proofImage,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(_selectedStatus!.icon, color: Colors.white),
                const SizedBox(width: 8),
                Text('Status updated to ${_selectedStatus!.label}'),
              ],
            ),
            backgroundColor: _selectedStatus!.color,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to update: $e')));
      }
    } finally {
      setState(() => _isSubmitting = false);
    }
  }
}

/// Show item status update dialog
void showItemStatusDialog(
  BuildContext context,
  Item item, {
  Function(ItemStatusOption, String?, File?)? onUpdate,
}) {
  showDialog(
    context: context,
    builder: (context) =>
        ItemStatusUpdateDialog(item: item, onUpdate: onUpdate),
  );
}
