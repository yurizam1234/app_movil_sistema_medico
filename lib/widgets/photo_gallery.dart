import 'package:flutter/material.dart';

class PhotoGallery extends StatelessWidget {
  final List<String> fotos;

  const PhotoGallery({
    super.key,
    required this.fotos,
  });

  @override
  Widget build(BuildContext context) {
    if (fotos.isEmpty) {
      return Card(
        child: SizedBox(
          height: 180,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(
                  Icons.image_not_supported,
                  size: 60,
                  color: Colors.grey,
                ),
                SizedBox(height: 10),
                Text("No existen fotografías"),
              ],
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 130,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: fotos.length,
        itemBuilder: (context, index) {
          return Container(
            width: 140,
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey.shade300,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                fotos[index],
                fit: BoxFit.cover,
              ),
            ),
          );
        },
      ),
    );
  }
}