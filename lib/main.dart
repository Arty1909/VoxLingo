import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:audio_io/audio_io.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:drift/drift.dart' as drift;
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import 'style.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TranslatorAppShell(home: TranslatorHome()));
}

// Byte-bounded Unicode chunks keep each TTS request below the model input limit.
List<String> speechChunks(String text) {
  final chunks = <String>[];
  final buffer = StringBuffer();
  var bytes = 0;
  for (final character in text.characters) {
    final size = utf8.encode(character).length;
    if (size > appConfig['ttsChunkBytes']!) {
      throw ServiceException(appStrings['audioError']!);
    }
    if (bytes + size > appConfig['ttsChunkBytes']!) {
      chunks.add(buffer.toString());
      buffer.clear();
      bytes = 0;
    }
    buffer.write(character);
    bytes += size;
  }
  if (buffer.isNotEmpty) chunks.add(buffer.toString());
  return chunks;
}

class AudioSessionGate {
  int _generation = 0;

  int begin() => ++_generation;

  bool isCurrent(int session) => session == _generation;

  bool claimTerminal(int session) {
    if (!isCurrent(session)) return false;
    _generation++;
    return true;
  }

  void invalidate() => _generation++;
}

class MockServices {
  MockServices({String? errorStage, String? timeoutStage, this.delayOverride})
    : errorStage = errorStage ?? appMockConfig['errorStage']!,
      timeoutStage = timeoutStage ?? appMockConfig['timeoutStage']!;

  final String errorStage;
  final String timeoutStage;
  final Duration? delayOverride;

  Future<String> transcribe(Uint8List audio, AppLanguage language) async {
    await _runStage(appMockStages['stt']!);
    final configured = appMockTranscriptions[language.code];
    if (configured != null) return configured;
    return appMockTemplates['transcription']!
        .replaceAll('{language}', language.name)
        .replaceAll('{bytes}', audio.length.toString());
  }

  Future<String> translate(
    String text,
    AppLanguage source,
    AppLanguage target,
  ) async {
    await _runStage(appMockStages['translation']!);
    final configured = appMockTranslations['${source.code}:${target.code}'];
    if (configured != null) return configured;
    return appMockTemplates['translation']!
        .replaceAll('{source}', source.name)
        .replaceAll('{target}', target.name)
        .replaceAll('{text}', text);
  }

  Future<void> synthesizeSpeech() {
    return _runStage(appMockStages['tts']!);
  }

  Future<void> _runStage(String stage) async {
    if (timeoutStage == stage) {
      await Future<void>.delayed(delayOverride ?? appMockDurations['timeout']!);
      throw TimeoutException('[Mock] Simulated $stage timeout.');
    }
    await Future<void>.delayed(delayOverride ?? appMockDurations[stage]!);
    if (errorStage == stage) {
      throw ServiceException(appMockErrorMessages[stage]!);
    }
  }
}

enum AppPhase { idle, recording, processing, success, error }

@immutable
class HistoryRecord {
  const HistoryRecord({
    required this.id,
    required this.sourceText,
    required this.translatedText,
    required this.sourceCode,
    required this.targetCode,
    required this.createdAt,
  });
  final int id;
  final String sourceText;
  final String translatedText;
  final String sourceCode;
  final String targetCode;
  final DateTime createdAt;
}

class HistoryDatabase extends drift.GeneratedDatabase {
  static const String _createHistorySql =
      'CREATE TABLE IF NOT EXISTS translation_history ('
      'id INTEGER PRIMARY KEY AUTOINCREMENT, '
      'source_text TEXT NOT NULL, '
      'translated_text TEXT NOT NULL, '
      'source_code TEXT NOT NULL, '
      'target_code TEXT NOT NULL, '
      'created_at INTEGER NOT NULL)';

  HistoryDatabase()
    : this._(
        driftDatabase(
          name: appDefaults['databaseName']!,
          web: DriftWebOptions(
            sqlite3Wasm: Uri.parse(appDefaults['driftWasm']!),
            driftWorker: Uri.parse(appDefaults['driftWorker']!),
          ),
        ),
      );

  HistoryDatabase.forTesting(drift.QueryExecutor executor) : this._(executor);

  HistoryDatabase._(super.executor);

  @override
  int get schemaVersion => 1;
  @override
  Iterable<drift.TableInfo<drift.Table, Object?>> get allTables => const [];
  @override
  drift.MigrationStrategy get migration =>
      drift.MigrationStrategy(onCreate: (_) => _ensureHistoryTable());

  Future<void> _ensureHistoryTable() => customStatement(_createHistorySql);

  Future<List<HistoryRecord>> readHistory() async {
    await _ensureHistoryTable();
    final rows = await customSelect(
      'SELECT * FROM translation_history ORDER BY created_at DESC LIMIT ${appConfig['historyLimit']}',
      readsFrom: const {},
    ).get();
    return rows
        .map(
          (row) => HistoryRecord(
            id: row.read<int>('id'),
            sourceText: row.read<String>('source_text'),
            translatedText: row.read<String>('translated_text'),
            sourceCode: row.read<String>('source_code'),
            targetCode: row.read<String>('target_code'),
            createdAt: DateTime.fromMillisecondsSinceEpoch(
              row.read<int>('created_at'),
            ),
          ),
        )
        .toList();
  }

  Future<void> addHistory({
    required String sourceText,
    required String translatedText,
    required String sourceCode,
    required String targetCode,
  }) async {
    await _ensureHistoryTable();
    await customStatement(
      'INSERT INTO translation_history (source_text, translated_text, source_code, target_code, created_at) VALUES (?, ?, ?, ?, ?)',
      [
        sourceText,
        translatedText,
        sourceCode,
        targetCode,
        DateTime.now().millisecondsSinceEpoch,
      ],
    );
  }

  Future<void> deleteHistory(int id) async {
    await _ensureHistoryTable();
    await customStatement('DELETE FROM translation_history WHERE id = ?', [id]);
  }

  Future<void> clearHistory() async {
    await _ensureHistoryTable();
    await customStatement('DELETE FROM translation_history');
  }
}

class TranslatorHome extends StatefulWidget {
  const TranslatorHome({
    super.key,
    this.client,
    this.database,
    this.backendBaseUrl,
  });

  final http.Client? client;
  final HistoryDatabase? database;
  final String? backendBaseUrl;
  @override
  State<TranslatorHome> createState() => _TranslatorHomeState();
}

class _TranslatorHomeState extends State<TranslatorHome> {
  final AudioIo _audioIo = AudioIo.instance;
  final AudioPlayer _player = AudioPlayer();
  final MockServices _mockServices = MockServices();
  late final http.Client _client = widget.client ?? http.Client();
  late final HistoryDatabase _database = widget.database ?? HistoryDatabase();
  final TextEditingController _sourceController = TextEditingController();
  final BytesBuilder _audioBytes = BytesBuilder(copy: false);
  final MethodChannel _permissionChannel = MethodChannel(
    appPlatformConfig['permissionChannel']!,
  );

  late AppLanguage _sourceLanguage;
  late AppLanguage _targetLanguage;
  StreamSubscription<Uint8List>? _audioSubscription;
  StreamSubscription<void>? _playerSubscription;
  Timer? _recordingTimer;
  Timer? _recordingLimitTimer;
  Future<void>? _audioCleanup;
  final AudioSessionGate _audioSessions = AudioSessionGate();
  List<HistoryRecord> _history = const [];
  AppPhase _phase = AppPhase.idle;
  String _translatedText = '';
  String? _message;
  int _recordingSeconds = 0;
  bool _isPlaying = false;
  bool _ttsProcessing = false;
  bool _historyBusy = true;
  bool _audioStarted = false;
  bool _stoppingRecording = false;
  bool _startingRecording = false;
  bool _discardAudioAfterCleanup = false;
  int _speechSession = 0;
  Completer<void>? _playbackDone;

  bool get _isBusy => _phase == AppPhase.processing || _startingRecording;
  String get _backendBaseUrl =>
      widget.backendBaseUrl ??
      resolveBackendBaseUrl(isWeb: kIsWeb, pageUri: Uri.base);
  bool get _hasBackend => _backendBaseUrl.trim().isNotEmpty;
  bool get _isSttConfigured => appMockFlags['stt']! || _hasBackend;
  bool get _isTranslationConfigured =>
      _isSameLanguage || appMockFlags['translation']! || _hasBackend;
  bool get _isTtsConfigured => appMockFlags['tts']! || _hasBackend;
  bool get _isSameLanguage =>
      _sourceLanguage.translationCode.toLowerCase() ==
      _targetLanguage.translationCode.toLowerCase();

  @override
  void initState() {
    super.initState();
    _sourceLanguage = appLanguages.firstWhere(
      (item) => item.code == appDefaults['sourceLanguageCode'],
    );
    _targetLanguage = appLanguages.firstWhere(
      (item) => item.code == appDefaults['targetLanguageCode'],
    );
    _playerSubscription = _player.onPlayerComplete.listen((_) {
      _finishPlaybackWait();
    });
    unawaited(_loadHistory());
  }

  @override
  void dispose() {
    _audioSessions.invalidate();
    _speechSession++;
    _finishPlaybackWait();
    _stoppingRecording = true;
    unawaited(_disposeAudioInput());
    unawaited(_playerSubscription?.cancel());
    _sourceController.dispose();
    unawaited(_player.dispose());
    if (widget.client == null) _client.close();
    if (widget.database == null) unawaited(_database.close());
    super.dispose();
  }

  Future<void> _loadHistory() async {
    try {
      final items = await _database.readHistory();
      if (!mounted) return;
      setState(() {
        _history = items;
        _historyBusy = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _historyBusy = false;
        _message = appStrings['historyError'];
      });
    }
  }

  void _setError(String message) {
    if (!mounted) return;
    setState(() {
      _phase = AppPhase.error;
      _message = message;
      _startingRecording = false;
    });
  }

  Future<void> _toggleRecording() async {
    if (_phase == AppPhase.recording) {
      await _stopRecording();
    } else if (!_isBusy) {
      await _startRecording();
    }
  }

  Future<bool> _requestMicrophonePermission() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return true;
    if (defaultTargetPlatform == TargetPlatform.android) {
      return await _permissionChannel.invokeMethod<bool>(
            appPlatformConfig['requestMicrophonePermission']!,
          ) ??
          false;
    }
    return true;
  }

  Future<void> _startRecording() async {
    if (!_isSttConfigured) {
      _setError(appStrings['backendHelp']!);
      return;
    }
    if (!_sourceLanguage.supportsStt) {
      _setError(appStrings['languageUnavailable']!);
      return;
    }
    final session = _audioSessions.begin();
    _startingRecording = true;
    if (mounted) {
      setState(() {
        _phase = AppPhase.processing;
        _message = null;
      });
    }
    try {
      await _cleanupAudioInput(discardBuffer: true);
      if (!_audioSessions.isCurrent(session)) return;
      if (!await _requestMicrophonePermission()) {
        await _failAudioSession(session, appStrings['permissionDenied']!);
        return;
      }
      if (!_audioSessions.isCurrent(session)) return;
      _audioSubscription = _audioIo.inputBytes.listen(
        _audioBytes.add,
        onError: (Object error, StackTrace stackTrace) =>
            unawaited(_handleAudioInputError(error, session)),
        onDone: () {
          if (_audioSessions.isCurrent(session) &&
              !_stoppingRecording &&
              (_phase == AppPhase.recording || _startingRecording)) {
            unawaited(
              _handleAudioInputError(
                StateError(appStrings['microphoneUnavailable']!),
                session,
              ),
            );
          }
        },
      );
      _audioStarted = true;
      await _audioIo.startWith(
        const AudioIoConfig(
          format: AudioIoFormat.pcm16,
          sampleRate: AudioIoSampleRate.rate16000,
        ),
      );
      if (!mounted || !_audioSessions.isCurrent(session)) {
        await _cleanupAudioInput(discardBuffer: true);
        return;
      }
      _recordingTimer = Timer.periodic(appDurations['timerTick']!, (_) {
        if (mounted && _phase == AppPhase.recording) {
          setState(() => _recordingSeconds++);
        }
      });
      _recordingLimitTimer = Timer(
        appDurations['recordingLimit']!,
        () => unawaited(_stopRecording()),
      );
      setState(() {
        _recordingSeconds = 0;
        _phase = AppPhase.recording;
        _message = null;
        _startingRecording = false;
      });
    } catch (error) {
      await _failAudioSession(session, _audioErrorMessage(error));
    }
  }

  Future<void> _handleAudioInputError(Object error, int session) {
    return _failAudioSession(session, _audioErrorMessage(error));
  }

  Future<void> _failAudioSession(int session, String message) async {
    if (_stoppingRecording || !_audioSessions.claimTerminal(session)) return;
    _setError(message);
    await _cleanupAudioInput(discardBuffer: true);
  }

  String _audioErrorMessage(Object error) {
    if (error is AudioIoException && error.isPermissionDenied) {
      return appStrings['permissionDenied']!;
    }
    if (error is PlatformException &&
        error.code.toLowerCase().contains('permission')) {
      return appStrings['permissionDenied']!;
    }
    final description = error.toString().toLowerCase();
    if (appAudioUnavailableTokens.any(description.contains)) {
      return appStrings['microphoneUnavailable']!;
    }
    return appStrings['recordingError']!;
  }

  Future<void> _cleanupAudioInput({required bool discardBuffer}) {
    _discardAudioAfterCleanup |= discardBuffer;
    final current = _audioCleanup;
    if (current != null) return current;
    late final Future<void> cleanup;
    cleanup = _performAudioCleanup().whenComplete(() {
      if (!identical(_audioCleanup, cleanup)) return;
      if (_discardAudioAfterCleanup) _audioBytes.clear();
      _discardAudioAfterCleanup = false;
      _audioCleanup = null;
    });
    _audioCleanup = cleanup;
    return cleanup;
  }

  Future<void> _performAudioCleanup() async {
    _recordingTimer?.cancel();
    _recordingLimitTimer?.cancel();
    _recordingTimer = null;
    _recordingLimitTimer = null;
    final subscription = _audioSubscription;
    _audioSubscription = null;
    try {
      await subscription?.cancel();
    } catch (_) {}
    if (_audioStarted) {
      try {
        await _audioIo.stop();
      } catch (_) {}
    }
    _audioStarted = false;
  }

  Future<void> _disposeAudioInput() async {
    await _cleanupAudioInput(discardBuffer: true);
    _audioIo.dispose();
  }

  Future<void> _stopRecording() async {
    if (_phase != AppPhase.recording || _stoppingRecording) return;
    _stoppingRecording = true;
    _audioSessions.invalidate();
    if (mounted) {
      setState(() {
        _phase = AppPhase.processing;
        _message = null;
      });
    }
    try {
      await _cleanupAudioInput(discardBuffer: false);
      final bytes = _audioBytes.takeBytes();
      if (bytes.isEmpty) {
        _setError(appStrings['emptySpeech']!);
        return;
      }
      final transcript = await _transcribe(bytes);
      if (transcript.trim().isEmpty) {
        _setError(appStrings['emptySpeech']!);
        return;
      }
      _sourceController.text = transcript;
      await _translate(saveToHistory: true);
    } on TimeoutException {
      _setError(appStrings['networkError']!);
    } on http.ClientException {
      _setError(appStrings['networkError']!);
    } on ServiceException catch (error) {
      _setError(error.message);
    } catch (_) {
      _setError(appStrings['serviceError']!);
    } finally {
      _stoppingRecording = false;
      _audioBytes.clear();
    }
  }

  Future<String> _transcribe(Uint8List audio) async {
    final sttCode = _sourceLanguage.sttCode;
    if (sttCode == null) {
      throw ServiceException(appStrings['languageUnavailable']!);
    }
    if (appMockFlags['stt']!) {
      return _mockServices.transcribe(audio, _sourceLanguage);
    }
    final response = await _postService(appApiConfig['sttRoute']!, {
      'audioBase64': base64Encode(audio),
      'audioFormat': appApiConfig['audioFormat'],
      'sampleRateHz': appConfig['sampleRate'],
      'channels': appConfig['audioChannels'],
      'languageCode': sttCode,
    });
    final transcript = response['text'] as String?;
    if (transcript == null || transcript.trim().isEmpty) {
      throw ServiceException(appStrings['serviceError']!);
    }
    return transcript;
  }

  Future<void> _translate({bool saveToHistory = true}) async {
    final sourceText = _sourceController.text;
    if (sourceText.trim().isEmpty) {
      _setError(appStrings['emptyText']!);
      return;
    }
    if (!_isTranslationConfigured) {
      _setError(appStrings['backendHelp']!);
      return;
    }
    _cancelSpeechState();
    FocusManager.instance.primaryFocus?.unfocus();
    if (mounted) {
      setState(() {
        _phase = AppPhase.processing;
        _message = null;
      });
    }
    try {
      final translated = await _translateText(sourceText);
      if (saveToHistory) {
        await _database.addHistory(
          sourceText: sourceText,
          translatedText: translated,
          sourceCode: _sourceLanguage.code,
          targetCode: _targetLanguage.code,
        );
      }
      if (!mounted) return;
      setState(() {
        _translatedText = translated;
        _phase = AppPhase.success;
      });
      if (saveToHistory) await _loadHistory();
    } on TimeoutException {
      _setError(appStrings['networkError']!);
    } on http.ClientException {
      _setError(appStrings['networkError']!);
    } on ServiceException catch (error) {
      _setError(error.message);
    } catch (_) {
      _setError(appStrings['serviceError']!);
    }
  }

  Future<String> _translateText(String text) async {
    if (_isSameLanguage) {
      return text;
    }
    if (appMockFlags['translation']!) {
      return _mockServices.translate(text, _sourceLanguage, _targetLanguage);
    }
    final response = await _postService(appApiConfig['translationRoute']!, {
      'text': text,
      'sourceCode': _sourceLanguage.translationCode,
      'sourceName': _sourceLanguage.name,
      'targetCode': _targetLanguage.translationCode,
      'targetName': _targetLanguage.name,
    });
    final translated = response['translatedText'] as String?;
    if (translated == null || translated.trim().isEmpty) {
      throw ServiceException(appStrings['serviceError']!);
    }
    return translated;
  }

  Uri _backendUri(String route) {
    final base = _backendBaseUrl.replaceFirst(RegExp(r'/+$'), '');
    final suffix = route.replaceFirst(RegExp(r'^/+'), '');
    return Uri.parse('$base/$suffix');
  }

  Future<Map<String, Object?>> _postService(
    String route,
    Map<String, Object?> payload,
  ) async {
    final response = await _client
        .post(
          _backendUri(route),
          headers: {'Content-Type': appApiConfig['contentType']!},
          body: jsonEncode(payload),
        )
        .timeout(appDurations['requestTimeout']!);
    Object? decoded;
    if (response.bodyBytes.isNotEmpty) {
      try {
        decoded = jsonDecode(utf8.decode(response.bodyBytes));
      } on FormatException {
        decoded = null;
      }
    }
    final body = _map(decoded);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final error = _map(body?['error']);
      final serviceMessage =
          error?['message'] as String? ?? body?['message'] as String?;
      throw ServiceException(
        serviceMessage?.trim().isNotEmpty == true
            ? serviceMessage!
            : appStrings['serviceError']!,
      );
    }
    if (body == null) throw ServiceException(appStrings['serviceError']!);
    return body;
  }

  Map<String, Object?>? _map(Object? value) => value is Map
      ? value.map((key, item) => MapEntry(key.toString(), item))
      : null;

  Future<void> _speakTranslation() async {
    if (_isPlaying || _ttsProcessing) {
      _speechSession++;
      _finishPlaybackWait();
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _ttsProcessing = false;
        });
      }
      try {
        await _player.stop();
      } catch (_) {
        _setError(appStrings['audioError']!);
      }
      return;
    }
    if (_translatedText.isEmpty) {
      _setError(appStrings['emptyText']!);
      return;
    }
    final ttsCode = _targetLanguage.ttsCode;
    if (ttsCode == null) {
      _setError(appStrings['languageUnavailable']!);
      return;
    }
    if (!_isTtsConfigured) {
      _setError(appStrings['backendHelp']!);
      return;
    }
    final session = ++_speechSession;
    try {
      if (mounted) {
        setState(() {
          _ttsProcessing = true;
          _message = null;
        });
      }
      for (final chunk in speechChunks(_translatedText)) {
        if (!mounted || session != _speechSession) return;
        setState(() => _ttsProcessing = true);
        final audio = await _synthesizeSpeech(chunk, ttsCode);
        if (!mounted || session != _speechSession) return;
        setState(() {
          _ttsProcessing = false;
          _isPlaying = true;
        });
        if (appMockFlags['tts']!) {
          await Future<void>.delayed(appMockDurations['ttsPlayback']!);
        } else {
          final completed = Completer<void>();
          _playbackDone = completed;
          // Prepare before resuming so a cancelled download cannot start audio.
          await _player.setSource(BytesSource(audio!, mimeType: 'audio/mpeg'));
          if (!mounted || session != _speechSession) return;
          await _player.resume();
          await completed.future.timeout(const Duration(minutes: 5));
        }
        if (!mounted || session != _speechSession) return;
      }
      setState(() => _isPlaying = false);
    } on TimeoutException {
      if (session != _speechSession) return;
      if (mounted) {
        setState(() {
          _ttsProcessing = false;
          _isPlaying = false;
        });
      }
      _setError(appStrings['networkError']!);
    } on http.ClientException {
      if (session != _speechSession) return;
      if (mounted) {
        setState(() {
          _ttsProcessing = false;
          _isPlaying = false;
        });
      }
      _setError(appStrings['networkError']!);
    } on ServiceException catch (error) {
      if (session != _speechSession) return;
      if (mounted) {
        setState(() {
          _ttsProcessing = false;
          _isPlaying = false;
        });
      }
      _setError(error.message);
    } catch (_) {
      if (session != _speechSession) return;
      if (mounted) {
        setState(() {
          _ttsProcessing = false;
          _isPlaying = false;
        });
      }
      _setError(appStrings['audioError']!);
    }
  }

  Future<Uint8List?> _synthesizeSpeech(String text, String languageCode) async {
    if (appMockFlags['tts']!) {
      await _mockServices.synthesizeSpeech();
      return null;
    }
    final response = await _postService(appApiConfig['ttsRoute']!, {
      'text': text,
      'languageCode': languageCode,
      'audioFormat': appApiConfig['ttsAudioFormat'],
    });
    final content = response['audioBase64'] as String?;
    if (content == null || content.isEmpty) {
      throw ServiceException(appStrings['audioError']!);
    }
    return base64Decode(content);
  }

  void _clearResults() {
    _cancelSpeechState();
    _sourceController.clear();
    setState(() {
      _translatedText = '';
      _phase = AppPhase.idle;
      _message = null;
      _isPlaying = false;
      _ttsProcessing = false;
    });
  }

  void _cancelSpeechState() {
    _speechSession++;
    _finishPlaybackWait();
    unawaited(_player.stop());
    _isPlaying = false;
    _ttsProcessing = false;
  }

  void _finishPlaybackWait() {
    final done = _playbackDone;
    _playbackDone = null;
    if (done != null && !done.isCompleted) done.complete();
  }

  void _copyText(String text) {
    if (text.isEmpty) return;
    Clipboard.setData(ClipboardData(text: text));
    showCopiedNotification(context);
  }

  void _swapLanguages() {
    _cancelSpeechState();
    setState(() {
      final previousSource = _sourceLanguage;
      _sourceLanguage = _targetLanguage;
      _targetLanguage = previousSource;
      final previousSourceText = _sourceController.text;
      _sourceController.text = _translatedText;
      _translatedText = previousSourceText;
      _message = null;
      _phase = _translatedText.isEmpty ? AppPhase.idle : AppPhase.success;
    });
  }

  Future<void> _selectLanguage({required bool source}) async {
    final selected = await showLanguagePicker(
      context: context,
      languages: appLanguages
          .where((item) => item.supportsTranslation)
          .toList(),
      selected: source ? _sourceLanguage : _targetLanguage,
    );
    if (selected == null || !mounted) return;
    _cancelSpeechState();
    setState(() {
      if (source) {
        _sourceLanguage = selected;
      } else {
        _targetLanguage = selected;
      }
      _translatedText = '';
      _phase = AppPhase.idle;
      _message = null;
    });
  }

  Future<void> _deleteHistory(int id) async {
    await _database.deleteHistory(id);
    await _loadHistory();
  }

  Future<void> _clearHistory() async {
    await _database.clearHistory();
    await _loadHistory();
  }

  void _restoreHistory(HistoryRecord item) {
    final source = appLanguages.where((value) => value.code == item.sourceCode);
    final target = appLanguages.where((value) => value.code == item.targetCode);
    _cancelSpeechState();
    setState(() {
      if (source.isNotEmpty) _sourceLanguage = source.first;
      if (target.isNotEmpty) _targetLanguage = target.first;
      _sourceController.text = item.sourceText;
      _translatedText = item.translatedText;
      _phase = AppPhase.success;
      _message = null;
    });
  }

  String get _recordingLabel {
    final minutes = (_recordingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_recordingSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  List<HistoryViewItem> get _historyViewItems => _history
      .map(
        (item) => HistoryViewItem(
          id: item.id,
          sourceText: item.sourceText,
          translatedText: item.translatedText,
        ),
      )
      .toList();

  void _restoreHistoryById(int id) {
    final matches = _history.where((item) => item.id == id);
    if (matches.isNotEmpty) _restoreHistory(matches.first);
  }

  @override
  Widget build(BuildContext context) => TranslatorScreen(
    mockMode: appMockFlags.values.any((enabled) => enabled),
    backendConfigured:
        _isSttConfigured && _isTranslationConfigured && _isTtsConfigured,
    message: _message,
    messageIsError: _phase == AppPhase.error,
    sourceLanguage: _sourceLanguage,
    targetLanguage: _targetLanguage,
    recording: _phase == AppPhase.recording,
    processing: _isBusy,
    recordingLabel: _recordingLabel,
    sourceController: _sourceController,
    translatedText: _translatedText,
    isPlaying: _isPlaying,
    ttsProcessing: _ttsProcessing,
    historyBusy: _historyBusy,
    historyItems: _historyViewItems,
    onSelectSource: () => _selectLanguage(source: true),
    onSelectTarget: () => _selectLanguage(source: false),
    onSwap: _swapLanguages,
    onMicrophone: _toggleRecording,
    onCopySource: () => _copyText(_sourceController.text),
    onCopyTranslation: () => _copyText(_translatedText),
    onTranslate: () => _translate(),
    onSpeak: _speakTranslation,
    onClear: _clearResults,
    onClearHistory: _clearHistory,
    onDeleteHistory: _deleteHistory,
    onRestoreHistory: _restoreHistoryById,
  );
}

class ServiceException implements Exception {
  const ServiceException(this.message);
  final String message;
}
