import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/tokens.dart';
import '../../core/utils/haptics.dart';

/// Bottom-navigation shell: Home · Discover · [Create] · Activity · Profile.
/// Create is an emphasized central action that pushes the wizard full-screen.
class OrganizerShell extends StatelessWidget {
  const OrganizerShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: shell,
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          height: 68,
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLow,
            border: Border(top: BorderSide(color: scheme.outlineVariant)),
          ),
          child: Row(
            children: [
              _NavItem(
                icon: Icons.home_outlined,
                selectedIcon: Icons.home,
                label: 'Home',
                selected: shell.currentIndex == 0,
                onTap: () => _goBranch(0),
              ),
              _NavItem(
                icon: Icons.explore_outlined,
                selectedIcon: Icons.explore,
                label: 'Discover',
                selected: shell.currentIndex == 1,
                onTap: () => _goBranch(1),
              ),
              _CreateButton(onTap: () {
                Haptics.light();
                context.push('/create');
              }),
              _NavItem(
                icon: Icons.notifications_outlined,
                selectedIcon: Icons.notifications,
                label: 'Activity',
                selected: shell.currentIndex == 2,
                onTap: () => _goBranch(2),
              ),
              _NavItem(
                icon: Icons.person_outline,
                selectedIcon: Icons.person,
                label: 'Profile',
                selected: shell.currentIndex == 3,
                onTap: () => _goBranch(3),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _goBranch(int index) {
    Haptics.selection();
    shell.goBranch(index, initialLocation: index == shell.currentIndex);
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = selected ? scheme.primary : scheme.onSurfaceVariant;
    return Expanded(
      child: Semantics(
        selected: selected,
        button: true,
        label: label,
        child: InkWell(
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(selected ? selectedIcon : icon, color: color, size: 24),
              const SizedBox(height: 2),
              Text(
                label,
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CreateButton extends StatelessWidget {
  const _CreateButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Center(
        child: Semantics(
          button: true,
          label: 'Create event',
          child: Material(
            color: scheme.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Corners.lg),
            ),
            elevation: Elevations.raised,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(Corners.lg),
              child: const SizedBox(
                width: 52,
                height: 44,
                child: Icon(Icons.add, color: Colors.white, size: 26),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
