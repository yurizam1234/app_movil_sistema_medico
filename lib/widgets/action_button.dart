import 'package:flutter/material.dart';

class ActionButton extends StatelessWidget {
  final String texto;
  final IconData icono;
  final VoidCallback onPressed;

  const ActionButton({
    super.key,
    required this.texto,
    required this.icono,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton.icon(
        icon: Icon(icono),
        label: Text(
          texto,
          style: const TextStyle(fontSize: 16),
        ),
        onPressed: onPressed,
      ),
    );
  }
}