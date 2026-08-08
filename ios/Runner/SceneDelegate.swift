import Flutter
import UIKit

class SceneDelegate: FlutterSceneDelegate {
  override func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    guard
      let appDelegate = UIApplication.shared.delegate as? AppDelegate,
      let windowScene = scene as? UIWindowScene
    else {
      super.scene(scene, willConnectTo: session, options: connectionOptions)
      return
    }

    let window = UIWindow(windowScene: windowScene)
    let viewController = FlutterViewController(
      engine: appDelegate.flutterEngine,
      nibName: nil,
      bundle: nil
    )
    window.rootViewController = viewController
    self.window = window
    window.makeKeyAndVisible()

    super.scene(scene, willConnectTo: session, options: connectionOptions)
  }
}
