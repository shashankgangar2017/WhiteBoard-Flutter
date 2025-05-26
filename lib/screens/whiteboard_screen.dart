import 'dart:io';
import 'dart:ui' as ui;

import 'package:external_path/external_path.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/shape.dart';
import '../models/stroke.dart';
import '../models/text_item.dart';
import '../services/file_service.dart';
import '../widgets/drawing_canvas.dart';

enum Tool { pen, rectangle, circle, line, text }

class WhiteboardScreen extends StatefulWidget {
  final Map<String, dynamic>? loadedData;

  const WhiteboardScreen({super.key, this.loadedData});

  @override
  State<WhiteboardScreen> createState() => _WhiteboardScreenState();
}

class _WhiteboardScreenState extends State<WhiteboardScreen> {
  final GlobalKey _canvasKey = GlobalKey();

  List<Stroke> _strokes = [];
  List<Shape> _shapes = [];
  List<TextItem> _texts = [];

  final List<List<dynamic>> _undoStack = [];
  final List<List<dynamic>> _redoStack = [];

  Stroke? _currentStroke;
  Offset? _startShape;
  Offset? _endShape;

  Tool _selectedTool = Tool.pen;
  Color _selectedColor = Colors.black;

  @override
  void initState() {
    super.initState();
    if (widget.loadedData != null) {
      _loadFromJson(widget.loadedData!);
    }
  }

  void _loadFromJson(Map<String, dynamic> json) {
    if (json['strokes'] != null) {
      _strokes =
          (json['strokes'] as List).map((e) => Stroke.fromJson(e)).toList();
    }
    if (json['shapes'] != null) {
      _shapes = (json['shapes'] as List).map((e) => Shape.fromJson(e)).toList();
    }
    if (json['texts'] != null) {
      _texts =
          (json['texts'] as List).map((e) => TextItem.fromJson(e)).toList();
    }
  }

  void _saveUndoState() {
    _undoStack.add([
      List<Stroke>.from(_strokes),
      List<Shape>.from(_shapes),
      List<TextItem>.from(_texts)
    ]);
    _redoStack.clear();
  }

  void _undo() {
    if (_undoStack.isEmpty) return;
    _redoStack.add([
      List<Stroke>.from(_strokes),
      List<Shape>.from(_shapes),
      List<TextItem>.from(_texts)
    ]);
    final last = _undoStack.removeLast();
    setState(() {
      _strokes
        ..clear()
        ..addAll(last[0]);
      _shapes
        ..clear()
        ..addAll(last[1]);
      _texts
        ..clear()
        ..addAll(last[2]);
    });
  }

  void _redo() {
    if (_redoStack.isEmpty) return;
    _undoStack.add([
      List<Stroke>.from(_strokes),
      List<Shape>.from(_shapes),
      List<TextItem>.from(_texts)
    ]);
    final next = _redoStack.removeLast();
    setState(() {
      _strokes
        ..clear()
        ..addAll(next[0]);
      _shapes
        ..clear()
        ..addAll(next[1]);
      _texts
        ..clear()
        ..addAll(next[2]);
    });
  }

  Future<void> _exportAsImage() async {
    try {
      final status = await Permission.manageExternalStorage.request();
      if (!status.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Storage permission not granted')),
        );
        return;
      }

      final boundary = _canvasKey.currentContext!.findRenderObject()
          as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      final path = await ExternalPath.getExternalStoragePublicDirectory(
          ExternalPath.DIRECTORY_PICTURES);
      final fileName =
          'whiteboard_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File('$path/$fileName');
      await file.writeAsBytes(pngBytes);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Exported as PNG:\n$fileName')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Whiteboard"),
        actions: [
          IconButton(icon: const Icon(Icons.undo), onPressed: _undo),
          IconButton(icon: const Icon(Icons.redo), onPressed: _redo),
          IconButton(icon: const Icon(Icons.save), onPressed: _save),
          IconButton(icon: const Icon(Icons.image), onPressed: _exportAsImage),
          PopupMenuButton<Color>(
            icon: Icon(Icons.color_lens, color: _selectedColor),
            onSelected: (color) => setState(() => _selectedColor = color),
            itemBuilder: (ctx) => [
              PopupMenuItem(
                  value: Colors.black, child: _colorDot(Colors.black)),
              PopupMenuItem(value: Colors.red, child: _colorDot(Colors.red)),
              PopupMenuItem(
                  value: Colors.green, child: _colorDot(Colors.green)),
              PopupMenuItem(value: Colors.blue, child: _colorDot(Colors.blue)),
              PopupMenuItem(
                  value: Colors.orange, child: _colorDot(Colors.orange)),
            ],
          ),
        ],
      ),
      body: GestureDetector(
        onPanStart: (details) {
          _saveUndoState();
          switch (_selectedTool) {
            case Tool.pen:
              _currentStroke =
                  Stroke(points: [], color: _selectedColor, width: 3.0);
              _currentStroke!.points.add(details.localPosition);
              break;
            case Tool.rectangle:
            case Tool.circle:
            case Tool.line:
              _startShape = details.localPosition;
              break;
            default:
              break;
          }
        },
        onPanUpdate: (details) {
          switch (_selectedTool) {
            case Tool.pen:
              setState(() {
                _currentStroke?.points.add(details.localPosition);
              });
              break;
            case Tool.rectangle:
            case Tool.circle:
            case Tool.line:
              setState(() {
                _endShape = details.localPosition;
              });
              break;
            default:
              break;
          }
        },
        onPanEnd: (_) {
          switch (_selectedTool) {
            case Tool.pen:
              if (_currentStroke != null) {
                setState(() {
                  _strokes.add(_currentStroke!);
                  _currentStroke = null;
                });
              }
              break;
            case Tool.rectangle:
            case Tool.circle:
            case Tool.line:
              if (_startShape != null && _endShape != null) {
                setState(() {
                  _shapes.add(Shape(
                    type: _selectedTool.name,
                    start: _startShape!,
                    end: _endShape!,
                    color: _selectedColor,
                  ));
                  _startShape = null;
                  _endShape = null;
                });
              }
              break;
            default:
              break;
          }
        },
        onDoubleTapDown: (details) {
          if (_selectedTool == Tool.text) {
            _showTextInput(details.localPosition);
          }
        },
        child: RepaintBoundary(
          key: _canvasKey,
          child: Stack(
            children: [
              DrawingCanvas(
                strokes: [
                  ..._strokes,
                  if (_currentStroke != null) _currentStroke!
                ],
                shapes: _shapes,
                texts: _texts,
              ),
              if (_startShape != null && _endShape != null)
                CustomPaint(
                  painter: _PreviewPainter(
                    type: _selectedTool.name,
                    start: _startShape!,
                    end: _endShape!,
                    color: _selectedColor,
                  ),
                ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: Tool.values.indexOf(_selectedTool),
        onTap: (index) => setState(() => _selectedTool = Tool.values[index]),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.edit), label: 'Pen'),
          BottomNavigationBarItem(
              icon: Icon(Icons.crop_square), label: 'Rectangle'),
          BottomNavigationBarItem(icon: Icon(Icons.circle), label: 'Circle'),
          BottomNavigationBarItem(icon: Icon(Icons.show_chart), label: 'Line'),
          BottomNavigationBarItem(icon: Icon(Icons.text_fields), label: 'Text'),
        ],
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  Widget _colorDot(Color color) => Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );

  void _showTextInput(Offset position) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Enter text"),
        content: TextField(controller: controller),
        actions: [
          TextButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty) {
                _saveUndoState();
                setState(() {
                  _texts.add(TextItem(
                    text: text,
                    position: position,
                    color: _selectedColor,
                    size: 20.0,
                  ));
                });
              }
              Navigator.of(ctx).pop();
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    await FileService.saveToFile(
      context: context,
      strokes: _strokes,
      shapes: _shapes,
      texts: _texts,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Saved successfully!")),
      );
    }
  }
}

class _PreviewPainter extends CustomPainter {
  final String type;
  final Offset start;
  final Offset end;
  final Color color;

  _PreviewPainter({
    required this.type,
    required this.start,
    required this.end,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final rect = Rect.fromPoints(start, end);
    switch (type) {
      case 'rectangle':
        canvas.drawRect(rect, paint);
        break;
      case 'circle':
        canvas.drawOval(rect, paint);
        break;
      case 'line':
        canvas.drawLine(start, end, paint);
        break;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
