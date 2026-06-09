import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/constants/app_constants.dart';
import 'core/navigation/app_router.dart';
import 'core/theme/app_theme.dart';
import 'data/models/app_user.dart';
import 'features/auth/providers/auth_provider.dart';

/// Root widget: theme, [GoRouter], and auth [StreamProvider].
class ThreeAshApp extends StatefulWidget {
  const ThreeAshApp({super.key});

  @override
  State<ThreeAshApp> createState() => _ThreeAshAppState();
}

class _ThreeAshAppState extends State<ThreeAshApp> {
  late final AuthProvider _authProvider;
  late final AppRouter _appRouter;
  AppUser? _cachedUser;

  @override
  void initState() {
    super.initState();
    _authProvider = context.read<AuthProvider>();
    _appRouter = AppRouter(
      authListenable: _authProvider,
      getUser: () => _cachedUser ?? _authProvider.user,
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamProvider<AppUser?>.value(
      value: _authProvider.authStateChanges(),
      initialData: _authProvider.user,
      catchError: (_, _) => null,
      child: Consumer<AppUser?>(
        builder: (context, user, _) {
          _cachedUser = user;
          return MaterialApp.router(
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: ThemeMode.system,
            routerConfig: _appRouter.router,
          );
        },
      ),
    );
  }
}
