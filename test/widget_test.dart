import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:audio_io/audio_io.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:voxlingo/main.dart';
import 'package:voxlingo/style.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('author flower reveals Arty signature only after 19 taps', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 640);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      const TranslatorAppShell(
        home: Scaffold(body: Center(child: AuthorFlowerMark())),
      ),
    );
    final flower = find.byKey(const ValueKey('author-flower'));
    final button = tester.widget<IconButton>(flower);
    expect(button.tooltip, 'Author mark');
    expect(button.iconSize, 22);
    expect(button.color, const Color(0xFFAB84CE));
    expect(tester.getSize(flower).shortestSide, greaterThanOrEqualTo(48));
    for (var i = 0; i < 18; i++) {
      await tester.tap(flower);
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(find.byType(AlertDialog), findsNothing);
    await tester.tap(flower);
    await tester.pumpAndSettle();
    expect(find.text('This app was created by Arty 💜'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    // Closing the dialog starts a fresh sequence, not another instant reveal.
    await tester.tap(flower);
    await tester.pump();
    expect(find.byType(AlertDialog), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('author tap sequence expires and its timer is disposed', (
    tester,
  ) async {
    await tester.pumpWidget(
      const TranslatorAppShell(
        home: Scaffold(body: Center(child: AuthorFlowerMark())),
      ),
    );
    final flower = find.byKey(const ValueKey('author-flower'));
    for (var i = 0; i < 18; i++) {
      await tester.tap(flower);
    }
    await tester.pump(const Duration(milliseconds: 3100));
    await tester.tap(flower);
    await tester.pump();
    expect(find.byType(AlertDialog), findsNothing);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 4));
    expect(tester.takeException(), isNull);
  });

  test(
    'Web discovers sibling backend and explicit URLs override discovery',
    () {
      for (final page in [
        'https://example.com/projects/VoxLingo/',
        'https://example.com/projects/VoxLingo/index.html?x=1#/home',
      ]) {
        expect(
          resolveBackendBaseUrl(
            isWeb: true,
            pageUri: Uri.parse(page),
            configuredUrl: '',
          ),
          'https://example.com/projects/VoxLingo/backend/',
        );
      }
      expect(
        resolveBackendBaseUrl(
          isWeb: true,
          pageUri: Uri.parse('https://example.com/'),
          configuredUrl: '',
        ),
        'https://example.com/backend/',
      );
      expect(
        resolveBackendBaseUrl(
          isWeb: true,
          pageUri: Uri.parse('https://example.com/'),
          configuredUrl: ' https://api.example.com/ ',
        ),
        'https://api.example.com/',
      );
      expect(
        resolveBackendBaseUrl(
          isWeb: false,
          pageUri: Uri.parse('file:///app/'),
          configuredUrl: '',
        ),
        isEmpty,
      );
    },
  );

  testWidgets('brand header fits mobile and desktop with accessible name', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    for (final width in [320.0, 800.0]) {
      tester.view.physicalSize = Size(width, 280);
      final boundaryKey = GlobalKey();
      await tester.pumpWidget(
        TranslatorAppShell(
          home: Scaffold(
            body: RepaintBoundary(
              key: boundaryKey,
              child: ColoredBox(
                color: appColors['background']!,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: buildAppHeader(mockMode: true),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.runAsync(
        () => precacheImage(
          AssetImage(appBrandAssets['wordmark']!),
          boundaryKey.currentContext!,
        ),
      );
      await tester.pumpAndSettle();
      final logo = tester.widget<Image>(find.byType(Image));
      expect(logo.semanticLabel, 'VoxLingo');
      expect((logo.image as AssetImage).assetName, appBrandAssets['wordmark']);
      expect(tester.takeException(), isNull);
      if (const bool.fromEnvironment('BRAND_PREVIEW')) {
        final boundary =
            boundaryKey.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        await tester.runAsync(() async {
          final image = await boundary.toImage(pixelRatio: 2);
          final data = await image.toByteData(format: ui.ImageByteFormat.png);
          final file = File('build/branding/header-${width.toInt()}.png');
          await file.parent.create(recursive: true);
          await file.writeAsBytes(data!.buffer.asUint8List());
          image.dispose();
        });
      }
    }
    await tester.pumpWidget(const SizedBox());
  });

  test('all services default to real backend with independent switches', () {
    expect(appMockFlags, {'stt': false, 'translation': false, 'tts': false});
    expect(appEnvironment['backendBaseUrl'], isEmpty);
    expect(appApiConfig['translationRoute'], 'translation');
  });

  test('language catalog is service-driven and unique', () {
    expect(appLanguages.length, 194);
    expect(
      appLanguages.map((item) => item.code).toSet().length,
      appLanguages.length,
    );
    expect(appLanguages.where((item) => item.supportsStt).length, 88);
    expect(appLanguages.where((item) => item.supportsTts).length, 63);
    expect(appLanguages.every((item) => item.supportsTranslation), isTrue);
  });

  test('translation-only languages remain selectable for manual input', () {
    final translationOnly = appLanguages.where(
      (item) => item.supportsTranslation && !item.supportsStt,
    );
    expect(translationOnly, isNotEmpty);
    expect(translationOnly.any((item) => !item.supportsTts), isTrue);
    expect(
      appLanguages.every(
        (item) =>
            item.name.isNotEmpty &&
            item.code.isNotEmpty &&
            item.translationCode.isNotEmpty,
      ),
      isTrue,
    );
  });

  test('rtl metadata is available in the catalog', () {
    final arabic = appLanguages.firstWhere((item) => item.code == 'ar');
    expect(arabic.rtl, isTrue);
    expect(arabic.sttCode, 'ar');
    expect(arabic.translationCode, 'ar');
    expect(arabic.ttsCode, 'ar');
  });

  test('normal stop invalidates a late audio stream error', () {
    final sessions = AudioSessionGate();
    final recordingSession = sessions.begin();

    sessions.invalidate();

    expect(sessions.claimTerminal(recordingSession), isFalse);
  });

  test('long speech chunks preserve Unicode and respect byte limit', () {
    final text = List.filled(400, 'Привет 👨‍👩‍👧‍👦 世界\n').join();
    final chunks = speechChunks(text);
    expect(chunks.length, greaterThan(1));
    expect(chunks.join(), text);
    expect(chunks.every((chunk) => utf8.encode(chunk).length <= 1800), isTrue);
    expect(speechChunks('Hello'), ['Hello']);
    expect(speechChunks(''), isEmpty);
  });

  test('only the first terminal audio event can claim a session', () {
    final sessions = AudioSessionGate();
    final recordingSession = sessions.begin();

    expect(sessions.claimTerminal(recordingSession), isTrue);
    expect(sessions.claimTerminal(recordingSession), isFalse);
  });

  test('mock services process PCM and supported translation pairs', () async {
    final service = MockServices(delayOverride: Duration.zero);
    final english = appLanguages.firstWhere((item) => item.code == 'en');
    final russian = appLanguages.firstWhere((item) => item.code == 'ru');

    final transcript = await service.transcribe(Uint8List(3200), english);
    final translated = await service.translate(transcript, english, russian);
    await service.synthesizeSpeech();

    expect(transcript, contains('Prototype transcription'));
    expect(translated, contains('Прототип перевода'));
  });

  test('mock translation has a marked fallback for every other pair', () async {
    final service = MockServices(delayOverride: Duration.zero);
    final arabic = appLanguages.firstWhere((item) => item.code == 'ar');
    final german = appLanguages.firstWhere((item) => item.code == 'de');

    final translated = await service.translate('مرحبا', arabic, german);

    expect(translated, startsWith('[Mock Arabic → German]'));
  });

  test('mock service can simulate errors and timeouts', () async {
    final english = appLanguages.firstWhere((item) => item.code == 'en');
    final russian = appLanguages.firstWhere((item) => item.code == 'ru');
    final errorService = MockServices(
      errorStage: appMockStages['translation'],
      timeoutStage: appMockStages['none'],
      delayOverride: Duration.zero,
    );
    final timeoutService = MockServices(
      errorStage: appMockStages['none'],
      timeoutStage: appMockStages['stt'],
      delayOverride: Duration.zero,
    );

    await expectLater(
      errorService.translate('test', english, russian),
      throwsA(isA<ServiceException>()),
    );
    await expectLater(
      timeoutService.transcribe(Uint8List(16), english),
      throwsA(isA<TimeoutException>()),
    );
  });

  test('Drift history supports add, load, delete and clear', () async {
    final database = HistoryDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);

    await database.addHistory(
      sourceText: 'Prototype source',
      translatedText: '[Mock] Prototype translation',
      sourceCode: 'en',
      targetCode: 'ru',
    );
    var records = await database.readHistory();
    expect(records, hasLength(1));
    expect(records.single.sourceCode, 'en');
    expect(records.single.targetCode, 'ru');

    await database.deleteHistory(records.single.id);
    expect(await database.readHistory(), isEmpty);

    await database.addHistory(
      sourceText: 'Second source',
      translatedText: '[Mock] Second translation',
      sourceCode: 'es',
      targetCode: 'en',
    );
    records = await database.readHistory();
    expect(records, hasLength(1));
    await database.clearHistory();
    expect(await database.readHistory(), isEmpty);
  });

  group('independent service routing', () {
    late HistoryDatabase database;
    late _TestAudioIo microphone;
    late List<http.Request> requests;
    late MockClient client;
    late List<String> playerCalls;
    Completer<http.Response>? pendingSpeech;
    String? playerId;

    setUp(() async {
      database = HistoryDatabase.forTesting(NativeDatabase.memory());
      microphone = _TestAudioIo();
      AudioIo.instance = microphone;
      requests = [];
      playerCalls = [];
      pendingSpeech = null;
      playerId = null;
      client = MockClient((request) async {
        requests.add(request);
        if (request.url.path == '/services/tts/synthesize' &&
            pendingSpeech != null) {
          return pendingSpeech!.future;
        }
        return http.Response(
          jsonEncode(switch (request.url.path) {
            '/services/stt/transcribe' => {'text': 'Hello from recorded audio'},
            '/services/tts/synthesize' => {
              'audioBase64': base64Encode([73, 68, 51, 0]),
            },
            _ => {'translatedText': 'Перевод ответа backend 🚀'},
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(
        MethodChannel(appPlatformConfig['permissionChannel']!),
        (_) async => true,
      );
      for (final name in [
        'xyz.luan/audioplayers.global',
        'xyz.luan/audioplayers.global/events',
      ]) {
        messenger.setMockMethodCallHandler(
          MethodChannel(name),
          (_) async => null,
        );
      }
      messenger.setMockMethodCallHandler(
        const MethodChannel('xyz.luan/audioplayers'),
        (call) async {
          playerCalls.add(call.method);
          if (call.method == 'create') {
            final id = (call.arguments as Map)['playerId'];
            playerId = id as String;
            messenger.setMockMethodCallHandler(
              MethodChannel('xyz.luan/audioplayers/events/$id'),
              (_) async => null,
            );
          }
          if (call.method == 'setSourceBytes' ||
              call.method == 'setSourceUrl') {
            final id = (call.arguments as Map)['playerId'];
            scheduleMicrotask(() {
              messenger.handlePlatformMessage(
                'xyz.luan/audioplayers/events/$id',
                const StandardMethodCodec().encodeSuccessEnvelope({
                  'event': 'audio.onPrepared',
                  'value': true,
                }),
                (_) {},
              );
            });
          }
          return null;
        },
      );
      // Initialize the process-wide singleton outside a widget's fake clock.
      await AudioPlayer.global.ensureInitialized();
    });

    tearDown(() async {
      client.close();
      await database.close();
    });

    void expectTranslationRequest() {
      final request = requests.singleWhere(
        (item) => item.url.path == '/translation',
      );
      expect(request.method, 'POST');
      expect(request.url.toString(), 'http://localhost:8080/translation');
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      expect(body['sourceCode'], 'en');
      expect(body['sourceName'], 'English');
      expect(body['targetCode'], 'ru');
      expect(body['targetName'], 'Russian');
    }

    Future<void> mount(WidgetTester tester, {String backend = ''}) async {
      final previousErrorHandler = FlutterError.onError;
      FlutterError.onError = (details) {
        // The existing history UI triggers this SDK advisory. UI layout is
        // outside these service-routing regression tests; keep all other errors.
        if (details.exceptionAsString().startsWith(
          'ListTile background color or ink splashes may be invisible.',
        )) {
          return;
        }
        previousErrorHandler?.call(details);
      };
      addTearDown(() => FlutterError.onError = previousErrorHandler);
      await tester.pumpWidget(
        TranslatorAppShell(
          home: TranslatorHome(
            client: client,
            database: database,
            backendBaseUrl: backend,
          ),
        ),
      );
      await settleServices(tester);
      expect(find.byType(AuthorFlowerMark), findsOneWidget);
    }

    testWidgets('manual text uses the backend route and persists history', (
      tester,
    ) async {
      await mount(tester, backend: 'http://localhost:8080');
      screen(tester).sourceController.text = '  Hello\nworld 🚀  ';
      screen(tester).onTranslate();
      await settleServices(tester);

      expect(requests, hasLength(1));
      expectTranslationRequest();
      expect(jsonDecode(requests.single.body)['text'], '  Hello\nworld 🚀  ');
      expect(screen(tester).translatedText, 'Перевод ответа backend 🚀');
      final history = await tester.runAsync(database.readHistory);
      expect(history, hasLength(1));
      expect(history!.single.sourceText, '  Hello\nworld 🚀  ');
      expect(history.single.translatedText, screen(tester).translatedText);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('real STT flows through backend Translation and real TTS', (
      tester,
    ) async {
      await mount(tester, backend: 'http://localhost:8080');
      screen(tester).onMicrophone();
      await tester.pump();
      expect(screen(tester).recording, isTrue);
      await tester.runAsync(() async {
        microphone.frames.add(Uint8List(3200));
        await Future<void>.delayed(Duration.zero);
      });
      await tester.pump();
      screen(tester).onMicrophone();
      await tester.pump();
      await tester.pump(appMockDurations['stt']!);
      await settleServices(tester);

      expect(requests, hasLength(2));
      expectTranslationRequest();
      expect(requests.first.url.path, '/services/stt/transcribe');
      final sttBody = jsonDecode(requests.first.body);
      expect(sttBody['languageCode'], 'en');
      expect(base64Decode(sttBody['audioBase64']), hasLength(3200));
      expect(
        jsonDecode(requests.last.body)['text'],
        'Hello from recorded audio',
      );
      expect(
        screen(tester).translatedText,
        'Перевод ответа backend 🚀',
        reason: screen(tester).message,
      );
      expect(screen(tester).historyItems, hasLength(1));
      screen(tester).onSpeak();
      await settleServices(tester);
      expect(screen(tester).isPlaying, isTrue);
      expect(requests.last.url.path, '/services/tts/synthesize');
      expect(jsonDecode(requests.last.body)['languageCode'], 'ru');
      await tester.pump(const Duration(milliseconds: 50));
      expect(playerCalls, contains('resume'));
      screen(tester).onSpeak();
      await settleServices(tester);
      expect(screen(tester).isPlaying, isFalse);
      expect(playerCalls, contains('stop'));
      expect(requests, hasLength(3));
      expect(microphone.startedConfig?.format, AudioIoFormat.pcm16);
      expect(microphone.startedConfig?.sampleRate, AudioIoSampleRate.rate16000);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('cancelling pending TTS never starts late audio', (
      tester,
    ) async {
      await mount(tester, backend: 'http://localhost:8080');
      screen(tester).sourceController.text = 'Hello';
      screen(tester).onTranslate();
      await settleServices(tester);
      pendingSpeech = Completer<http.Response>();
      screen(tester).onSpeak();
      await tester.pump();
      expect(screen(tester).ttsProcessing, isTrue);
      screen(tester).onClear();
      await tester.pump();
      pendingSpeech!.complete(
        http.Response(
          jsonEncode({
            'audioBase64': base64Encode([73, 68, 51, 0]),
          }),
          200,
        ),
      );
      await settleServices(tester);
      expect(screen(tester).translatedText, isEmpty);
      expect(screen(tester).isPlaying, isFalse);
      expect(screen(tester).ttsProcessing, isFalse);
      expect(playerCalls, isNot(contains('resume')));
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('playback completion resets the play button', (tester) async {
      await mount(tester, backend: 'http://localhost:8080');
      screen(tester).sourceController.text = 'Hello';
      screen(tester).onTranslate();
      await settleServices(tester);
      screen(tester).onSpeak();
      await settleServices(tester);
      await tester.pump(const Duration(milliseconds: 50));
      expect(playerCalls, contains('resume'));
      await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .handlePlatformMessage(
            'xyz.luan/audioplayers/events/$playerId',
            const StandardMethodCodec().encodeSuccessEnvelope({
              'event': 'audio.onComplete',
            }),
            (_) {},
          );
      await tester.pump();
      expect(screen(tester).isPlaying, isFalse);
      expect(screen(tester).messageIsError, isFalse);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('missing backend blocks real Translation and STT', (
      tester,
    ) async {
      await mount(tester);
      screen(tester).sourceController.text = 'Hello';
      screen(tester).onTranslate();
      await tester.pump();
      expect(screen(tester).message, appStrings['backendHelp']);
      expect(screen(tester).historyItems, isEmpty);
      expect(requests, isEmpty);

      screen(tester).onMicrophone();
      await tester.pump();
      expect(screen(tester).recording, isFalse);
      expect(microphone.startedConfig, isNull);
      expect(screen(tester).message, appStrings['backendHelp']);
      expect(requests, isEmpty);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets(
      'same language without backend preserves text and history; real TTS needs backend',
      (tester) async {
        await mount(tester);
        screen(tester).onSelectTarget();
        await tester.pumpAndSettle();
        Navigator.of(
          tester.element(find.byType(TextField).last),
        ).pop(appLanguages.firstWhere((language) => language.code == 'en'));
        await tester.pumpAndSettle();
        const text = '  Keep this\n\nexactly 🚀  ';
        screen(tester).sourceController.text = text;
        screen(tester).onTranslate();
        await settleServices(tester);

        expect(screen(tester).messageIsError, isFalse);
        expect(screen(tester).translatedText, text);
        expect(screen(tester).backendConfigured, isFalse);
        expect(requests, isEmpty);
        final history = await tester.runAsync(database.readHistory);
        expect(history, hasLength(1));
        expect(history!.single.sourceText, text);
        expect(history.single.translatedText, text);
        expect(history.single.sourceCode, 'en');
        expect(history.single.targetCode, 'en');
        screen(tester).onSpeak();
        await tester.pump();
        expect(screen(tester).isPlaying, isFalse);
        expect(screen(tester).message, appStrings['backendHelp']);
        expect(requests, isEmpty);
        await tester.pumpWidget(const SizedBox());
      },
    );
  });
}

TranslatorScreen screen(WidgetTester tester) =>
    tester.widget<TranslatorScreen>(find.byType(TranslatorScreen));

Future<void> settleServices(WidgetTester tester) async {
  // Drift's native executor completes outside the widget test's fake clock.
  for (var i = 0; i < 100; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump(const Duration(milliseconds: 20));
    if (!screen(tester).historyBusy &&
        !screen(tester).processing &&
        !screen(tester).ttsProcessing) {
      break;
    }
  }
}

class _TestAudioIo extends Fake implements AudioIo {
  final frames = StreamController<Uint8List>.broadcast();
  AudioIoConfig? startedConfig;

  @override
  Stream<Uint8List> get inputBytes => frames.stream;

  @override
  Future<void> startWith(AudioIoConfig config) async {
    startedConfig = config;
  }

  @override
  Future<void> stop() async {}

  @override
  void dispose() => unawaited(frames.close());
}
