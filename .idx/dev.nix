# Firebase Studio / Project IDX environment for Promofy.
# Open this repo at https://idx.google.com (or studio.firebase.google.com),
# then use the Android preview to run the Flutter app live in the cloud —
# no local Gradle, so it sidesteps the local loopback build wall.
{ pkgs, ... }: {
  # Nixpkgs channel.
  channel = "stable-24.05";

  # Tools available in the workspace.
  packages = [
    pkgs.flutter
    pkgs.jdk17
  ];

  # Environment variables.
  env = { };

  idx = {
    # VS Code extensions (from the Open VSX registry).
    extensions = [
      "Dart-Code.flutter"
      "Dart-Code.dart-code"
    ];

    # One-time + every-start hooks.
    workspace = {
      onCreate = {
        # Fetch packages for the Flutter app (it lives in ./mobile).
        flutter-pub-get = "cd mobile && flutter pub get";
        # Open the consumer home screen by default.
        default.openFiles = [ "mobile/lib/screens/consumer/home_screen.dart" ];
      };
      onStart = {
        flutter-pub-get = "cd mobile && flutter pub get";
      };
    };

    # Live previews.
    previews = {
      enable = true;
      previews = {
        # Android emulator preview — the one that works for this app
        # (Google Maps / Firebase / mobile_scanner don't support Flutter web).
        android = {
          command = [
            "flutter"
            "run"
            "--machine"
            "-d"
            "android"
            "-d"
            "emulator-5554"
          ];
          manager = "flutter";
          cwd = "mobile";
        };
      };
    };
  };
}
