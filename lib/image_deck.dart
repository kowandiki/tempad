

import 'package:bloknot/image_preview.dart';
import 'package:flutter/material.dart';

class ImageDeck extends StatefulWidget {
  final List<String> imageUrls;
  final void Function(String url) onRemove;
  const ImageDeck({
    super.key,
    required this.imageUrls,
    required this.onRemove,
  });

  @override
  State<ImageDeck> createState() => _ImageDeckState();
}

class _ImageDeckState extends State<ImageDeck> {

  final double _minHeight = 80.0;
  final double _maxHeight = 300.0;
  double _height = 150.0;

  // These values are used for smooth drag-resizing
  double _startHeight = 0.0;
  double _dragStart = 0.0;

  List<Widget> getImagePreviews() {
    
    List<Widget> previews = [];

    for (String url in widget.imageUrls) {
      previews.add(
        Padding(
          padding: EdgeInsetsGeometry.all(5),
          child: ImagePreview(imageUrl: url, onRemove: widget.onRemove)
        )  
      );
    }

    return previews;    
  }

  @override
  Widget build(BuildContext context) {
    
    return GestureDetector(
      child: SizedBox(
        height: _height,
        width: double.infinity,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: getImagePreviews()
          )
        )
      ),
      onVerticalDragStart: (details) {
        _dragStart = details.globalPosition.dy;
        _startHeight = _height;
      },
      onVerticalDragUpdate: (details) {

        final diff = (_dragStart - details.globalPosition.dy);

        if (_startHeight + diff < _minHeight) {
          return;
        }

        if (_startHeight + diff > _maxHeight) {
          return;
        }

        _height = _startHeight + diff;
        
        setState((){});
      },
      onVerticalDragEnd: (details) => setState((){}),
    );
  }

}