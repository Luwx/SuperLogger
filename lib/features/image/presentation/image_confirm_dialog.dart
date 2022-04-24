import 'dart:developer';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:super_logger/core/main_controller.dart';
import 'package:super_logger/core/models/file_path.dart';
import 'package:super_logger/features/image/models/image_log.dart';
import 'package:super_logger/locator.dart';
import 'package:super_logger/utils/extensions.dart';

class ImageConfirmDialog extends StatefulWidget {
  const ImageConfirmDialog({Key? key, required this.imageLog}) : super(key: key);
  final ImageLog imageLog;

  @override
  _ImageConfirmDialogState createState() => _ImageConfirmDialogState();
}

class _ImageConfirmDialogState extends State<ImageConfirmDialog> {
  late TextEditingController _nameController;

  late ImageLog _imageLog;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.imageLog.name);
    _imageLog = widget.imageLog;
  }

  Future<void> _deleteFile(FilePath filePath) async {
    if (filePath is AbsoluteFilePath) {
      File cachedImage = File(filePath.path);
      if (await cachedImage.exists()) {
        try {
          await cachedImage.delete();
        } catch (e) {
          log("failed to delete $filePath");
        }
      }
    }
  }

  Future<void> _onDeleted(FilePath deletedFilePath) async {
    // delete old cache image
    _deleteFile(deletedFilePath);
    setState(() {
      _imageLog.filePaths.removeWhere((filePath) => filePath.path == deletedFilePath.path);
    });
  }

  Future<void> _onFileChanged({required FilePath oldPath, required FilePath newPath}) async {
    // delete old cache image
    _deleteFile(oldPath);

    for (int i = 0; i < _imageLog.filePaths.length; i++) {
      if (_imageLog.filePaths[i].path == oldPath.path) {
        setState(() {
          _imageLog = _imageLog.copyWith(filePaths: _imageLog.filePaths.put(i, newPath));
        });
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.l10n.addImages),
      actions: <Widget>[
        TextButton(
          child: Text(context.l10n.cancel),
          onPressed: () async {
            for (final filePath in _imageLog.filePaths) {
              _deleteFile(filePath);
            }
            Navigator.pop(context);
          },
        ),
        TextButton(
          child: Text(context.l10n.ok),
          onPressed: () {
            Navigator.pop(
              context,
              ImageLog(name: _nameController.text, filePaths: _imageLog.filePaths),
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
                  ..._imageLog.filePaths
                      .map(
                        (filePath) => ImageCardWithActions(
                          filePath: filePath,
                          onDelete: _imageLog.filePaths.length > 1 ? _onDeleted : null,
                          onFilePathChanged: _onFileChanged,
                        ),
                      )
                      .toList(),
                  IconButton(
                    onPressed: _imageLog.filePaths.length > 10
                        ? null
                        : () async {
                            XFile? image = await pickImageDialog(context);
                            if (image == null) return;

                            // repeated paths
                            if (_imageLog.filePaths
                                .any((filePath) => filePath.path == image.path)) {
                              return;
                            }

                            setState(() {
                              _imageLog.filePaths.add(
                                AbsoluteFilePath(path: image.path, fileType: FileType.image),
                              );
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

Future<XFile?> pickImageDialog(BuildContext context) async {
  bool? fromCamera = await showDialog<bool>(
    context: context,
    builder: (BuildContext context) {
      return SimpleDialog(
        title: Text(context.l10n.imageSourcePrompt),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
        children: [
          SimpleDialogOption(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Text(context.l10n.imageSourceCamera),
            ),
            onPressed: () async {
              Navigator.pop(context, true);
            },
          ),
          SimpleDialogOption(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Text(context.l10n.imageSourceGallery),
            ),
            onPressed: () async {
              Navigator.pop(context, false);
            },
          ),
        ],
      );
    },
  );

  if (fromCamera == null) return null;

  final ImagePicker _picker = ImagePicker();
  // Pick an image
  final XFile? image = fromCamera
      ? await _picker.pickImage(source: ImageSource.camera)
      : await _picker.pickImage(source: ImageSource.gallery);

  return image;
}

enum _ImageAction { change, delete }

class ImageCardWithActions extends StatelessWidget {
  const ImageCardWithActions({
    Key? key,
    required this.filePath,
    required this.onDelete,
    required this.onFilePathChanged,
  }) : super(key: key);
  final FilePath filePath;

  final Function(FilePath filePath)? onDelete;
  final Function({required FilePath newPath, required FilePath oldPath}) onFilePathChanged;

  Future<void> _onChangePress(BuildContext context) async {
    XFile? image = await pickImageDialog(context);
    if (image == null) return;
    onFilePathChanged(
      newPath: AbsoluteFilePath(path: image.path, fileType: FileType.image),
      oldPath: filePath,
    );
  }

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
                child: FutureBuilder<String>(
                  future: locator.get<MainController>().docsPath,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const CircularProgressIndicator();
                    final file = filePath.when(
                      saved: (saved) {
                        return File(p.join(snapshot.data!, saved.path));
                      },
                      absolute: (absolute) {
                        return File(absolute.path);
                      },
                    );
                    if (!file.existsSync()) {
                      return Text(
                        context.l10n.imageNotFound,
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    }
                    return GestureDetector(
                      child: Image.file(file),
                    );
                  },
                ),
              ),
            ),
            PopupMenuButton<_ImageAction>(
              icon: Icon(
                Icons.more_horiz,
                color: Theme.of(context).colorScheme.primary,
              ),
              onSelected: (action) {
                switch (action) {
                  case _ImageAction.change:
                    _onChangePress(context);
                    break;
                  case _ImageAction.delete:
                    onDelete!(filePath);
                    break;
                }
              },
              elevation: 16,
              itemBuilder: (context) => [
                PopupMenuItem(
                  child: Text(context.l10n.changeImage),
                  //onTap: () => _onChangePress(context),
                  value: _ImageAction.change,
                ),
                if (onDelete != null)
                  PopupMenuItem(
                    child: Text(
                      context.l10n.removeImage,
                    ),
                    // onTap: () {
                    //   onDelete!(filePath);
                    // },
                    value: _ImageAction.delete,
                  ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
