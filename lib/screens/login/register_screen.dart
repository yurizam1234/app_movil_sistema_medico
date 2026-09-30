import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../config/app_colors.dart';
import '../../config/routes.dart';

// ═══════════════════════════════════════════════════════════════════════
//  REGISTRO DE USUARIO — MEDCONTROL
// ═══════════════════════════════════════════════════════════════════════
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey      = GlobalKey<FormState>();
  final _nombreCtrl   = TextEditingController();
  final _emailCtrl    = TextEditingController();
  final _passCtrl     = TextEditingController();
  final _confirmCtrl  = TextEditingController();

  bool _obscurePass    = true;
  bool _obscureConfirm = true;
  bool _isLoading      = false;
  String _rolSeleccionado = 'enfermera';

  static const _roles = [
    {'value': 'administrador', 'label': 'Administrador',  'icon': Icons.admin_panel_settings_outlined, 'desc': 'Gestiona usuarios, hospitales y configuración'},
    {'value': 'biomedico',     'label': 'Biomédico',      'icon': Icons.medical_services_outlined,     'desc': 'Atiende y registra mantenimiento de equipos'},
    {'value': 'enfermera',     'label': 'Enfermera',      'icon': Icons.local_hospital_outlined,       'desc': 'Reporta incidencias y consulta equipos'},
  ];

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _registrar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      // 1. Crear cuenta en Firebase Auth
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email:    _emailCtrl.text.trim(),
        password: _passCtrl.text,
      );

      // 2. Actualizar displayName
      await cred.user!.updateDisplayName(_nombreCtrl.text.trim());

      // 3. Guardar en Firestore
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(cred.user!.uid)
          .set({
        'uid':            cred.user!.uid,
        'nombre':         _nombreCtrl.text.trim(),
        'email':          _emailCtrl.text.trim(),
        'rol':            _rolSeleccionado,
        'cargo':          _rolSeleccionado,
        'activo':         true,
        'photoUrl':       '',
        'hospital':       '',
        'telefono':       '',
        'especialidad':   '',
        'experiencia':    '',
        'fechaRegistro':  DateTime.now().toIso8601String(),
      });

      if (!mounted) return;
      setState(() => _isLoading = false);

      Navigator.pushReplacementNamed(context, _routeForRol(_rolSeleccionado));
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _snack(_mensajeError(e.code));
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
        _snack('Error inesperado. Intenta nuevamente.');
      }
    }
  }

  String _routeForRol(String rol) {
    if (rol == 'biomedico')     return AppRoutes.dashboardBiomedico;
    if (rol == 'administrador') return AppRoutes.dashboardAdmin;
    return AppRoutes.dashboardEnfermera;
  }

  String _mensajeError(String code) {
    switch (code) {
      case 'email-already-in-use':   return 'Este correo ya tiene una cuenta registrada.';
      case 'invalid-email':          return 'El formato del correo no es válido.';
      case 'weak-password':          return 'La contraseña es demasiado débil (mín. 6 caracteres).';
      case 'operation-not-allowed':  return 'Registro no habilitado. Contacta al administrador.';
      default:                       return 'Error al crear cuenta. Intenta nuevamente.';
    }
  }

  void _snack(String msg, {bool ok = false}) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: ok ? AppColors.resolved : AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));

  Color _rolColor(String val) {
    if (val == 'administrador') return AppColors.primary;
    if (val == 'biomedico')     return AppColors.accent;
    return Colors.teal;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Column(
          children: [
            // ── Encabezado azul ─────────────────────────────────────────
            SizedBox(
              height: size.height * 0.22,
              child: Stack(
                children: [
                  // Botón volver
                  Positioned(
                    top: 8, left: 8,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white70, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 70, height: 70,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: Colors.white.withOpacity(0.3), width: 2),
                          ),
                          child: const Icon(Icons.person_add_outlined,
                              color: Colors.white, size: 34),
                        ),
                        const SizedBox(height: 12),
                        const Text('Crear cuenta',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        const Text('Elige tu rol y completa tus datos',
                            style: TextStyle(
                                color: Colors.white60, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Formulario blanco ────────────────────────────────────────
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
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        // ── Selector de rol ───────────────────────────
                        const Text('Tipo de cuenta',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: AppColors.textPrimary)),
                        const SizedBox(height: 12),

                        Row(
                          children: _roles.map((r) {
                            final val      = r['value']! as String;
                            final label    = r['label']! as String;
                            final icon     = r['icon']!  as IconData;
                            final selected = _rolSeleccionado == val;
                            final color    = _rolColor(val);
                            return Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: GestureDetector(
                                  onTap: () =>
                                      setState(() => _rolSeleccionado = val),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12, horizontal: 4),
                                    decoration: BoxDecoration(
                                      color: selected
                                          ? color.withOpacity(0.1)
                                          : AppColors.background,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: selected
                                            ? color
                                            : AppColors.divider,
                                        width: selected ? 2 : 1,
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Icon(icon,
                                            color: selected
                                                ? color
                                                : AppColors.textSecondary,
                                            size: 26),
                                        const SizedBox(height: 6),
                                        Text(label,
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: selected
                                                    ? FontWeight.bold
                                                    : FontWeight.normal,
                                                color: selected
                                                    ? color
                                                    : AppColors.textSecondary)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 6),
                        Text(
                          _roles.firstWhere((r) =>
                              r['value'] == _rolSeleccionado)['desc'] as String,
                          style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12),
                        ),

                        const SizedBox(height: 22),

                        // ── Campos ───────────────────────────────────
                        _campo(
                          ctrl:        _nombreCtrl,
                          label:       'Nombre completo',
                          icon:        Icons.person_outline,
                          action:      TextInputAction.next,
                          validator:   (v) => v == null || v.trim().isEmpty
                              ? 'Ingresa tu nombre' : null,
                        ),

                        _campo(
                          ctrl:        _emailCtrl,
                          label:       'Correo electrónico',
                          icon:        Icons.email_outlined,
                          tipo:        TextInputType.emailAddress,
                          action:      TextInputAction.next,
                          validator:   (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Ingresa tu correo';
                            }
                            if (!v.contains('@') || !v.contains('.')) {
                              return 'Correo no válido';
                            }
                            return null;
                          },
                        ),

                        // Contraseña
                        Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: TextFormField(
                            controller:   _passCtrl,
                            obscureText:  _obscurePass,
                            textInputAction: TextInputAction.next,
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return 'Ingresa una contraseña';
                              }
                              if (v.length < 6) {
                                return 'Mínimo 6 caracteres';
                              }
                              return null;
                            },
                            decoration: _deco('Contraseña', Icons.lock_outline).copyWith(
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePass
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: AppColors.textSecondary, size: 20,
                                ),
                                onPressed: () =>
                                    setState(() => _obscurePass = !_obscurePass),
                              ),
                            ),
                          ),
                        ),

                        // Confirmar contraseña
                        Padding(
                          padding: const EdgeInsets.only(bottom: 24),
                          child: TextFormField(
                            controller:      _confirmCtrl,
                            obscureText:     _obscureConfirm,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _registrar(),
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return 'Confirma tu contraseña';
                              }
                              if (v != _passCtrl.text) {
                                return 'Las contraseñas no coinciden';
                              }
                              return null;
                            },
                            decoration: _deco('Confirmar contraseña', Icons.lock_outline).copyWith(
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirm
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: AppColors.textSecondary, size: 20,
                                ),
                                onPressed: () => setState(
                                    () => _obscureConfirm = !_obscureConfirm),
                              ),
                            ),
                          ),
                        ),

                        // ── Botón registrar ───────────────────────
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _registrar,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _rolColor(_rolSeleccionado),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                              elevation: 3,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 22, height: 22,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: Colors.white))
                                : const Text('Crear cuenta',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold)),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // ── Ya tienes cuenta ──────────────────────
                        Center(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: RichText(
                              text: const TextSpan(
                                text: '¿Ya tienes cuenta? ',
                                style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 13),
                                children: [
                                  TextSpan(
                                    text: 'Iniciar sesión',
                                    style: TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.bold),
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
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _campo({
    required TextEditingController ctrl,
    required String label,
    required IconData icon,
    TextInputType tipo = TextInputType.text,
    TextInputAction action = TextInputAction.next,
    String? Function(String?)? validator,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: TextFormField(
          controller:      ctrl,
          keyboardType:    tipo,
          textInputAction: action,
          validator:       validator,
          decoration:      _deco(label, icon),
        ),
      );

  InputDecoration _deco(String label, IconData icon) => InputDecoration(
        labelText:  label,
        prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 20),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.divider, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
              color: _rolColor(_rolSeleccionado), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        filled:         true,
        fillColor:      AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 16),
      );
}
