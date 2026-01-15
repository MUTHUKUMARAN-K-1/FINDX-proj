import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/models/item.dart';
import 'package:frontend/services/police_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

/// Dialog for police reporting options
class PoliceReportDialog extends StatefulWidget {
  final Item item;

  const PoliceReportDialog({super.key, required this.item});

  @override
  State<PoliceReportDialog> createState() => _PoliceReportDialogState();
}

class _PoliceReportDialogState extends State<PoliceReportDialog> {
  final PoliceService _policeService = PoliceService();
  String? _selectedState;
  bool _showFIRDraft = false;
  String _firDraft = '';

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedState = _policeService.getAvailableStates().first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isMobile =
        widget.item.category?.toLowerCase().contains('phone') ?? false;

    if (_showFIRDraft) {
      return _buildFIRDraftView(colorScheme);
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.local_police,
                      color: Colors.red,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Report to Police',
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Get official help for your ${widget.item.isLost ? "lost" : "found"} item',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Emergency Contacts Section
              _buildSectionTitle('📞 Emergency Contacts'),
              const SizedBox(height: 12),
              _buildEmergencyButton(
                icon: Icons.phone,
                title: 'Police Emergency',
                subtitle: 'Call 100',
                color: Colors.red,
                onTap: () => _policeService.callPolice(),
              ),
              const SizedBox(height: 8),
              _buildEmergencyButton(
                icon: Icons.security,
                title: 'Cyber Crime',
                subtitle: 'Call 1930',
                color: const Color(0xFF6366F1),
                onTap: () => _policeService.callHelpline('1930'),
              ),
              if (widget.item.category?.toLowerCase() == 'people') ...[
                const SizedBox(height: 8),
                _buildEmergencyButton(
                  icon: Icons.woman,
                  title: 'Women Helpline',
                  subtitle: 'Call 1091',
                  color: Colors.pink,
                  onTap: () => _policeService.callHelpline('1091'),
                ),
                _buildEmergencyButton(
                  icon: Icons.child_care,
                  title: 'Child Helpline',
                  subtitle: 'Call 1098',
                  color: Colors.orange,
                  onTap: () => _policeService.callHelpline('1098'),
                ),
              ],

              const SizedBox(height: 24),

              // Online FIR Section
              _buildSectionTitle('🌐 File Online Complaint'),
              const SizedBox(height: 12),

              // State selector
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedState,
                    isExpanded: true,
                    items: _policeService.getAvailableStates().map((state) {
                      return DropdownMenuItem(value: state, child: Text(state));
                    }).toList(),
                    onChanged: (value) =>
                        setState(() => _selectedState = value),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              _buildActionButton(
                icon: Icons.open_in_browser,
                title: 'Open State Police Portal',
                subtitle: 'File FIR online',
                color: const Color(0xFF22C55E),
                onTap: () {
                  if (_selectedState != null) {
                    _policeService.openPolicePortal(_selectedState!);
                  }
                },
              ),

              // CEIR for mobile phones
              if (isMobile) ...[
                const SizedBox(height: 12),
                _buildActionButton(
                  icon: Icons.phone_android,
                  title: 'CEIR Portal',
                  subtitle: 'Block/Track lost mobile phone',
                  color: const Color(0xFFF59E0B),
                  onTap: () => _policeService.openCEIRPortal(),
                ),
              ],

              const SizedBox(height: 24),

              // FIR Draft Section
              _buildSectionTitle('📝 Generate FIR Draft'),
              const SizedBox(height: 8),
              Text(
                'Get a pre-filled complaint letter to take to police station',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    _firDraft = _policeService.generateFIRDraft(
                      widget.item,
                      complainantName: _nameController.text.isNotEmpty
                          ? _nameController.text
                          : null,
                      complainantPhone: _phoneController.text.isNotEmpty
                          ? _phoneController.text
                          : null,
                      complainantAddress: _addressController.text.isNotEmpty
                          ? _addressController.text
                          : null,
                    );
                    setState(() => _showFIRDraft = true);
                  },
                  icon: const Icon(Icons.description),
                  label: const Text('Generate FIR Draft'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Center(child: Text('Close')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFIRDraftView(ColorScheme colorScheme) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.primary,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => setState(() => _showFIRDraft = false),
                ),
                const Expanded(
                  child: Text(
                    'FIR Draft',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy, color: Colors.white),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _firDraft));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Copied to clipboard!')),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.share, color: Colors.white),
                  onPressed: () {
                    Share.share(_firDraft, subject: 'FIR Draft - FindX Report');
                  },
                ),
              ],
            ),
          ),
          // Content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: SelectableText(
                  _firDraft,
                  style: GoogleFonts.firaCode(fontSize: 11, height: 1.5),
                ),
              ),
            ),
          ),
          // Actions
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() => _showFIRDraft = false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Back'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Share.share(_firDraft, subject: 'FIR Draft - FindX');
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.print),
                    label: const Text('Share & Print'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildEmergencyButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.phone, color: color),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.open_in_new, color: color, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

/// Show police report dialog
void showPoliceReportDialog(BuildContext context, Item item) {
  showDialog(
    context: context,
    builder: (context) => PoliceReportDialog(item: item),
  );
}
