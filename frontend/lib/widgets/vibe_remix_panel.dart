import 'package:flutter/material.dart';
import '../models/recommendation.dart';
import '../theme/app_theme.dart';

/// Panneau « Vibe Remix » : 3 curseurs temps réel pilotant la pondération existante.
///
/// Positions par défaut : Ambiance 0.5, Rythme 0.5, Pépites 0.3.
/// Elles reproduisent exactement les poids CineBook par défaut
/// (atmosphere 1.5, visual 1.2, pacing 0.8, discovery 0.3) :
/// sans interaction, les recommandations sont identiques à celles du moteur actuel.
class VibeRemixPanel extends StatelessWidget {
  final RecommendationWeights weights;
  final double alpha;
  final ValueChanged<RecommendationWeights> onWeightsChanged;
  final ValueChanged<double> onAlphaChanged;

  const VibeRemixPanel({
    super.key,
    required this.weights,
    required this.alpha,
    required this.onWeightsChanged,
    required this.onAlphaChanged,
  });

  // t=0.5 -> facteur 1.0 -> poids par défaut inchangés.
  static const double _minFactor = 0.4;
  static const double _factorRange = 1.2;

  static double _factor(double t) => _minFactor + _factorRange * t;

  static double _position(double weight, double baseWeight) {
    if (baseWeight <= 0) return 0.5;
    return ((weight / baseWeight - _minFactor) / _factorRange).clamp(0.0, 1.0);
  }

  void _reset() {
    onWeightsChanged(RecommendationWeights.equilibre);
    onAlphaChanged(0.3);
  }

  @override
  Widget build(BuildContext context) {
    const defaults = RecommendationWeights.equilibre;
    final mood = _position(weights.atmosphere, defaults.atmosphere);
    final rythme = _position(weights.pacing, defaults.pacing);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.gold.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: AppTheme.gold, size: 18),
              const SizedBox(width: 8),
              const Text(
                'Vibe Remix',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.gold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'TEMPS RÉEL',
                  style: TextStyle(
                    color: AppTheme.gold,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const Spacer(),
              TextButton.icon(
                icon: const Icon(Icons.refresh, size: 14, color: AppTheme.textMuted),
                label: const Text(
                  'Réinitialiser',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                ),
                onPressed: _reset,
              ),
            ],
          ),
          const Text(
            'Ajustez la vibe : les recommandations se recalculent automatiquement.',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
          ),
          const SizedBox(height: 8),
          _buildSlider(
            label: 'Ambiance / Sombre',
            icon: Icons.nights_stay_outlined,
            color: AppTheme.purple,
            value: mood,
            badge: '${(_factor(mood) * 100).round()}%',
            leftLabel: 'Léger',
            rightLabel: 'Sombre',
            onChanged: (t) {
              final f = _factor(t);
              onWeightsChanged(weights.copyWith(
                atmosphere: defaults.atmosphere * f,
                visual: defaults.visual * f,
              ));
            },
          ),
          _buildSlider(
            label: 'Rythme',
            icon: Icons.speed,
            color: Colors.orangeAccent,
            value: rythme,
            badge: '${(_factor(rythme) * 100).round()}%',
            leftLabel: 'Calme',
            rightLabel: 'Nerveux',
            onChanged: (t) {
              onWeightsChanged(weights.copyWith(
                pacing: defaults.pacing * _factor(t),
              ));
            },
          ),
          _buildSlider(
            label: 'Pépites cachées / Mainstream',
            icon: Icons.diamond_outlined,
            color: AppTheme.cyan,
            value: alpha.clamp(0.0, 1.0),
            badge: '${(alpha * 100).round()}%',
            leftLabel: 'Mainstream',
            rightLabel: 'Pépites',
            onChanged: onAlphaChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildSlider({
    required String label,
    required IconData icon,
    required Color color,
    required double value,
    required String badge,
    required String leftLabel,
    required String rightLabel,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: color,
              thumbColor: color,
              overlayColor: color.withValues(alpha: 0.15),
              inactiveTrackColor: AppTheme.surfaceElevated,
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            ),
            child: Slider(
              value: value,
              min: 0.0,
              max: 1.0,
              divisions: 20,
              onChanged: onChanged,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  leftLabel,
                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
                ),
                Text(
                  rightLabel,
                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}