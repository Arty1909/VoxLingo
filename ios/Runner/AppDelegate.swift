import AVFoundation
import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    requestMicrophonePermission()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func requestMicrophonePermission() {
    if #available(iOS 17.0, *) {
      AVAudioApplication.requestRecordPermission { _ in }
    } else {
      AVAudioSession.sharedInstance().requestRecordPermission { _ in }
    }
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
