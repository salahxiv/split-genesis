import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/services/deep_link_service.dart';
import 'core/theme/app_theme.dart';
import 'features/groups/screens/home_screen.dart';
import 'features/onboarding/providers/onboarding_provider.dart';
import 'features/onboarding/screens/onboarding_screen.dart';
import 'features/settings/providers/settings_provider.dart';

class SplitGenesisApp extends ConsumerWidget {
  const SplitGenesisApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final onboardingAsync = ref.watch(onboardingCompleteProvider);

    return MaterialApp(
      title: 'Split Genesis',
      theme: AppTheme.theme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: onboardingAsync.when(
        data: (completed) {
          // Skip onboarding if deep link is present or already completed
          if (completed || DeepLinkService.instance.initialCode != null) {
            return const HomeScreen();
          }
          return const OnboardingScreen();
        },
        loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
        error: (_, __) => const HomeScreen(),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
