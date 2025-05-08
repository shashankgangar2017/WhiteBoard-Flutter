import 'package:flutter/material.dart';

class Stroke {
  List<Offset> points;
  Color color;
  double width;

  Stroke({required this.points, required this.color, required this.width});

  Map<String, dynamic> toJson() => {
    'points': points.map((e) => {'dx': e.dx, 'dy': e.dy}).toList(),
    'color': color.value,
    'width': width,
  };

  factory Stroke.fromJson(Map<String, dynamic> json) => Stroke(
    points: (json['points'] as List)
        .map((e) => Offset(e['dx'], e['dy']))
        .toList(),
    color: Color(json['color']),
    width: json['width'],
  );
}
