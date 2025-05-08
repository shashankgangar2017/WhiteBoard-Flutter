import 'package:flutter/material.dart';

class Shape {
  String type; // 'rectangle', 'circle', 'line'
  Offset start;
  Offset end;
  Color color;

  Shape({
    required this.type,
    required this.start,
    required this.end,
    required this.color,
});

  Map<String, dynamic> toJson() => {
    'type': type,
    'start': {'dx': start.dx, 'dy': start.dy},
    'end': {'dx': end.dx, 'dy': end.dy},
    'color': color.value,
  };

  factory Shape.fromJson(Map<String, dynamic> json) => Shape(
    type: json['type'],
    start: Offset(json['start']['dx'], json['start']['dy']),
    end: Offset(json['end']['dx'], json['end']['dy']),
    color: Color(json['color']),
  );
}
