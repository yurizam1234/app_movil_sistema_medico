import 'package:flutter/material.dart';

abstract class AppColors {
  // ── Brand ────────────────────────────────────────────────────────────
  static const Color primary      = Color(0xFF0D2D6C);
  static const Color primaryDark  = Color(0xFF091E4A);
  static const Color primaryLight = Color(0xFF1A4A9E);
  static const Color secondary    = Color(0xFF1E88E5);
  static const Color accent       = Color(0xFF00B8A9);
  static const Color accentDark   = Color(0xFF00897B);

  // ── Backgrounds ──────────────────────────────────────────────────────
  static const Color background     = Color(0xFFF5F7FA);
  static const Color surface        = Colors.white;
  static const Color surfaceVariant = Color(0xFFF0F4FF);

  // ── Text ─────────────────────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textLight     = Color(0xFF9CA3AF);

  // ── Status / Estado ───────────────────────────────────────────────────
  static const Color pending   = Color(0xFFF59E0B);   // Pendiente
  static const Color assigned  = Color(0xFF3B82F6);   // Asignada
  static const Color inProcess = Color(0xFF8B5CF6);   // En Proceso
  static const Color resolved  = Color(0xFF10B981);   // Resuelta
  static const Color error     = Color(0xFFEF4444);   // Error / Fuera de servicio

  // ── Utility ──────────────────────────────────────────────────────────
  static const Color divider = Color(0xFFE5E7EB);
  static const Color shadow  = Color(0x0F000000);
}
