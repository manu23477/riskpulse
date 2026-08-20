import 'package:flutter/material.dart';
import '../models/safety_playbook.dart';

class SafetyRepository {
  List<SafetyPlaybook> getPlaybooks(String languageCode) {
    if (languageCode == 'hi') {
      return _getHindiPlaybooks();
    }
    return _getEnglishPlaybooks();
  }

  List<SafetyPlaybook> _getEnglishPlaybooks() {
    return [
      const SafetyPlaybook(
        id: 'pb-landslide',
        title: 'Landslide Safety',
        description: 'Survival guide for debris flows and rockfalls.',
        icon: Icons.terrain,
        essentialItems: ['Flashlight', 'Whistle', 'First Aid Kit', 'Water'],
        steps: [
          SafetyStep(
            title: 'Stay Alert',
            body: 'Listen for unusual sounds like trees cracking or boulders knocking together.',
            isCritical: true,
          ),
          SafetyStep(
            title: 'Move Uphill',
            body: 'If you are near a stream or channel, move away and uphill immediately.',
          ),
          SafetyStep(
            title: 'Curl into a Ball',
            body: 'If escape is impossible, curl into a tight ball and protect your head.',
          ),
        ],
      ),
      const SafetyPlaybook(
        id: 'pb-flood',
        title: 'Flash Flood Safety',
        description: 'Emergency actions for sudden rising waters.',
        icon: Icons.water,
        essentialItems: ['Power bank', 'Dry clothes', 'Energy bars', 'Radio'],
        steps: [
          SafetyStep(
            title: 'Higher Ground',
            body: 'Move to higher ground immediately. Do not wait for instructions.',
            isCritical: true,
          ),
          SafetyStep(
            title: 'Avoid Floodwater',
            body: 'Do not walk or drive through moving water. Even 6 inches can knock you over.',
          ),
          SafetyStep(
            title: 'Power Safety',
            body: 'If your home is flooded, turn off electricity at the main breaker.',
          ),
        ],
      ),
    ];
  }

  List<SafetyPlaybook> _getHindiPlaybooks() {
    return [
      const SafetyPlaybook(
        id: 'pb-landslide',
        title: 'भूस्खलन सुरक्षा',
        description: 'मलबे के प्रवाह और चट्टान गिरने के लिए उत्तरजीविता मार्गदर्शिका।',
        icon: Icons.terrain,
        essentialItems: ['टॉर्च', 'सीटी', 'प्राथमिक चिकित्सा किट', 'पानी'],
        steps: [
          SafetyStep(
            title: 'सतर्क रहें',
            body: 'पेड़ों के टूटने या पत्थरों के टकराने जैसी असामान्य आवाजों को सुनें।',
            isCritical: true,
          ),
          SafetyStep(
            title: 'ऊंचाई पर जाएं',
            body: 'यदि आप किसी धारा या नाले के पास हैं, तो तुरंत वहां से हट जाएं और ऊंचाई पर जाएं।',
          ),
          SafetyStep(
            title: 'सिर की रक्षा करें',
            body: 'यदि बचना असंभव है, तो गेंद की तरह सिमट जाएं और अपने सिर की रक्षा करें।',
          ),
        ],
      ),
      const SafetyPlaybook(
        id: 'pb-flood',
        title: 'अचानक बाढ़ से सुरक्षा',
        description: 'अचानक बढ़ते पानी के लिए आपातकालीन कार्रवाई।',
        icon: Icons.water,
        essentialItems: ['पावर बैंक', 'सूखे कपड़े', 'एनर्जी बार', 'रेडियो'],
        steps: [
          SafetyStep(
            title: 'ऊंचा स्थान',
            body: 'तुरंत ऊंचे स्थान पर जाएं। निर्देशों की प्रतीक्षा न करें।',
            isCritical: true,
          ),
          SafetyStep(
            title: 'बाढ़ के पानी से बचें',
            body: 'बहते पानी में न चलें और न ही वाहन चलाएं। केवल 6 इंच पानी आपको गिरा सकता है।',
          ),
          SafetyStep(
            title: 'बिजली सुरक्षा',
            body: 'यदि आपके घर में बाढ़ आ गई है, तो मुख्य ब्रेकर से बिजली बंद कर दें।',
          ),
        ],
      ),
    ];
  }
}
