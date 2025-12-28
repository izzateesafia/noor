import Flutter
import UIKit
import WidgetKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    let widgetChannel = FlutterMethodChannel(name: "com.hexahelix.dq/widget",
                                              binaryMessenger: controller.binaryMessenger)
    
    widgetChannel.setMethodCallHandler({
      (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
      if call.method == "updatePrayerTimes" {
        if let args = call.arguments as? [String: Any] {
          // Use App Group UserDefaults to share data with widget
          let userDefaults = UserDefaults(suiteName: "group.com.hexahelix.dq")
          userDefaults?.set(args["fajr"], forKey: "fajr")
          userDefaults?.set(args["dhuhr"], forKey: "dhuhr")
          userDefaults?.set(args["asr"], forKey: "asr")
          userDefaults?.set(args["maghrib"], forKey: "maghrib")
          userDefaults?.set(args["isha"], forKey: "isha")
          userDefaults?.set(args["nextPrayer"], forKey: "nextPrayer")
          userDefaults?.set(args["location"], forKey: "location")
          
          // Reload widget timeline
          WidgetCenter.shared.reloadTimelines(ofKind: "PrayerTimesWidget")
          result(true)
        } else {
          result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
        }
      } else {
        result(FlutterMethodNotImplemented)
      }
    })
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
