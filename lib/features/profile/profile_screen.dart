import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/tokens.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/states.dart';
import '../auth/session_controller.dart';
import 'settings_controller.dart';

/// Profile & settings: verification status, appearance, privacy, account.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionControllerProvider);
    final settings = ref.watch(settingsControllerProvider);
    final theme = Theme.of(context);

    if (!session.isAuthenticated) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: SafeArea(
          child: EmptyState(
            icon: Icons.person_outline,
            title: 'No account yet',
            message:
                'Participants don\'t need an account. Create one only if you want to organize events.',
            actionLabel: 'Create organizer account',
            onAction: () => context.push('/auth/register'),
          ),
        ),
      );
    }

    final organizer = session.organizer!;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(Spacing.lg),
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: theme.colorScheme.primary,
                  child: Text(
                    organizer.fullName.isNotEmpty
                        ? organizer.fullName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: Spacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(organizer.fullName,
                          style: theme.textTheme.titleLarge),
                      Text(organizer.email, style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: Spacing.lg),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(
                      organizer.emailVerified
                          ? Icons.check_circle
                          : Icons.error_outline,
                      color: organizer.emailVerified
                          ? AppColors.success
                          : AppColors.warning,
                    ),
                    title: const Text('Email'),
                    subtitle: Text(
                      organizer.emailVerified ? 'Verified' : 'Not verified',
                    ),
                    trailing: organizer.emailVerified
                        ? null
                        : TextButton(
                            onPressed: () => context.push('/auth/verify-email'),
                            child: const Text('Verify'),
                          ),
                  ),
                  const Divider(),
                  ListTile(
                    leading: Icon(
                      organizer.phoneVerified
                          ? Icons.check_circle
                          : Icons.error_outline,
                      color: organizer.phoneVerified
                          ? AppColors.success
                          : AppColors.warning,
                    ),
                    title: const Text('Phone'),
                    subtitle: Text(
                      organizer.phoneVerified
                          ? 'Verified · ${organizer.phone}'
                          : 'Not verified',
                    ),
                    trailing: organizer.phoneVerified
                        ? null
                        : TextButton(
                            onPressed: () => context.push('/auth/verify-phone'),
                            child: const Text('Verify'),
                          ),
                  ),
                ],
              ),
            ),
            const SectionHeader(title: 'Appearance'),
            SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(
                  value: ThemeMode.light,
                  label: Text('Light'),
                  icon: Icon(Icons.light_mode_outlined),
                ),
                ButtonSegment(
                  value: ThemeMode.system,
                  label: Text('System'),
                  icon: Icon(Icons.brightness_auto_outlined),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  label: Text('Dark'),
                  icon: Icon(Icons.dark_mode_outlined),
                ),
              ],
              selected: {settings.themeMode},
              onSelectionChanged: (selection) => ref
                  .read(settingsControllerProvider.notifier)
                  .setThemeMode(selection.first),
            ),
            const SectionHeader(title: 'Preferences'),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Notifications'),
              subtitle: const Text('Event activity and closing reminders'),
              value: settings.notificationsEnabled,
              onChanged: (v) => ref
                  .read(settingsControllerProvider.notifier)
                  .setNotifications(v),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.language),
              title: const Text('Language'),
              subtitle: Text(settings.language),
              onTap: () => _pickLanguage(context, ref, settings.language),
            ),
            const SectionHeader(title: 'Privacy & security'),
            const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.devices_other_outlined),
              title: Text('Connected devices'),
              subtitle: Text('This device'),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.download_outlined),
              title: const Text('Export my data'),
              onTap: () => _snack(context, 'Data export requested.'),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.description_outlined),
              title: const Text('Terms & privacy policy'),
              onTap: () => _snack(context, 'This would open the terms.'),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.help_outline),
              title: const Text('Help & support'),
              onTap: () => _snack(context, 'This would open help.'),
            ),
            const SizedBox(height: Spacing.lg),
            OutlinedButton(
              onPressed: () async {
                await ref.read(sessionControllerProvider.notifier).signOut();
                if (context.mounted) context.go('/home');
              },
              child: const Text('Sign out'),
            ),
            const SizedBox(height: Spacing.md),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: AppColors.danger),
              onPressed: () => _confirmDelete(context, ref),
              child: const Text('Delete organizer account'),
            ),
            const SizedBox(height: Spacing.lg),
            Center(
              child: Text(
                'PulseVote 0.1.0 (development)',
                style: theme.textTheme.labelSmall,
              ),
            ),
            const SizedBox(height: Spacing.xl),
          ],
        ),
      ),
    );
  }

  void _snack(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _pickLanguage(
    BuildContext context,
    WidgetRef ref,
    String current,
  ) async {
    final choice = await showAppSheet<String>(
      context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final lang in const ['English', 'Spanish', 'French', 'German', 'Hindi'])
            ListTile(
              title: Text(lang),
              trailing: lang == current ? const Icon(Icons.check) : null,
              onTap: () => Navigator.of(context).pop(lang),
            ),
        ],
      ),
    );
    if (choice != null) {
      ref.read(settingsControllerProvider.notifier).setLanguage(choice);
    }
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete account?'),
        content: const Text(
          'Your organizer account and events will be permanently deleted. '
          'Ballots already cast remain counted in closed events.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await ref.read(sessionControllerProvider.notifier).signOut();
      if (context.mounted) context.go('/onboarding');
    }
  }
}
