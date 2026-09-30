import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../config/app_colors.dart';
import '../../config/routes.dart';

// ═══════════════════════════════════════════════════════════════════════
//  LOGIN SCREEN — MEDCONTROL
//  Diseño split: parte superior azul oscuro + parte inferior blanca
// ═══════════════════════════════════════════════════════════════════════
class LoginScreen extends StatefulWidget {
  LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey   = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  bool _obscure   = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  // ── Autenticación + lectura de rol ──────────────────────────────────
  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email:    _emailCtrl.text.trim(),
        password: _passCtrl.text,
      );

      if (!mounted) return;

      final doc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(cred.user!.uid)
          .get();

      if (!mounted) return;
      setState(() => _isLoading = false);

      final rol = doc.exists
          ? (doc.data()?['rol'] ?? doc.data()?['cargo'] ?? 'enfermera')
              .toString()
              .toLowerCase()
          : 'enfermera';

      Navigator.pushReplacementNamed(context, _routeForRol(rol));
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _snack(_mensajeError(e.code));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _snack('Error inesperado. Intenta nuevamente.');
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

  // ── Recuperar contraseña ────────────────────────────────────────────
  void _showForgotPassword() {
    final ctrl = TextEditingController(text: _emailCtrl.text.trim());
    bool sending = false;

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, set) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.lock_reset_outlined, color: AppColors.primary),
              SizedBox(width: 10),
              Text('Recuperar contraseña'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Ingresa tu correo institucional para recibir el enlace de recuperación.',
                style: TextStyle(
                    color: AppColors.textSecondary, fontSize: 14, height: 1.45),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: ctrl,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Correo electrónico',
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: sending
                  ? null
                  : () async {
                      if (ctrl.text.trim().isEmpty) return;
                      set(() => sending = true);
                      try {
                        await FirebaseAuth.instance
                            .sendPasswordResetEmail(email: ctrl.text.trim());
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                          _snack(
                              '✅ Enlace enviado a ${ctrl.text.trim()}',
                              isSuccess: true);
                        }
                      } on FirebaseAuthException {
                        set(() => sending = false);
                        _snack('Correo no encontrado.');
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: sending
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Enviar enlace'),
            ),
          ],
        ),
      ),
    );
  }

  void _snack(String msg, {bool isSuccess = false}) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: isSuccess ? AppColors.resolved : AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));

  String _mensajeError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No existe una cuenta con este correo.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Contraseña incorrecta. Intenta nuevamente.';
      case 'invalid-email':
        return 'El formato del correo no es válido.';
      case 'user-disabled':
        return 'Esta cuenta ha sido deshabilitada.';
      case 'too-many-requests':
        return 'Demasiados intentos. Espera unos minutos.';
      default:
        return 'Error de autenticación. Intenta nuevamente.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.primary,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            // ══════════════════════════════════════════════════
            // PARTE SUPERIOR — Azul oscuro con logo y título
            // ══════════════════════════════════════════════════
            SizedBox(
              height: size.height * 0.34,
              child: Container(
                color: AppColors.primary,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo circular
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Colors.white.withOpacity(0.35), width: 2),
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/logo_medcontrol.jpg',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    const Text(
                      'MedControl',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.3,
                      ),
                    ),

                    const SizedBox(height: 6),

                    const Text(
                      'Sistema Inteligente de Gestión Biomédica',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ══════════════════════════════════════════════════
            // PARTE INFERIOR — Blanca con esquinas redondeadas
            // ══════════════════════════════════════════════════
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft:  Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(28, 28, 28, 20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Iniciar sesión',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Ingresa tus credenciales institucionales',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 13),
                        ),

                        const SizedBox(height: 24),

                        // ── Correo ─────────────────────────────
                        TextFormField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Ingresa tu correo';
                            }
                            if (!v.contains('@')) return 'Correo no válido';
                            return null;
                          },
                          decoration: _inputDeco(
                            'Correo electrónico',
                            Icons.email_outlined,
                          ),
                        ),

                        const SizedBox(height: 14),

                        // ── Contraseña ─────────────────────────
                        TextFormField(
                          controller: _passCtrl,
                          obscureText: _obscure,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _login(),
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Ingresa tu contraseña';
                            }
                            if (v.length < 6) {
                              return 'Mínimo 6 caracteres';
                            }
                            return null;
                          },
                          decoration: _inputDeco(
                            'Contraseña',
                            Icons.lock_outline,
                          ).copyWith(
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscure
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: AppColors.textSecondary,
                              ),
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                            ),
                          ),
                        ),

                        // ── ¿Olvidaste tu contraseña? ──────────
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _showForgotPassword,
                            child: const Text(
                              '¿Olvidaste tu contraseña?',
                              style: TextStyle(
                                  color: AppColors.secondary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500),
                            ),
                          ),
                        ),

                        // ── Botón ingresar ─────────────────────
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                              elevation: 3,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: Colors.white))
                                : const Text(
                                    'Ingresar',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // ── Botón Crear cuenta ─────────────────
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: OutlinedButton.icon(
                            onPressed: () => Navigator.pushNamed(
                                context, AppRoutes.register),
                            icon: const Icon(Icons.person_add_outlined,
                                size: 20, color: AppColors.primary),
                            label: const Text(
                              'Crear cuenta nueva',
                              style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                  color: AppColors.primary, width: 1.5),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // ── Footer ─────────────────────────────
                        Center(
                          child: Text(
                            'MedControl v1.0 · Q&Q Medical Ltda.',
                            style: TextStyle(
                                color: Colors.grey.shade400, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDeco(String label, IconData icon) => InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 20),
        border:
            OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: AppColors.divider, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: AppColors.error, width: 1.5),
        ),
        filled: true,
        fillColor: AppColors.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      );
}
