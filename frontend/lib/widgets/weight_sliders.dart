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
    if (val < 0.15) return 'Populaires & Blockbusters acceptés';
    if (val < 0.45) return 'Équilibre entre classiques et découvertes';
    if (val < 0.75) return 'Favorise activement les films méconnus';
    return '💎 Mode Pépite : Priorité absolue aux trésors cachés';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // En-tête de section
          Row(
            children: [
              const Icon(Icons.tune, color: AppTheme.gold, size: 20),
              const SizedBox(width: 10),
              const Text(
                'Pondération des Vecteurs de Similarité',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                icon: const Icon(Icons.refresh, size: 16, color: AppTheme.textMuted),
                label: const Text(
                  'Réinitialiser',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                ),
                onPressed: () {
                  onWeightsChanged(RecommendationWeights.equilibre);
                  onDiscoveryChanged(0.3);
                },
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Boutons de Présélections (Presets)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildPresetChip(
                  label: 'Équilibré',
                  icon: Icons.balance,
                  isSelected: weights.atmosphere == 1.5 && weights.visual == 1.2,
                  onTap: () => onWeightsChanged(RecommendationWeights.equilibre),
                ),
                const SizedBox(width: 8),
                _buildPresetChip(
                  label: 'Ambiance Pure',
                  icon: Icons.nights_stay,
                  isSelected: weights.atmosphere == 2.5,
                  onTap: () => onWeightsChanged(RecommendationWeights.ambiancePure),
                ),
                const SizedBox(width: 8),
                _buildPresetChip(
                  label: 'Esthétique Visuelle',
                  icon: Icons.palette,
                  isSelected: weights.visual == 2.8,
                  onTap: () => onWeightsChanged(RecommendationWeights.esthetiqueVisuelle),
                ),
                const SizedBox(width: 8),
                _buildPresetChip(
                  label: 'Rythme & Genre',
                  icon: Icons.speed,
                  isSelected: weights.genre == 2.0 && weights.pacing == 2.0,
                  onTap: () => onWeightsChanged(RecommendationWeights.rythmeEtGenre),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Divider(color: AppTheme.border, height: 1),
          const SizedBox(height: 16),

          // Les 5 curseurs individuels
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
          const Divider(color: AppTheme.border, height: 1),
          const SizedBox(height: 16),

          // Curseur de Découverte
          Row(
            children: [
              const Icon(Icons.diamond_outlined, color: AppTheme.cyan, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Curseur de Découverte',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.cyan.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${(discoverySlider * 100).toInt()}%',
                  style: const TextStyle(
                    color: AppTheme.cyan,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _getDiscoveryDescription(discoverySlider),
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
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
              min: 0.0,
              max: 1.0,
              divisions: 20,
              onChanged: onDiscoveryChanged,
            ),
          ),

          // Sélection du nombre de recommandations (Top N)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Nombre de recommandations :',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Row(
                children: [3, 5, 8, 10].map((n) {
                  final isSelected = topN == n;
                  return Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: ChoiceChip(
                      label: Text('$n'),
                      selected: isSelected,
                      selectedColor: AppTheme.gold,
                      backgroundColor: AppTheme.surfaceElevated,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.black : AppTheme.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      onSelected: (_) => onTopNChanged(n),
                    ),
                  );
                }).toList(),
              ),
            ],
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
      child: Container(
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
              color: isSelected ? Colors.black : AppTheme.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.black : AppTheme.textPrimary,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Text(
                '${value.toStringAsFixed(1)}x',
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
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
              max: 3.0,
              divisions: 30,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
