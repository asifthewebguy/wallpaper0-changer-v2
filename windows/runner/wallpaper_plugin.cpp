#include "wallpaper_plugin.h"

#include <windows.h>
#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>
#include <memory>
#include <string>

// static
void WallpaperPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows* registrar) {
  auto plugin = std::make_unique<WallpaperPlugin>();

  plugin->wallpaper_channel_ =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          registrar->messenger(), "wallpaper_changer/wallpaper",
          &flutter::StandardMethodCodec::GetInstance());

  plugin->protocol_channel_ =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          registrar->messenger(), "wallpaper_changer/protocol",
          &flutter::StandardMethodCodec::GetInstance());

  WallpaperPlugin* plugin_ptr = plugin.get();

  plugin->wallpaper_channel_->SetMethodCallHandler(
      [plugin_ptr](const auto& call, auto result) {
        plugin_ptr->HandleWallpaperChannel(call, std::move(result));
      });

  plugin->protocol_channel_->SetMethodCallHandler(
      [plugin_ptr](const auto& call, auto result) {
        plugin_ptr->HandleProtocolChannel(call, std::move(result));
      });

  registrar->AddPlugin(std::move(plugin));
}

WallpaperPlugin::WallpaperPlugin() {}
WallpaperPlugin::~WallpaperPlugin() {}

void WallpaperPlugin::HandleWallpaperChannel(
    const flutter::MethodCall<flutter::EncodableValue>& call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  if (call.method_name() == "setWallpaper") {
    const auto* path_value = std::get_if<std::string>(call.arguments());
    if (!path_value) {
      result->Error("INVALID_ARGS", "Expected a String path");
      return;
    }

    // Convert UTF-8 path to wide string for Win32 API
    int wlen = MultiByteToWideChar(CP_UTF8, 0, path_value->c_str(), -1,
                                   nullptr, 0);
    std::wstring wpath(wlen, 0);
    MultiByteToWideChar(CP_UTF8, 0, path_value->c_str(), -1,
                        wpath.data(), wlen);
    // MultiByteToWideChar with -1 includes NUL in count; trim it.
    if (!wpath.empty() && wpath.back() == L'\0') {
      wpath.pop_back();
    }

    BOOL ok = SystemParametersInfoW(
        SPI_SETDESKWALLPAPER, 0,
        static_cast<PVOID>(wpath.data()),
        SPIF_UPDATEINIFILE | SPIF_SENDCHANGE);

    if (!ok) {
      DWORD err = GetLastError();
      result->Success(flutter::EncodableValue(
          std::string("SystemParametersInfoW failed: ") +
          std::to_string(err)));
    } else {
      result->Success(flutter::EncodableValue());  // null = success
    }
  } else {
    result->NotImplemented();
  }
}

void WallpaperPlugin::HandleProtocolChannel(
    const flutter::MethodCall<flutter::EncodableValue>& call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  if (call.method_name() == "register") {
    // Get the path to this executable
    wchar_t exe_path[MAX_PATH];
    DWORD path_len = GetModuleFileNameW(nullptr, exe_path, MAX_PATH);
    if (path_len == 0 ||
        (path_len == MAX_PATH &&
         GetLastError() == ERROR_INSUFFICIENT_BUFFER)) {
      result->Success(flutter::EncodableValue(
          std::string("GetModuleFileNameW failed: ") +
          std::to_string(GetLastError())));
      return;
    }

    // Command string: "<exe_path>" "%1"
    std::wstring cmd =
        std::wstring(L"\"") + exe_path + L"\" \"%1\"";

    const wchar_t* kBase =
        L"Software\\Classes\\wallpaper0-changer";

    // --- Write base key ---
    HKEY hKey;
    LSTATUS s = RegCreateKeyExW(
        HKEY_CURRENT_USER, kBase, 0, nullptr,
        REG_OPTION_NON_VOLATILE, KEY_SET_VALUE, nullptr, &hKey, nullptr);
    if (s != ERROR_SUCCESS) {
      result->Success(flutter::EncodableValue(
          std::string("RegCreateKeyExW failed: ") + std::to_string(s)));
      return;
    }

    const wchar_t* kDesc = L"URL:wallpaper0-changer Protocol";
    LSTATUS sv = RegSetValueExW(
        hKey, L"", 0, REG_SZ,
        reinterpret_cast<const BYTE*>(kDesc),
        (static_cast<DWORD>(wcslen(kDesc)) + 1) * sizeof(wchar_t));
    if (sv != ERROR_SUCCESS) {
      RegCloseKey(hKey);
      result->Success(flutter::EncodableValue(
          std::string("RegSetValueExW (default) failed: ") +
          std::to_string(sv)));
      return;
    }
    sv = RegSetValueExW(hKey, L"URL Protocol", 0, REG_SZ,
                        reinterpret_cast<const BYTE*>(L""), sizeof(wchar_t));
    if (sv != ERROR_SUCCESS) {
      RegCloseKey(hKey);
      result->Success(flutter::EncodableValue(
          std::string("RegSetValueExW (url protocol) failed: ") +
          std::to_string(sv)));
      return;
    }
    RegCloseKey(hKey);

    // --- Write shell\open\command key ---
    std::wstring cmd_key_path =
        std::wstring(kBase) + L"\\shell\\open\\command";
    s = RegCreateKeyExW(
        HKEY_CURRENT_USER, cmd_key_path.c_str(), 0, nullptr,
        REG_OPTION_NON_VOLATILE, KEY_SET_VALUE, nullptr, &hKey, nullptr);
    if (s != ERROR_SUCCESS) {
      result->Success(flutter::EncodableValue(
          std::string("RegCreateKeyExW (command) failed: ") +
          std::to_string(s)));
      return;
    }

    sv = RegSetValueExW(
        hKey, L"", 0, REG_SZ,
        reinterpret_cast<const BYTE*>(cmd.c_str()),
        (static_cast<DWORD>(cmd.size()) + 1) * sizeof(wchar_t));
    if (sv != ERROR_SUCCESS) {
      RegCloseKey(hKey);
      result->Success(flutter::EncodableValue(
          std::string("RegSetValueExW (command) failed: ") +
          std::to_string(sv)));
      return;
    }
    RegCloseKey(hKey);

    result->Success(flutter::EncodableValue());  // null = success
  } else {
    result->NotImplemented();
  }
}
