import 'package:flutter/material.dart';
import '../models/stroke.dart';
import '../models/shape.dart';
import '../models/text_item.dart';

class DrawingCanvas extends StatelessWidget {
  final List<Stroke> strokes;
  final List<Shape> shapes;
  final List<TextItem> texts;

  const DrawingCanvas({
    super.key,
    required this.strokes,
    required this.shapes,
    required this.texts,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _CanvasPainter(
        strokes: strokes,
        shapes: shapes,
        texts: texts,
      ),
      size: Size.infinite,
    );
  }
}

class _CanvasPainter extends CustomPainter {
  final List<Stroke> strokes;
  final List<Shape> shapes;
  final List<TextItem> texts;

  _CanvasPainter({
    required this.strokes,
    required this.shapes,
    required this.texts,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (var stroke in strokes) {
      final paint = Paint()
        ..color = stroke.color
        ..strokeWidth = stroke.width
        ..strokeCap = StrokeCap.round;

      for (int i = 0; i < stroke.points.length - 1; i++) {
        canvas.drawLine(stroke.points[i], stroke.points[i + 1], paint);
      }
    }

    for (var shape in shapes) {
      final paint = Paint()
        ..color = shape.color
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;

      final rect = Rect.fromPoints(shape.start, shape.end);
      switch (shape.type) {
        case 'rectangle':
          canvas.drawRect(rect, paint);
          break;
        case 'circle':
          canvas.drawOval(rect, paint);
          break;
        case 'line':
          canvas.drawLine(shape.start, shape.end, paint);
          break;
      }
    }

    for (var text in texts) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: text.text,
          style: TextStyle(color: text.color, fontSize: text.size),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, text.position);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
