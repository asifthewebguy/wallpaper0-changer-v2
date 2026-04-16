#ifndef RUNNER_WALLPAPER_PLUGIN_H_
#define RUNNER_WALLPAPER_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>
#include <memory>

class WallpaperPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(
      flutter::PluginRegistrarWindows* registrar);

  explicit WallpaperPlugin();
  ~WallpaperPlugin() override;

 private:
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>>
      wallpaper_channel_;
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>>
      protocol_channel_;

  void HandleWallpaperChannel(
      const flutter::MethodCall<flutter::EncodableValue>& call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  void HandleProtocolChannel(
      const flutter::MethodCall<flutter::EncodableValue>& call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

#endif  // RUNNER_WALLPAPER_PLUGIN_H_
