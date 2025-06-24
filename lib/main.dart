import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'providers/auth_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/auth/profile_setup_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/swipe/swipe_screen.dart';
import 'screens/matches/matches_screen.dart';
import 'screens/chat/chat_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/checkin/checkin_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: 'YOUR_SUPABASE_URL', // Replace with your Supabase URL
    anonKey: 'YOUR_SUPABASE_ANON_KEY', // Replace with your Supabase anon key
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
      ],
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          return MaterialApp.router(
            title: 'Skip The Chase',
            theme: ThemeData(
              primarySwatch: Colors.pink,
              visualDensity: VisualDensity.adaptivePlatformDensity,
              appBarTheme: const AppBarTheme(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                elevation: 0,
              ),
            ),
            routerConfig: _createRouter(authProvider),
          );
        },
      ),
    );
  }

  GoRouter _createRouter(AuthProvider authProvider) {
    return GoRouter(
      initialLocation: authProvider.isAuthenticated ? '/home' : '/login',
      redirect: (context, state) {
        final isAuthenticated = authProvider.isAuthenticated;
        final hasProfile = authProvider.userProfile != null;
        
        if (!isAuthenticated && !state.matchedLocation.startsWith('/auth')) {
          return '/login';
        }
        
        if (isAuthenticated && !hasProfile && state.matchedLocation != '/profile-setup') {
          return '/profile-setup';
        }
        
        return null;
      },
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/signup',
          builder: (context, state) => const SignUpScreen(),
        ),
        GoRoute(
          path: '/profile-setup',
          builder: (context, state) => const ProfileSetupScreen(),
        ),
        GoRoute(
          path: '/home',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/swipe',
          builder: (context, state) => const SwipeScreen(),
        ),
        GoRoute(
          path: '/matches',
          builder: (context, state) => const MatchesScreen(),
        ),
        GoRoute(
          path: '/chat/:matchId',
          builder: (context, state) => ChatScreen(
            matchId: state.pathParameters['matchId']!,
          ),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
        ),
        GoRoute(
          path: '/checkin',
          builder: (context, state) => const CheckInScreen(),
        ),
      ],
    );
  }
}