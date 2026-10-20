class LanguageHelper {
  static const Map<String, String> languages = {
    'en': 'English',
    'hi': 'हिंदी (Hindi)',
    'mr': 'मराठी (Marathi)',
    'gu': 'ગુજરાતી (Gujarati)',
    'kn': 'ಕನ್ನಡ (Kannada)',
    'te': 'తెలుగు (Telugu)',
    'ta': 'தமிழ் (Tamil)',
  };

  static const Map<String, Map<String, String>> translations = {
    'app_title': {
      'en': 'OniQ',
      'hi': 'OniQ',
      'mr': 'OniQ',
      'gu': 'OniQ',
      'kn': 'OniQ',
      'te': 'OniQ',
      'ta': 'OniQ',
    },
    'scan_disease': {
      'en': 'Scan Disease',
      'hi': 'रोग स्कैन करें',
      'mr': 'रोग स्कॅन करा',
      'gu': 'રોગ સ્કેન કરો',
      'kn': 'ರೋಗ ಸ್ಕ್ಯಾನ್ ಮಾಡಿ',
      'te': 'వ్యాధిని స్కాన్ చేయండి',
      'ta': 'நோயை ஸ்கேன் செய்க',
    },
    'healthy': {
      'en': 'Healthy',
      'hi': 'स्वस्थ',
      'mr': 'निरोगी / निरोगी कांदा',
      'gu': 'સ્વસ્થ',
      'kn': 'ಆರೋಗ್ಯಕರ',
      'te': 'ఆరోగ్యకరమైన',
      'ta': 'ஆரோக்கியமான',
    },
    'treatment': {
      'en': 'Treatment',
      'hi': 'उपचार / निदान',
      'mr': 'उपाययोजना',
      'gu': 'ઉપચાર',
      'kn': 'ಚಿಕಿತ್ಸೆ',
      'te': 'చికిత్స',
      'ta': 'சிகிச்சை',
    },
    'history': {
      'en': 'History',
      'hi': 'इतिहास',
      'mr': 'इतिहास',
      'gu': 'ઇતિહાસ',
      'kn': 'ಇತಿಹಾಸ',
      'te': 'చరిత్ర',
      'ta': 'வரலாறு',
    },
    'settings': {
      'en': 'Settings',
      'hi': 'सेटिंग्स',
      'mr': 'सेटिंग्ज',
      'gu': 'સેટિંગ્સ',
      'kn': 'ಸೆಟ್ಟಿಂಗ್‌ಗಳು',
      'te': 'సెట్టింగ్‌లు',
      'ta': 'அமைப்புகள்',
    },
    'welcome': {
      'en': 'Welcome',
      'hi': 'नमस्ते / स्वागत',
      'mr': 'सुस्वागतम',
      'gu': 'સ્વાગત',
      'kn': 'ಸುಸ್ವಾಗತ',
      'te': 'స్వాగతం',
      'ta': 'வரவேற்பு',
    },
    'login': {
      'en': 'Login',
      'hi': 'लॉग इन करें',
      'mr': 'लॉगिन करा',
      'gu': 'લૉગિન',
      'kn': 'ಲಾಗಿನ್',
      'te': 'లాగిన్',
      'ta': 'உள்நுழைக',
    },
    'register': {
      'en': 'Register',
      'hi': 'पंजीकरण करें',
      'mr': 'नोंदणी करा',
      'gu': 'નોંધણી',
      'kn': 'ನೋಂದಣಿ',
      'te': 'నమోదు',
      'ta': 'பதிவு',
    },
    'listen': {
      'en': 'Listen',
      'hi': 'सुनें',
      'mr': 'ऐका',
      'gu': 'સાંભળો',
      'kn': 'ಆಲಿಸಿ',
      'te': 'వినండి',
      'ta': 'கேளுங்கள்',
    },
  };

  static String translate(String key, String langCode) {
    return translations[key]?[langCode] ?? translations[key]?['en'] ?? key;
  }
}
