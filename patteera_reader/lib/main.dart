import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:patteera_reader/services/config_service.dart';
import 'package:patteera_reader/services/readability_service.dart';
import 'package:patteera_reader/services/ocr_service.dart';
import 'package:patteera_reader/ui/main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final configService = ConfigService();
  await configService.loadConfig();

  runApp(
    MultiProvider(
      providers: [
        Provider.value(value: configService),
        ProxyProvider<ConfigService, ReadabilityService>(
          update: (_, config, __) => ReadabilityService(config),
        ),
        Provider(create: (_) => OcrService()),
      ],
      child: const PatteeraApp(),
    ),
  );
}

class PatteeraApp extends StatelessWidget {
  const PatteeraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Patteera Reader',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C63FF),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        textTheme: GoogleFonts.outfitTextTheme(),
        scaffoldBackgroundColor: const Color(0xFFF8F9FE),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C63FF),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
        scaffoldBackgroundColor: const Color(0xFF1A1B26),
      ),
      themeMode: ThemeMode.system,
      home: const MainScreen(),
    );
  }
}
