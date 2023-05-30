import 'package:flutter/material.dart';
import 'dart:io';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ImagePreview extends StatelessWidget {
  final File? image;
  final Function? onRemove;

  const ImagePreview({Key? key, this.image, this.onRemove}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(3.0),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: FileImage(image!),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned(
            bottom: 15.0,
            right: 15.0,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(50.0),
                color: Colors.black.withOpacity(0.35),
              ),
              child: IconButton(
                iconSize: 18.0,
                visualDensity: VisualDensity.compact,
                icon: Icon(
                  FontAwesomeIcons.times,
                  color: Colors.white,
                ),
                onPressed: () => {onRemove!()},
              ),
            ),
          )
        ],
      ),
    );
  }
}
