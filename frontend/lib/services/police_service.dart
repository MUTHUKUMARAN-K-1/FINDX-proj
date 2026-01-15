import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:frontend/models/item.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

/// Police service for emergency contacts and FIR filing
class PoliceService {
  static final PoliceService _instance = PoliceService._internal();
  factory PoliceService() => _instance;
  PoliceService._internal();

  /// India emergency numbers
  static const String policeEmergency = '100';
  static const String womenHelpline = '1091';
  static const String childHelpline = '1098';
  static const String cyberCrime = '1930';

  /// State-wise police portal URLs (India)
  static const Map<String, String> statePolicePortals = {
    'Tamil Nadu': 'https://eservices.tnpolice.gov.in/CCTNSNICSDC/',
    'Karnataka': 'https://ksp.karnataka.gov.in/en',
    'Maharashtra': 'https://citizen.mahapolice.gov.in/',
    'Delhi': 'https://delhipolice.gov.in/',
    'Kerala': 'https://keralapolice.gov.in/',
    'Andhra Pradesh': 'https://www.appolice.gov.in/',
    'Telangana': 'https://www.tspolice.gov.in/',
    'Gujarat': 'https://police.gujarat.gov.in/',
    'Rajasthan': 'https://police.rajasthan.gov.in/',
    'Uttar Pradesh': 'https://uppolice.gov.in/',
    'West Bengal': 'https://wbpolice.gov.in/',
    'Bihar': 'https://biharpolice.bih.nic.in/',
    'Madhya Pradesh': 'https://mppolice.gov.in/',
    'Punjab': 'https://punjabpolice.gov.in/',
    'Haryana': 'https://haryanapolice.gov.in/',
  };

  /// CEIR Portal for lost mobile phones
  static const String ceirPortalUrl = 'https://www.ceir.gov.in/Home/index.jsp';

  /// National Lost & Found portal
  static const String nationalLostFoundUrl =
      'https://citizen.mahapolice.gov.in/Lostandfound/Index.aspx';

  /// Call police emergency
  Future<void> callPolice() async {
    final uri = Uri.parse('tel:$policeEmergency');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  /// Call specific helpline
  Future<void> callHelpline(String number) async {
    final uri = Uri.parse('tel:$number');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  /// Open state police portal
  Future<void> openPolicePortal(String state) async {
    final url = statePolicePortals[state];
    if (url != null) {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  /// Open CEIR portal for mobile phone reports
  Future<void> openCEIRPortal() async {
    final uri = Uri.parse(ceirPortalUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// Generate FIR draft text
  String generateFIRDraft(
    Item item, {
    String? complainantName,
    String? complainantPhone,
    String? complainantAddress,
  }) {
    // Parse title and description
    String itemTitle = '';
    String itemDescription = '';
    if (item.description.contains('|||')) {
      final parts = item.description.split('|||');
      itemTitle = parts.first.trim();
      itemDescription = parts.length > 1 ? parts[1].trim() : '';
    } else {
      itemTitle = item.description.split('\n').first;
      itemDescription = item.description;
    }

    final dateFormatter = DateFormat('dd-MM-yyyy');
    final timeFormatter = DateFormat('HH:mm');
    final incidentDate = dateFormatter.format(item.timestamp);
    final incidentTime = timeFormatter.format(item.timestamp);
    final today = dateFormatter.format(DateTime.now());

    return '''
═══════════════════════════════════════════════════════════════
                    FIRST INFORMATION REPORT (FIR)
                       DRAFT FOR POLICE STATION
═══════════════════════════════════════════════════════════════

Date: $today
Reference: FindX App Report #${item.id.substring(0, 8).toUpperCase()}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

COMPLAINANT DETAILS:
────────────────────
Name: ${complainantName ?? '[YOUR NAME]'}
Phone: ${complainantPhone ?? '[YOUR PHONE NUMBER]'}
Address: ${complainantAddress ?? '[YOUR ADDRESS]'}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

INCIDENT DETAILS:
────────────────────
Type: ${item.isLost ? 'LOST PROPERTY' : 'FOUND PROPERTY'}
Date of Incident: $incidentDate
Approximate Time: $incidentTime

Location: ${item.placeName ?? 'Unknown'}
GPS Coordinates: ${item.latitude.toStringAsFixed(6)}, ${item.longitude.toStringAsFixed(6)}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ITEM DETAILS:
────────────────────
Item Name: $itemTitle
Category: ${item.category ?? 'Not Specified'}
Description: $itemDescription
${item.tags != null && item.tags!.isNotEmpty ? 'Identifiers/Tags: ${item.tags!.join(', ')}' : ''}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

STATEMENT:
────────────────────
I, the undersigned, hereby ${item.isLost ? 'report the loss of' : 'report finding'} the above-mentioned item ${item.isLost ? 'which was in my possession' : 'at the location mentioned above'}. 

${item.isLost ? 'The item was lost on $incidentDate at approximately $incidentTime near the location specified. I request the police to record this complaint and help in recovering my property.' : 'I found this item on $incidentDate at approximately $incidentTime and wish to hand it over to the rightful owner through proper legal channels.'}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

DECLARATION:
────────────────────
I hereby declare that the information provided above is true and 
correct to the best of my knowledge and belief.


Signature: _________________________

Date: $today

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Generated via FindX - AI-Powered Lost & Found Platform
App Report ID: ${item.id}

═══════════════════════════════════════════════════════════════
''';
  }

  /// Save police report reference to item
  Future<void> savePoliceReportNumber({
    required String itemId,
    required String reportNumber,
    String? stationName,
    String? officerName,
  }) async {
    await FirebaseFirestore.instance.collection('items').doc(itemId).update({
      'policeReport': {
        'reportNumber': reportNumber,
        'stationName': stationName,
        'officerName': officerName,
        'filedAt': Timestamp.now(),
      },
    });
  }

  /// Get list of available states
  List<String> getAvailableStates() {
    return statePolicePortals.keys.toList()..sort();
  }
}
