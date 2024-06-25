import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
// import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FileUtils {
  // List<String> fileList = List.empty(growable: true);

  static Future<List<String>> getFileList() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String>? files = prefs.getStringList('files');
    if (files != null) {
      return files;
    } else {
      return [];
    }
  }

  static Future<void> saveFileList(List<String> fileList) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('files', fileList);
  }

  static Future<String> get localPath async {
    final directory = await getApplicationDocumentsDirectory();

    return directory.path;
  }

  static Future<File> localFile(String fileName) async {
    final path = await localPath;
    return File('$path/$fileName');
  }

  static Future<String> getExternalDocumentPath() async {
    final plugin = DeviceInfoPlugin();
    final android = await plugin.androidInfo;
    // To check whether permission is given for this app or not.
    final status = android.version.sdkInt < 33
        ? await Permission.storage.request()
        : PermissionStatus.granted;

    if (!status.isGranted) {
      // If not we will ask for permission first
      await Permission.storage.request();
    }
    Directory _directory = Directory("");
    if (Platform.isAndroid) {
      // Redirects it to download folder in android
      _directory = Directory("/storage/emulated/0/Download");
    } else {
      _directory = await getApplicationDocumentsDirectory();
    }

    final exPath = _directory.path;
    await Directory(exPath).create(recursive: true);
    return exPath;
  }
}
