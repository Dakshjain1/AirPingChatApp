import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class ImageFullScreen extends StatelessWidget {
  final String url;
  final String tag;
  ImageFullScreen(this.tag, this.url);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        color: Colors.black.withOpacity(0.5),
        child: Hero(
          tag: tag,
          child: Center(
            child: CachedNetworkImage(
              placeholder: (context, url) => CircularProgressIndicator(),
              imageUrl: url,
            ),
          ),
        ),
      ),
    );
  }
}
