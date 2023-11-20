import 'package:flutter/material.dart';
import 'package:photo_view/photo_view_gallery.dart';

import '../conditional/conditional.dart';
import '../models/preview_image.dart';

class ImageGallery extends StatefulWidget {
  const ImageGallery({
    super.key,
    this.imageHeaders,
    this.imageProviderBuilder,
    required this.images,
    required this.onClosePressed,
    required this.initPage,
    this.options = const ImageGalleryOptions(),
    required this.pageController,
  });

  /// See [Chat.imageHeaders].
  final Map<String, String>? imageHeaders;

  /// See [Chat.imageProviderBuilder].
  final ImageProvider Function({
    required String uri,
    required Map<String, String>? imageHeaders,
    required Conditional conditional,
  })? imageProviderBuilder;

  /// Images to show in the gallery.
  final List<PreviewImage> images;

  /// Triggered when the gallery is swiped down or closed via the icon.
  final VoidCallback onClosePressed;

  /// Customisation options for the gallery.
  final ImageGalleryOptions options;

  /// Page controller for the image pages.
  final PageController pageController;

  /// Init page for current image.
  final int initPage;

  @override
  State<ImageGallery> createState() => _ImageGalleryState();
}

class _ImageGalleryState extends State<ImageGallery> {
  int currentPage = 0;

  @override
  void initState() {
    setState(() {
      currentPage = widget.initPage;
    });
    super.initState();
  }

  Widget _imageGalleryLoadingBuilder(ImageChunkEvent? event) => Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            value: event == null || event.expectedTotalBytes == null
                ? 0
                : event.cumulativeBytesLoaded / event.expectedTotalBytes!,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) => WillPopScope(
        onWillPop: () async {
          widget.onClosePressed();
          return false;
        },
        child: Dismissible(
          key: const Key('photo_view_gallery'),
          direction: DismissDirection.down,
          onDismissed: (direction) => widget.onClosePressed(),
          child: Stack(
            children: [
              PhotoViewGallery.builder(
                builder: (BuildContext context, int index) =>
                    PhotoViewGalleryPageOptions(
                  imageProvider: widget.imageProviderBuilder != null
                      ? widget.imageProviderBuilder!(
                          uri: widget.images[index].uri,
                          imageHeaders: widget.imageHeaders,
                          conditional: Conditional(),
                        )
                      : Conditional().getProvider(
                          widget.images[index].uri,
                          headers: widget.imageHeaders,
                        ),
                  minScale: widget.options.minScale,
                  maxScale: widget.options.maxScale,
                ),
                itemCount: widget.images.length,
                loadingBuilder: (context, event) =>
                    _imageGalleryLoadingBuilder(event),
                pageController: widget.pageController,
                scrollPhysics: const ClampingScrollPhysics(),
                onPageChanged: (index) => setState(() {
                  currentPage = index + 1;
                }),
              ),
              Positioned.directional(
                textDirection: Directionality.of(context),
                top: 20,
                child: SizedBox(
                  width: MediaQuery.sizeOf(context).width,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: CloseButton(
                          color: Colors.white,
                          onPressed: widget.onClosePressed,
                        ),
                      ),
                      Container(
                        height: 26,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: ShapeDecoration(
                          color: Colors.white.withOpacity(0.699999988079071),
                          shape: RoundedRectangleBorder(
                            side: BorderSide(
                              width: 1,
                              color:
                                  Colors.white.withOpacity(0.30000001192092896),
                            ),
                            borderRadius: BorderRadius.circular(1000),
                          ),
                        ),
                        child: Text(
                          '$currentPage/${widget.images.length}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFF08080A),
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}

class ImageGalleryOptions {
  const ImageGalleryOptions({
    this.maxScale,
    this.minScale,
  });

  /// See [PhotoViewGalleryPageOptions.maxScale].
  final dynamic maxScale;

  /// See [PhotoViewGalleryPageOptions.minScale].
  final dynamic minScale;
}
