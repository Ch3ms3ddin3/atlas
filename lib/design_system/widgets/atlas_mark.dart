import 'package:flutter/material.dart';

import '../theme/atlas_colors.dart';

/// Marque Atlas — The Threshold (piliers, arche, point apex).
class AtlasMark extends StatelessWidget {
  const AtlasMark({
    super.key,
    this.size = 28,
    this.showApexDot = true,
  });

  final double size;
  final bool showApexDot;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _AtlasMarkPainter(showApexDot: showApexDot),
      ),
    );
  }
}

class _AtlasMarkPainter extends CustomPainter {
  const _AtlasMarkPainter({required this.showApexDot});

  final bool showApexDot;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 100;
    final stroke = Paint()
      ..color = AtlasColors.midnightBlue
      ..strokeWidth = 4 * scale
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    void line(double x1, double y1, double x2, double y2) {
      canvas.drawLine(
        Offset(x1 * scale, y1 * scale),
        Offset(x2 * scale, y2 * scale),
        stroke,
      );
    }

    line(32, 72, 32, 28);
    line(64, 72, 64, 28);

    final arch = Path()
      ..moveTo(36 * scale, 28 * scale)
      ..quadraticBezierTo(50 * scale, 16 * scale, 64 * scale, 28 * scale);
    canvas.drawPath(arch, stroke);

    if (showApexDot) {
      canvas.drawCircle(
        Offset(50 * scale, 14 * scale),
        2 * scale,
        Paint()..color = AtlasColors.terracotta,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _AtlasMarkPainter oldDelegate) {
    return oldDelegate.showApexDot != showApexDot;
  }
}
