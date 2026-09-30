import 'package:flutter/material.dart';

class InfoCard extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String valor;

  const InfoCard({
    super.key,
    required this.icono,
    required this.titulo,
    required this.valor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListTile(
        leading: Icon(
          icono,
          color: Colors.blue,
        ),
        title: Text(
          titulo,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(valor),
      ),
    );
  }
}