import 'dart:io';

import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

class PermissionService {
  static Future<bool> requestStoragePermissions() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await DeviceInfoPlugin().androidInfo;

        if (androidInfo.version.sdkInt >= 33) {
          // Android 13+ needs different permissions
          final photos = await Permission.photos.status;
          final media = await Permission.mediaLibrary.status;

          if (!photos.isGranted || !media.isGranted) {
            final result = await [
              Permission.photos,
              Permission.mediaLibrary,
            ].request();

            return result[Permission.photos]?.isGranted == true &&
                result[Permission.mediaLibrary]?.isGranted == true;
          }
          return true;
        } else {
          // Android 10-12
          final status = await Permission.storage.status;
          if (!status.isGranted) {
            final result = await Permission.storage.request();
            return result.isGranted;
          }
          return true;
        }
      }
      return true; // iOS doesn't need storage permissions for this
    } on PlatformException catch (e) {
      print("Permission error: $e");
      return false;
    }
  }

  static Future<bool> hasStoragePermissions() async {
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;

      if (androidInfo.version.sdkInt >= 33) {
        return await Permission.photos.isGranted &&
            await Permission.mediaLibrary.isGranted;
      } else {
        return await Permission.storage.isGranted;
      }
    }
    return true;
  }
}