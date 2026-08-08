import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  /// Explicit engine avoids iOS 26 ProMotion VSyncClient crash during implicit
  /// FlutterViewController.viewDidLoad (platformTaskRunner null before shell).
  lazy var flutterEngine = FlutterEngine(name: "Atlas")

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    flutterEngine.run()
    GeneratedPluginRegistrant.register(with: flutterEngine)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
