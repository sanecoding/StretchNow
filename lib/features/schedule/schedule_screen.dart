import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:stretchnow/features/home/home_view_model.dart';
import 'package:stretchnow/features/routine/routine_player_screen.dart';
import 'package:stretchnow/features/schedule/schedule_view_model.dart';

class ScheduleScreen extends StatelessWidget {
  const ScheduleScreen({super.key});

  static const _dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Consumer2<ScheduleViewModel, HomeViewModel>(
        builder: (context, viewModel, homeVm, _) {
          final tier = homeVm.selectedTier;

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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Wake-Up Routine',
                            style: GoogleFonts.outfit(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Set your morning wake-up stretch schedule',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Wake-Up Time Hero Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: colorScheme.primary.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF59E0B)
                                    .withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.wb_sunny_rounded,
                                color: Color(0xFFF59E0B),
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Wake-Up Time',
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    viewModel.reminderEnabled
                                        ? 'Stretch at ${viewModel.formattedStretchTime} · ${viewModel.repeatSummary}'
                                        : 'Morning reminder paused',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: viewModel.reminderEnabled,
                              onChanged: viewModel.toggleReminder,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        InkWell(
                          onTap: () async {
                            final picked = await _selectTime(
                              context,
                              viewModel.wakeUpHour,
                              viewModel.wakeUpMinute,
                            );
                            if (picked != null) {
                              await viewModel.updateWakeUpTime(
                                picked.hour,
                                picked.minute,
                              );
                            }
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.surface.withValues(alpha: 0.72),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: colorScheme.outlineVariant
                                    .withValues(alpha: 0.45),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      viewModel.formattedWakeUpTime,
                                      style: GoogleFonts.outfit(
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                        color: colorScheme.onSurface,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.edit_outlined,
                                      size: 16,
                                      color: colorScheme.primary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Change',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: colorScheme.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        FilledButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => RoutinePlayerScreen(
                                  exercises: homeVm.routine,
                                  initialIndex: 0,
                                  tier: tier,
                                  sessionTitle: 'Wake-Up Stretch Routine',
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.play_arrow_rounded),
                          label: Text(
                            'Start Wake-Up Routine (${tier.label})',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: tier.accentColor,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Repeat Days
                  Text(
                    'Wake-Up Days',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurfaceVariant,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: List.generate(7, (idx) {
                            final weekday = idx + 1;
                            final active =
                                viewModel.repeatDays.contains(weekday);
                            return Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(
                                  right: idx == 6 ? 0 : 6,
                                ),
                                child: InkWell(
                                  onTap: () => viewModel.toggleDay(weekday),
                                  borderRadius: BorderRadius.circular(12),
                                  child: AnimatedContainer(
                                    duration:
                                        const Duration(milliseconds: 160),
                                    height: 40,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: active
                                          ? colorScheme.primary
                                          : colorScheme.surface
                                              .withValues(alpha: 0.65),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: active
                                            ? colorScheme.primary
                                            : colorScheme.outlineVariant
                                                .withValues(alpha: 0.45),
                                      ),
                                    ),
                                    child: Text(
                                      _dayLabels[idx],
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: active
                                            ? Colors.white
                                            : colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            ChoiceChip(
                              label: const Text('Every day'),
                              selected: viewModel.repeatSummary == 'Every day',
                              onSelected: (_) => viewModel.setRepeatPreset(
                                ScheduleViewModel.everyDay,
                              ),
                              visualDensity: VisualDensity.compact,
                            ),
                            ChoiceChip(
                              label: const Text('Weekdays'),
                              selected: viewModel.repeatSummary == 'Weekdays',
                              onSelected: (_) => viewModel.setRepeatPreset(
                                ScheduleViewModel.weekdaysOnly,
                              ),
                              visualDensity: VisualDensity.compact,
                            ),
                            ChoiceChip(
                              label: const Text('Weekends'),
                              selected: viewModel.repeatSummary == 'Weekends',
                              onSelected: (_) => viewModel.setRepeatPreset(
                                ScheduleViewModel.weekendsOnly,
                              ),
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Delay after waking up
                  Text(
                    'After Waking Up',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurfaceVariant,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Choose how soon after waking up to begin your routine',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Material(
                    color: colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.45),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: RadioGroup<int>(
                      groupValue: viewModel.delayMinutes,
                      onChanged: (val) {
                        if (val != null) viewModel.updateDelayMinutes(val);
                      },
                      child: Column(
                        children: [
                          const _DelayTile(
                            title: 'Right when I wake up',
                            subtitle: 'Start stretching immediately (0 min)',
                            value: 0,
                            icon: Icons.alarm_on_outlined,
                          ),
                          Divider(
                            height: 1,
                            color: colorScheme.outlineVariant
                                .withValues(alpha: 0.3),
                          ),
                          const _DelayTile(
                            title: '5 minutes after wake-up',
                            subtitle: 'Sit up, drink water, then stretch',
                            value: 5,
                            icon: Icons.water_drop_outlined,
                          ),
                          Divider(
                            height: 1,
                            color: colorScheme.outlineVariant
                                .withValues(alpha: 0.3),
                          ),
                          const _DelayTile(
                            title: '10 minutes after wake-up',
                            subtitle: 'Gentle morning transition',
                            value: 10,
                            icon: Icons.coffee_outlined,
                          ),
                          Divider(
                            height: 1,
                            color: colorScheme.outlineVariant
                                .withValues(alpha: 0.3),
                          ),
                          const _DelayTile(
                            title: '15 minutes after wake-up',
                            subtitle: 'Short buffer before starting',
                            value: 15,
                            icon: Icons.snooze_outlined,
                          ),
                        ],
                      ),
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

  Future<TimeOfDay?> _selectTime(
    BuildContext context,
    int initialHour,
    int initialMinute,
  ) {
    return showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: initialHour, minute: initialMinute),
      initialEntryMode: TimePickerEntryMode.dialOnly,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
          child: child!,
        );
      },
    );
  }
}

class _DelayTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final int value;
  final IconData icon;

  const _DelayTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return RadioListTile<int>(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      secondary: Icon(icon, size: 20),
      value: value,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      fillColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? Theme.of(context).colorScheme.primary
            : null,
      ),
    );
  }
}
