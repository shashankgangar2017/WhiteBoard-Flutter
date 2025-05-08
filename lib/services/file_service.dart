import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../models/shape.dart';
import '../models/stroke.dart';
import '../models/text_item.dart';
import 'package:file_picker/file_picker.dart';

class FileService {

  // Save file to internal storage (Androidsafe)
  static Future<void> saveToFile({
    required BuildContext context,
    required List<Stroke> strokes,
    required List<Shape> shapes,
    required List<TextItem> texts,
  }) async {
      final jsonData = jsonEncode({
        'strokes': strokes.map((e) => e.toJson()).toList(),
        'shapes': shapes.map((e) => e.toJson()).toList(),
        'texts': texts.map((e) => e.toJson()).toList(),
      });

    try {
      final dir = await getApplicationDocumentsDirectory();
      final fileName = 'whiteboard_${DateTime.now().toIso8601String().replaceAll(RegExp(r'[:.-]'), '')}.json';
      final filePath = '${dir.path}/$fileName';

      final file = File(filePath);
      await file.writeAsString(jsonData);

    } catch (e) {
      if (context.mounted) {
        debugPrint('Save failed: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: $e')),
        );
      }
    }
  }


  static Future<Map<String, dynamic>> loadFromFile(String fileName) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$fileName');
    final content = await file.readAsString();
    return jsonDecode(content);
  }

}
