import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../config/app_colors.dart';
import '../../config/routes.dart';

// ═══════════════════════════════════════════════════════════════════════
//  PERFIL ENFERMERA
// ═══════════════════════════════════════════════════════════════════════
class PerfilEnfermeraScreen extends StatelessWidget {
  const PerfilEnfermeraScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final nombre = user?.displayName ?? 'Enfermera';
    final email = user?.email ?? 'sin.correo@qqmedical.com';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Avatar y datos principales ────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primary, AppColors.primaryLight],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Column(
                children: [
                  Stack(
                    children: [
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: Colors.white.withOpacity(0.5),
                              width: 3),
                        ),
                        child: const Icon(Icons.person,
                            color: Colors.white, size: 48),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                              color: AppColors.accent,
                              shape: BoxShape.circle),
                          child: const Icon(Icons.edit,
                              color: Colors.white, size: 14),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    nombre,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('Enfermera',
                        style:
                            TextStyle(color: Colors.white70, fontSize: 13)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    email,
                    style: const TextStyle(
                        color: Colors.white60, fontSize: 13),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Información institucional ──────────────────────────
            _SectionCard(
              title: 'Información institucional',
              children: const [
                _ProfileTile(
                  icon: Icons.local_hospital_outlined,
                  label: 'Hospital',
                  value: 'Q&Q Medical Ltda.',
                ),
                _ProfileTile(
                  icon: Icons.location_on_outlined,
                  label: 'Área',
                  value: 'UCI — Unidad de Cuidados Intensivos',
                ),
                _ProfileTile(
                  icon: Icons.badge_outlined,
                  label: 'Cargo',
                  value: 'Enfermera Jefe de Turno',
                  isLast: true,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── Datos de contacto ──────────────────────────────────
            _SectionCard(
              title: 'Datos de contacto',
              children: [
                _ProfileTile(
                  icon: Icons.email_outlined,
                  label: 'Correo',
                  value: email,
                ),
                const _ProfileTile(
                  icon: Icons.phone_outlined,
                  label: 'Teléfono',
                  value: '+591 7XXXXXXX',
                  isLast: true,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── Configuración ──────────────────────────────────────
            _SectionCard(
              title: 'Configuración',
              children: [
                _ActionTile(
                  icon: Icons.lock_outline,
                  label: 'Cambiar contraseña',
                  color: AppColors.secondary,
                  onTap: () => _showChangePassword(context, email),
                ),
                _ActionTile(
                  icon: Icons.notifications_outlined,
                  label: 'Notificaciones',
                  color: AppColors.accent,
                  onTap: () {},
                  isLast: true,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── Cerrar sesión ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GestureDetector(
                onTap: () => _showLogoutDialog(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: AppColors.error.withOpacity(0.2)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.logout_rounded,
                          color: AppColors.error, size: 20),
                      SizedBox(width: 10),
                      Text('Cerrar sesión',
                          style: TextStyle(
                              color: AppColors.error,
                              fontWeight: FontWeight.bold,
                              fontSize: 15)),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            const Text(
              'MedControl v1.0 — Q&Q Medical Ltda.',
              style: TextStyle(color: AppColors.textLight, fontSize: 12),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ── Cambiar contraseña ──────────────────────────────────────────────
  void _showChangePassword(BuildContext context, String email) {
    showDialog<void>(
      context: context,
      builder: (ctx) {
        bool loading = false;
        return StatefulBuilder(builder: (ctx2, setDlgState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            title: const Text('Cambiar contraseña'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Te enviaremos un enlace de recuperación a tu correo registrado.',
                  style: TextStyle(
                      color: AppColors.textSecondary, fontSize: 14, height: 1.4),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.email_outlined,
                          color: AppColors.primary, size: 18),
                      const SizedBox(width: 8),
                      Text(email,
                          style: const TextStyle(
                              fontWeight: FontWeight.w500, fontSize: 13)),
                    ],
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
                onPressed: loading
                    ? null
                    : () async {
                        setDlgState(() => loading = true);
                        try {
                          await FirebaseAuth.instance
                              .sendPasswordResetEmail(email: email);
                          if (ctx.mounted) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    '✅ Enlace enviado. Revisa tu correo.'),
                                backgroundColor: AppColors.resolved,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        } catch (_) {
                          setDlgState(() => loading = false);
                        }
                      },
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white),
                child: loading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Enviar enlace'),
              ),
            ],
          );
        });
      },
    );
  }

  // ── Confirmar cierre de sesión ──────────────────────────────────────
  void _showLogoutDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Cerrar sesión'),
        content: const Text(
          '¿Estás seguro de que deseas cerrar sesión en MedControl?',
          style: TextStyle(color: AppColors.textSecondary, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                    context, AppRoutes.login, (_) => false);
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
  }
}

// ─── Card de sección ──────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: Text(
                title,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.5),
              ),
            ),
            const Divider(height: 1, color: AppColors.divider),
            ...children,
          ],
        ),
      ),
    );
  }
}

// ─── Fila de perfil ───────────────────────────────────────────────────
class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isLast;

  const _ProfileTile({
    required this.icon,
    required this.label,
    required this.value,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: AppColors.primary, size: 18),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 12)),
                    const SizedBox(height: 2),
                    Text(value,
                        style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                            color: AppColors.textPrimary)),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          const Divider(
              height: 1, color: AppColors.divider, indent: 16, endIndent: 16),
      ],
    );
  }
}

// ─── Fila de acción ───────────────────────────────────────────────────
class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool isLast;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8)),
                  child: Icon(icon, color: color, size: 18),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(label,
                      style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                          color: AppColors.textPrimary)),
                ),
                const Icon(Icons.arrow_forward_ios,
                    size: 14, color: AppColors.textLight),
              ],
            ),
          ),
        ),
        if (!isLast)
          const Divider(
              height: 1, color: AppColors.divider, indent: 16, endIndent: 16),
      ],
    );
  }
}
