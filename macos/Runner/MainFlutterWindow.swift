import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)
    WallpaperPlugin.register(
      with: flutterViewController.registrar(forPlugin: "WallpaperPlugin"))

    super.awakeFromNib()
  }
}

class WallpaperPlugin: NSObject, FlutterPlugin {
  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "wallpaper_changer/wallpaper",
      binaryMessenger: registrar.messenger
    )
    let instance = WallpaperPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard call.method == "setWallpaper" else {
      result(FlutterMethodNotImplemented)
      return
    }
    guard let path = call.arguments as? String else {
      result(FlutterError(code: "INVALID_ARGUMENT",
                          message: "Expected a String path",
                          details: nil))
      return
    }
    guard let screen = NSScreen.main else {
      result(FlutterError(code: "NO_SCREEN",
                          message: "No main screen available",
                          details: nil))
      return
    }
    let url = URL(fileURLWithPath: path)
    do {
      try NSWorkspace.shared.setDesktopImageURL(url, for: screen, options: [:])
      result(nil) // nil = success
    } catch {
      result(error.localizedDescription)
    }
  }
}
