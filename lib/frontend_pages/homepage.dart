import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../depth_live_app.dart';
import '../frontend_theme/app_theme.dart';
import 'navigation_page.dart';

class HomePage extends StatelessWidget {
  final CameraDescription camera;
  const HomePage({super.key, required this.camera});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      body: Column(
        children: [
          // Navigation Mode Button
          Expanded(
            child: Semantics(
              label: 'Navigation Mode. Double tap to activate.',
              hint: 'This mode helps you navigate your surroundings.',
              button: true,
              child: _ModeButton(
                title: 'Navigation Mode',
                icon: Icons.navigation,
                color: AppTheme.primaryBlue,
                onTap: () {
                  Navigator.of(context).push(
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) =>
                          const NavigationPage(),
                      transitionsBuilder: (context, animation, secondaryAnimation, child) {
                        return FadeTransition(opacity: animation, child: child);
                      },
                    ),
                  );
                },
              ),
            ),
          ),
          // Object Detection Mode Button
          Expanded(
            child: Semantics(
              label: 'Object Detection Mode. Double tap to activate.',
              hint: 'This mode helps you detect and identify objects around you.',
              button: true,
              child: _ModeButton(
                title: 'Object Detection Mode',
                icon: Icons.camera_alt,
                color: AppTheme.primaryGreen,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => DepthLivePage(camera: camera),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ModeButton({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color,
                color.withOpacity(0.8),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 64,
                color: Colors.white,
              ),
              const SizedBox(height: AppTheme.spacingL),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
