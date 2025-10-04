import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:epansa_app/services/auth_service.dart';
import 'package:epansa_app/presentation/screens/sync_setup_screen.dart';

/// Login screen - primary entry point requiring Google authentication
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOut));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);

    try {
      debugPrint('🔵 Attempting Google Sign-In...');
      final authService = context.read<AuthService>();
      final success = await authService.signIn();

      debugPrint('🔵 Sign-in result: $success');

      if (!mounted) return;

      if (success) {
        debugPrint('✅ Sign-in successful, navigating to sync setup');
        // Navigate to sync setup screen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const SyncSetupScreen(),
          ),
        );
      } else {
        debugPrint('❌ Sign-in failed');
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sign in failed. Please check your internet connection and try again.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Sign-in error: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFF87CEEB),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF87CEEB), // Sky blue
              const Color(0xFF4A90E2), // Deep blue
              const Color(0xFF87CEEB).withOpacity(0.8),
            ],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 40.0),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // App Logo/Icon
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.smart_toy_rounded,
                          size: 60,
                          color: Color(0xFF4A90E2),
                        ),
                      ),
                      const SizedBox(height: 40),

                      // App Name
                      const Text(
                        'EPANSA',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Tagline
                      Text(
                        'Your AI-Powered Personal Assistant',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.9),
                          letterSpacing: 0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 60),

                      // Features List
                      _buildFeatureItem(Icons.calendar_today, 'Manage your calendar'),
                      const SizedBox(height: 16),
                      _buildFeatureItem(Icons.note_outlined, 'Organize your notes'),
                      const SizedBox(height: 16),
                      _buildFeatureItem(Icons.contacts_outlined, 'Access your contacts'),
                      const SizedBox(height: 16),
                      _buildFeatureItem(Icons.alarm, 'Set and manage alarms'),
                      const SizedBox(height: 16),
                      _buildFeatureItem(Icons.phone, 'Track your call history'),
                      const SizedBox(height: 16),
                      _buildFeatureItem(Icons.search, 'Search the web'),
                      const SizedBox(height: 60),

                      // Sign In Button
                      _isLoading
                          ? const CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            )
                          : ElevatedButton.icon(
                              onPressed: _handleGoogleSignIn,
                              icon: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Icon(
                                  Icons.g_mobiledata_rounded,
                                  size: 24,
                                  color: Color(0xFF4285F4),
                                ),
                              ),
                              label: const Text(
                                'Sign in with Google',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFF4A90E2),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32,
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                elevation: 8,
                              ),
                            ),
                      const SizedBox(height: 24),

                      // Privacy Notice
                      Text(
                        'By signing in, you agree to sync your calendar,\ncontacts, notes, alarms, and call history with EPANSA',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.7),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(width: 12),
        Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
