import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:stretchnow/features/history/history_screen.dart';
import 'package:stretchnow/features/home/home_screen.dart';
import 'package:stretchnow/features/schedule/schedule_screen.dart';
import 'package:stretchnow/features/settings/settings_screen.dart';
import 'package:stretchnow/features/stretches/stretches_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  DateTime? _lastBackAt;
  bool _exitDialogOpen = false;

  final List<Widget> _screens = const [
    HomeScreen(),
    StretchesScreen(),
    ScheduleScreen(),
    HistoryScreen(),
    SettingsScreen(),
  ];

  bool _unfocusActiveTextBox() {
    final focus = FocusManager.instance.primaryFocus;
    final focusCtx = focus?.context;
    final editing =
        focusCtx != null &&
        (focusCtx.widget is EditableText ||
            focusCtx.findAncestorStateOfType<EditableTextState>() != null);
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    if ((focus != null && focus.hasFocus && editing) || keyboardOpen) {
      focus?.unfocus();
      return true;
    }
    return false;
  }

  Future<void> _handleBackPressed() async {
    if (_unfocusActiveTextBox()) {
      _lastBackAt = null;
      return;
    }
    if (_currentIndex != 0) {
      _lastBackAt = null;
      setState(() => _currentIndex = 0);
      return;
    }
    if (_exitDialogOpen) return;

    final now = DateTime.now();
    final messenger = ScaffoldMessenger.of(context);
    if (_lastBackAt == null ||
        now.difference(_lastBackAt!) > const Duration(seconds: 2)) {
      _lastBackAt = now;
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Press back again to quit'),
            behavior: SnackBarBehavior.fixed,
            duration: Duration(seconds: 2),
          ),
        );
      return;
    }

    _lastBackAt = null;
    messenger.hideCurrentSnackBar();
    _exitDialogOpen = true;
    try {
      final shouldLeave = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Quit StretchNow?',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          content: const Text('Do you want to close the app?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Leave'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Stay'),
            ),
          ],
        ),
      );
      if (shouldLeave == true) {
        await SystemNavigator.pop();
      }
    } finally {
      _exitDialogOpen = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_handleBackPressed());
      },
      child: Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          for (var i = 0; i < _screens.length; i++)
            TickerMode(
              enabled: _currentIndex == i,
              child: _screens[i],
            ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        height: 72,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Routine',
          ),
          NavigationDestination(
            icon: Icon(Icons.self_improvement_outlined),
            selectedIcon: Icon(Icons.self_improvement),
            label: 'Motions',
          ),
          NavigationDestination(
            icon: Icon(Icons.schedule_outlined),
            selectedIcon: Icon(Icons.schedule),
            label: 'Schedule',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart_rounded),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    ),
    );
  }
}
