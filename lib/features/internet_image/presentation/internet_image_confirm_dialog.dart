import 'package:cached_network_image/cached_network_image.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/material.dart';
import 'package:super_logger/features/internet_image/models/internet_image_log.dart';
import 'package:super_logger/utils/extensions.dart';

class InternetImageConfirmDialog extends StatefulWidget {
  const InternetImageConfirmDialog({Key? key, required this.internetImageLog}) : super(key: key);
  final InternetImageLog? internetImageLog;

  @override
  _InternetImageConfirmDialogState createState() => _InternetImageConfirmDialogState();
}

class _InternetImageConfirmDialogState extends State<InternetImageConfirmDialog> {
  late TextEditingController _nameController;

  late InternetImageLog _internetImageLog;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.internetImageLog?.name);
    _internetImageLog =
        widget.internetImageLog ?? InternetImageLog(name: '', urls: <String>[].lock);
  }

  Future<void> _onDeleted(String urlToBeDeleted) async {
    // delete old cache image
    setState(() {
      _internetImageLog = _internetImageLog.copyWith(
          urls: _internetImageLog.urls.removeWhere((url) => url == urlToBeDeleted));
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.l10n.addImages),
      actions: <Widget>[
        TextButton(
          child: Text(context.l10n.cancel),
          onPressed: () async {
            Navigator.pop(context);
          },
        ),
        TextButton(
          child: Text(context.l10n.ok),
          onPressed: () {
            Navigator.pop(
              context,
              InternetImageLog(name: _nameController.text, urls: _internetImageLog.urls),
            );
          },
        ),
      ],
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SizedBox(
              height: 230,
              width: double.maxFinite,
              //constraints: const BoxConstraints(maxHeight: 220, maxWidth: double.maxFinite),
              child: ListView(
                shrinkWrap: true,
                scrollDirection: Axis.horizontal,
                children: [
                  ..._internetImageLog.urls
                      .map(
                        (filePath) => ImageCardWithActions(
                          url: filePath,
                          onDelete: _internetImageLog.urls.length > 1 ? _onDeleted : null,
                        ),
                      )
                      .toList(),
                  IconButton(
                    onPressed: _internetImageLog.urls.length > 10
                        ? null
                        : () async {
                            String? internetImageUrl = await showDialog<String>(
                                context: context, builder: (context) => const UrlInputDialog());
                            if (internetImageUrl == null) return;

                            // do not allow repeated urls
                            if (_internetImageLog.urls.any((url) => url == internetImageUrl)) {
                              return;
                            }

                            setState(() {
                              _internetImageLog = _internetImageLog.copyWith(
                                  urls: _internetImageLog.urls.add(internetImageUrl));
                            });
                          },
                    icon: const Icon(Icons.add),
                    color: Theme.of(context).colorScheme.primary,
                  )
                ],
              ),
            ),
            const SizedBox(
              height: 11,
            ),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                isDense: true,
                label: Text(context.l10n.imageNameLabel),
              ),
            )
          ],
        ),
      ),
    );
  }
}

enum _InternetImageAction { delete }

class ImageCardWithActions extends StatelessWidget {
  const ImageCardWithActions({
    Key? key,
    required this.url,
    required this.onDelete,
  }) : super(key: key);
  final String url;

  final Function(String)? onDelete;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withAlpha(16),
          borderRadius: BorderRadius.circular(6),
        ),
        margin: const EdgeInsets.all(2),
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 160),
                child: GestureDetector(
                  child: CachedNetworkImage(
                    imageUrl: url,
                    placeholder: (context, url) => const CircularProgressIndicator(),
                    errorWidget: (context, url, error) {
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(
                            Icons.error,
                            color: Colors.redAccent,
                          ),
                          Text(
                            "Error",
                            style: TextStyle(
                              color: Colors.redAccent,
                            ),
                          )
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
            PopupMenuButton<_InternetImageAction>(
              icon: Icon(
                Icons.more_horiz,
                color: Theme.of(context).colorScheme.primary,
              ),
              onSelected: (action) {
                switch (action) {
                  case _InternetImageAction.delete:
                    onDelete!(url);
                    break;
                }
              },
              elevation: 16,
              itemBuilder: (context) => [
                if (onDelete != null)
                  PopupMenuItem(
                    child: Text(
                      context.l10n.removeImage,
                    ),
                    value: _InternetImageAction.delete,
                  ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

class UrlInputDialog extends StatefulWidget {
  const UrlInputDialog({Key? key}) : super(key: key);

  @override
  _UrlInputDialogState createState() => _UrlInputDialogState();
}

class _UrlInputDialogState extends State<UrlInputDialog> {
  final _urlTextController = TextEditingController();

  bool _wasTouched = false;
  String? _errorText;

  void _urlControllerListener() {
    if (!_wasTouched && _urlTextController.text.isEmpty) return;

    if (!_wasTouched) {
      setState(() {
        _wasTouched = true;
      });
    }

    final uri = Uri.tryParse(_urlTextController.text);

    if (_urlTextController.text.isEmpty) {
      setState(() {
        _errorText = "Cannot be empty";
      });
    } else if (uri == null || !uri.isAbsolute) {
      setState(() {
        _errorText = "Invalid URL";
      });
    } else {
      if (_errorText != null) {
        setState(() {
          _errorText = null;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _urlTextController.addListener(_urlControllerListener);
  }

  @override
  void dispose() {
    _urlTextController.removeListener(_urlControllerListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.l10n.enterImageUrlLabel),
      actions: <Widget>[
        TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text(context.l10n.cancel)),
        TextButton(
          onPressed: _errorText != null || !_wasTouched
              ? null
              : () {
                  Navigator.pop(context, _urlTextController.text);
                },
          child: Text(context.l10n.ok),
        ),
      ],
      content: TextFormField(
        controller: _urlTextController,
        decoration: InputDecoration(
          errorText: _errorText,
        ),
        minLines: 1,
        maxLines: null,
      ),
    );
  }
}
