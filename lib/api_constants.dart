import 'package:flutter/foundation.dart';

class ApiConstants {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://prog-mobile-api-pvzly8-035b36-132-145-196-104.sslip.io';
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://prog-mobile-api-pvzly8-035b36-132-145-196-104.sslip.io';
    } else {
      return 'http://prog-mobile-api-pvzly8-035b36-132-145-196-104.sslip.io';
    }
  }
}
