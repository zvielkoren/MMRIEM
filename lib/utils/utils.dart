import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class AppUtils {
  static Future<String> getDeviceId() async {
    final deviceInfo = DeviceInfoPlugin();
    if (defaultTargetPlatform == TargetPlatform.android) {
      final androidInfo = await deviceInfo.androidInfo;
      return androidInfo.id;
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      final iosInfo = await deviceInfo.iosInfo;
      return iosInfo.identifierForVendor ?? '';
    }
    return '';
  }

  static Future<String> getAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version;
  }

  static Future<bool> isConnected() async {
    final connectivity = await Connectivity().checkConnectivity();
    return connectivity != ConnectivityResult.none;
  }

  static String formatPhoneNumber(String phoneNumber) {
    // Remove all non-digit characters
    final digits = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');

    // If the number already has the country code, return as is
    if (digits.startsWith('972')) {
      return digits;
    }

    // Add country code for Israeli numbers
    if (digits.startsWith('0') || digits.length == 9 || digits.length == 10) {
      return '972${digits.startsWith('0') ? digits.substring(1) : digits}';
    }

    return digits;
  }

  static String formatPhoneInput(String input) {
    // Remove all non-digit characters except the first 0
    final firstChar = input.isNotEmpty ? input[0] : '';
    final rest = input.length > 1
        ? input.substring(1).replaceAll(RegExp(r'[^0-9]'), '')
        : '';
    final digits = firstChar == '0' ? '0$rest' : rest;

    // Return only digits
    return digits;
  }
}
