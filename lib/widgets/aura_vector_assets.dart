import 'dart:math' as math;
import 'package:flutter/material.dart';

/// නිල් පාට "A" + Film Strip Logo එක (Shorebird patch-safe)
class AuraBlueLogo extends StatelessWidget {
  final double size;
  const AuraBlueLogo({super.key, this.size = 36});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _AuraBlueLogoPainter(),
    );
  }
}

class _AuraBlueLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Left leg of "A" (Deep Royal Blue)
    final leftLeg = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF0A2A9C), Color(0xFF0E5AE0)],
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.20
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final leftPath = Path()
      ..moveTo(w * 0.25, h * 0.84)
      ..lineTo(w * 0.48, h * 0.18);
    canvas.drawPath(leftPath, leftLeg);

    // 2. Right leg + rounded peak of "A" (Electric Blue -> Cyan)
    final rightLeg = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF0077FF), Color(0xFF00D2E6)],
        begin: Alignment.topCenter,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.20
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final archPath = Path()
      ..moveTo(w * 0.42, h * 0.28)
      ..quadraticBezierTo(w * 0.50, h * 0.08, w * 0.58, h * 0.28)
      ..lineTo(w * 0.77, h * 0.84);
    canvas.drawPath(archPath, rightLeg);

    // 3. Curved Film Strip Band wrapping around "A"
    final filmPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF0B2C9E), Color(0xFF0088FF), Color(0xFF00DCE8)],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(Rect.fromLTWH(0, h * 0.35, w, h * 0.45))
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.16
      ..strokeCap = StrokeCap.round;

    final filmCurve = Path()
      ..moveTo(w * 0.13, h * 0.65)
      ..quadraticBezierTo(w * 0.54, h * 0.78, w * 0.86, h * 0.44);
    canvas.drawPath(filmCurve, filmPaint);

    // 4. White Sprocket Holes on Film Strip
    final holePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final metrics = filmCurve.computeMetrics().first;
    final length = metrics.length;
    const int holeCount = 7;

    for (int i = 1; i <= holeCount; i++) {
      final distance = length * (i / (holeCount + 1));
      final tangent = metrics.getTangentForOffset(distance);
      if (tangent == null) continue;

      final pos = tangent.position;
      final angle = tangent.angle;
      final normal = Offset(-math.sin(angle), math.cos(angle));
      final offsetDist = w * 0.048;

      for (final sign in [-1.0, 1.0]) {
        final holeCenter = pos + normal * (offsetDist * sign);
        canvas.save();
        canvas.translate(holeCenter.dx, holeCenter.dy);
        canvas.rotate(-angle);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset.zero,
              width: w * 0.045,
              height: w * 0.028,
            ),
            const Radius.circular(0.8),
          ),
          holePaint,
        );
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Sun / Moon Theme Toggle Icon (Patch-safe)
class AuraThemeIcon extends StatelessWidget {
  final bool isDarkMode;
  final Color color;
  final double size;

  const AuraThemeIcon({
    super.key,
    required this.isDarkMode,
    required this.color,
    this.size = 20,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _ThemeIconPainter(isDarkMode: isDarkMode, color: color),
    );
  }
}

class _ThemeIconPainter extends CustomPainter {
  final bool isDarkMode;
  final Color color;

  _ThemeIconPainter({required this.isDarkMode, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.9
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);

    if (isDarkMode) {
      final radius = size.width * 0.22;
      canvas.drawCircle(center, radius, paint..style = PaintingStyle.fill);
      paint.style = PaintingStyle.stroke;
      for (int i = 0; i < 8; i++) {
        final angle = i * math.pi / 4;
        final start = Offset(
          center.dx + (radius + 2.8) * math.cos(angle),
          center.dy + (radius + 2.8) * math.sin(angle),
        );
        final end = Offset(
          center.dx + (radius + 5.5) * math.cos(angle),
          center.dy + (radius + 5.5) * math.sin(angle),
        );
        canvas.drawLine(start, end, paint);
      }
    } else {
      final moon = Path()
        ..addOval(Rect.fromCircle(center: center, radius: size.width * 0.36));
      final cut = Path()
        ..addOval(Rect.fromCircle(
          center: Offset(
            center.dx + size.width * 0.16,
            center.dy - size.height * 0.14,
          ),
          radius: size.width * 0.30,
        ));
      canvas.drawPath(
        Path.combine(PathOperation.difference, moon, cut),
        paint..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ThemeIconPainter oldDelegate) =>
      oldDelegate.isDarkMode != isDarkMode || oldDelegate.color != color;
}

/// Circular Info (i) Icon (Patch-safe)
class AuraInfoIcon extends StatelessWidget {
  final Color color;
  final double size;

  const AuraInfoIcon({super.key, required this.color, this.size = 24});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _InfoIconPainter(color),
    );
  }
}

class _InfoIconPainter extends CustomPainter {
  final Color color;
  _InfoIconPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;

    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final c = Offset(size.width / 2, size.height / 2);
    canvas.drawCircle(c, size.width * 0.42, stroke);
    canvas.drawCircle(Offset(c.dx, size.height * 0.33), size.width * 0.055, fill);
    canvas.drawLine(
      Offset(c.dx, size.height * 0.47),
      Offset(c.dx, size.height * 0.69),
      stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _InfoIconPainter oldDelegate) =>
      oldDelegate.color != color;
}