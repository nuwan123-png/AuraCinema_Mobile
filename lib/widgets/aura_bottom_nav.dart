import 'package:flutter/material.dart';

class AuraBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final bool isDarkMode;

  const AuraBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.isDarkMode = true,
  });

  static const List<String> _labels = [
    'Home',
    'Movies',
    'Series',
    'Anime',
    'More',
  ];

  @override
  Widget build(BuildContext context) {
    const Color bgColor = Colors.white;
    const Color activeColor = Color(0xFF3B0F82);
    const Color inactiveColor = Color(0xFF4A4357);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
        child: Container(
          height: 68,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDarkMode ? 0.42 : 0.14),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_labels.length, (index) {
              final isSelected = currentIndex == index;
              final color = isSelected ? activeColor : inactiveColor;

              return Expanded(
                child: InkWell(
                  onTap: () => onTap(index),
                  borderRadius: BorderRadius.circular(22),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CustomPaint(
                        size: const Size(23, 23),
                        painter: _AuraNavIconPainter(
                          index: index,
                          isSelected: isSelected,
                          color: color,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _labels[index],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _AuraNavIconPainter extends CustomPainter {
  final int index;
  final bool isSelected;
  final Color color;

  _AuraNavIconPainter({
    required this.index,
    required this.isSelected,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final paint = Paint()
      ..color = color
      ..style = isSelected ? PaintingStyle.fill : PaintingStyle.stroke
      ..strokeWidth = 1.85
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    switch (index) {
      case 0: // Home
        final house = Path()
          ..moveTo(w * 0.50, h * 0.14)
          ..lineTo(w * 0.85, h * 0.44)
          ..lineTo(w * 0.85, h * 0.86)
          ..lineTo(w * 0.60, h * 0.86)
          ..lineTo(w * 0.60, h * 0.62)
          ..lineTo(w * 0.40, h * 0.62)
          ..lineTo(w * 0.40, h * 0.86)
          ..lineTo(w * 0.15, h * 0.86)
          ..lineTo(w * 0.15, h * 0.44)
          ..close();
        canvas.drawPath(house, paint);
        break;

      case 1: // Movies
        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.14, h * 0.20, w * 0.72, h * 0.62),
          const Radius.circular(4),
        );
        canvas.drawRRect(rect, paint);
        final linePaint = Paint()
          ..color = isSelected ? Colors.white : color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.65
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(
          Offset(w * 0.15, h * 0.39),
          Offset(w * 0.85, h * 0.39),
          linePaint,
        );
        canvas.drawLine(
          Offset(w * 0.36, h * 0.21),
          Offset(w * 0.29, h * 0.39),
          linePaint,
        );
        canvas.drawLine(
          Offset(w * 0.64, h * 0.21),
          Offset(w * 0.57, h * 0.39),
          linePaint,
        );
        break;

      case 2: // Series
        final tvRect = RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.12, h * 0.26, w * 0.76, h * 0.50),
          const Radius.circular(4),
        );
        canvas.drawRRect(tvRect, paint);
        final strokeOnly = Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.85
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(
          Offset(w * 0.36, h * 0.13),
          Offset(w * 0.50, h * 0.26),
          strokeOnly,
        );
        canvas.drawLine(
          Offset(w * 0.64, h * 0.13),
          Offset(w * 0.50, h * 0.26),
          strokeOnly,
        );
        canvas.drawLine(
          Offset(w * 0.34, h * 0.86),
          Offset(w * 0.66, h * 0.86),
          strokeOnly,
        );
        break;

      case 3: // Anime
        final star = Path()
          ..moveTo(w * 0.50, h * 0.12)
          ..quadraticBezierTo(w * 0.53, h * 0.47, w * 0.88, h * 0.50)
          ..quadraticBezierTo(w * 0.53, h * 0.53, w * 0.50, h * 0.88)
          ..quadraticBezierTo(w * 0.47, h * 0.53, w * 0.12, h * 0.50)
          ..quadraticBezierTo(w * 0.47, h * 0.47, w * 0.50, h * 0.12)
          ..close();
        canvas.drawPath(star, paint);
        break;

      case 4: // More
        final gap = w * 0.10;
        final box = (w * 0.72 - gap) / 2;
        final start = w * 0.14;
        for (int r = 0; r < 2; r++) {
          for (int c = 0; c < 2; c++) {
            canvas.drawRRect(
              RRect.fromRectAndRadius(
                Rect.fromLTWH(
                  start + c * (box + gap),
                  start + r * (box + gap),
                  box,
                  box,
                ),
                const Radius.circular(3.2),
              ),
              paint,
            );
          }
        }
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _AuraNavIconPainter oldDelegate) =>
      oldDelegate.index != index ||
      oldDelegate.isSelected != isSelected ||
      oldDelegate.color != color;
}