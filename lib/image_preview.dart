import 'dart:io';

import 'package:bloknot/image_view.dart';
import 'package:flutter/material.dart';

class ImagePreview extends StatelessWidget {

  final String imageUrl;

  final void Function(String url) onRemove;

  const ImagePreview({
    super.key,
    required this.imageUrl,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ImageView(imageUrl: imageUrl),
          ),
        );
      },
      
      child: Stack(
        children: [
          Hero(tag: imageUrl, child: Image.file(File(imageUrl))),
          Positioned(
            top: 0,
            right: 0,
            child: SizedBox(
              width: 24,
              height: 24,
              
              child: IconButton(
                  onPressed: () => onRemove(imageUrl),
                  padding: EdgeInsets.zero,
                  icon: Icon(Icons.close_outlined, size: 20),
                  style: ButtonStyle(backgroundColor: WidgetStateProperty.all(Color(0xaaffffff)),
                )
              ),
            )
          )
        ]
      )
    );
  }
}