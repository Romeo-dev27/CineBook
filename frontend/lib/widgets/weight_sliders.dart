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

  bool _isPreset(RecommendationWeights preset) =>
      weights.atmosphere == preset.atmosphere &&
      weights.visual == preset.visual &&
      weights.genre == preset.genre &&
      weights.era == preset.era &&
      weights.pacing == preset.pacing;

  String _getDiscoveryDescription(double value) {
    if (value < 0.15) return 'Populaires et blockbusters acceptés';
    if (value < 0.45) return 'Équilibre entre classiques et découvertes';
    if (value < 0.75) return 'Favorise activement les films méconnus';
    return 'Mode Pépite : priorité absolue aux trésors cachés';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.cineColors;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.tune, color: colors.accent, size: 19),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'RÉGLAGES DE SÉLECTION',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Cinq dimensions pour affiner les résultats',
                      style: TextStyle(
                        fontSize: 10,
                        color: colors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.refresh, size: 18, color: colors.textMuted),
                tooltip: 'Réinitialiser les réglages',
                onPressed: () {
                  onWeightsChanged(RecommendationWeights.equilibre);
                  onDiscoveryChanged(0.3);
                  onTopNChanged(5);
                },
              ),
            ],
          ),
          const SizedBox(height: 14),
          SingleChildScrollView(
            key: const PageStorageKey('weight-presets-scroll'),
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildPresetChip(
                  colors,
                  label: 'Équilibré',
                  icon: Icons.balance,
                  isSelected: _isPreset(RecommendationWeights.equilibre),
                  onTap: () =>
                      onWeightsChanged(RecommendationWeights.equilibre),
                ),
                const SizedBox(width: 7),
                _buildPresetChip(
                  colors,
                  label: 'Ambiance Pure',
                  icon: Icons.nights_stay,
                  isSelected: _isPreset(RecommendationWeights.ambiancePure),
                  onTap: () =>
                      onWeightsChanged(RecommendationWeights.ambiancePure),
                ),
                const SizedBox(width: 7),
                _buildPresetChip(
                  colors,
                  label: 'Esthétique Visuelle',
                  icon: Icons.palette_outlined,
                  isSelected: _isPreset(
                    RecommendationWeights.esthetiqueVisuelle,
                  ),
                  onTap: () => onWeightsChanged(
                    RecommendationWeights.esthetiqueVisuelle,
                  ),
                ),
                const SizedBox(width: 7),
                _buildPresetChip(
                  colors,
                  label: 'Rythme & Genre',
                  icon: Icons.speed,
                  isSelected: _isPreset(RecommendationWeights.rythmeEtGenre),
                  onTap: () =>
                      onWeightsChanged(RecommendationWeights.rythmeEtGenre),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Divider(color: colors.border, height: 1),
          const SizedBox(height: 10),
          _buildSlider(
            colors,
            label: 'Ambiance & Émotions',
            icon: Icons.mood,
            value: weights.atmosphere,
            color: colors.purple,
            onChanged: (value) =>
                onWeightsChanged(weights.copyWith(atmosphere: value)),
          ),
          _buildSlider(
            colors,
            label: 'Esthétique Visuelle & Couleurs',
            icon: Icons.palette_outlined,
            value: weights.visual,
            color: colors.cyan,
            onChanged: (value) =>
                onWeightsChanged(weights.copyWith(visual: value)),
          ),
          _buildSlider(
            colors,
            label: 'Genres Cinématographiques',
            icon: Icons.movie_filter,
            value: weights.genre,
            color: colors.accent,
            onChanged: (value) =>
                onWeightsChanged(weights.copyWith(genre: value)),
          ),
          _buildSlider(
            colors,
            label: 'Époque & Année',
            icon: Icons.history,
            value: weights.era,
            color: colors.emerald,
            onChanged: (value) => onWeightsChanged(weights.copyWith(era: value)),
          ),
          _buildSlider(
            colors,
            label: 'Rythme & Cadence',
            icon: Icons.speed,
            value: weights.pacing,
            color: colors.orange,
            onChanged: (value) =>
                onWeightsChanged(weights.copyWith(pacing: value)),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.fromLTRB(13, 13, 13, 5),
            decoration: BoxDecoration(
              color: colors.surfaceElevated.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: colors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.diamond_outlined, color: colors.cyan, size: 17),
                    const SizedBox(width: 7),
                    const Expanded(
                      child: Text(
                        'CURSEUR DE DÉCOUVERTE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.7,
                        ),
                      ),
                    ),
                    Text(
                      '${(discoverySlider * 100).toInt()}%',
                      style: TextStyle(
                        color: colors.cyan,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  _getDiscoveryDescription(discoverySlider),
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 10,
                    height: 1.45,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: colors.cyan,
                    thumbColor: colors.cyan,
                    overlayColor: colors.cyan.withValues(alpha: 0.12),
                  ),
                  child: Slider(
                    value: discoverySlider,
                    semanticFormatterCallback: (value) =>
                        'Découverte : ${(value * 100).round()} pour cent',
                    min: 0,
                    max: 1,
                    divisions: 20,
                    onChanged: onDiscoveryChanged,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'NOMBRE DE RECOMMANDATIONS',
            style: TextStyle(
              color: colors.textMuted,
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [3, 5, 8, 10].map((count) {
              final isSelected = topN == count;
              return ChoiceChip(
                label: Text('$count films'),
                selected: isSelected,
                selectedColor: colors.accent,
                backgroundColor: colors.surfaceElevated,
                showCheckmark: false,
                side: BorderSide(
                  color: isSelected ? colors.accent : colors.border,
                ),
                labelStyle: TextStyle(
                  color: isSelected ? colors.onAccent : colors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                ),
                onSelected: (_) => onTopNChanged(count),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetChip(
    CineBookColors colors, {
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(3),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? colors.accent : colors.surfaceElevated,
          borderRadius: BorderRadius.circular(3),
          border: Border.all(
            color: isSelected ? colors.accent : colors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: isSelected ? colors.onAccent : colors.textSecondary,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? colors.onAccent : colors.textPrimary,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlider(
    CineBookColors colors, {
    required String label,
    required IconData icon,
    required double value,
    required Color color,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: color),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${value.toStringAsFixed(1)}x',
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: color,
              thumbColor: color,
              overlayColor: color.withValues(alpha: 0.12),
              inactiveTrackColor: colors.surfaceElevated,
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            ),
            child: Slider(
              value: value,
              semanticFormatterCallback: (value) =>
                  '$label : ${value.toStringAsFixed(1)}',
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
