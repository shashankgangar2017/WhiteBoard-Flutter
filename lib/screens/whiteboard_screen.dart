import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../models/stroke.dart';
import '../models/shape.dart';
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
  late List<Stroke> _strokes = [];
  late List<Shape> _shapes = [];
  late List<TextItem> _texts = [];
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

  //This method maps the json into the respective types.
  void _loadFromJson(Map<String, dynamic> json) {
    if (json['strokes'] != null) {
      _strokes = (json['strokes'] as List).map((e) => Stroke.fromJson(e)).toList();
    }
    if (json['shapes'] != null) {
      _shapes = (json['shapes'] as List).map((e) => Shape.fromJson(e)).toList();
    }
    if (json['texts'] != null) {
      _texts = (json['texts'] as List).map((e) => TextItem.fromJson(e)).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Whiteboard"),
        actions: [
          IconButton(icon: const Icon(Icons.save), onPressed: _save),
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
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Saved successfully!")));
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
