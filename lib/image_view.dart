
import 'dart:io';

import 'package:bloknot/globals.dart';
import 'package:flutter/material.dart';

class ImageView extends StatelessWidget {

  final String imageUrl;

  const ImageView({
    super.key,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: RichText(
          text: TextSpan(
            text: "Image View",
            style: TextStyle(color: Globals.appButtonColor, fontSize: 25.0),
          ),
        ),
        backgroundColor: Globals.appColor,
        iconTheme: IconThemeData(color: Globals.appButtonColor),
      ),
      body: InteractiveViewer(
        panEnabled: true,
        minScale: 0.1,
        maxScale: 4.0, 
        child: SizedBox.expand(
          child: Hero(
              tag: imageUrl,
              child: Image.file(
              File(imageUrl),
              fit: BoxFit.contain
            )
          )
        )
      )
    );
  }
}