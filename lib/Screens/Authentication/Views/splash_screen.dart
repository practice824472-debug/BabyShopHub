import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../Controllers/auth_controller.dart';

class SplashScreen extends StatefulWidget {
  /// Message shown under the loading indicator. Defaults to the app's
  /// first-launch copy; login/logout transitions pass a contextual message.
  final String loadingMessage;

  /// How long the splash is shown before routing. First launch keeps the
  /// original 3s brand moment; login/logout transitions use a shorter delay
  /// so the app still feels responsive.
  final Duration duration;

  const SplashScreen({
    super.key,
    this.loadingMessage = 'Loading...',
    this.duration = const Duration(seconds: 3),
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.7,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.elasticOut,
      ),
    );

    _controller.forward();

    Future.delayed(widget.duration, () async {
      if (!mounted) return;

      final auth = context.read<AuthController>();

      // Wait for the role/profile to actually load before routing, otherwise
      // an admin reopening the app is sent to the user home while the role is
      // still null.
      if (auth.user != null) {
        await auth.ensureUserLoaded();
      }

      if (!mounted) return;

      // Check if user is disabled
      if (auth.user != null) {
        final isDisabled = await auth.isUserDisabled();
        if (!mounted) return;

        if (isDisabled) {
          // User is disabled, show login screen
          Navigator.pushReplacementNamed(context, '/login');
          return;
        }
      }

      // Route based on login status and role
      if (auth.user == null) {
        Navigator.pushReplacementNamed(context, '/login');
      } else if (auth.isAdmin) {
        Navigator.pushReplacementNamed(context, '/admin-dashboard');
      } else {
        Navigator.pushReplacementNamed(context, '/user-home');
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white,
                Color(0xff64B5F6),
              ],
            ),
          ),
          child: Stack(
            children: [
              Center(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          "assets/logos/Imagelogo.png",
                          width: 150,
                          height: 150,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "All Your Baby Needs in One Place",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(height: 35),
                        const CircularProgressIndicator(
                          color: Colors.white,
                        ),
                        const SizedBox(height: 15),
                        Text(
                          widget.loadingMessage,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
