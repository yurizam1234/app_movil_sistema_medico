import 'package:flutter/material.dart';
import '../config/app_colors.dart';

class StatusChip extends StatelessWidget {
  final String estado;
  final bool small;

  const StatusChip({super.key, required this.estado, this.small = false});

  @override
  Widget build(BuildContext context) {
    final color = colorFor(estado);
    final fs = small ? 11.0 : 12.0;
    final ph = small ? 8.0 : 10.0;
    final pv = small ? 3.0 : 5.0;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: ph, vertical: pv),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            estado,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: fs,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  static Color colorFor(String e) {
    switch (e) {
      case 'Pendiente':        return AppColors.pending;
      case 'Asignada':         return AppColors.assigned;
      case 'En Proceso':       return AppColors.inProcess;
      case 'Resuelta':         return AppColors.resolved;
      case 'Activo':           return AppColors.resolved;
      case 'En mantenimiento': return AppColors.assigned;
      case 'Fuera de servicio':return AppColors.error;
      case 'Baja':             return AppColors.error;
      default:                 return Colors.grey;
    }
  }
}