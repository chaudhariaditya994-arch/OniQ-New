import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  String _languageCode = 'en';

  String get code => _languageCode;

  LanguageProvider() {
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    _languageCode = prefs.getString('language') ?? 'en';
    notifyListeners();
  }

  Future<void> setLanguage(String code) async {
    _languageCode = code;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', code);
    notifyListeners();
  }

  /// Translate a key using the built-in dictionary.
  /// Falls back to English if direct translation is not present.
  String t(String key) {
    final entry = _translations[key];
    if (entry == null) return key;
    final direct = entry[_languageCode];
    if (direct != null) return direct;
    return entry['en'] ?? key;
  }

  /// Translate `key` then substitute `{name}` placeholders from `params`.
  String tf(String key, Map<String, Object?> params) {
    var s = t(key);
    params.forEach((k, v) => s = s.replaceAll('{$k}', '${v ?? ''}'));
    return s;
  }

  static const Map<String, Map<String, String>> _translations = {
    // App
    'app_title': {
      'en': 'OniQ', 'hi': 'OniQ', 'mr': 'OniQ', 'gu': 'OniQ', 'kn': 'OniQ', 'te': 'OniQ', 'ta': 'OniQ',
    },

    // Navbar
    'home': {
      'en': 'Home', 'hi': 'होम', 'mr': 'मुख्य', 'gu': 'મુખ્ય', 'kn': 'ಮುಖಪುಟ', 'te': 'హోమ్', 'ta': 'முகப்பு',
    },
    'freshness': {
      'en': 'Freshness', 'hi': 'ताज़गी', 'mr': 'ताजेपणा', 'gu': 'તાજગી', 'kn': 'ತಾಜಾತನ', 'te': 'తాజాదనం', 'ta': 'புத்துணர்ச்சி',
    },
    'history': {
      'en': 'History', 'hi': 'इतिहास', 'mr': 'इतिहास', 'gu': 'ઇતિહાસ', 'kn': 'ಇತಿಹಾಸ', 'te': 'చరిత్ర', 'ta': 'வரலாறு',
    },
    'analytics': {
      'en': 'Analytics', 'hi': 'विश्लेषण', 'mr': 'विश्लेषण', 'gu': 'વિશ્લેષણ', 'kn': 'ವಿಶ್ಲೇಷಣೆ', 'te': 'విశ్లేషణ', 'ta': 'பகுப்பாய்வு',
    },

    // Home page
    'welcome': {
      'en': 'Welcome', 'tw': 'Akwaaba', 'dg': 'Anlaibiisim', 'ee': 'Woezon', 'ha': 'Sannu', 'mp': 'Anlaibiisim', 'fr': 'Bienvenue',
    },
    'protect_crops': {
      'en': 'Protect your onion crops with AI', 'tw': 'Bɔ wo gyeene nnɔbae ho ban de AI', 'dg': 'Di a gabuŋ alubosa din pam', 'ee': 'Dzɔ wo sabala numedodowo', 'ha': 'Kare albasa da AI', 'mp': 'Di a gabuŋ alubosa din pam', 'fr': "Protégez vos cultures d'oignons avec l'IA",
    },
    'scan_disease': {
      'en': 'Scan Disease', 'tw': 'Hwehwɛ Nyarewa', 'dg': 'Daliri Bɛhigu', 'ee': 'Dɔlele Didi', 'ha': 'Bincika Cuta', 'mp': 'Daliri Bɛhigu', 'fr': 'Scanner une maladie',
    },
    'take_photo': {
      'en': 'Take a photo of your onion plant', 'tw': 'Fa wo gyeene dua no foto', 'dg': 'Lahi a alubosa tihi foto', 'ee': 'Ɖe wo sabala fotoɖeka', 'ha': 'Ɗauki hoton albasa ka', 'mp': 'Lahi a alubosa tihi foto', 'fr': "Prenez une photo de votre plant d'oignon",
    },
    'gallery': {
      'en': 'Gallery', 'tw': 'Mfonini', 'dg': 'Foto doo', 'ee': 'Nufotowo', 'ha': 'Hoto', 'mp': 'Foto doo', 'fr': 'Galerie',
    },
    'stats': {
      'en': 'Stats', 'tw': 'Akontaabu', 'dg': 'Yɛltɔɣa', 'ee': 'Akɔntawo', 'ha': 'Ƙididdiga', 'mp': 'Yɛltɔɣa', 'fr': 'Stats',
    },
    'quick_actions': {
      'en': 'Quick Actions', 'tw': 'Dwumadie ntɛm', 'dg': 'Tuma salima', 'ee': 'Dɔwɔwɔ kabakaba', 'ha': 'Ayyuka cikin sauri', 'mp': 'Tuma salima', 'fr': 'Actions rapides',
    },

    // Freshness page
    'freshness_check': {
      'en': 'Freshness Check', 'tw': 'Foforɔ hwehwɛ', 'dg': 'Palli daliri', 'ee': 'Yeye kpɔkpɔ', 'ha': 'Binciken sabo', 'mp': 'Palli daliri', 'fr': 'Vérification de fraîcheur',
    },
    'freshness_desc': {
      'en': 'Check if your onion is fresh, almost spoilt, or rotten', 'tw': 'Hwɛ sɛ wo gyeene no yɛ foforɔ, ɛrebɛsɛe, anaasɛ aporɔw', 'dg': 'Nyɛli ka a alubosa palli bee ka di bɔri', 'ee': 'Kpɔ ne wo sabala le yeye, ale adzɔ, alo adzɔ', 'ha': 'Duba ko albasa ka sabo ne, kusa ta lalace, ko ta lalace', 'mp': 'Nyɛli ka a alubosa palli bee ka di bɔri', 'fr': "Vérifiez si votre oignon est frais, presque gâté, ou pourri",
    },
    'camera': {
      'en': 'Camera', 'tw': 'Kamera', 'dg': 'Kamera', 'ee': 'Kamera', 'ha': 'Kyamara', 'mp': 'Kamera', 'fr': 'Caméra',
    },
    'analyzing': {
      'en': 'Analyzing freshness...', 'tw': 'Ɛrehwehwɛ foforɔ...', 'dg': 'Daliri palli...', 'ee': 'Le yeye kpɔm...', 'ha': 'Ana bincike...', 'mp': 'Daliri palli...', 'fr': 'Analyse de la fraîcheur...',
    },
    'analysis': {
      'en': 'Analysis', 'tw': 'Nhwehwɛmu', 'dg': 'Daliri', 'ee': 'Numeɖeɖe', 'ha': 'Bincike', 'mp': 'Daliri', 'fr': 'Analyse',
    },
    'tips': {
      'en': 'Tips', 'tw': 'Afotu', 'dg': 'Wuntarigu', 'ee': 'Aɖaŋuwo', 'ha': 'Shawarwari', 'mp': 'Wuntarigu', 'fr': 'Conseils',
    },

    // Login / Register
    'login': {
      'en': 'Login', 'tw': 'Wura mu', 'dg': 'Kpe niŋ', 'ee': 'Ge eme', 'ha': 'Shiga', 'mp': 'Kpe niŋ', 'fr': 'Connexion',
    },
    'register': {
      'en': 'Register', 'tw': 'Kyerɛw din', 'dg': 'Sabi din', 'ee': 'Ŋlɔ ŋkɔ', 'ha': 'Yi rajista', 'mp': 'Sabi din', 'fr': "S'inscrire",
    },
    'create_account': {
      'en': 'Create Account', 'tw': 'Bue akawnt', 'dg': 'Mali akawnt', 'ee': 'Ŋlɔ ŋkɔ', 'ha': 'Buɗe asusu', 'mp': 'Mali akawnt', 'fr': 'Créer un compte',
    },
    'email': {
      'en': 'Email', 'tw': 'Email', 'dg': 'Email', 'ee': 'Email', 'ha': 'Imel', 'mp': 'Email', 'fr': 'E-mail',
    },
    'password': {
      'en': 'Password', 'tw': 'Nsɛmfua', 'dg': 'Password', 'ee': 'Ŋkugbalẽ', 'ha': 'Kalmar wucewa', 'mp': 'Password', 'fr': 'Mot de passe',
    },
    'full_name': {
      'en': 'Full Name', 'tw': 'Din nyinaa', 'dg': 'Yulin yuuli', 'ee': 'Ŋkɔ blibo', 'ha': 'Suna cikakke', 'mp': 'Yulin yuuli', 'fr': 'Nom complet',
    },
    'username': {
      'en': 'Username', 'tw': 'Din', 'dg': 'Yuuli', 'ee': 'Ŋkɔ', 'ha': 'Sunan mai amfani', 'mp': 'Yuuli', 'fr': "Nom d'utilisateur",
    },
    'phone': {
      'en': 'Phone Number', 'tw': 'Fon nɔma', 'dg': 'Tilifon nɔmba', 'ee': 'Fon dzia', 'ha': 'Lambar waya', 'mp': 'Tilifon nɔmba', 'fr': 'Numéro de téléphone',
    },
    'user_type': {
      'en': 'User Type', 'tw': 'Dwumadie', 'dg': 'Tumda buɣili', 'ee': 'Dɔwɔla ƒomevi', 'ha': 'Irin mai amfani', 'mp': 'Tumda buɣili', 'fr': "Type d'utilisateur",
    },
    'language': {
      'en': 'Language', 'tw': 'Kasa', 'dg': 'Zili', 'ee': 'Gbe', 'ha': 'Harshe', 'mp': 'Zili', 'fr': 'Langue',
    },
    'no_account': {
      'en': "Don't have an account? Register here", 'tw': 'Wonni akawnt? Kyerɛw din wɔ ha', 'dg': 'Ka n nyɛ akawnt? Sabi din kani', 'ee': 'Mele akawnt aɖeke o? Ŋlɔ ŋkɔ le afisia', 'ha': 'Ba ka asusu ba? Yi rajista a nan', 'mp': 'Ka n nyɛ akawnt? Sabi din kani', 'fr': "Pas de compte ? Inscrivez-vous ici",
    },
    'have_account': {
      'en': 'Already have an account? Login', 'tw': 'Wowɔ akawnt dada? Wura mu', 'dg': 'Ka nyɛla ni akawnt? Kpe niŋ', 'ee': 'Ele akawnt xoxo? Ge eme', 'ha': 'Kana da asusu? Shiga', 'mp': 'Ka nyɛla ni akawnt? Kpe niŋ', 'fr': 'Vous avez déjà un compte ? Connectez-vous',
    },
    'forgot_password': {
      'en': 'Forgot Your Password?', 'tw': 'Wo werɛ afi wo nsɛmfua?', 'dg': 'Ka che yɛlimi a password?', 'ee': 'Ŋkugbalẽ ŋutɔ wò?', 'ha': 'Ka manta kalmar wucewa?', 'mp': 'Ka che yɛlimi a password?', 'fr': 'Mot de passe oublié ?',
    },
    'login_biometric': {
      'en': 'Login with Biometrics', 'tw': 'Fa nsateaa wura mu', 'dg': 'Kpe niŋ ni biometric', 'ee': 'Ge eme kple biometric', 'ha': 'Shiga da biometric', 'mp': 'Kpe niŋ ni biometric', 'fr': 'Se connecter avec la biométrie',
    },

    // Settings
    'settings': {
      'en': 'Settings', 'tw': 'Nhyehyɛe', 'dg': 'Zaŋli', 'ee': 'Ɖoɖo', 'ha': 'Saiti', 'mp': 'Zaŋli', 'fr': 'Paramètres',
    },
    'security': {
      'en': 'Security', 'tw': 'Ahobammɔ', 'dg': 'Soŋsim', 'ee': 'Deɖeɖe', 'ha': 'Tsaro', 'mp': 'Soŋsim', 'fr': 'Sécurité',
    },
    'biometric_login': {
      'en': 'Biometric Login', 'tw': 'Nsateaa wura mu', 'dg': 'Biometric kpe niŋ', 'ee': 'Biometric ge eme', 'ha': 'Biometric shiga', 'mp': 'Biometric kpe niŋ', 'fr': 'Connexion biométrique',
    },
    'biometric_desc': {
      'en': 'Use fingerprint or face to login', 'tw': 'Fa nsateaa anaa anim wura mu', 'dg': 'Tum ni biometric kpe niŋ', 'ee': 'Zã biometric ge eme', 'ha': 'Yi amfani da biometric don shiga', 'mp': 'Tum ni biometric kpe niŋ', 'fr': "Utilisez l'empreinte ou le visage pour vous connecter",
    },
    'about': {
      'en': 'About', 'tw': 'Ɛfa ho', 'dg': 'Din pam', 'ee': 'Tɔtrɔ', 'ha': 'Game da', 'mp': 'Din pam', 'fr': 'À propos',
    },
    'logout': {
      'en': 'Logout', 'tw': 'Fi mu', 'dg': 'Yi niŋ', 'ee': 'Do go eme', 'ha': 'Fita', 'mp': 'Yi niŋ', 'fr': 'Déconnexion',
    },
    'do_you_want_logout': {
      'en': 'Do you want to logout?', 'tw': 'Wopɛ sɛ wofi mu?', 'dg': 'A bɔri ka yi niŋ?', 'ee': 'Dè di be nado go eme?', 'ha': 'Kana so ka fita?', 'mp': 'A bɔri ka yi niŋ?', 'fr': 'Voulez-vous vous déconnecter ?',
    },
    'yes': {
      'en': 'Yes', 'tw': 'Aane', 'dg': 'Ayi', 'ee': 'Ɛ', 'ha': 'Eh', 'mp': 'Ayi', 'fr': 'Oui',
    },
    'no': {
      'en': 'No', 'tw': 'Dabi', 'dg': 'Ayi', 'ee': 'Ao', 'ha': 'A\'a', 'mp': 'Ayi', 'fr': 'Non',
    },

    // Treatment
    'treatment': {
      'en': 'Treatment', 'tw': 'Ayaresa', 'dg': 'Tiba', 'ee': 'Atike', 'ha': 'Magani', 'mp': 'Tiba', 'fr': 'Traitement',
    },
    'treatment_guide': {
      'en': 'Treatment Guide', 'tw': 'Ayaresa nkyerɛwde', 'dg': 'Tiba zaŋli', 'ee': 'Atike alesi', 'ha': 'Jagoran magani', 'mp': 'Tiba zaŋli', 'fr': 'Guide de traitement',
    },
    'symptoms': {
      'en': 'Symptoms', 'tw': 'Nsɛnkyerɛnne', 'dg': 'Bɛhigu wuhigu', 'ee': 'Dzesi', 'ha': 'Alamomi', 'mp': 'Bɛhigu wuhigu', 'fr': 'Symptômes',
    },
    'treatment_steps': {
      'en': 'Treatment Steps', 'tw': 'Ayaresa anammɔn', 'dg': 'Tiba tuma', 'ee': 'Atike afɔɖeɖewo', 'ha': 'Matakai magani', 'mp': 'Tiba tuma', 'fr': 'Étapes du traitement',
    },
    'prevention': {
      'en': 'Prevention', 'tw': 'Ɛho banbɔ', 'dg': 'Kpahigu', 'ee': 'Kpekpe', 'ha': 'Rigakafi', 'mp': 'Kpahigu', 'fr': 'Prévention',
    },
    'recommended_products': {
      'en': 'Recommended Products', 'tw': 'Nneɛma a wɔkamfo', 'dg': 'Bindi shɛli', 'ee': 'Nuɖoɖowo', 'ha': 'Kayayyakin da ake ba da shawara', 'mp': 'Bindi shɛli', 'fr': 'Produits recommandés',
    },
    'listen': {
      'en': 'Listen', 'tw': 'Tie', 'dg': 'Wumbu', 'ee': 'Se', 'ha': 'Saurara', 'mp': 'Wumbu', 'fr': 'Écouter',
    },
    'translating': {
      'en': 'Translating...', 'tw': 'Ɛrekyerɛ ase...', 'dg': 'Zaŋli...', 'ee': 'Le ɖeɖem...', 'ha': 'Ana fassara...', 'mp': 'Zaŋli...', 'fr': 'Traduction en cours...',
    },

    // Diagnosis
    'scan_failed': {
      'en': 'Scan Failed', 'tw': 'Nhwehwɛ no ansi yie', 'dg': 'Daliri ka ti', 'ee': 'Didi me dzo o', 'ha': 'Bincike bai yi', 'mp': 'Daliri ka ti', 'fr': 'Échec du scan',
    },
    'confidence': {
      'en': 'confidence', 'tw': 'gyidi', 'dg': 'tɛɣili', 'ee': 'ŋuɖoɖo', 'ha': 'tabbaci', 'mp': 'tɛɣili', 'fr': 'confiance',
    },
    'view_treatment': {
      'en': 'View Treatment', 'tw': 'Hwɛ ayaresa', 'dg': 'Nyɛli tiba', 'ee': 'Kpɔ atike', 'ha': 'Duba magani', 'mp': 'Nyɛli tiba', 'fr': 'Voir le traitement',
    },
    'scan_history_empty': {
      'en': 'Scan history will appear here', 'tw': 'Nhwehwɛ abakɔsɛm bɛba ha', 'dg': 'Daliri tarihi ni ti kani', 'ee': 'Didi nutinya ava afisia', 'ha': 'Tarihin bincike zai bayyana anan', 'mp': 'Daliri tarihi ni ti kani', 'fr': "L'historique des scans apparaîtra ici",
    },

    // Common
    'ok': {
      'en': 'OK', 'tw': 'OK', 'dg': 'OK', 'ee': 'OK', 'ha': 'OK', 'mp': 'OK', 'fr': 'OK',
    },
    'cancel': {
      'en': 'Cancel', 'tw': 'Gyae', 'dg': 'Chɛ', 'ee': 'Dzudzɔ', 'ha': 'Soke', 'mp': 'Chɛ', 'fr': 'Annuler',
    },
    'send': {
      'en': 'Send', 'tw': 'Mena', 'dg': 'Tum', 'ee': 'Ɖo', 'ha': 'Aika', 'mp': 'Tum', 'fr': 'Envoyer',
    },
    'change_password': {
      'en': 'Change Password', 'tw': 'Sesa nsɛmfua', 'dg': 'Labi password', 'ee': 'Trɔ ŋkugbalẽ', 'ha': 'Canja kalmar wucewa', 'mp': 'Labi password', 'fr': 'Changer le mot de passe',
    },
    'old_password': {
      'en': 'Old Password', 'tw': 'Nsɛmfua tete', 'dg': 'Password kpahili', 'ee': 'Ŋkugbalẽ xoxo', 'ha': 'Tsohuwar kalmar wucewa', 'mp': 'Password kpahili', 'fr': 'Ancien mot de passe',
    },
    'new_password': {
      'en': 'New Password', 'tw': 'Nsɛmfua foforɔ', 'dg': 'Password palli', 'ee': 'Ŋkugbalẽ yeye', 'ha': 'Sabuwar kalmar wucewa', 'mp': 'Password palli', 'fr': 'Nouveau mot de passe',
    },
    'save': {
      'en': 'Save', 'tw': 'Kora', 'dg': 'Daliri', 'ee': 'Dzra', 'ha': 'Ajiye', 'mp': 'Daliri', 'fr': 'Enregistrer',
    },
    'reset_password': {
      'en': 'Reset Password', 'tw': 'Sesa nsɛmfua', 'dg': 'Labi password', 'ee': 'Trɔ ŋkugbalẽ', 'ha': 'Sake kalmar wucewa', 'mp': 'Labi password', 'fr': 'Réinitialiser le mot de passe',
    },
    'confirm_password': {
      'en': 'Confirm Password', 'tw': 'Si nsɛmfua so dua', 'dg': 'Sɔŋ password', 'ee': 'Ɖo kpe ŋkugbalẽ dzi', 'ha': 'Tabbatar da kalmar wucewa', 'mp': 'Sɔŋ password', 'fr': 'Confirmer le mot de passe',
    },
    'verification_code': {
      'en': 'Verification Code', 'tw': 'Nhwehwɛmu nsɛnkyerɛnne', 'dg': 'Verification code', 'ee': 'Kpɔɖeŋu nudzeƒe', 'ha': 'Lambar tabbatarwa', 'mp': 'Verification code', 'fr': 'Code de vérification',
    },
    'check_email_intro': {
      'en': 'We sent a 6-digit code to:', 'tw': 'Yɛasoma nsɛnkyerɛnne 6 akɔ:', 'dg': 'Ti tum 6-digit code n-ti:', 'ee': 'Míeɖo nudzeƒe 6 ɖe:', 'ha': 'Mun aiko da lamba mai lamba 6 zuwa:', 'mp': 'Ti tum 6-digit code n-ti:', 'fr': 'Nous avons envoyé un code à 6 chiffres à :',
    },
    'reset_code_invalid_length': {
      'en': 'Please enter the 6-digit code from your email.', 'tw': 'Mesrɛ wo, twerɛ nsɛnkyerɛnne 6 a ɛwɔ wo email mu.', 'dg': 'Sabbi 6-digit code din be a email puuni.', 'ee': 'Taflatse, ŋlɔ nudzeƒe 6 si le wò email me.', 'ha': 'Da fatan za a shigar da lambobi 6 daga emailka.', 'mp': 'Sabbi 6-digit code din be a email puuni.', 'fr': "Veuillez entrer le code à 6 chiffres reçu par e-mail.",
    },
    'password_too_short': {
      'en': 'Password must be at least 6 characters.', 'tw': 'Nsɛmfua ɛsɛ sɛ ɛyɛ akoraa nsɛnkyerɛnne 6.', 'dg': 'Password yɛn niŋ 6 characters yaɣinli.', 'ee': 'Ŋkugbalẽ ƒe nudzeƒe nele 6.', 'ha': 'Kalmar wucewa dole ta zama akalla haruffa 6.', 'mp': 'Password yɛn niŋ 6 characters yaɣinli.', 'fr': 'Le mot de passe doit comporter au moins 6 caractères.',
    },
    'passwords_do_not_match': {
      'en': 'Passwords do not match.', 'tw': 'Nsɛmfua no nyɛ pɛ.', 'dg': 'Passwords bi nyɛ.', 'ee': 'Ŋkugbalẽawo mesɔ o.', 'ha': 'Kalmomin wucewa basu zo daya ba.', 'mp': 'Passwords bi nyɛ.', 'fr': 'Les mots de passe ne correspondent pas.',
    },
    'reset_success_title': {
      'en': 'Password Updated', 'tw': 'Nsɛmfua asakyera', 'dg': 'Password labi', 'ee': 'Ŋkugbalẽ trɔ', 'ha': 'An sabunta kalmar wucewa', 'mp': 'Password labi', 'fr': 'Mot de passe mis à jour',
    },
    'reset_success_message': {
      'en': 'You can now log in with your new password.', 'tw': 'Afei wubetumi de nsɛmfua foforɔ no abɔ wo din.', 'dg': 'A ni tooi login ni a password palli.', 'ee': 'Azɔ àte ŋu age ɖe eme kple wò ŋkugbalẽ yeye.', 'ha': 'Yanzu zaka iya shiga da sabuwar kalmar wucewa.', 'mp': 'A ni tooi login ni a password palli.', 'fr': 'Vous pouvez maintenant vous connecter avec votre nouveau mot de passe.',
    },
    'reset_failed': {
      'en': 'Could not reset password. Please try again.', 'tw': 'Yentumi nsesa nsɛmfua no. Mesrɛ wo, sɔ hwɛ bio.', 'dg': 'Bi tooi labi password. Sabbi yele.', 'ee': 'Míete ŋu trɔ ŋkugbalẽ o. Taflatse, te kpɔ ake.', 'ha': 'Ba a iya sake saita kalmar wucewa ba. Da fatan a sake gwadawa.', 'mp': 'Bi tooi labi password. Sabbi yele.', 'fr': 'Impossible de réinitialiser le mot de passe. Veuillez réessayer.',
    },
    'resend_code': {
      'en': 'Resend Code', 'tw': 'San soma nsɛnkyerɛnne no', 'dg': 'Sani tum code', 'ee': 'Gaɖo nudzeƒe', 'ha': 'Sake aikawa da lamba', 'mp': 'Sani tum code', 'fr': 'Renvoyer le code',
    },
    'code_resent_title': {
      'en': 'Code Sent', 'tw': 'Nsɛnkyerɛnne asoma', 'dg': 'Code tum', 'ee': 'Nudzeƒe ɖo', 'ha': 'An aiko da lamba', 'mp': 'Code tum', 'fr': 'Code envoyé',
    },
    'code_resent_message': {
      'en': 'A new code has been sent to your email.', 'tw': 'Yɛasoma nsɛnkyerɛnne foforɔ akɔ wo email mu.', 'dg': 'Ti tum code palli n-ti email puuni.', 'ee': 'Míeɖo nudzeƒe yeye ɖe wò email me.', 'ha': 'An aiko da sabuwar lamba zuwa emailka.', 'mp': 'Ti tum code palli n-ti email puuni.', 'fr': 'Un nouveau code a été envoyé à votre e-mail.',
    },
    'error': {
      'en': 'Error', 'tw': 'Mfomso', 'dg': 'Yelimsim', 'ee': 'Vodada', 'ha': 'Kuskure', 'mp': 'Yelimsim', 'fr': 'Erreur',
    },
    'not_an_onion_title': {
      'en': 'Not an Onion', 'tw': 'Ɛnyɛ gyeene', 'dg': 'Pa onion', 'ee': 'Menye sabala o', 'ha': 'Ba albasa ba ne', 'mp': 'Pa onion', 'fr': "Pas un oignon",
    },
    'not_an_onion_message': {
      'en': 'This looks like a {object}, not an onion. Please capture a clear photo of an onion to continue.',
      'tw': 'Yei te sɛ {object}, ɛnyɛ gyeene. Mesrɛ wo, fa gyeene foto pa kyerɛ na kɔ so.',
      'dg': 'Ŋo ŋmana {object}, pa onion. Sabbi onion picture suŋ ka kpɛ.',
      'ee': 'Esia ɖi {object}, menye sabala o. Taflatse, tsɔ sabala ƒe foto nyuie ne nàyi edzi.',
      'ha': 'Wannan kamar {object} ne, ba albasa ba ne. Da fatan a dauki hoton albasa a fili don ci gaba.',
      'mp': 'Ŋo ŋmana {object}, pa onion. Sabbi onion picture suŋ ka kpɛ.',
      'fr': "Cela ressemble à {object}, pas à un oignon. Veuillez prendre une photo claire d'un oignon pour continuer.",
    },
    'unknown_object': {
      'en': 'unknown object', 'tw': 'ade a yɛnnim', 'dg': 'binɛri shɛli', 'ee': 'nu si womenya o', 'ha': 'abun da ba a sani ba', 'mp': 'binɛri shɛli', 'fr': 'objet inconnu',
    },
    'retake_image_title': {
      'en': 'Please Retake Photo', 'tw': 'Mesrɛ wo, fa foto no bio', 'dg': 'Sabbi foto maa lala', 'ee': 'Taflatse, ɖe foto la ake', 'ha': 'Da fatan a sake daukar hoto', 'mp': 'Sabbi foto maa lala', 'fr': 'Veuillez reprendre la photo',
    },
    'retake_image_message': {
      'en': "We couldn't analyze your photo clearly. Please retake the photo of the onion in good lighting and try again.",
      'tw': 'Yentumi nhwehwɛ wo foto no yiye. Mesrɛ wo, fa gyeene no foto bio wɔ kanea pa mu na sɔ hwɛ bio.',
      'dg': 'Ti bi tooi yɛli a foto maa nyaŋŋ. Sabbi onion foto lala suŋ sahaŋ ka kpɛ.',
      'ee': "Míete ŋu kpɔ wò foto la nyuie o. Taflatse, ɖe sabala la ƒe foto ake le kekeli nyuie me ne nàte kpɔ ake.",
      'ha': "Ba mu iya bincika hoton ka da kyau ba. Da fatan a sake daukar hoton albasa cikin haske mai kyau a sake gwadawa.",
      'mp': 'Ti bi tooi yɛli a foto maa nyaŋŋ. Sabbi onion foto lala suŋ sahaŋ ka kpɛ.',
      'fr': "Nous n'avons pas pu analyser votre photo clairement. Veuillez reprendre la photo de l'oignon avec un bon éclairage et réessayer.",
    },
    'not_onion_retake_message': {
      'en': 'We detected: {object}\n\nThis is not an onion. Please retake the photo with a clear view of an onion bulb or onion plant.',
      'tw': 'Yɛhunuiɛ: {object}\n\nƐnyɛ gyeene. Mesrɛ wo, fa gyeene afuw anaa gyeene dua foto bio.',
      'dg': 'Ti nya: {object}\n\nPa onion. Sabbi onion bulb bee onion bihi foto lala suŋ.',
      'ee': "Míekpɔ: {object}\n\nMenye sabala o. Taflatse, ɖe sabala ŋutsui alo sabala ti la ƒe foto nyuie ake.",
      'ha': "Mun gano: {object}\n\nBa albasa ba ne. Da fatan a sake daukar hoton albasa ko shukar albasa cikin haske.",
      'mp': 'Ti nya: {object}\n\nPa onion. Sabbi onion bulb bee onion bihi foto lala suŋ.',
      'fr': "Nous avons détecté : {object}\n\nCe n'est pas un oignon. Veuillez reprendre la photo avec une vue claire d'un bulbe ou d'une plante d'oignon.",
    },
    'my_profile': {
      'en': 'My Profile', 'tw': "Mʼahofadeɛ", 'dg': 'N profile', 'ee': 'Nye ŋutɔ ŋu nyatakaka', 'ha': 'Bayanaina', 'mp': 'N profile', 'fr': 'Mon profil',
    },
    'talk_to_us': {
      'en': 'Talk To Us', 'tw': 'Ka kyerɛ yɛn', 'dg': 'Yɛli ti sani', 'ee': 'Ƒo nu na mí', 'ha': 'Yi mana mu', 'mp': 'Yɛli ti sani', 'fr': 'Nous contacter',
    },
    'talk_to_us_intro_title': {
      'en': "We'd love to hear from you", 'tw': 'Yɛpɛ sɛ yɛte wo nka', 'dg': 'Ti yu yɛla a yɛli zaa', 'ee': 'Míadi be míase tso gbɔwò', 'ha': 'Muna son mu ji ka', 'mp': 'Ti yu yɛla a yɛli zaa', 'fr': 'Nous aimerions vous lire',
    },
    'talk_to_us_intro_body': {
      'en': 'Tell us about a bug, suggest a feature, or share what you think about OniQ.',
      'hi': 'बग की रिपोर्ट करें, सुविधा का सुझाव दें, या OniQ के बारे में अपनी राय साझा करें।',
      'mr': 'समस्या नोंदवा, नवीन वैशिष्ट्य सुचवा किंवा OniQ बद्दल आपले मत सांगा.',
    },
    'feedback_from': {
      'en': 'From', 'tw': 'Ɛfiri', 'dg': 'Yiŋga', 'ee': 'Tso', 'ha': 'Daga', 'mp': 'Yiŋga', 'fr': 'De',
    },
    'feedback_subject_label': {
      'en': 'Subject (optional)', 'tw': 'Asɛm tirinsɛm (sɛ ɛho hia)', 'dg': 'Yɛli zuɣu (lan be tu yi)', 'ee': 'Tanya (ne èdi)', 'ha': 'Take (idan ana so)', 'mp': 'Yɛli zuɣu (lan be tu yi)', 'fr': 'Sujet (facultatif)',
    },
    'feedback_subject_hint': {
      'en': 'App Crashes', 'tw': 'App Crashes', 'dg': 'App Crashes', 'ee': 'App Crashes', 'ha': 'App Crashes', 'mp': 'App Crashes', 'fr': 'App Crashes',
    },
    'feedback_message_label': {
      'en': 'Your message', 'tw': 'Wo nkrataa', 'dg': 'A yɛla', 'ee': 'Wò nya', 'ha': 'Sakonka', 'mp': 'A yɛla', 'fr': 'Votre message',
    },
    'feedback_message_hint': {
      'en': 'Describe the issue, idea, or suggestion in detail',
      'tw': 'Kyerɛkyerɛ asɛmnsɛm, adwene anaa nyansapɔ no mu kɔ akyiri',
      'dg': 'Yɛli yɛla maa, sabbi adwene bee suggestion zaŋ ka',
      'ee': 'Ƒo nu tso nukpe la, susu, alo nudodoɖa ŋu blibo',
      'ha': 'Bayyana matsalar, ra\'ayi, ko shawara dalla-dalla',
      'mp': 'Yɛli yɛla maa, sabbi adwene bee suggestion zaŋ ka',
      'fr': "Décrivez le problème, l'idée ou la suggestion en détail",
    },
    'feedback_message_required': {
      'en': 'Please write a message before sending.',
      'tw': 'Mesrɛ wo, twerɛ nkrataa kyerɛ ansa na woasoma.',
      'dg': 'Sabbi yɛli yele zaŋ ka tum.',
      'ee': 'Taflatse, ŋlɔ nya hafi nàɖoe ɖa.',
      'ha': 'Da fatan rubuta sako kafin a aika.',
      'mp': 'Sabbi yɛli yele zaŋ ka tum.',
      'fr': "Veuillez écrire un message avant l'envoi.",
    },
    'feedback_sent_title': {
      'en': 'Thanks for the feedback', 'tw': 'Yɛda wo ase', 'dg': 'Ti puhigu', 'ee': 'Akpe na wò', 'ha': 'Na gode', 'mp': 'Ti puhigu', 'fr': 'Merci pour vos retours',
    },
    'feedback_sent_message': {
      'en': "We received your message. We'll read it and reply by email if needed.",
      'tw': 'Yɛagye wo nkrataa no. Yɛbɛkenkan na yɛama ho mmuae denam email so sɛ ɛho hia.',
      'dg': 'Ti deei a yɛla maa. Ti ni karim ka ti zali email puuni di yɛni a tu yi.',
      'ee': 'Míexɔ wò nya la. Míaxlẽe eye míaɖo eŋu na wò to email dzi ne ehiã.',
      'ha': 'Mun karbi sakonka. Za mu karanta mu kuma amsa ta email idan an bukata.',
      'mp': 'Ti deei a yɛla maa. Ti ni karim ka ti zali email puuni di yɛni a tu yi.',
      'fr': "Nous avons reçu votre message. Nous le lirons et répondrons par e-mail si nécessaire.",
    },
    'feedback_send_failed': {
      'en': 'Could not send your feedback. Please try again later.',
      'tw': 'Yentumi mfa wo nkrataa no nkɔ. Mesrɛ wo, sɔ hwɛ bio akyire yi.',
      'dg': 'Bi tooi tum a yɛla maa. Sabbi yele yim.',
      'ee': 'Míete ŋu ɖo wò nya la ɖa o. Taflatse, te kpɔ ake emegbe.',
      'ha': 'Ba a iya aika sakonka ba. Da fatan a sake gwadawa daga baya.',
      'mp': 'Bi tooi tum a yɛla maa. Sabbi yele yim.',
      'fr': "Impossible d'envoyer vos retours. Veuillez réessayer plus tard.",
    },
    'sending': {
      'en': 'Sending...', 'tw': 'Ɛresoma...', 'dg': 'Tundi...', 'ee': 'Le ɖoɖom...', 'ha': 'Ana aika...', 'mp': 'Tundi...', 'fr': 'Envoi...',
    },

    // Admin analytics dashboard
    'platform_analytics': {
      'en': 'Platform Analytics', 'tw': 'Pɛtfɔm Nsɛm Ahorow', 'dg': 'Platform Yɛltɔɣa', 'ee': 'Platform ƒe Numeɖeɖe', 'ha': 'Bayanan Dandalin', 'mp': 'Platform Yɛltɔɣa', 'fr': 'Statistiques de la plateforme',
    },
    'users': {
      'en': 'Users', 'tw': 'Adwumayɛfoɔ', 'dg': 'Niriba', 'ee': 'Zãlawo', 'ha': 'Masu amfani', 'mp': 'Niriba', 'fr': 'Utilisateurs',
    },
    'scans': {
      'en': 'Scans', 'tw': 'Nhwehwɛmu', 'dg': 'Daliri', 'ee': 'Numeɖeɖewo', 'ha': 'Bincike', 'mp': 'Daliri', 'fr': 'Analyses',
    },
    'healthy': {
      'en': 'Healthy', 'tw': 'Apɔmuden', 'dg': 'Alaafee', 'ee': 'Lãme nyo', 'ha': 'Lafiya', 'mp': 'Alaafee', 'fr': 'Sain',
    },
    'diseased': {
      'en': 'Diseased', 'tw': 'Ɔyareni', 'dg': 'Doroyaa', 'ee': 'Dɔlele le edzi', 'ha': 'Cuta', 'mp': 'Doroyaa', 'fr': 'Malade',
    },
    'no_analytics_data': {
      'en': 'No analytics data yet', 'tw': 'Nsɛm ahorow biara nni hɔ ɛnnɛ', 'dg': 'Yɛltɔɣa zaa ka di kuli', 'ee': 'Numeɖeɖe aɖeke meli haɖe o', 'ha': 'Babu bayanai tukuna', 'mp': 'Yɛltɔɣa zaa ka di kuli', 'fr': "Pas encore de données d'analyse",
    },

    // User analytics page
    'your_farm_analytics': {
      'en': 'Your Farm Analytics', 'tw': 'Wo Afuo Nsɛm Ahorow', 'dg': 'A puuni Yɛltɔɣa', 'ee': 'Wò Agble ƒe Numeɖeɖe', 'ha': 'Bayanan Gonarka', 'mp': 'A puuni Yɛltɔɣa', 'fr': 'Statistiques de votre ferme',
    },
    'farm_analytics_subtitle': {
      'en': 'Insights from your scan history', 'tw': 'Nsɛm a efi wo nhwehwɛmu abakɔsɛm mu', 'dg': 'Yɛltɔɣa din yi a daliri tarihi puuni', 'ee': 'Nyatakaka tso wò numeɖeɖe ŋutinya me', 'ha': 'Bayanai daga tarihin bincikenka', 'mp': 'Yɛltɔɣa din yi a daliri tarihi puuni', 'fr': "Aperçus tirés de votre historique d'analyses",
    },
    'total_scans': {
      'en': 'Total Scans', 'tw': 'Nhwehwɛmu Nyinaa', 'dg': 'Daliri Zaa', 'ee': 'Numeɖeɖe Katã', 'ha': 'Jimillar Bincike', 'mp': 'Daliri Zaa', 'fr': 'Total des analyses',
    },
    'start_scanning_hint': {
      'en': 'Start scanning onions to build your\npersonal disease tracking history', 'tw': 'Hyɛ aseɛ hwehwɛ gyeene na woahyehyɛ\nwʼankasa nyarewa abakɔsɛm', 'dg': 'Pili daliri alubosa ka di mali a\nmaŋmaŋ doroyaa tarihi', 'ee': 'Dze numeɖeɖe sabala dzi nàtu wò\nŋutɔ wò dɔlele ŋutinya', 'ha': 'Fara binciken albasa don gina\ntarihin cututtukan ka na kashin kanka', 'mp': 'Pili daliri alubosa ka di mali a\nmaŋmaŋ doroyaa tarihi', 'fr': "Commencez à scanner des oignons pour bâtir\nvotre historique personnel de maladies",
    },
    'scans_over_time': {
      'en': 'Scans Over Time', 'tw': 'Nhwehwɛmu wɔ ɛberɛ mu', 'dg': 'Daliri sahakam puuni', 'ee': 'Numeɖeɖe le Ɣeyiɣiwo me', 'ha': 'Bincike na lokaci', 'mp': 'Daliri sahakam puuni', 'fr': 'Analyses au fil du temps',
    },
    'scans_over_time_subtitle': {
      'en': 'Last {days} days · green = healthy · orange = diseased', 'tw': 'Nnafua {days} a atwam · ahaban = apɔmuden · ankaa = ɔyareni', 'dg': 'Dabsa {days} din gariga · zoo = alaafee · ankaa = doroyaa', 'ee': 'Ŋkeke {days} si va yi · gbe damanyo = lãme nyo · ankaa = dɔlele le edzi', 'ha': 'Kwana {days} da suka wuce · kore = lafiya · ruwan goro = cuta', 'mp': 'Dabsa {days} din gariga · zoo = alaafee · ankaa = doroyaa', 'fr': 'Derniers {days} jours · vert = sain · orange = malade',
    },
    'chart_tooltip_breakdown': {
      'en': '{healthy} healthy · {diseased} diseased', 'tw': '{healthy} apɔmuden · {diseased} ɔyareni', 'dg': '{healthy} alaafee · {diseased} doroyaa', 'ee': '{healthy} lãme nyo · {diseased} dɔlele le edzi', 'ha': '{healthy} lafiya · {diseased} cuta', 'mp': '{healthy} alaafee · {diseased} doroyaa', 'fr': '{healthy} sain · {diseased} malade',
    },
    'disease_distribution': {
      'en': 'Disease Distribution', 'tw': 'Nyarewa Nkyekyɛmu', 'dg': 'Doroyaa Tariga', 'ee': 'Dɔlele ƒe Mama', 'ha': 'Rabon Cututtuka', 'mp': 'Doroyaa Tariga', 'fr': 'Répartition des maladies',
    },
    'disease_distribution_subtitle': {
      'en': 'Breakdown of all your scans by class', 'tw': 'Wo nhwehwɛmu nyinaa nkyekyɛmu sɛnea wɔahyehyɛ', 'dg': 'A daliri zaa tariga ka di nuli', 'ee': 'Wò numeɖeɖewo katã ƒe mama nu', 'ha': 'Cikakken bayanin duk binciken ka', 'mp': 'A daliri zaa tariga ka di nuli', 'fr': 'Répartition de vos analyses par classe',
    },
    'no_data': {
      'en': 'No data', 'tw': 'Nsɛm biara nni hɔ', 'dg': 'Yɛltɔɣa kani', 'ee': 'Numeɖeɖe aɖeke meli o', 'ha': 'Babu bayanai', 'mp': 'Yɛltɔɣa kani', 'fr': 'Aucune donnée',
    },
    'weekly_pattern': {
      'en': 'Weekly Pattern', 'tw': 'Nnawɔtwe Nhyehyɛeɛ', 'dg': 'Bakari Soli', 'ee': 'Kɔsiɖa Ɖoɖo', 'ha': 'Tsarin Mako', 'mp': 'Bakari Soli', 'fr': 'Tendance hebdomadaire',
    },
    'you_scan_most_on': {
      'en': 'You scan most on {day}', 'tw': 'Wohwehwɛ kɛse wɔ {day}', 'dg': 'A daliri pam {day} dali', 'ee': 'Èwɔa numeɖeɖe geɖe le {day} dzi', 'ha': 'Kana yawan bincike a ranar {day}', 'mp': 'A daliri pam {day} dali', 'fr': 'Vous analysez le plus le {day}',
    },
    'activity_by_day_of_week': {
      'en': 'Activity by day of week', 'tw': 'Dwumadie sɛnea da biara teɛ', 'dg': 'Tuma sɛnea bakari dali biara', 'ee': 'Dɔwɔwɔ le kɔsiɖagbe ɖe sia ɖe', 'ha': 'Ayyuka bisa kowace rana', 'mp': 'Tuma sɛnea bakari dali biara', 'fr': 'Activité par jour de la semaine',
    },
    'recent_scans': {
      'en': 'Recent Scans', 'tw': 'Nhwehwɛmu a ɛbaa nnansa yi', 'dg': 'Daliri din kuli', 'ee': 'Numeɖeɖe yeyetɔwo', 'ha': 'Bincike na kwanan baya', 'mp': 'Daliri din kuli', 'fr': 'Analyses récentes',
    },
    'recent_scans_subtitle_one': {
      'en': 'Your last {count} scan', 'tw': 'Wo nhwehwɛmu {count} a etwa toɔ', 'dg': 'A daliri {count} din yo bahi', 'ee': 'Wò numeɖeɖe mamlɛtɔ {count}', 'ha': 'Binciken ka na karshe {count}', 'mp': 'A daliri {count} din yo bahi', 'fr': 'Votre dernière {count} analyse',
    },
    'recent_scans_subtitle_many': {
      'en': 'Your last {count} scans', 'tw': 'Wo nhwehwɛmu {count} a ɛtwa toɔ', 'dg': 'A daliri {count} din yo bahi', 'ee': 'Wò numeɖeɖe {count} mamlɛtɔwo', 'ha': "Binciken ka na karshe {count}", 'mp': 'A daliri {count} din yo bahi', 'fr': 'Vos {count} dernières analyses',
    },
    'no_recent_activity': {
      'en': 'No recent activity', 'tw': 'Dwumadie biara nni hɔ nnansa yi', 'dg': 'Tuma kani din kuli', 'ee': 'Dɔwɔwɔ yeyetɔ aɖeke meli o', 'ha': 'Babu ayyukan kwanan baya', 'mp': 'Tuma kani din kuli', 'fr': 'Aucune activité récente',
    },
    'just_now': {
      'en': 'Just now', 'tw': 'Seesei ara', 'dg': 'Pumpɔŋɔ', 'ee': 'Fifia ko', 'ha': 'Yanzu yanzu', 'mp': 'Pumpɔŋɔ', 'fr': "À l'instant",
    },
    'minutes_ago': {
      'en': '{n}m ago', 'tw': 'Sima {n} a atwam', 'dg': 'Manti {n} din gariga', 'ee': 'Aɖabaƒoƒo {n} si va yi', 'ha': 'Mintuna {n} da suka wuce', 'mp': 'Manti {n} din gariga', 'fr': 'Il y a {n} min',
    },
    'hours_ago': {
      'en': '{n}h ago', 'tw': 'Nnɔnhwere {n} a atwam', 'dg': 'Awa {n} din gariga', 'ee': 'Gaƒoƒo {n} si va yi', 'ha': 'Awanni {n} da suka wuce', 'mp': 'Awa {n} din gariga', 'fr': 'Il y a {n} h',
    },
    'days_ago': {
      'en': '{n}d ago', 'tw': 'Nnafua {n} a atwam', 'dg': 'Dabsa {n} din gariga', 'ee': 'Ŋkeke {n} si va yi', 'ha': 'Kwana {n} da suka wuce', 'mp': 'Dabsa {n} din gariga', 'fr': 'Il y a {n} j',
    },
    'confidence_dot': {
      'en': '{pct}% confidence', 'tw': 'Gyidie {pct}%', 'dg': 'Naani {pct}%', 'ee': 'Kakaɖedzi {pct}%', 'ha': 'Tabbas {pct}%', 'mp': 'Naani {pct}%', 'fr': 'Confiance {pct}%',
    },
    'weekday_mon_short': {'en': 'Mon', 'tw': 'Dwo', 'dg': 'Atani', 'ee': 'Dzo', 'ha': 'Lit', 'mp': 'Atani', 'fr': 'Lun'},
    'weekday_tue_short': {'en': 'Tue', 'tw': 'Ben', 'dg': 'Atalata', 'ee': 'Bla', 'ha': 'Tal', 'mp': 'Atalata', 'fr': 'Mar'},
    'weekday_wed_short': {'en': 'Wed', 'tw': 'Wuk', 'dg': 'Alaba', 'ee': 'Kuɖa', 'ha': 'Lar', 'mp': 'Alaba', 'fr': 'Mer'},
    'weekday_thu_short': {'en': 'Thu', 'tw': 'Yaw', 'dg': 'Alaamishi', 'ee': 'Yaw', 'ha': 'Alh', 'mp': 'Alaamishi', 'fr': 'Jeu'},
    'weekday_fri_short': {'en': 'Fri', 'tw': 'Fia', 'dg': 'Alizumma', 'ee': 'Fiɖa', 'ha': 'Jum', 'mp': 'Alizumma', 'fr': 'Ven'},
    'weekday_sat_short': {'en': 'Sat', 'tw': 'Mem', 'dg': 'Asibili', 'ee': 'Mem', 'ha': 'Asa', 'mp': 'Asibili', 'fr': 'Sam'},
    'weekday_sun_short': {'en': 'Sun', 'tw': 'Kwa', 'dg': 'Alahari', 'ee': 'Kɔs', 'ha': 'Lah', 'mp': 'Alahari', 'fr': 'Dim'},
  };

  static const Map<String, String> languages = {
    'en': 'English',
    'hi': 'हिंदी (Hindi)',
    'mr': 'मराठी (Marathi)',
    'gu': 'ગુજરાતી (Gujarati)',
    'kn': 'ಕನ್ನಡ (Kannada)',
    'te': 'తెలుగు (Telugu)',
    'ta': 'தமிழ் (Tamil)',
  };
}
