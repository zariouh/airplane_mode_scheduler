import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/home_screen.dart';
import 'screens/permission_screen.dart';
import 'services/airplane_mode_service.dart';
import 'utils/logger.dart';

class AirplaneModeSchedulerApp extends StatefulWidget {
  const AirplaneModeSchedulerApp({super.key});

  @override
  State<AirplaneModeSchedulerApp> createState() => _AirplaneModeSchedulerAppState();
}

class _AirplaneModeSchedulerAppState extends State<AirplaneModeSchedulerApp> {
  bool _hasPermissions = false;
  bool _isLoading = true;

  static const platformRoot = MethodChannel('com.airplane.scheduler/root');

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    try {
      // Force trigger root popup on app start
      AppLogger.i('Triggering root request on app start');
      await platformRoot.invokeMethod('forceRootRequest');

      final hasPermissions = await AirplaneModeService.checkAllPermissions();
      AppLogger.i('Permissions check: $hasPermissions');
      setState(() {
        _hasPermissions = hasPermissions;
        _isLoading = false;
      });
    } catch (e) {
      AppLogger.e('Error checking permissions', e);
      setState(() {
        _hasPermissions = false;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Set system UI overlay style
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );

    return MaterialApp(
      title: 'Airplane Mode Scheduler',
      debugShowCheckedModeBanner: false,
      theme: _buildLightTheme(),
      darkTheme: _buildDarkTheme(),
      themeMode: ThemeMode.system,
      home: _isLoading
          ? const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            )
          : const HomeScreen(), // Force home to bypass permission screen temporarily
      // Original: _hasPermissions ? const HomeScreen() : const PermissionScreen(),
    );
  }

  ThemeData _buildLightTheme() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF6750A4),
      brightness: Brightness.light,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: Brightness.light,
      textTheme: GoogleFonts.robotoTextTheme(ThemeData.light().textTheme),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        titleTextStyle: GoogleFonts.roboto(
          fontSize: 20,
          fontWeight: FontWeight.w500,
          color: colorScheme.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurfaceVariant,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: colorScheme.primary,
            width: 2,
          ),
        ),
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: colorScheme.surface,
        hourMinuteShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        dayPeriodShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF6750A4),
      brightness: Brightness.dark,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: Brightness.dark,
      textTheme: GoogleFonts.robotoTextTheme(ThemeData.dark().textTheme),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        titleTextStyle: GoogleFonts.roboto(
          fontSize: 20,
          fontWeight: FontWeight.w500,
          color: colorScheme.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurfaceVariant,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: colorScheme.primary,
            width: 2,
          ),
        ),
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: colorScheme.surface,
        hourMinuteShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        dayPeriodShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
