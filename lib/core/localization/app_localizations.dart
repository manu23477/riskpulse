import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'app_title': 'RiskPulse',
      'tagline': 'Disaster Risk Intelligence',
      'home': 'Home',
      'risk_map': 'Risk Map',
      'ai_assistant': 'AI Assistant',
      'my_risk': 'My Risk',
      'report_hazard': 'Report Hazard',
      'emergency_hub': 'Emergency Hub',
      'current_risk_status': 'CURRENT RISK STATUS',
      'moderate': 'Moderate',
      'risk_score': 'Risk Score',
      'trend': 'Trend',
      'confidence': 'Confidence',
      'increasing': 'Increasing',
      'what_would_you_like_to_know': 'What would you like to know?',
      'risk_map_subtitle': 'Explore hazards, exposure and vulnerability',
      'current_risk_subtitle': 'Understand what is happening right now',
      'what_if_subtitle': 'Explore possible disaster scenarios',
      'ai_assistant_subtitle': 'Ask questions about disaster risk',
      'my_risk_subtitle': 'Understand risk around your location',
      'report_hazard_subtitle': 'Contribute real-time data from your location',
      'principle_title': 'RiskPulse Principle',
      'principle_body': 'AI analyses complexity. Humans make decisions.',
      'sos': 'SOS',
      'district_risk_alerts': 'District Risk Alerts',
      'himalayan_region': 'Indian Himalayan Region',
      'tourist_safety': 'Safe Route',
      'global_feed': 'Global Alerts',
      'hello_state': 'Hello Himalayan Citizen',
      'current_region': 'Western Himalayan Region',
      'yatra_status': 'Yatra Status',
      'yatra_bulletin': 'Char Dham Live Bulletin',
      'risk_reports': 'Risk Reports',
      'live_temperature': 'LIVE TEMPERATURE',
      'feels_like': 'Feels like',
      'today': 'Today',
      'updated': 'Updated',
      'weather_unavailable': 'Temperature unavailable',
      'getting_local_temperature': 'Getting your local temperature...',
      'allow_location_weather': 'Allow location access to see your local temperature on RiskPulse.',
      'location_access_unavailable': 'Location access unavailable',
      'open_settings': 'Open Location Settings',
      'set_manually': 'Set Location Manually',
    },
    'hi': {
      'app_title': 'रिस्कपल्स (RiskPulse)',
      'tagline': 'आपदा जोखिम इंटेलिजेंस',
      'home': 'होम',
      'risk_map': 'जोखिम मानचित्र',
      'ai_assistant': 'AI सहायक',
      'my_risk': 'मेरा जोखिम',
      'report_hazard': 'खतरे की रिपोर्ट करें',
      'emergency_hub': 'आपातकालीन हब',
      'current_risk_status': 'वर्तमान जोखिम स्थिति',
      'moderate': 'मध्यम',
      'risk_score': 'जोखिम स्कोर',
      'trend': 'प्रवृत्ति',
      'confidence': 'आत्मविश्वास',
      'increasing': 'बढ़ रहा है',
      'what_would_you_like_to_know': 'आप क्या जानना चाहेंगे?',
      'risk_map_subtitle': 'खतरों और संवेदनशीलता का पता लगाएं',
      'current_risk_subtitle': 'समझें कि अभी क्या हो रहा है',
      'what_if_subtitle': 'संभावित आपदा परिदृश्यों का पता लगाएं',
      'ai_assistant_subtitle': 'आपदा जोखिम के बारे में प्रश्न पूछें',
      'my_risk_subtitle': 'अपने स्थान के आसपास के जोखिम को समझें',
      'report_hazard_subtitle': 'अपने स्थान से रीयल-टाइम डेटा दें',
      'principle_title': 'रिस्कपल्स सिद्धांत',
      'principle_body': 'AI जटिलता का विश्लेषण करता है। मनुष्य निर्णय लेते हैं।',
      'sos': 'एसओएस (SOS)',
      'district_risk_alerts': 'जिला जोखिम अलर्ट',
      'himalayan_region': 'भारतीय हिमालयी क्षेत्र',
      'global_feed': 'वैश्विक अलर्ट',
      'hello_state': 'नमस्ते हिमालयी नागरिक',
      'current_region': 'पश्चिमी हिमालयी क्षेत्र',
      'yatra_status': 'यात्रा की स्थिति',
      'yatra_bulletin': 'चार धाम लाइव बुलेटिन',
      'risk_reports': 'जोखिम रिपोर्ट',
      'live_temperature': 'लाइव तापमान (LIVE TEMPERATURE)',
      'feels_like': 'महसूस होता है',
      'today': 'आज',
      'updated': 'अद्यतित',
      'weather_unavailable': 'तापमान अनुपलब्ध है',
      'getting_local_temperature': 'आपका स्थानीय तापमान प्राप्त कर रहे हैं...',
      'allow_location_weather': 'रिस्कपल्स पर अपना स्थानीय तापमान देखने के लिए स्थान पहुंच की अनुमति दें।',
      'location_access_unavailable': 'स्थान पहुंच अनुपलब्ध है',
      'open_settings': 'स्थान सेटिंग खोलें',
      'set_manually': 'स्थान मैन्युअल रूप से सेट करें',
    },
  };

  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? key;
  }
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'hi'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) {
    return Future.value(AppLocalizations(locale));
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}

class LanguageProvider extends ChangeNotifier {
  Locale _locale = const Locale('en');

  Locale get locale => _locale;

  void setLocale(Locale locale) {
    _locale = locale;
    notifyListeners();
  }

  void toggleLanguage() {
    if (_locale.languageCode == 'en') {
      _locale = const Locale('hi');
    } else {
      _locale = const Locale('en');
    }
    notifyListeners();
  }
}
