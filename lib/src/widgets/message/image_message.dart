import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_ui/src/widgets/state/inherited_user.dart';

import '../../conditional/conditional.dart';

/// A class that represents image message widget. Supports different
/// aspect ratios, renders blurred image as a background which is visible
/// if the image is narrow, renders image in form of a file if aspect
/// ratio is very small or very big.
class ImageMessage extends StatefulWidget {
  /// Creates an image message widget based on [types.ImageMessage].
  const ImageMessage({
    super.key,
    this.imageHeaders,
    this.imageProviderBuilder,
    required this.message,
    required this.messageWidth,
    this.onImagePressed,
  });

  /// See [Chat.imageHeaders].
  final Map<String, String>? imageHeaders;

  /// See [Chat.imageProviderBuilder].
  final ImageProvider Function({
    required String uri,
    required Map<String, String>? imageHeaders,
    required Conditional conditional,
  })? imageProviderBuilder;

  /// [types.ImageMessage].
  final types.ImageMessage message;

  /// Maximum message width.
  final int messageWidth;

  final void Function(String imageId)? onImagePressed;

  @override
  State<ImageMessage> createState() => _ImageMessageState();
}

/// [ImageMessage] widget state.
class _ImageMessageState extends State<ImageMessage> {
  ImageProvider? _image;
  List<String>? _images;
  Size _size = Size.zero;
  ImageStream? _stream;

  @override
  void initState() {
    super.initState();
    _images = widget.message.uris;
    _size = Size(widget.message.width ?? 0, widget.message.height ?? 0);
  }

  void _getImage() {
    final oldImageStream = _stream;
    _stream = _image?.resolve(createLocalImageConfiguration(context));
    if (_stream?.key == oldImageStream?.key) {
      return;
    }
    final listener = ImageStreamListener(_updateImage);
    oldImageStream?.removeListener(listener);
    _stream?.addListener(listener);
  }

  void _updateImage(ImageInfo info, bool _) {
    setState(() {
      _size = Size(
        info.image.width.toDouble(),
        info.image.height.toDouble(),
      );
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_size.isEmpty) {
      _getImage();
    }
  }

  @override
  void dispose() {
    _stream?.removeListener(ImageStreamListener(_updateImage));
    super.dispose();
  }

  bool _isCurrentUserAuthor() {
    final user = InheritedUser.of(context).user;
    return user.id == widget.message.author.id;
  }

  @override
  Widget build(BuildContext context) {
    if (_images == null) return const SizedBox();

    final imagesNums = (_images?.length ?? 0);
    final itemPadding = 8.toDouble();
    const maxItemInRow = 3;
    const maxItemInColumn = 3;

    final rowNums = (imagesNums / maxItemInRow).ceil();
    final colNums = imagesNums >= maxItemInColumn
        ? maxItemInColumn
        : (imagesNums % maxItemInColumn).ceil();

    final itemSize =
        (widget.messageWidth - (itemPadding * (colNums - 1))) / colNums;

    return Container(
      alignment:
          _isCurrentUserAuthor() ? Alignment.centerRight : Alignment.centerLeft,
      child: Wrap(
        alignment:
            _isCurrentUserAuthor() ? WrapAlignment.end : WrapAlignment.start,
        children: _images == null
            ? []
            : _images!
                .map(
                  (uri) => GestureDetector(
                    onTap: () => widget.onImagePressed?.call(
                      '${widget.message.id}-$uri',
                    ),
                    child: Container(
                      width: itemSize,
                      height: itemSize,
                      padding: EdgeInsets.only(
                        right: (colNums > 1 && !_isCurrentUserAuthor())
                            ? itemPadding
                            : 0,
                        left: (colNums > 1 && _isCurrentUserAuthor())
                            ? itemPadding
                            : 0,
                        bottom: rowNums > 1 ? itemPadding : 0,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image(
                          fit: BoxFit.cover,
                          image: widget.imageProviderBuilder != null
                              ? widget.imageProviderBuilder!(
                                  uri: uri,
                                  imageHeaders: widget.imageHeaders,
                                  conditional: Conditional(),
                                )
                              : Conditional().getProvider(
                                  uri,
                                  headers: widget.imageHeaders,
                                ),
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
      ),
    );
  }
}
