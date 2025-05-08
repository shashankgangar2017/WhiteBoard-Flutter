import 'package:flutter/material.dart';

class TextItem {
  String text;
  Offset position;
  Color color;
  double size;

  TextItem({
    required this.text,
    required this.position,
    required this.color,
    required this.size,
  });

  Map<String, dynamic> toJson() => {
    'text': text,
    'position': {'dx': position.dx, 'dy': position.dy},
    'color': color.value,
    'size': size,
  };

  factory TextItem.fromJson(Map<String, dynamic> json) => TextItem(
    text: json['text'],
    position: Offset(json['position']['dx'], json['position']['dy']),
    color: Color(json['color']),
    size: json['size'],
  );
}
