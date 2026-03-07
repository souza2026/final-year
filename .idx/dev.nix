{ pkgs, ... }:
{
  channel = "stable-23.11";

  packages = [
    pkgs.flutter
    pkgs.dart
    pkgs.nodejs_20
    pkgs.firebase-tools
    pkgs.chromium
    pkgs.android-sdk
    pkgs.android-sdk-cmdline-tools
    pkgs.android-emulator-unwrapped
  ];

  env = {
    CHROME_EXECUTABLE = "${pkgs.chromium}/bin/chromium-browser";
    ANDROID_HOME = "${pkgs.android-sdk}/share/android-sdk";
    ACCEPT_LICENSES = "y";
  };
}
