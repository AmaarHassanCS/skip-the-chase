import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:skip_the_chase/screens/splash_screen.dart';
import 'package:provider/provider.dart';
import 'package:skip_the_chase/providers/auth_provider.dart';
import 'package:skip_the_chase/providers/location_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://cwvedtrzitimchagmhnf.supabase.co', // Replace with your Supabase URL
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImN3dmVkdHJ6aXRpbWNoYWdtaG5mIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTAwNjkxMDMsImV4cCI6MjA2NTY0NTEwM30.UT-OkXkEBuv1ice3mpuHL_PV2hj-wVZbM_m_czLtZ08'
  );
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => LocationProvider()),
      ],
      child: MaterialApp(
        title: 'SkipTheChase',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.purple,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.purple,
            secondary: Colors.pinkAccent,
          ),
          useMaterial3: true,
        ),
        home: const SplashScreen(),
      ),
    );
  }
}