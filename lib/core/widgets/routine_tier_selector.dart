import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stretchnow/core/models/stretch_model.dart';

/// Shared 4-option tier selector bar (Halfway, Sweatless, Sweaty, Intense).
class RoutineTierSelector extends StatelessWidget {
  final RoutineTier selectedTier;
  final ValueChanged<RoutineTier> onSelect;

  const RoutineTierSelector({
    super.key,
    required this.selectedTier,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: RoutineTier.values.map((tier) {
        final isSelected = tier == selectedTier;
        final color = tier.accentColor;

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: tier == RoutineTier.intense ? 0 : 6,
            ),
            child: Material(
              color: isSelected
                  ? color
                  : colorScheme.surface.withValues(alpha: 0.7),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(
                  color: isSelected
                      ? color
                      : colorScheme.outlineVariant.withValues(alpha: 0.45),
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => onSelect(tier),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 4,
                  ),
                  child: Column(
                    children: [
                      Text(
                        tier.badge,
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: isSelected ? Colors.white : color,
                        ),
                      ),
                      const SizedBox(height: 2),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          tier.label,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: isSelected
                                ? Colors.white
                                : colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
