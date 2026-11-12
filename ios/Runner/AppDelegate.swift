import Flutter
import UIKit
import FirebaseCore
import FirebaseMessaging
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // FirebaseApp.configure()
    // Clé Google Maps iOS (Club). Remplacez-la par votre clé Maps SDK for iOS.
    GMSServices.provideAPIKey("VOTRE_CLE_GOOGLE_MAPS_IOS")
    GeneratedPluginRegistrant.register(with: self)

    // Demande permission notifications iOS
    UNUserNotificationCenter.current().delegate = self
    application.registerForRemoteNotifications()

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}