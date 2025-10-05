import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:workmanager/workmanager.dart';
import 'package:epansa_app/core/config/app_config.dart';
import 'package:epansa_app/providers/chat_provider.dart';
import 'package:epansa_app/services/auth_service.dart';
import 'package:epansa_app/services/voice_input_service.dart';
import 'package:epansa_app/services/sync_service.dart';
import 'package:epansa_app/services/alarm_service.dart';
import 'package:epansa_app/services/calendar_event_service.dart';
import 'package:epansa_app/services/sms_service.dart';
import 'package:epansa_app/services/call_service.dart';
import 'package:epansa_app/presentation/screens/login_screen.dart';
import 'package:epansa_app/presentation/screens/chat_screen.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize configuration from .env file
  await AppConfig.initialize();
  
  // Initialize WorkManager for background sync (even when app is closed)
  // This is the key to enabling sync while app is terminated
  if (!kIsWeb) {
    try {
      await Workmanager().initialize(
        callbackDispatcher, // Import from sync_service.dart - runs in background isolate
      );
      debugPrint('✅ Workmanager initialized - background sync ready');
      debugPrint('📱 App can now sync data even when completely closed');
    } catch (e) {
      debugPrint('❌ Failed to initialize Workmanager: $e');
    }
  }
  
  // Print configuration status in debug mode
  if (AppConfig.debugMode) {
    AppConfig.printStatus();
  }
  
  runApp(const EpansaApp());
}

class EpansaApp extends StatefulWidget {
  const EpansaApp({super.key});

  @override
  State<EpansaApp> createState() => _EpansaAppState();
}

class _EpansaAppState extends State<EpansaApp> {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    // Note: flutter_alarm_clock doesn't provide alarm ring events
    // The system Clock app handles all alarm notifications
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => VoiceInputService()),
        ChangeNotifierProvider(
          create: (_) => AlarmService()..initialize(),
        ),
        ChangeNotifierProvider(
          create: (_) => CalendarEventService()..initialize(),
        ),
        ChangeNotifierProvider(
          create: (_) => SmsService()..initialize(),
        ),
        ChangeNotifierProvider(
          create: (_) => CallService()..initialize(),
        ),
        ChangeNotifierProvider(create: (_) => SyncService()),
        ChangeNotifierProxyProvider5<AlarmService, CalendarEventService, SmsService, CallService, SyncService, ChatProvider>(
          create: (context) => ChatProvider(
            alarmService: context.read<AlarmService>(),
            calendarEventService: context.read<CalendarEventService>(),
            smsService: context.read<SmsService>(),
            callService: context.read<CallService>(),
            syncService: context.read<SyncService>(),
          ),
          update: (context, alarmService, calendarEventService, smsService, callService, syncService, previous) =>
              previous ?? ChatProvider(
                alarmService: alarmService,
                calendarEventService: calendarEventService,
                smsService: smsService,
                callService: callService,
                syncService: syncService,
              ),
        ),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        title: 'EPANSA',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
        // Sky blue and white color palette
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF87CEEB), // Sky blue
          primary: const Color(0xFF87CEEB),
          secondary: const Color(0xFF4A90E2),
          surface: Colors.white,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF87CEEB),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF4A90E2),
          foregroundColor: Colors.white,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF0F8FF), // Alice blue (very light sky blue)
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF87CEEB)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFB0E0E6)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF4A90E2), width: 2),
          ),
        ),
        useMaterial3: true,
        ),
        home: const AuthGate(),
      ),
    );
  }
}

/// Auth gate - checks if user is signed in
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();

    if (authService.isSignedIn) {
      return const ChatScreen();
    } else {
      return const LoginScreen();
    }
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'EPANSA',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App logo/icon placeholder
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFF87CEEB).withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.assistant,
                size: 64,
                color: Color(0xFF4A90E2),
              ),
            ),
            const SizedBox(height: 32),
            
            // Welcome text
            const Text(
              'Welcome to EPANSA',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4A90E2),
              ),
            ),
            const SizedBox(height: 16),
            
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Your AI-powered personal assistant',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                ),
              ),
            ),
            const SizedBox(height: 48),
            
            // Get Started button
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const ChatScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A90E2),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 48,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                elevation: 2,
              ),
              child: const Text(
                'Get Started',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Configuration status indicator (visible in debug mode)
            if (AppConfig.debugMode && !AppConfig.isConfigured)
              Card(
                margin: const EdgeInsets.all(16),
                color: Colors.orange.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.warning, color: Colors.orange),
                          SizedBox(width: 8),
                          Text(
                            'Configuration Incomplete',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Missing: ${AppConfig.missingConfiguration.join(", ")}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const ChatScreen(),
            ),
          );
        },
        tooltip: 'Start Chat',
        child: const Icon(Icons.chat),
      ),
    );
  }
}
