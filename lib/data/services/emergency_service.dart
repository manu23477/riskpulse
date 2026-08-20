import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'location_service.dart';
import '../models/emergency_contact.dart';

class EmergencyService {
  final LocationService _locationService = LocationService();

  List<EmergencyContact> getOfficialHelplines() {
    return const [
      EmergencyContact(
        id: 'hp-sdma',
        name: 'HP State Disaster Mgmt',
        phoneNumber: '1070',
        isOfficial: true,
        subtitle: 'State Emergency Operation Centre',
      ),
      EmergencyContact(
        id: 'dist-disaster',
        name: 'District Disaster Mgmt',
        phoneNumber: '1077',
        isOfficial: true,
        subtitle: 'District Emergency Operation Centre',
      ),
      EmergencyContact(
        id: 'hp-police',
        name: 'HP Police',
        phoneNumber: '112',
        isOfficial: true,
        subtitle: 'Emergency Response Support System',
      ),
      EmergencyContact(
        id: 'ambulance',
        name: 'Ambulance',
        phoneNumber: '108',
        isOfficial: true,
        subtitle: 'Health Emergencies',
      ),
      EmergencyContact(
        id: 'fire',
        name: 'Fire Department',
        phoneNumber: '101',
        isOfficial: true,
      ),
    ];
  }

  Future<void> sendSOS() async {
    try {
      final position = await _locationService.getCurrentPosition();
      final mapsUrl = 'https://www.google.com/maps/search/?api=1&query=${position.latitude},${position.longitude}';
      
      final String message = 
          'EMERGENCY SOS! I need immediate help. \n'
          'My current location is: \n'
          '$mapsUrl \n'
          '(Sent via RiskPulse Disaster Intelligence)';

      await Share.share(message, subject: 'Emergency SOS');
    } catch (e) {
      // If location fails, still allow sharing a basic SOS message
      await Share.share('EMERGENCY SOS! I need help. (Sent via RiskPulse)');
    }
  }

  Future<void> callContact(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }
}
