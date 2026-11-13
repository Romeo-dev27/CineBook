import 'package:flutter/material.dart';
import '../models/recommendation.dart';
import '../theme/app_theme.dart';

class WeightSliders extends StatelessWidget {
  final RecommendationWeights weights;
  final double discoverySlider;
  final int topN;
  final ValueChanged<RecommendationWeights> onWeightsChanged;
  final ValueChanged<double> onDiscoveryChanged;
  final ValueChanged<int> onTopNChanged;

  const WeightSliders({
    super.key,
    required this.weights,
    required this.discoverySlider,
    required this.topN,
    required this.onWeightsChanged,
    required this.onDiscoveryChanged,
    required this.onTopNChanged,
  });

  String _getDiscoveryDescription(double val) {
    if (val < 0.15) return 'Populaires et blockbusters acceptés';
    if (val < 0.45) return 'Équilibre entre classiques et découvertes';
    if (val < 0.75) return 'Favorise activement les films méconnus';
    return 'Mode Pépite : priorité absolue aux trésors cachés';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.purple.withValues(alpha: 0.05),
            AppTheme.surface,
            AppTheme.cyan.withValues(alpha: 0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppTheme.gold.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(
                    color: AppTheme.gold.withValues(alpha: 0.22),
                  ),
                ),
                child: const Icon(
                  Icons.tune_rounded,
                  color: AppTheme.goldLight,
                  size: 19,
                ),
              ),
              const SizedBox(width: 11),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'RÉGIE DES SENSATIONS',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Cinq dimensions pour sculpter ta sélection',
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.refresh_rounded,
                  size: 19,
                  color: AppTheme.textMuted,
                ),
                tooltip: 'Réinitialiser les réglages',
                onPressed: () {
                  onWeightsChanged(RecommendationWeights.equilibre);
                  onDiscoveryChanged(0.3);
                },
              ),
            ],
          ),
          const SizedBox(height: 17),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildPresetChip(
                  label: 'Équilibré',
                  icon: Icons.balance,
                  isSelected:
                      weights.atmosphere == 1.5 && weights.visual == 1.2,
                  onTap: () =>
                      onWeightsChanged(RecommendationWeights.equilibre),
                ),
                const SizedBox(width: 8),
                _buildPresetChip(
                  label: 'Ambiance Pure',
                  icon: Icons.nights_stay,
                  isSelected: weights.atmosphere == 2.5,
                  onTap: () =>
                      onWeightsChanged(RecommendationWeights.ambiancePure),
                ),
                const SizedBox(width: 8),
                _buildPresetChip(
                  label: 'Esthétique Visuelle',
                  icon: Icons.palette,
                  isSelected: weights.visual == 2.8,
                  onTap: () => onWeightsChanged(
                    RecommendationWeights.esthetiqueVisuelle,
                  ),
                ),
                const SizedBox(width: 8),
                _buildPresetChip(
                  label: 'Rythme & Genre',
                  icon: Icons.speed,
                  isSelected: weights.genre == 2.0 && weights.pacing == 2.0,
                  onTap: () =>
                      onWeightsChanged(RecommendationWeights.rythmeEtGenre),
                ),
              ],
            ),
          ),
          const SizedBox(height: 17),
          const Divider(color: AppTheme.border, height: 1),
          const SizedBox(height: 12),
          _buildSlider(
            label: 'Ambiance & Émotions',
            icon: Icons.mood,
            value: weights.atmosphere,
            color: AppTheme.purple,
            onChanged: (v) => onWeightsChanged(weights.copyWith(atmosphere: v)),
          ),
          _buildSlider(
            label: 'Esthétique Visuelle & Couleurs',
            icon: Icons.palette_outlined,
            value: weights.visual,
            color: AppTheme.cyan,
            onChanged: (v) => onWeightsChanged(weights.copyWith(visual: v)),
          ),
          _buildSlider(
            label: 'Genres Cinématographiques',
            icon: Icons.movie_filter,
            value: weights.genre,
            color: AppTheme.gold,
            onChanged: (v) => onWeightsChanged(weights.copyWith(genre: v)),
          ),
          _buildSlider(
            label: 'Époque & Année',
            icon: Icons.history,
            value: weights.era,
            color: AppTheme.emerald,
            onChanged: (v) => onWeightsChanged(weights.copyWith(era: v)),
          ),
          _buildSlider(
            label: 'Rythme & Cadence',
            icon: Icons.speed,
            value: weights.pacing,
            color: Colors.orangeAccent,
            onChanged: (v) => onWeightsChanged(weights.copyWith(pacing: v)),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 7),
            decoration: BoxDecoration(
              color: AppTheme.cyan.withValues(alpha: 0.035),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.cyan.withValues(alpha: 0.18)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.diamond_outlined,
                      color: AppTheme.cyan,
                      size: 19,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'CURSEUR DE DÉCOUVERTE',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.7,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.cyan.withValues(alpha: 0.13),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${(discoverySlider * 100).toInt()}%',
                        style: const TextStyle(
                          color: AppTheme.cyan,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                Text(
                  _getDiscoveryDescription(discoverySlider),
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                    height: 1.35,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: AppTheme.cyan,
                    thumbColor: AppTheme.cyan,
                    overlayColor: AppTheme.cyan.withValues(alpha: 0.15),
                  ),
                  child: Slider(
                    value: discoverySlider,
                    min: 0,
                    max: 1,
                    divisions: 20,
                    onChanged: onDiscoveryChanged,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 15),
          const Text(
            'NOMBRE DE RECOMMANDATIONS',
            style: TextStyle(
              color: AppTheme.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 9),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [3, 5, 8, 10].map((n) {
              final isSelected = topN == n;
              return ChoiceChip(
                label: Text('$n films'),
                selected: isSelected,
                selectedColor: AppTheme.gold,
                backgroundColor: AppTheme.surfaceElevated,
                showCheckmark: false,
                side: BorderSide(
                  color: isSelected ? AppTheme.gold : AppTheme.border,
                ),
                labelStyle: TextStyle(
                  color: isSelected
                      ? const Color(0xFF171006)
                      : AppTheme.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
                onSelected: (_) => onTopNChanged(n),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.gold : AppTheme.surfaceElevated,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.gold : AppTheme.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected
                  ? const Color(0xFF171006)
                  : AppTheme.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? const Color(0xFF171006)
                    : AppTheme.textPrimary,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlider({
    required String label,
    required IconData icon,
    required double value,
    required Color color,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${value.toStringAsFixed(1)}x',
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
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
              min: 0,
              max: 3,
              divisions: 30,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
