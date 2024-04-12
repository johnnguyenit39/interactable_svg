import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../models/region.dart';
import '../size_controller.dart';

class RegionPainter extends CustomPainter {
  final Region region;
  final List<Region> selectedRegion;
  final Color? strokeColor;
  final Color? selectedColor;
  final Color? dotColor;
  final double? strokeWidth;
  final bool? centerDotEnable;
  final bool? centerTextEnable;
  final TextStyle? centerTextStyle;
  final String? unSelectableId;
  final ui.Image? pinIcon; // Thêm thuộc tính để lưu trữ biểu tượng pin map

  final sizeController = SizeController.instance;

  double _scale = 1.0;

  RegionPainter({
    required this.region,
    required this.selectedRegion,
    this.selectedColor,
    this.strokeColor,
    this.dotColor,
    this.centerDotEnable,
    this.centerTextEnable,
    this.centerTextStyle,
    this.strokeWidth,
    this.unSelectableId,
    this.pinIcon, // Thêm tham số để truyền biểu tượng pin map vào
  });

  @override
  void paint(Canvas canvas, Size size) {
    final pen = Paint()
      ..color = strokeColor ?? Colors.black45
      ..strokeWidth = strokeWidth ?? 1.0
      ..style = PaintingStyle.stroke;

    final selectedPen = Paint()
      ..color = selectedColor ?? Colors.blue
      ..strokeWidth = 1.0
      ..style = PaintingStyle.fill;

    final redDot = Paint()
      ..color = dotColor ?? Colors.red
      ..strokeWidth = 3.0
      ..style = PaintingStyle.fill;

    final bounds = region.path.getBounds();

    _scale = sizeController.calculateScale(size);
    canvas.scale(_scale);

    if (selectedRegion.contains(region)) {
      canvas.drawPath(region.path, selectedPen);
    }
    canvas.drawPath(region.path, pen);

    if (pinIcon != null && selectedRegion.contains(region)) {
      final iconOffset = Offset(bounds.center.dx - pinIcon!.width / 2,
          bounds.center.dy - pinIcon!.height);
      canvas.drawImage(pinIcon!, iconOffset, Paint());
    }
    if ((centerDotEnable ?? false) && region.id != unSelectableId) {
      canvas.drawCircle(bounds.center, 3.0, redDot);
    }
    if ((centerTextEnable ?? false) && region.id != unSelectableId) {
      TextSpan span = TextSpan(
          style: centerTextStyle ?? const TextStyle(color: Colors.black),
          text: region.name);
      TextPainter tp = TextPainter(
        text: span,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );
      tp.layout();
      tp.paint(canvas, bounds.center);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;

  @override
  bool hitTest(Offset position) {
    double inverseScale = sizeController.inverseOfScale(_scale);
    return region.path.contains(position.scale(inverseScale, inverseScale));
  }
}
