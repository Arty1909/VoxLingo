import 'dart:async';

import 'package:flutter/material.dart';

@immutable
class AppLanguage {
  const AppLanguage({
    required this.name,
    required this.code,
    required this.translationCode,
    this.sttCode,
    this.ttsCode,
    this.rtl = false,
  });

  final String name;
  final String code;
  final String translationCode;
  final String? sttCode;
  final String? ttsCode;
  final bool rtl;

  bool get supportsStt => sttCode != null;
  bool get supportsTranslation => translationCode.isNotEmpty;
  bool get supportsTts => ttsCode != null;
}

const Map<String, String> appStrings = {
  'appName': 'VoxLingo',
  'tagline': 'Speak naturally. Understand anyone.',
  'source': 'I speak',
  'target': 'Translate to',
  'swap': 'Swap languages',
  'tapToSpeak': 'Tap to speak',
  'listening': 'Listening… tap to finish',
  'processing': 'Understanding your voice…',
  'ready': 'Ready to listen',
  'transcription': 'Transcription',
  'translation': 'Translation',
  'sourceHint': 'Speak or type something here',
  'translationHint': 'Your translation will appear here',
  'translate': 'Translate text',
  'speak': 'Play translation · AI voice',
  'stopAudio': 'Stop audio',
  'clear': 'Clear',
  'copy': 'Copy',
  'copied': 'Copied to clipboard',
  'history': 'Recent translations',
  'emptyHistory': 'Your translations will appear here',
  'clearHistory': 'Clear history',
  'delete': 'Delete',
  'settingsNeeded': 'Backend setup required',
  'backendHelp':
      'Build with --dart-define=BACKEND_BASE_URL=https://your-server/backend/',
  'prototypeMode': 'Prototype / Mock mode',
  'processingAudio': 'Preparing audio…',
  'permissionDenied': 'Microphone permission was denied.',
  'microphoneUnavailable': 'No microphone is available on this device.',
  'recordingError': 'Could not start recording. Check the microphone.',
  'emptySpeech': 'No speech was detected. Try again closer to the microphone.',
  'emptyText': 'Enter or record some text first.',
  'networkError': 'Could not reach the translation service.',
  'serviceError': 'The configured service could not complete this request.',
  'languageUnavailable':
      'This function is not available for the selected language.',
  'historyError': 'History is temporarily unavailable.',
  'audioError': 'The translated audio could not be played.',
  'steps': 'Voice translation',
  'stepListen': 'Listen',
  'stepTranslate': 'Translate',
  'stepSpeak': 'Speak',
  'searchLanguage': 'Search languages',
  'authorMark': 'Author mark',
  'authorSignature': 'This app was created by Arty 💜',
  'close': 'Close',
  'microphoneUnsupported':
      'Speech recognition is unavailable for this language. You can still type text.',
};

const Map<String, String> appDefaults = {
  'sourceLanguageCode': 'en',
  'targetLanguageCode': 'ru',
  'databaseName': 'voxlingo_history',
  'driftWasm': 'sqlite3.wasm',
  'driftWorker': 'drift_worker.js',
};

const Map<String, int> appConfig = {
  'sampleRate': 16000,
  'audioChannels': 1,
  'historyLimit': 100,
  'ttsChunkBytes': 1800,
  'authorTapsToReveal': 19,
};

const Map<String, String> appEnvironment = {
  'backendBaseUrl': String.fromEnvironment('BACKEND_BASE_URL'),
};

// Browser deployments use the API beside index.html even without dart-defines.
// Native applications still receive their public URL via --dart-define.
String resolveBackendBaseUrl({
  required bool isWeb,
  required Uri pageUri,
  String? configuredUrl,
}) {
  final configured = (configuredUrl ?? appEnvironment['backendBaseUrl']!)
      .trim();
  if (configured.isNotEmpty) return configured;
  if (isWeb && (pageUri.scheme == 'https' || pageUri.scheme == 'http')) {
    return pageUri.resolve('backend/').toString();
  }
  return '';
}

const Map<String, String> appApiConfig = {
  'sttRoute': 'services/stt/transcribe',
  'translationRoute': 'translation',
  'ttsRoute': 'services/tts/synthesize',
  'audioFormat': 'pcm16',
  'ttsAudioFormat': 'mp3',
  'contentType': 'application/json; charset=utf-8',
};

const Map<String, bool> appMockFlags = {
  'stt': bool.fromEnvironment('STT_MOCK_MODE', defaultValue: false),
  'translation': bool.fromEnvironment(
    'TRANSLATION_MOCK_MODE',
    defaultValue: false,
  ),
  'tts': bool.fromEnvironment('TTS_MOCK_MODE', defaultValue: false),
};

const Map<String, String> appMockConfig = {
  'errorStage': String.fromEnvironment(
    'MOCK_ERROR_STAGE',
    defaultValue: 'none',
  ),
  'timeoutStage': String.fromEnvironment(
    'MOCK_TIMEOUT_STAGE',
    defaultValue: 'none',
  ),
};

const Map<String, String> appMockStages = {
  'none': 'none',
  'stt': 'stt',
  'translation': 'translation',
  'tts': 'tts',
};

const Map<String, Duration> appMockDurations = {
  'stt': Duration(milliseconds: 450),
  'translation': Duration(milliseconds: 400),
  'tts': Duration(milliseconds: 350),
  'ttsPlayback': Duration(milliseconds: 1200),
  'timeout': Duration(milliseconds: 700),
};

const Map<String, String> appMockTranscriptions = {
  'en': '[Prototype transcription] This is a test voice recording.',
  'ru': '[Прототип распознавания] Это тестовая голосовая запись.',
  'es': '[Transcripción de prototipo] Esta es una grabación de voz de prueba.',
};

const Map<String, String> appMockTranslations = {
  'en:ru': '[Прототип перевода] Это тестовая голосовая запись.',
  'ru:en': '[Prototype translation] This is a test voice recording.',
  'en:es': '[Traducción de prototipo] Esta es una grabación de voz de prueba.',
  'es:en': '[Prototype translation] This is a test voice recording.',
};

const Map<String, String> appMockTemplates = {
  'transcription':
      '[Prototype transcription — {language}] Test audio captured ({bytes} PCM bytes).',
  'translation': '[Mock {source} → {target}] {text}',
};

const Map<String, String> appMockErrorMessages = {
  'stt': '[Mock] Simulated STT error.',
  'translation': '[Mock] Simulated Translation error.',
  'tts': '[Mock] Simulated TTS error.',
};

const Map<String, String> appPlatformConfig = {
  'permissionChannel': 'voxlingo/permissions',
  'requestMicrophonePermission': 'requestMicrophonePermission',
};

const List<String> appAudioUnavailableTokens = [
  'no device',
  'no input',
  'not found',
  'notfound',
  'unavailable',
  'device unavailable',
  'device lost',
];

const Map<String, Color> appColors = {
  'background': Color(0xFFF5F7FB),
  'surface': Color(0xFFFFFFFF),
  'onPrimary': Color(0xFFFFFFFF),
  'surfaceMuted': Color(0xFFF0F3F8),
  'primary': Color(0xFF5B5FEF),
  'primarySoft': Color(0xFFE9EAFE),
  'text': Color(0xFF172033),
  'textMuted': Color(0xFF6F7787),
  'border': Color(0xFFE1E5EC),
  'danger': Color(0xFFD94A58),
  'dangerSoft': Color(0xFFFFE9EC),
  'shadow': Color(0x140F172A),
  'authorMark': Color(0xFFAB84CE),
};

const Map<String, double> appSizes = {
  'pagePadding': 24,
  'mobilePadding': 16,
  'sectionGap': 20,
  'itemGap': 12,
  'smallGap': 8,
  'tinyGap': 4,
  'radiusLarge': 28,
  'radiusMedium': 18,
  'radiusSmall': 12,
  'contentMax': 1040,
  'desktopBreakpoint': 780,
  'languageHeight': 64,
  'micSize': 92,
  'iconButton': 44,
  'resultMinHeight': 150,
  'authorIcon': 22,
  'authorDialogIcon': 48,
};

const Map<String, Duration> appDurations = {
  'normal': Duration(milliseconds: 280),
  'snack': Duration(seconds: 2),
  'recordingLimit': Duration(seconds: 55),
  'requestTimeout': Duration(seconds: 45),
  'timerTick': Duration(seconds: 1),
  'authorTapReset': Duration(seconds: 3),
};

const Map<String, IconData> appIcons = {
  'microphone': Icons.mic_rounded,
  'stop': Icons.stop_rounded,
  'translate': Icons.translate_rounded,
  'speak': Icons.volume_up_rounded,
  'stopAudio': Icons.stop_circle_outlined,
  'swap': Icons.swap_horiz_rounded,
  'clear': Icons.close_rounded,
  'copy': Icons.copy_rounded,
  'history': Icons.history_rounded,
  'delete': Icons.delete_outline_rounded,
  'check': Icons.check_rounded,
  'error': Icons.error_outline_rounded,
  'keyboard': Icons.keyboard_alt_outlined,
  'arrow': Icons.keyboard_arrow_down_rounded,
  'cloud': Icons.cloud_outlined,
  'search': Icons.search_rounded,
  'authorMark': Icons.local_florist_rounded,
};

final Map<String, TextStyle> appTextStyles = {
  'display': TextStyle(
    color: appColors['text'],
    fontSize: 34,
    fontWeight: FontWeight.w800,
    letterSpacing: -1.2,
  ),
  'section': TextStyle(
    color: appColors['text'],
    fontSize: 15,
    fontWeight: FontWeight.w700,
  ),
  'body': TextStyle(color: appColors['text'], fontSize: 16, height: 1.5),
  'label': TextStyle(
    color: appColors['textMuted'],
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: .2,
  ),
  'button': TextStyle(
    color: appColors['onPrimary'],
    fontSize: 15,
    fontWeight: FontWeight.w700,
  ),
  'caption': TextStyle(
    color: appColors['textMuted'],
    fontSize: 13,
    height: 1.35,
  ),
};

const Map<String, String> appBrandAssets = {
  'wordmark': 'assets/branding/wordmark.png',
  'icon': 'assets/branding/app_icon.png',
};

final List<AppLanguage> appLanguages = [
  _lang('Abkhaz', 'ab'),
  _lang('Acehnese', 'ace'),
  _lang('Acholi', 'ach'),
  _lang('Afrikaans', 'af', stt: 'af', tts: 'af'),
  _lang('Albanian', 'sq', stt: 'sq'),
  _lang('Alur', 'alz'),
  _lang('Amharic', 'am', stt: 'am'),
  _lang('Arabic', 'ar', stt: 'ar', tts: 'ar', rtl: true),
  _lang('Armenian', 'hy', stt: 'hy', tts: 'hy'),
  _lang('Assamese', 'as', stt: 'as'),
  _lang('Awadhi', 'awa'),
  _lang('Aymara', 'ay'),
  _lang('Azerbaijani', 'az', stt: 'az', tts: 'az'),
  _lang('Balinese', 'ban'),
  _lang('Bambara', 'bm'),
  _lang('Bashkir', 'ba'),
  _lang('Basque', 'eu', stt: 'eu'),
  _lang('Batak Karo', 'btx'),
  _lang('Batak Simalungun', 'bts'),
  _lang('Batak Toba', 'bbc'),
  _lang('Belarusian', 'be', stt: 'be', tts: 'be'),
  _lang('Bemba', 'bem'),
  _lang('Bengali', 'bn', stt: 'bn'),
  _lang('Betawi', 'bew'),
  _lang('Bhojpuri', 'bho'),
  _lang('Bikol', 'bik'),
  _lang('Bosnian', 'bs', stt: 'bs', tts: 'bs'),
  _lang('Breton', 'br'),
  _lang('Bulgarian', 'bg', stt: 'bg', tts: 'bg'),
  _lang('Buryat', 'bua'),
  _lang('Cantonese', 'yue', stt: 'yue'),
  _lang('Catalan', 'ca', stt: 'ca', tts: 'ca'),
  _lang('Cebuano', 'ceb'),
  _lang('Chichewa (Nyanja)', 'ny'),
  _lang('Chinese (Simplified)', 'zh-CN', stt: 'zh-cn', tts: 'zh-cn'),
  _lang('Chinese (Traditional)', 'zh-TW', stt: 'zh-tw', tts: 'zh-tw'),
  _lang('Chuvash', 'cv'),
  _lang('Corsican', 'co'),
  _lang('Crimean Tatar', 'crh'),
  _lang('Croatian', 'hr', stt: 'hr', tts: 'hr'),
  _lang('Czech', 'cs', stt: 'cs', tts: 'cs'),
  _lang('Danish', 'da', stt: 'da', tts: 'da'),
  _lang('Dinka', 'din'),
  _lang('Divehi', 'dv', rtl: true),
  _lang('Dogri', 'doi'),
  _lang('Dombe', 'dov'),
  _lang('Dutch', 'nl', stt: 'nl', tts: 'nl'),
  _lang('Dzongkha', 'dz'),
  _lang('English', 'en', stt: 'en', tts: 'en'),
  _lang('Esperanto', 'eo'),
  _lang('Estonian', 'et', stt: 'et', tts: 'et'),
  _lang('Ewe', 'ee'),
  _lang('Fijian', 'fj'),
  _lang('Filipino (Tagalog)', 'fil', stt: 'tl', tts: 'tl'),
  _lang('Finnish', 'fi', stt: 'fi', tts: 'fi'),
  _lang('French', 'fr', stt: 'fr', tts: 'fr'),
  _lang('French (French)', 'fr-FR', stt: 'fr', tts: 'fr-FR'),
  _lang('French (Canadian)', 'fr-CA', stt: 'fr', tts: 'fr-CA'),
  _lang('Frisian', 'fy'),
  _lang('Fulfulde', 'ff'),
  _lang('Ga', 'gaa'),
  _lang('Galician', 'gl', stt: 'gl', tts: 'gl'),
  _lang('Ganda (Luganda)', 'lg'),
  _lang('Georgian', 'ka', stt: 'ka'),
  _lang('German', 'de', stt: 'de', tts: 'de'),
  _lang('Greek', 'el', stt: 'el', tts: 'el'),
  _lang('Guarani', 'gn'),
  _lang('Gujarati', 'gu', stt: 'gu'),
  _lang('Haitian Creole', 'ht'),
  _lang('Hakha Chin', 'cnh'),
  _lang('Hausa', 'ha', stt: 'ha'),
  _lang('Hawaiian', 'haw'),
  _lang('Hebrew', 'iw', stt: 'he', tts: 'he', rtl: true),
  _lang('Hiligaynon', 'hil'),
  _lang('Hindi', 'hi', stt: 'hi', tts: 'hi'),
  _lang('Hmong', 'hmn'),
  _lang('Hungarian', 'hu', stt: 'hu', tts: 'hu'),
  _lang('Hunsrik', 'hrx'),
  _lang('Icelandic', 'is', stt: 'is', tts: 'is'),
  _lang('Igbo', 'ig'),
  _lang('Iloko', 'ilo'),
  _lang('Indonesian', 'id', stt: 'id', tts: 'id'),
  _lang('Irish', 'ga'),
  _lang('Italian', 'it', stt: 'it', tts: 'it'),
  _lang('Japanese', 'ja', stt: 'ja', tts: 'ja'),
  _lang('Javanese', 'jw', stt: 'jv'),
  _lang('Kannada', 'kn', stt: 'kn', tts: 'kn'),
  _lang('Kapampangan', 'pam'),
  _lang('Kazakh', 'kk', stt: 'kk', tts: 'kk'),
  _lang('Khmer', 'km', stt: 'km'),
  _lang('Kiga', 'cgg'),
  _lang('Kinyarwanda', 'rw'),
  _lang('Kituba', 'ktu'),
  _lang('Konkani', 'gom'),
  _lang('Korean', 'ko', stt: 'ko', tts: 'ko'),
  _lang('Krio', 'kri'),
  _lang('Kurdish (Kurmanji)', 'ku'),
  _lang('Kurdish (Sorani)', 'ckb', rtl: true),
  _lang('Kyrgyz', 'ky', stt: 'ky'),
  _lang('Lao', 'lo', stt: 'lo'),
  _lang('Latgalian', 'ltg'),
  _lang('Latin', 'la'),
  _lang('Latvian', 'lv', stt: 'lv', tts: 'lv'),
  _lang('Ligurian', 'lij'),
  _lang('Limburgan', 'li'),
  _lang('Lingala', 'ln'),
  _lang('Lithuanian', 'lt', stt: 'lt', tts: 'lt'),
  _lang('Lombard', 'lmo'),
  _lang('Luo', 'luo'),
  _lang('Luxembourgish', 'lb', stt: 'lb'),
  _lang('Macedonian', 'mk', stt: 'mk', tts: 'mk'),
  _lang('Maithili', 'mai'),
  _lang('Makassar', 'mak'),
  _lang('Malagasy', 'mg'),
  _lang('Malay', 'ms', stt: 'ms', tts: 'ms'),
  _lang('Malay (Jawi)', 'ms-Arab', stt: 'ms', tts: 'ms-Arab', rtl: true),
  _lang('Malayalam', 'ml', stt: 'ml'),
  _lang('Maltese', 'mt', stt: 'mt'),
  _lang('Maori', 'mi', stt: 'mi', tts: 'mi'),
  _lang('Marathi', 'mr', stt: 'mr', tts: 'mr'),
  _lang('Meadow Mari', 'chm'),
  _lang('Meiteilon (Manipuri)', 'mni-Mtei'),
  _lang('Minang', 'min'),
  _lang('Mizo', 'lus'),
  _lang('Mongolian', 'mn', stt: 'mn'),
  _lang('Myanmar (Burmese)', 'my', stt: 'my'),
  _lang('Ndebele (South)', 'nr'),
  _lang('Nepalbhasa (Newari)', 'new'),
  _lang('Nepali', 'ne', stt: 'ne', tts: 'ne'),
  _lang('Northern Sotho (Sepedi)', 'nso'),
  _lang('Norwegian', 'no', stt: 'no', tts: 'no'),
  _lang('Nuer', 'nus'),
  _lang('Occitan', 'oc'),
  _lang('Odia (Oriya)', 'or', stt: 'or'),
  _lang('Oromo', 'om'),
  _lang('Pangasinan', 'pag'),
  _lang('Papiamento', 'pap'),
  _lang('Pashto', 'ps', rtl: true),
  _lang('Persian', 'fa', stt: 'fa', tts: 'fa', rtl: true),
  _lang('Polish', 'pl', stt: 'pl', tts: 'pl'),
  _lang('Portuguese', 'pt', stt: 'pt', tts: 'pt'),
  _lang('Portuguese (Portugal)', 'pt-PT', stt: 'pt', tts: 'pt-PT'),
  _lang('Portuguese (Brazil)', 'pt-BR', stt: 'pt', tts: 'pt-BR'),
  _lang('Punjabi', 'pa', stt: 'pa'),
  _lang('Punjabi (Shahmukhi)', 'pa-Arab', rtl: true),
  _lang('Quechua', 'qu'),
  _lang('Romani', 'rom'),
  _lang('Romanian', 'ro', stt: 'ro', tts: 'ro'),
  _lang('Rundi', 'rn'),
  _lang('Russian', 'ru', stt: 'ru', tts: 'ru'),
  _lang('Samoan', 'sm'),
  _lang('Sango', 'sg'),
  _lang('Sanskrit', 'sa'),
  _lang('Scots Gaelic', 'gd'),
  _lang('Serbian', 'sr', stt: 'sr', tts: 'sr'),
  _lang('Sesotho', 'st'),
  _lang('Seychellois Creole', 'crs'),
  _lang('Shan', 'shn'),
  _lang('Shona', 'sn'),
  _lang('Sicilian', 'scn'),
  _lang('Silesian', 'szl'),
  _lang('Sindhi', 'sd', rtl: true),
  _lang('Sinhala (Sinhalese)', 'si'),
  _lang('Slovak', 'sk', stt: 'sk', tts: 'sk'),
  _lang('Slovenian', 'sl', stt: 'sl', tts: 'sl'),
  _lang('Somali', 'so'),
  _lang('Spanish', 'es', stt: 'es', tts: 'es'),
  _lang('Sundanese', 'su'),
  _lang('Swahili', 'sw', stt: 'sw', tts: 'sw'),
  _lang('Swati', 'ss'),
  _lang('Swedish', 'sv', stt: 'sv', tts: 'sv'),
  _lang('Tajik', 'tg'),
  _lang('Tamil', 'ta', stt: 'ta', tts: 'ta'),
  _lang('Tatar', 'tt'),
  _lang('Telugu', 'te', stt: 'te'),
  _lang('Tetum', 'tet'),
  _lang('Thai', 'th', stt: 'th', tts: 'th'),
  _lang('Tigrinya', 'ti'),
  _lang('Tsonga', 'ts'),
  _lang('Tswana', 'tn'),
  _lang('Turkish', 'tr', stt: 'tr', tts: 'tr'),
  _lang('Turkmen', 'tk'),
  _lang('Twi (Akan)', 'ak'),
  _lang('Ukrainian', 'uk', stt: 'uk', tts: 'uk'),
  _lang('Urdu', 'ur', stt: 'ur', tts: 'ur', rtl: true),
  _lang('Uyghur', 'ug', rtl: true),
  _lang('Uzbek', 'uz', stt: 'uz'),
  _lang('Vietnamese', 'vi', stt: 'vi', tts: 'vi'),
  _lang('Welsh', 'cy', stt: 'cy', tts: 'cy'),
  _lang('Xhosa', 'xh', stt: 'xh'),
  _lang('Yiddish', 'yi', rtl: true),
  _lang('Yoruba', 'yo', stt: 'yo'),
  _lang('Yucatec Maya', 'yua'),
  _lang('Zulu', 'zu', stt: 'zu'),
];

AppLanguage _lang(
  String name,
  String code, {
  String? stt,
  String? tts,
  bool rtl = false,
}) => AppLanguage(
  name: name,
  code: code,
  translationCode: code,
  sttCode: stt,
  ttsCode: tts,
  rtl: rtl,
);

class TranslatorAppShell extends StatelessWidget {
  const TranslatorAppShell({super.key, required this.home});

  final Widget home;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: appStrings['appName'],
      theme: buildAppTheme(),
      home: home,
    );
  }
}

ThemeData buildAppTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: appColors['primary']!,
    brightness: Brightness.light,
    surface: appColors['surface']!,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: appColors['background'],
    fontFamily: 'Arial',
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: appColors['primary'],
      selectionColor: appColors['primarySoft'],
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: appColors['text'],
      contentTextStyle: appTextStyles['caption']?.copyWith(
        color: appColors['onPrimary'],
      ),
    ),
  );
}

Future<AppLanguage?> showLanguagePicker({
  required BuildContext context,
  required List<AppLanguage> languages,
  required AppLanguage selected,
}) {
  return showModalBottomSheet<AppLanguage>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: appColors['surface'],
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(appSizes['radiusLarge']!),
      ),
    ),
    builder: (context) =>
        LanguagePicker(languages: languages, selected: selected),
  );
}

void showCopiedNotification(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(appStrings['copied']!),
      duration: appDurations['snack']!,
    ),
  );
}

Widget buildSurfaceCard({required Widget child, EdgeInsetsGeometry? padding}) {
  return Container(
    padding: padding ?? EdgeInsets.all(appSizes['sectionGap']!),
    decoration: BoxDecoration(
      color: appColors['surface'],
      borderRadius: BorderRadius.circular(appSizes['radiusLarge']!),
      border: Border.all(color: appColors['border']!),
      boxShadow: [
        BoxShadow(
          color: appColors['shadow']!,
          blurRadius: appSizes['sectionGap']!,
          offset: Offset(0, appSizes['tinyGap']!),
        ),
      ],
    ),
    child: child,
  );
}

Widget buildSectionTitle(String title, {IconData? icon, Widget? trailing}) {
  return Row(
    children: [
      if (icon != null) ...[
        Icon(icon, size: appSizes['sectionGap'], color: appColors['primary']),
        SizedBox(width: appSizes['smallGap']),
      ],
      Expanded(child: Text(title, style: appTextStyles['section'])),
      ?trailing,
    ],
  );
}

Widget buildPrimaryButton({
  required String label,
  required IconData icon,
  required VoidCallback? onPressed,
  bool busy = false,
}) {
  return FilledButton.icon(
    onPressed: busy ? null : onPressed,
    icon: busy
        ? SizedBox.square(
            dimension: appSizes['sectionGap'],
            child: const CircularProgressIndicator(strokeWidth: 2),
          )
        : Icon(icon),
    label: Text(label),
    style: FilledButton.styleFrom(
      minimumSize: Size(0, appSizes['languageHeight']!),
      backgroundColor: appColors['primary'],
      foregroundColor: appColors['onPrimary'],
      disabledBackgroundColor: appColors['primarySoft'],
      disabledForegroundColor: appColors['primary'],
      textStyle: appTextStyles['button'],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(appSizes['radiusMedium']!),
      ),
    ),
  );
}

Widget buildLanguageButton({
  required String label,
  required AppLanguage language,
  required VoidCallback onTap,
}) {
  return Semantics(
    button: true,
    label: '$label: ${language.name}',
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(appSizes['radiusMedium']!),
      child: Container(
        height: appSizes['languageHeight'],
        padding: EdgeInsets.symmetric(horizontal: appSizes['itemGap']!),
        decoration: BoxDecoration(
          color: appColors['surface'],
          borderRadius: BorderRadius.circular(appSizes['radiusMedium']!),
          border: Border.all(color: appColors['border']!),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: appTextStyles['label']),
                  SizedBox(height: appSizes['tinyGap']),
                  Text(
                    language.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: appTextStyles['section'],
                  ),
                ],
              ),
            ),
            Icon(appIcons['arrow'], color: appColors['textMuted']),
          ],
        ),
      ),
    ),
  );
}

Widget buildStatusBanner({required String message, required bool error}) {
  return AnimatedContainer(
    duration: appDurations['normal']!,
    padding: EdgeInsets.all(appSizes['itemGap']!),
    decoration: BoxDecoration(
      color: error ? appColors['dangerSoft'] : appColors['primarySoft'],
      borderRadius: BorderRadius.circular(appSizes['radiusSmall']!),
    ),
    child: Row(
      children: [
        Icon(
          error ? appIcons['error'] : appIcons['cloud'],
          color: error ? appColors['danger'] : appColors['primary'],
        ),
        SizedBox(width: appSizes['smallGap']),
        Expanded(child: Text(message, style: appTextStyles['caption'])),
      ],
    ),
  );
}

@immutable
class HistoryViewItem {
  const HistoryViewItem({
    required this.id,
    required this.sourceText,
    required this.translatedText,
  });

  final int id;
  final String sourceText;
  final String translatedText;
}

class TranslatorScreen extends StatelessWidget {
  const TranslatorScreen({
    super.key,
    required this.mockMode,
    required this.backendConfigured,
    required this.message,
    required this.messageIsError,
    required this.sourceLanguage,
    required this.targetLanguage,
    required this.recording,
    required this.processing,
    required this.recordingLabel,
    required this.sourceController,
    required this.translatedText,
    required this.isPlaying,
    required this.ttsProcessing,
    required this.historyBusy,
    required this.historyItems,
    required this.onSelectSource,
    required this.onSelectTarget,
    required this.onSwap,
    required this.onMicrophone,
    required this.onCopySource,
    required this.onCopyTranslation,
    required this.onTranslate,
    required this.onSpeak,
    required this.onClear,
    required this.onClearHistory,
    required this.onDeleteHistory,
    required this.onRestoreHistory,
  });

  final bool mockMode;
  final bool backendConfigured;
  final String? message;
  final bool messageIsError;
  final AppLanguage sourceLanguage;
  final AppLanguage targetLanguage;
  final bool recording;
  final bool processing;
  final String recordingLabel;
  final TextEditingController sourceController;
  final String translatedText;
  final bool isPlaying;
  final bool ttsProcessing;
  final bool historyBusy;
  final List<HistoryViewItem> historyItems;
  final VoidCallback onSelectSource;
  final VoidCallback onSelectTarget;
  final VoidCallback onSwap;
  final VoidCallback onMicrophone;
  final VoidCallback onCopySource;
  final VoidCallback onCopyTranslation;
  final VoidCallback onTranslate;
  final VoidCallback onSpeak;
  final VoidCallback onClear;
  final VoidCallback onClearHistory;
  final ValueChanged<int> onDeleteHistory;
  final ValueChanged<int> onRestoreHistory;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final desktop =
                constraints.maxWidth >= appSizes['desktopBreakpoint']!;
            final padding = desktop
                ? appSizes['pagePadding']!
                : appSizes['mobilePadding']!;
            return SelectionArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(padding),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: appSizes['contentMax']!,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        buildAppHeader(mockMode: mockMode),
                        SizedBox(height: appSizes['sectionGap']),
                        buildLanguageRow(
                          desktop: desktop,
                          sourceLanguage: sourceLanguage,
                          targetLanguage: targetLanguage,
                          busy: processing,
                          onSelectSource: onSelectSource,
                          onSelectTarget: onSelectTarget,
                          onSwap: onSwap,
                        ),
                        SizedBox(height: appSizes['sectionGap']),
                        if (!backendConfigured) ...[
                          buildStatusBanner(
                            message:
                                '${appStrings['settingsNeeded']}\n${appStrings['backendHelp']}',
                            error: false,
                          ),
                          SizedBox(height: appSizes['sectionGap']),
                        ],
                        if (message != null) ...[
                          buildStatusBanner(
                            message: message!,
                            error: messageIsError,
                          ),
                          SizedBox(height: appSizes['sectionGap']),
                        ],
                        buildTranslatorWorkspace(
                          desktop: desktop,
                          recording: recording,
                          processing: processing,
                          microphoneEnabled: sourceLanguage.supportsStt,
                          recordingLabel: recordingLabel,
                          sourceController: sourceController,
                          sourceRtl: sourceLanguage.rtl,
                          targetRtl: targetLanguage.rtl,
                          translatedText: translatedText,
                          isPlaying: isPlaying,
                          ttsProcessing: ttsProcessing,
                          targetSupportsTts: targetLanguage.supportsTts,
                          onMicrophone: onMicrophone,
                          onCopySource: onCopySource,
                          onCopyTranslation: onCopyTranslation,
                          onTranslate: onTranslate,
                          onSpeak: onSpeak,
                          onClear: onClear,
                        ),
                        SizedBox(height: appSizes['sectionGap']),
                        buildHistorySection(
                          busy: historyBusy,
                          items: historyItems,
                          onClear: onClearHistory,
                          onDelete: onDeleteHistory,
                          onRestore: onRestoreHistory,
                        ),
                        SizedBox(height: appSizes['smallGap']),
                        const Center(child: AuthorFlowerMark()),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// The same discreet signature used in the author's music player.
class AuthorFlowerMark extends StatefulWidget {
  const AuthorFlowerMark({super.key});

  @override
  State<AuthorFlowerMark> createState() => _AuthorFlowerMarkState();
}

class _AuthorFlowerMarkState extends State<AuthorFlowerMark> {
  Timer? _tapResetTimer;
  int _tapCount = 0;

  void _handleTap() {
    _tapResetTimer?.cancel();
    _tapResetTimer = null;
    _tapCount++;
    if (_tapCount >= appConfig['authorTapsToReveal']!) {
      _tapCount = 0;
      showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          icon: Icon(
            appIcons['authorMark'],
            color: appColors['authorMark'],
            size: appSizes['authorDialogIcon'],
          ),
          content: Text(
            appStrings['authorSignature']!,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, height: 1.6),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(appStrings['close']!),
            ),
          ],
        ),
      );
      return;
    }
    _tapResetTimer = Timer(
      appDurations['authorTapReset']!,
      () => _tapCount = 0,
    );
  }

  @override
  void dispose() {
    _tapResetTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      key: const ValueKey('author-flower'),
      tooltip: appStrings['authorMark'],
      onPressed: _handleTap,
      iconSize: appSizes['authorIcon'],
      color: appColors['authorMark'],
      icon: Icon(appIcons['authorMark']),
    );
  }
}

Widget buildAppHeader({required bool mockMode}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Image.asset(
        appBrandAssets['wordmark']!,
        width: 420,
        fit: BoxFit.contain,
        alignment: Alignment.centerLeft,
        semanticLabel: appStrings['appName'],
        // Blend the white image matte into the existing pale page background.
        color: appColors['background'],
        colorBlendMode: BlendMode.darken,
      ),
      SizedBox(height: appSizes['tinyGap']),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(appStrings['tagline']!, style: appTextStyles['caption']),
          if (mockMode) ...[
            SizedBox(height: appSizes['smallGap']),
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: appSizes['itemGap']!,
                  vertical: appSizes['tinyGap']!,
                ),
                decoration: BoxDecoration(
                  color: appColors['primarySoft'],
                  borderRadius: BorderRadius.circular(appSizes['radiusSmall']!),
                ),
                child: Text(
                  appStrings['prototypeMode']!,
                  style: appTextStyles['label']?.copyWith(
                    color: appColors['primary'],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    ],
  );
}

Widget buildLanguageRow({
  required bool desktop,
  required AppLanguage sourceLanguage,
  required AppLanguage targetLanguage,
  required bool busy,
  required VoidCallback onSelectSource,
  required VoidCallback onSelectTarget,
  required VoidCallback onSwap,
}) {
  final source = buildLanguageButton(
    label: appStrings['source']!,
    language: sourceLanguage,
    onTap: onSelectSource,
  );
  final target = buildLanguageButton(
    label: appStrings['target']!,
    language: targetLanguage,
    onTap: onSelectTarget,
  );
  final swap = IconButton.filledTonal(
    onPressed: busy ? null : onSwap,
    tooltip: appStrings['swap'],
    icon: Icon(appIcons['swap']),
    style: IconButton.styleFrom(
      minimumSize: Size.square(appSizes['iconButton']!),
      backgroundColor: appColors['primarySoft'],
      foregroundColor: appColors['primary'],
    ),
  );
  if (desktop) {
    return Row(
      children: [
        Expanded(child: source),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: appSizes['itemGap']!),
          child: swap,
        ),
        Expanded(child: target),
      ],
    );
  }
  return Column(
    children: [
      source,
      Padding(
        padding: EdgeInsets.symmetric(vertical: appSizes['smallGap']!),
        child: swap,
      ),
      target,
    ],
  );
}

Widget buildTranslatorWorkspace({
  required bool desktop,
  required bool recording,
  required bool processing,
  required bool microphoneEnabled,
  required String recordingLabel,
  required TextEditingController sourceController,
  required bool sourceRtl,
  required bool targetRtl,
  required String translatedText,
  required bool isPlaying,
  required bool ttsProcessing,
  required bool targetSupportsTts,
  required VoidCallback onMicrophone,
  required VoidCallback onCopySource,
  required VoidCallback onCopyTranslation,
  required VoidCallback onTranslate,
  required VoidCallback onSpeak,
  required VoidCallback onClear,
}) {
  final sourceEditor = _buildSourceEditor(
    controller: sourceController,
    enabled: !processing && !recording,
    rtl: sourceRtl,
    onCopy: onCopySource,
  );
  final translationResult = _buildTranslationResult(
    translatedText: translatedText,
    rtl: targetRtl,
    onCopy: onCopyTranslation,
  );
  return buildSurfaceCard(
    child: Column(
      children: [
        buildSectionTitle(
          appStrings['steps']!,
          icon: appIcons['microphone'],
          trailing: _buildStepIndicators(),
        ),
        SizedBox(height: appSizes['sectionGap']),
        _buildMicrophone(
          recording: recording,
          processing: processing,
          enabled: microphoneEnabled,
          recordingLabel: recordingLabel,
          onTap: onMicrophone,
        ),
        SizedBox(height: appSizes['sectionGap']),
        if (desktop)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: sourceEditor),
              SizedBox(width: appSizes['itemGap']),
              Expanded(child: translationResult),
            ],
          )
        else ...[
          sourceEditor,
          SizedBox(height: appSizes['itemGap']),
          translationResult,
        ],
        SizedBox(height: appSizes['itemGap']),
        _buildTranslatorActions(
          desktop: desktop,
          busy: processing,
          isPlaying: isPlaying,
          ttsProcessing: ttsProcessing,
          targetSupportsTts: targetSupportsTts,
          onTranslate: onTranslate,
          onSpeak: onSpeak,
          onClear: onClear,
        ),
      ],
    ),
  );
}

Widget _buildStepIndicators() {
  final steps = [
    (appStrings['stepListen']!, appIcons['microphone']!),
    (appStrings['stepTranslate']!, appIcons['translate']!),
    (appStrings['stepSpeak']!, appIcons['speak']!),
  ];
  return Row(
    children: steps
        .map(
          (step) => Padding(
            padding: EdgeInsets.only(left: appSizes['smallGap']!),
            child: Tooltip(
              message: step.$1,
              child: CircleAvatar(
                radius: appSizes['radiusSmall'],
                backgroundColor: appColors['primarySoft'],
                child: Icon(
                  step.$2,
                  size: appSizes['sectionGap'],
                  color: appColors['primary'],
                ),
              ),
            ),
          ),
        )
        .toList(),
  );
}

Widget _buildMicrophone({
  required bool recording,
  required bool processing,
  required bool enabled,
  required String recordingLabel,
  required VoidCallback onTap,
}) {
  final available = enabled || recording;
  final primaryColor = recording
      ? appColors['danger']!
      : available
      ? appColors['primary']!
      : appColors['surfaceMuted']!;
  final label = processing
      ? appStrings['processing']!
      : recording
      ? appStrings['listening']!
      : available
      ? appStrings['tapToSpeak']!
      : appStrings['microphoneUnsupported']!;
  return Column(
    children: [
      Semantics(
        button: true,
        enabled: available && !processing,
        label: label,
        child: InkWell(
          onTap: processing || !available ? null : onTap,
          customBorder: const CircleBorder(),
          child: AnimatedContainer(
            duration: appDurations['normal']!,
            width: appSizes['micSize'],
            height: appSizes['micSize'],
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: primaryColor,
              boxShadow: [
                BoxShadow(
                  color: recording
                      ? appColors['dangerSoft']!
                      : available
                      ? appColors['primarySoft']!
                      : appColors['shadow']!,
                  blurRadius: appSizes['sectionGap']!,
                  spreadRadius: appSizes['smallGap']!,
                ),
              ],
            ),
            child: processing
                ? Padding(
                    padding: EdgeInsets.all(appSizes['sectionGap']!),
                    child: CircularProgressIndicator(
                      color: appColors['onPrimary'],
                    ),
                  )
                : Icon(
                    recording ? appIcons['stop'] : appIcons['microphone'],
                    color: available
                        ? appColors['onPrimary']
                        : appColors['textMuted'],
                    size: appSizes['iconButton'],
                  ),
          ),
        ),
      ),
      SizedBox(height: appSizes['itemGap']),
      Text(label, textAlign: TextAlign.center, style: appTextStyles['section']),
      SizedBox(height: appSizes['tinyGap']),
      Text(
        recording ? recordingLabel : appStrings['ready']!,
        style: appTextStyles['caption'],
      ),
    ],
  );
}

Widget _buildSourceEditor({
  required TextEditingController controller,
  required bool enabled,
  required bool rtl,
  required VoidCallback onCopy,
}) {
  return Container(
    constraints: BoxConstraints(minHeight: appSizes['resultMinHeight']!),
    padding: EdgeInsets.all(appSizes['itemGap']!),
    decoration: BoxDecoration(
      color: appColors['surfaceMuted'],
      borderRadius: BorderRadius.circular(appSizes['radiusMedium']!),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        buildSectionTitle(
          appStrings['transcription']!,
          icon: appIcons['keyboard'],
          trailing: IconButton(
            onPressed: onCopy,
            tooltip: appStrings['copy'],
            icon: Icon(appIcons['copy']),
          ),
        ),
        TextField(
          controller: controller,
          enabled: enabled,
          minLines: 4,
          maxLines: 8,
          textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
          style: appTextStyles['body'],
          decoration: InputDecoration(
            hintText: appStrings['sourceHint'],
            hintStyle: appTextStyles['caption'],
            border: InputBorder.none,
          ),
        ),
      ],
    ),
  );
}

Widget _buildTranslationResult({
  required String translatedText,
  required bool rtl,
  required VoidCallback onCopy,
}) {
  return Container(
    constraints: BoxConstraints(minHeight: appSizes['resultMinHeight']!),
    padding: EdgeInsets.all(appSizes['itemGap']!),
    decoration: BoxDecoration(
      color: appColors['primarySoft'],
      borderRadius: BorderRadius.circular(appSizes['radiusMedium']!),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        buildSectionTitle(
          appStrings['translation']!,
          icon: appIcons['translate'],
          trailing: IconButton(
            onPressed: onCopy,
            tooltip: appStrings['copy'],
            icon: Icon(appIcons['copy']),
          ),
        ),
        SizedBox(height: appSizes['itemGap']),
        Directionality(
          textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
          child: SelectableText(
            translatedText.isEmpty
                ? appStrings['translationHint']!
                : translatedText,
            style: translatedText.isEmpty
                ? appTextStyles['caption']
                : appTextStyles['body'],
          ),
        ),
      ],
    ),
  );
}

Widget _buildTranslatorActions({
  required bool desktop,
  required bool busy,
  required bool isPlaying,
  required bool ttsProcessing,
  required bool targetSupportsTts,
  required VoidCallback onTranslate,
  required VoidCallback onSpeak,
  required VoidCallback onClear,
}) {
  final buttons = <Widget>[
    buildPrimaryButton(
      label: appStrings['translate']!,
      icon: appIcons['translate']!,
      onPressed: busy ? null : onTranslate,
      busy: busy,
    ),
    if (targetSupportsTts)
      OutlinedButton.icon(
        onPressed: busy ? null : onSpeak,
        icon: ttsProcessing
            ? SizedBox.square(
                dimension: appSizes['sectionGap'],
                child: const CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(isPlaying ? appIcons['stopAudio'] : appIcons['speak']),
        label: Text(
          ttsProcessing
              ? appStrings['processingAudio']!
              : isPlaying
              ? appStrings['stopAudio']!
              : appStrings['speak']!,
        ),
        style: OutlinedButton.styleFrom(
          minimumSize: Size(0, appSizes['languageHeight']!),
          foregroundColor: appColors['primary'],
          side: BorderSide(color: appColors['border']!),
          textStyle: appTextStyles['section'],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(appSizes['radiusMedium']!),
          ),
        ),
      ),
    TextButton.icon(
      onPressed: onClear,
      icon: Icon(appIcons['clear']),
      label: Text(appStrings['clear']!),
      style: TextButton.styleFrom(
        minimumSize: Size(0, appSizes['languageHeight']!),
        foregroundColor: appColors['textMuted'],
      ),
    ),
  ];
  if (desktop) {
    return Row(
      children: buttons
          .map(
            (button) => Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: appSizes['tinyGap']!),
                child: button,
              ),
            ),
          )
          .toList(),
    );
  }
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: buttons
        .map(
          (button) => Padding(
            padding: EdgeInsets.only(bottom: appSizes['smallGap']!),
            child: button,
          ),
        )
        .toList(),
  );
}

Widget buildHistorySection({
  required bool busy,
  required List<HistoryViewItem> items,
  required VoidCallback onClear,
  required ValueChanged<int> onDelete,
  required ValueChanged<int> onRestore,
}) {
  return buildSurfaceCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        buildSectionTitle(
          appStrings['history']!,
          icon: appIcons['history'],
          trailing: items.isEmpty
              ? null
              : TextButton(
                  onPressed: onClear,
                  child: Text(appStrings['clearHistory']!),
                ),
        ),
        SizedBox(height: appSizes['itemGap']),
        if (busy)
          Center(
            child: Padding(
              padding: EdgeInsets.all(appSizes['sectionGap']!),
              child: const CircularProgressIndicator(),
            ),
          )
        else if (items.isEmpty)
          Center(
            child: Padding(
              padding: EdgeInsets.all(appSizes['sectionGap']!),
              child: Text(
                appStrings['emptyHistory']!,
                style: appTextStyles['caption'],
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (_, _) => Divider(color: appColors['border']),
            itemBuilder: (context, index) {
              final item = items[index];
              return ListTile(
                contentPadding: EdgeInsets.zero,
                onTap: () => onRestore(item.id),
                title: Text(
                  item.sourceText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: appTextStyles['section'],
                ),
                subtitle: Text(
                  item.translatedText,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: appTextStyles['caption'],
                ),
                trailing: IconButton(
                  onPressed: () => onDelete(item.id),
                  tooltip: appStrings['delete'],
                  icon: Icon(appIcons['delete']),
                ),
              );
            },
          ),
      ],
    ),
  );
}

class LanguagePicker extends StatefulWidget {
  const LanguagePicker({
    super.key,
    required this.languages,
    required this.selected,
  });

  final List<AppLanguage> languages;
  final AppLanguage selected;

  @override
  State<LanguagePicker> createState() => _LanguagePickerState();
}

class _LanguagePickerState extends State<LanguagePicker> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final query = _query.toLowerCase();
    final filtered = widget.languages
        .where(
          (item) =>
              item.name.toLowerCase().contains(query) ||
              item.code.toLowerCase().contains(query),
        )
        .toList();
    return Padding(
      padding: EdgeInsets.fromLTRB(
        appSizes['mobilePadding']!,
        appSizes['sectionGap']!,
        appSizes['mobilePadding']!,
        MediaQuery.viewInsetsOf(context).bottom + appSizes['mobilePadding']!,
      ),
      child: Column(
        children: [
          TextField(
            autofocus: true,
            onChanged: (value) => setState(() => _query = value),
            decoration: InputDecoration(
              hintText: appStrings['searchLanguage'],
              prefixIcon: Icon(appIcons['search']),
              filled: true,
              fillColor: appColors['surfaceMuted'],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(appSizes['radiusMedium']!),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          SizedBox(height: appSizes['itemGap']),
          Expanded(
            child: ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final language = filtered[index];
                final selected = language.code == widget.selected.code;
                return ListTile(
                  onTap: () => Navigator.pop(context, language),
                  title: Text(language.name, style: appTextStyles['body']),
                  subtitle: Text(
                    language.code,
                    style: appTextStyles['caption'],
                  ),
                  trailing: selected
                      ? Icon(appIcons['check'], color: appColors['primary'])
                      : null,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      appSizes['radiusSmall']!,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
