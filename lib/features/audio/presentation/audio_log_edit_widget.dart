import 'dart:io';

import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:super_logger/core/models/file_path.dart';
import 'package:super_logger/features/image/models/image_log.dart';
import 'package:super_logger/features/image/models/image_properties.dart';
import 'package:super_logger/features/image/presentation/image_confirm_dialog.dart';
import 'package:super_logger/utils/extensions.dart';
import 'package:super_logger/utils/value_controller.dart';

class ImageLogEditWidget extends StatefulWidget {
  const ImageLogEditWidget({
    Key? key,
    required this.controller,
    required this.properties,
    required this.title,
  }) : super(key: key);

  final ValueEitherController<ImageLog> controller;
  final ImageProperties properties;
  final String title;

  @override
  _ImageLogEditWidgetState createState() => _ImageLogEditWidgetState();
}

class _ImageLogEditWidgetState extends State<ImageLogEditWidget> {
  late TextEditingController _nameController;

  late ImageLog _imageLog;

  Future<void> _deleteFile(FilePath filePath) async {
    if (filePath is AbsoluteFilePath) {
      File cachedImage = File(filePath.path);
      if (await cachedImage.exists()) {
        try {
          await cachedImage.delete();
        } catch (e) {
          // print("failed to delete");
        }
      }
    }
  }

  Future<void> _onDeleted(FilePath deletedFilePath) async {
    // delete old cache image
    _deleteFile(deletedFilePath);
    setState(() {
      _imageLog = _imageLog.copyWith(
        filePaths:
            _imageLog.filePaths.removeWhere((filePath) => filePath.path == deletedFilePath.path),
      );
    });

    widget.controller.setRightValue(_imageLog);
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
    widget.controller.setRightValue(_imageLog);
  }

  @override
  void initState() {
    super.initState();

    if (widget.controller.isSetUp) {
      _nameController =
          TextEditingController(text: widget.controller.value.fold((l) => "", (r) => r.name));
      _imageLog = widget.controller.value
          .fold((l) => ImageLog(name: "", filePaths: <FilePath>[].lock), (r) => r);
    } else {
      _imageLog = ImageLog(name: "", filePaths: <FilePath>[].lock);
      _nameController = TextEditingController(text: "");
      widget.controller.setErrorValue("no image selected", notify: false);
    }

    _nameController.addListener(() {
      _imageLog = _imageLog.copyWith(name: _nameController.text);
      if (_imageLog.filePaths.isEmpty) {
        widget.controller.setErrorValue(context.l10n.noImageSelected);
      } else {
        widget.controller.setRightValue(_imageLog);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
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
                        if (_imageLog.filePaths.any((filePath) => filePath.path == image.path)) {
                          return;
                        }

                        setState(() {
                          _imageLog = _imageLog.copyWith(
                            filePaths: _imageLog.filePaths.add(
                              AbsoluteFilePath(path: image.path, fileType: FileType.image),
                            ),
                          );
                        });
                        widget.controller.setRightValue(_imageLog);
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
    );
    
  }
}
