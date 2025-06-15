import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'config/firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/staff_provider.dart';
import 'providers/reports_provider.dart';
import 'providers/theme_provider.dart';
import 'routes/routes.dart';

void main() async {
  // Set up error handling
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('Flutter Error: ${details.exception}');
  };

  // Set up zone error handling
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // Set persistence only for web platform
      if (kIsWeb) {
        await auth.FirebaseAuth.instance.setPersistence(auth.Persistence.LOCAL);
      }

      final prefs = await SharedPreferences.getInstance();
      runApp(MyApp(prefs: prefs));
    } catch (e, stack) {
      debugPrint('Error initializing app: $e');
      debugPrint('Stack trace: $stack');
      // You might want to show an error screen here
      runApp(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Text('Error initializing app: $e'),
            ),
          ),
        ),
      );
    }
  }, (error, stack) {
    debugPrint('Uncaught error: $error');
    debugPrint('Stack trace: $stack');
  });
}

class MyApp extends StatelessWidget {
  final SharedPreferences prefs;

  const MyApp({super.key, required this.prefs});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => StaffProvider()),
        ChangeNotifierProvider(create: (_) => ReportsProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider(prefs)),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'MMRIEM',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              primarySwatch: Colors.blue,
              useMaterial3: true,
              fontFamily: 'Roboto',
              brightness:
                  themeProvider.isDark ? Brightness.dark : Brightness.light,
              appBarTheme: AppBarTheme(
                centerTitle: true,
                elevation: 0,
                backgroundColor:
                    themeProvider.isDark ? Colors.grey[900] : Colors.white,
                foregroundColor:
                    themeProvider.isDark ? Colors.white : Colors.black87,
              ),
              scaffoldBackgroundColor: themeProvider.isDark
                  ? Colors.grey[850]
                  : const Color(0xFFF5F5F5),
              cardTheme: CardThemeData(
                elevation: 1,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                color: themeProvider.isDark ? Colors.grey[800] : Colors.white,
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              inputDecorationTheme: InputDecorationTheme(
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                alignLabelWithHint: true,
              ),
              textTheme: TextTheme(
                bodyLarge: TextStyle(
                  fontSize: 16,
                  color: themeProvider.isDark ? Colors.white : Colors.black87,
                ),
                bodyMedium: TextStyle(
                  fontSize: 14,
                  color: themeProvider.isDark ? Colors.white : Colors.black87,
                ),
                titleLarge: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: themeProvider.isDark ? Colors.white : Colors.black87,
                ),
                titleMedium: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: themeProvider.isDark ? Colors.white : Colors.black87,
                ),
              ),
              iconTheme: IconThemeData(
                size: 24,
                color: themeProvider.isDark ? Colors.white : Colors.black87,
                opacity: 0.9,
              ),
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.blue,
                brightness:
                    themeProvider.isDark ? Brightness.dark : Brightness.light,
                primary: Colors.blue,
                secondary: Colors.orange,
                tertiary: Colors.green,
                error: const Color(0xFFE57373),
                background: themeProvider.isDark
                    ? Colors.grey[850]!
                    : const Color(0xFFF5F5F5),
                surface:
                    themeProvider.isDark ? Colors.grey[800]! : Colors.white,
                onPrimary: Colors.white,
                onSecondary: Colors.white,
                onError: Colors.white,
                onBackground:
                    themeProvider.isDark ? Colors.white : Colors.black87,
                onSurface: themeProvider.isDark ? Colors.white : Colors.black87,
              ),
            ),
            initialRoute: AppRoutes.splash,
            onGenerateRoute: AppRoutes.generateRoute,
            builder: (context, child) {
              return AppScaffold(child: child);
            },
          );
        },
      ),
    );
  }
}

class AppScaffold extends StatelessWidget {
  final Widget? child;

  const AppScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: child!,
      ),
    );
  }
}
