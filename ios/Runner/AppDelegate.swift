import Flutter
import UIKit
import UserNotifications
import WidgetKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
    }

    GeneratedPluginRegistrant.register(with: self)

    // Keychain-backed bridge for the home-screen widget. UserDefaults app-group
    // sharing doesn't survive iLoader's re-sign on free certs; the keychain
    // route does.
    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(
        name: "loopify/widget",
        binaryMessenger: controller.binaryMessenger
      )
      channel.setMethodCallHandler { call, result in
        guard call.method == "sync",
              let args = call.arguments as? [String: Any] else {
          result(FlutterMethodNotImplemented)
          return
        }
        if let v = args["streak"] as? Int {
          WidgetKeychainStore.setInt(v, forKey: "streak")
        }
        if let v = args["habits_completed"] as? Int {
          WidgetKeychainStore.setInt(v, forKey: "habits_completed")
        }
        if let v = args["quip"] as? String {
          WidgetKeychainStore.setString(v, forKey: "quip")
        }
        if let v = args["image"] as? String {
          WidgetKeychainStore.setString(v, forKey: "image")
        }
        if let v = args["last_update"] as? String {
          WidgetKeychainStore.setString(v, forKey: "last_update")
        }
        if #available(iOS 14.0, *) {
          WidgetCenter.shared.reloadTimelines(ofKind: "LoopifyWidget")
        }
        result(true)
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
