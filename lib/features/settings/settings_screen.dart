import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:stretchnow/core/models/stretch_model.dart';
import 'package:stretchnow/features/about/about_screen.dart';
import 'package:stretchnow/features/settings/settings_view_model.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Consumer<SettingsViewModel>(
        builder: (context, viewModel, _) {
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: ListView(
                padding: const EdgeInsets.all(24.0),
                children: [
                  SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4, bottom: 4),
                      child: Text(
                        'Settings',
                        style: GoogleFonts.outfit(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Routine Preferences
                  const _SectionLabel(label: 'ROUTINE'),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: _cardDecoration(colorScheme),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Default Exercise Option',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: RoutineTier.values.map((tier) {
                            final selected = viewModel.selectedTier == tier;
                            return ChoiceChip(
                              label: Text('${tier.badge} · ${tier.label}'),
                              selected: selected,
                              onSelected: (_) => viewModel.setSelectedTier(tier),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 18),
                        Divider(
                          height: 1,
                          color: colorScheme.outlineVariant
                              .withValues(alpha: 0.35),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'Prep Countdown Between Moves',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          children: [0, 3, 5, 10].map((sec) {
                            final selected = viewModel.prepSeconds == sec;
                            return ChoiceChip(
                              label: Text(sec == 0 ? 'Off' : '${sec}s'),
                              selected: selected,
                              onSelected: (_) => viewModel.setPrepSeconds(sec),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 18),
                        Divider(
                          height: 1,
                          color: colorScheme.outlineVariant
                              .withValues(alpha: 0.35),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                'Daily Routine Goal',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    colorScheme.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: Text(
                                '${viewModel.dailyGoal}',
                                style: TextStyle(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Slider(
                          value: viewModel.dailyGoal.toDouble(),
                          min: 1,
                          max: 5,
                          divisions: 4,
                          onChanged: (val) =>
                              viewModel.setDailyGoal(val.toInt()),
                        ),
                        Text(
                          '1 full 12-move routine daily is the sweet spot.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Notifications & Cues
                  const _SectionLabel(label: 'CUES & REMINDERS'),
                  const SizedBox(height: 12),
                  Material(
                    color: colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.45),
                    shape: _cardShape(colorScheme),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        _SwitchTile(
                          icon: Icons.volume_up_outlined,
                          iconColor: const Color(0xFF14B8A6),
                          title: 'Transition Sound Cues',
                          subtitle: 'Subtle click on rep or phase switch',
                          value: viewModel.soundCueEnabled,
                          onChanged: viewModel.toggleSoundCue,
                        ),
                        Divider(
                          height: 1,
                          indent: 56,
                          color: colorScheme.outlineVariant
                              .withValues(alpha: 0.3),
                        ),
                        _SwitchTile(
                          icon: Icons.notifications_outlined,
                          iconColor: colorScheme.primary,
                          title: 'Stretch Reminders',
                          subtitle: 'Regular prompts to move',
                          value: viewModel.notificationsEnabled,
                          onChanged: viewModel.toggleNotifications,
                        ),
                        Divider(
                          height: 1,
                          indent: 56,
                          color: colorScheme.outlineVariant
                              .withValues(alpha: 0.3),
                        ),
                        _SwitchTile(
                          icon: Icons.vibration_outlined,
                          iconColor: colorScheme.secondary,
                          title: 'Vibration & Haptics',
                          subtitle: 'Tactile feedback on cues & reminders',
                          value: viewModel.vibrationEnabled,
                          onChanged: viewModel.toggleVibration,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Appearance
                  const _SectionLabel(label: 'APPEARANCE'),
                  const SizedBox(height: 12),
                  Material(
                    color: colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.45),
                    shape: _cardShape(colorScheme),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        _ThemeTile(
                          title: 'System Default',
                          icon: Icons.brightness_auto_outlined,
                          isSelected: viewModel.themeMode == ThemeMode.system,
                          onTap: () => viewModel.setThemeMode(ThemeMode.system),
                        ),
                        Divider(
                          height: 1,
                          indent: 56,
                          color: colorScheme.outlineVariant
                              .withValues(alpha: 0.3),
                        ),
                        _ThemeTile(
                          title: 'Light',
                          icon: Icons.light_mode_outlined,
                          isSelected: viewModel.themeMode == ThemeMode.light,
                          onTap: () => viewModel.setThemeMode(ThemeMode.light),
                        ),
                        Divider(
                          height: 1,
                          indent: 56,
                          color: colorScheme.outlineVariant
                              .withValues(alpha: 0.3),
                        ),
                        _ThemeTile(
                          title: 'Dark',
                          icon: Icons.dark_mode_outlined,
                          isSelected: viewModel.themeMode == ThemeMode.dark,
                          onTap: () => viewModel.setThemeMode(ThemeMode.dark),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Data & Support
                  const _SectionLabel(label: 'DATA & SUPPORT'),
                  const SizedBox(height: 12),
                  Material(
                    color: colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.45),
                    shape: _cardShape(colorScheme),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        _ActionTile(
                          icon: Icons.info_outline_rounded,
                          iconColor: colorScheme.primary,
                          title: 'About StretchNow',
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const AboutScreen(),
                            ),
                          ),
                        ),
                        Divider(
                          height: 1,
                          indent: 56,
                          color: colorScheme.outlineVariant
                              .withValues(alpha: 0.3),
                        ),
                        _ActionTile(
                          icon: Icons.shield_outlined,
                          iconColor: const Color(0xFF22C55E),
                          title: 'Privacy Policy',
                          onTap: () => _showPolicyDialog(
                            context,
                            'Privacy Policy',
                            'We do not collect any personal data. All your routines and history remain securely stored on your local device.',
                          ),
                        ),
                        Divider(
                          height: 1,
                          indent: 56,
                          color: colorScheme.outlineVariant
                              .withValues(alpha: 0.3),
                        ),
                        _ActionTile(
                          icon: Icons.delete_outline_rounded,
                          iconColor: colorScheme.error,
                          title: 'Reset Data',
                          titleColor: colorScheme.error,
                          onTap: () => _confirmReset(context, viewModel),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 36),

                  Center(
                    child: Column(
                      children: [
                        Text(
                          'StretchNow',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Version 1.0.1',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 80),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  ShapeBorder _cardShape(ColorScheme colorScheme) {
    return RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: BorderSide(
        color: colorScheme.outlineVariant.withValues(alpha: 0.4),
      ),
    );
  }

  BoxDecoration _cardDecoration(ColorScheme colorScheme) {
    return BoxDecoration(
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: colorScheme.outlineVariant.withValues(alpha: 0.4),
      ),
    );
  }

  void _showPolicyDialog(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _confirmReset(BuildContext context, SettingsViewModel viewModel) {
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('Reset Data?'),
        content: const Text(
          'This will clear your streak and routine history. Settings will remain unchanged.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              viewModel.resetData();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('App data reset successfully'),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            },
            child: Text(
              'Reset',
              style: TextStyle(color: colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            letterSpacing: 0.8,
          ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  const _SwitchTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      secondary: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 18),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      value: value,
      onChanged: onChanged,
    );
  }
}

class _ThemeTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeTile({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: (isSelected ? colorScheme.primary : colorScheme.outline)
              .withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: isSelected ? colorScheme.primary : colorScheme.outline,
          size: 18,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          color: isSelected ? colorScheme.primary : null,
        ),
      ),
      trailing: isSelected
          ? Icon(
              Icons.check_circle_rounded,
              color: colorScheme.primary,
              size: 22,
            )
          : null,
      onTap: onTap,
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final Color? titleColor;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.titleColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 18),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: titleColor,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: Theme.of(context).colorScheme.outline,
      ),
      onTap: onTap,
    );
  }
}
