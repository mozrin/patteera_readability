import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:patteera_readability/services/config_service.dart';
import 'package:patteera_readability/services/readability_service.dart';
import 'package:patteera_readability/services/ocr_service.dart';
import 'package:patteera_readability/ui/main_screen.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  final configService = ConfigService();
  await configService.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: configService),
        ProxyProvider<ConfigService, ReadabilityService>(
          update: (_, config, previous) => ReadabilityService(config),
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
      title: 'Patteera Readability',
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
