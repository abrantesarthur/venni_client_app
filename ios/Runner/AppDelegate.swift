import UIKit
import Flutter
import GoogleMaps
// import Firebase

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GMSServices.provideAPIKey("AIzaSyC2U3XE3TOXBFoYBbZjdWyKpbXVD395Pa8")
    GeneratedPluginRegistrant.register(with: self)
    // FirebaseApp.configure()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
