import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../config/app_colors.dart';
import '../../config/routes.dart';

// ═══════════════════════════════════════════════════════════════════════
//  SPLASH SCREEN — MEDCONTROL
// ═══════════════════════════════════════════════════════════════════════
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _fade  = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _scale = Tween<double>(begin: 0.85, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));
    _ctrl.forward();
    _checkAuth();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  // ── Verificar sesión activa y redirigir por rol ─────────────────────
  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      Navigator.pushReplacementNamed(context, AppRoutes.login);
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .get();

      if (!mounted) return;

      final rol = doc.exists
          ? (doc.data()?['rol'] ?? doc.data()?['cargo'] ?? 'enfermera')
              .toString()
              .toLowerCase()
          : 'enfermera';

      Navigator.pushReplacementNamed(context, _routeForRol(rol));
    } catch (_) {
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.login);
      }
    }
  }

  String _routeForRol(String rol) {
    if (rol.contains('biomedico') || rol.contains('biomédico')) {
      return AppRoutes.dashboardBiomedico;
    }
    if (rol.contains('admin') || rol.contains('administrador')) {
      return AppRoutes.dashboardAdmin;
    }
    if (rol.contains('gerente')) {
      return AppRoutes.dashboardGerente;
    }
    return AppRoutes.dashboardEnfermera;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: FadeTransition(
        opacity: _fade,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ── Logo ──────────────────────────────────────────
              ScaleTransition(
                scale: _scale,
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: Colors.white.withOpacity(0.3), width: 2),
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/logo_medcontrol.jpg',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ── Nombre ────────────────────────────────────────
              const Text(
                'MedControl',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Sistema Inteligente de Gestión Biomédica',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 14,
                ),
              ),

              const SizedBox(height: 64),

              // ── Indicador de carga ────────────────────────────
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white38,
                ),
              ),

              const SizedBox(height: 16),

              const Text(
                'Q&Q Medical Ltda.',
                style: TextStyle(color: Colors.white38, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
