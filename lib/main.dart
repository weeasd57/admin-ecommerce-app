import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'providers/app_provider.dart';
import 'pages/home_page.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers/language_provider.dart';
import 'config/app_localizations.dart';
import 'widgets/loading_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp(prefs: prefs));
}

class MyApp extends StatelessWidget {
  final SharedPreferences prefs;

  const MyApp({required this.prefs, super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
      ],
      child: const AppWithLoading(),
    );
  }
}

class AppWithLoading extends StatelessWidget {
  const AppWithLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<AppProvider, LanguageProvider>(
      builder: (context, appProvider, languageProvider, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Admin AI',
          locale: languageProvider.locale,
          supportedLocales: const [
            Locale('en', ''),
            Locale('ar', ''),
          ],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
            useMaterial3: true,
          ),
          home: FutureBuilder(
            // Add any initialization futures here
            future: Future.wait([
              appProvider.initialize(),
              Future.delayed(
                  const Duration(seconds: 2)), // Minimum display time
            ]),
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const LoadingScreen();
              }

              if (snapshot.hasError) {
                return Scaffold(
                  body: Center(
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                );
              }

              return const HomePage();
            },
          ),
        );
      },
    );
  }
}
