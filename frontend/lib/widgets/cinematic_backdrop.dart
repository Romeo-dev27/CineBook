import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CinematicBackdrop extends StatelessWidget {
  final Widget child;

  const CinematicBackdrop({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: context.cineColors.background,
      child: child,
    );
  }
}
