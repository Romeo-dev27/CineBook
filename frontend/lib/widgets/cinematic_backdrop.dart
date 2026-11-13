import 'dart:math' as math;
import 'package:flutter/material.dart';

class CinematicBackdrop extends StatefulWidget {
  final Widget child;

  const CinematicBackdrop({super.key, required this.child});

  @override
  State<CinematicBackdrop> createState() => _CinematicBackdropState();
}

class _CinematicBackdropState extends State<CinematicBackdrop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 28),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF11131D),
                  Color(0xFF0C0E15),
                  Color(0xFF0C1219),
                ],
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: RepaintBoundary(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) =>
                    CustomPaint(painter: _AmbientSkyPainter(_controller.value)),
              ),
            ),
          ),
        ),
        const Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(painter: _CinemaTexturePainter()),
          ),
        ),
        widget.child,
      ],
    );
  }
}

class _AmbientSkyPainter extends CustomPainter {
  final double progress;

  const _AmbientSkyPainter(this.progress);

  void _glow(Canvas canvas, Offset center, double radius, Color color) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [color, color.withValues(alpha: 0)],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, paint);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final angle = progress * math.pi * 2;
    final longest = math.max(size.width, size.height);

    _glow(
      canvas,
      Offset(
        size.width * (0.08 + math.sin(angle) * 0.04),
        size.height * (0.12 + math.cos(angle) * 0.04),
      ),
      longest * 0.52,
      const Color(0x20E3AC52),
    );
    _glow(
      canvas,
      Offset(
        size.width * (0.90 + math.cos(angle) * 0.04),
        size.height * (0.72 + math.sin(angle) * 0.05),
      ),
      longest * 0.50,
      const Color(0x1462C6D4),
    );
    _glow(
      canvas,
      Offset(
        size.width * (0.58 + math.sin(angle + 2) * 0.06),
        size.height * (0.30 + math.cos(angle + 2) * 0.06),
      ),
      longest * 0.40,
      const Color(0x129A82D0),
    );
  }

  @override
  bool shouldRepaint(covariant _AmbientSkyPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _CinemaTexturePainter extends CustomPainter {
  const _CinemaTexturePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(2049);
    final paint = Paint()..color = const Color(0x08FFFFFF);
    for (var i = 0; i < 60; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      canvas.drawCircle(Offset(x, y), random.nextDouble() * 0.8 + 0.25, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
