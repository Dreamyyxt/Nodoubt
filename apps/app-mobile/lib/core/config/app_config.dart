import 'package:flutter/foundation.dart';

class AppConfig {
  static String get defaultBaseUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:3000/api/v1';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:3000/api/v1';
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
      case TargetPlatform.fuchsia:
        return 'http://127.0.0.1:3000/api/v1';
    }
  }
}
