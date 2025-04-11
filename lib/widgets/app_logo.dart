import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? accentColor;

  const AppLogo({
    super.key,
    this.size = 100,
    this.backgroundColor,
    this.foregroundColor,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = backgroundColor ?? theme.colorScheme.primary;
    final fgColor = foregroundColor ?? theme.colorScheme.onPrimary;
    final accent = accentColor ?? theme.colorScheme.secondary;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: bgColor.withOpacity(0.5),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Rupee Symbol
          CustomPaint(
            size: Size(size * 0.6, size * 0.6),
            painter: RupeePainter(
              color: fgColor,
              strokeWidth: size * 0.05,
            ),
          ),
          
          // Graph line
          Positioned(
            bottom: size * 0.22,
            left: size * 0.25,
            child: CustomPaint(
              size: Size(size * 0.5, size * 0.15),
              painter: GraphLinePainter(
                color: fgColor.withOpacity(0.7),
                strokeWidth: size * 0.025,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class RupeePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  RupeePainter({
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Draw the rupee symbol
    final path = Path()
      // Horizontal line at top
      ..moveTo(size.width * 0.3, size.height * 0.2)
      ..lineTo(size.width * 0.7, size.height * 0.2)
      
      // Vertical line
      ..moveTo(size.width * 0.5, size.height * 0.2)
      ..lineTo(size.width * 0.5, size.height * 0.75)
      
      // Middle horizontal line
      ..moveTo(size.width * 0.3, size.height * 0.4)
      ..lineTo(size.width * 0.7, size.height * 0.4)
      
      // Diagonal line
      ..moveTo(size.width * 0.3, size.height * 0.4)
      ..lineTo(size.width * 0.7, size.height * 0.75);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class GraphLinePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  GraphLinePainter({
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Draw a simple graph line
    final path = Path()
      ..moveTo(0, size.height * 0.6)
      ..lineTo(size.width * 0.3, size.height * 0.8)
      ..lineTo(size.width * 0.7, size.height * 0.2)
      ..lineTo(size.width, size.height * 0.4);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
} 