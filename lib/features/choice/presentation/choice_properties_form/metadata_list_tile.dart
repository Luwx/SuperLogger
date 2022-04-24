import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:super_logger/features/choice/models/choice_properties.dart';
import 'package:super_logger/utils/extensions.dart';

class MetadataListTile extends StatefulWidget {
  const MetadataListTile({
    Key? key,
    required this.templateProperty,
    required this.onConfirmEdit,
    required this.onDelete,
  }) : super(key: key);
  final ChoiceOptionMetadataPropertyTemplate templateProperty;
  final void Function(String oldName, String newName) onConfirmEdit;
  final void Function(String name) onDelete;

  @override
  _MetadataListTileState createState() => _MetadataListTileState();
}

class _MetadataListTileState extends State<MetadataListTile> {
  bool _isEditing = false;

  late String _tempName;

  String? _errorText;

  @override
  void didUpdateWidget(covariant MetadataListTile oldWidget) {
    super.didUpdateWidget(oldWidget);

    // widget was updated
    if (oldWidget.templateProperty != widget.templateProperty) {
      _tempName = widget.templateProperty.propertyName;
      _errorText = null;
      _isEditing = false;
    }
  }

  @override
  void initState() {
    super.initState();
    _tempName = widget.templateProperty.propertyName;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: kThemeAnimationDuration,
      child: PageTransitionSwitcher(
        //duration: const Duration(milliseconds: 400),
        child: _isEditing
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  TextFormField(
                    initialValue: _tempName,
                    decoration: InputDecoration(
                        label: const Text("Name"), isDense: true, errorText: _errorText),
                    onChanged: (s) => setState(() {
                      _tempName = s;
                      if (s.isEmpty) {
                        _errorText = "Invalid name";
                      } else {
                        _errorText = null;
                      }
                    }),
                  ),
                  Row(
                    //mainAxisSize: MainAxisSize.min,
                    //crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Expanded(
                        child: TextButton(
                          onPressed: _tempName == widget.templateProperty.propertyName
                              ? null
                              : () {
                                  widget.onConfirmEdit(
                                      widget.templateProperty.propertyName, _tempName);
                                },
                          child: Text(context.l10n.confirm),
                        ),
                      ),
                      Expanded(
                        child: TextButton(
                            onPressed: () {
                              setState(() {
                                _isEditing = false;
                                _tempName = widget.templateProperty.propertyName;
                              });
                            },
                            child: Text(context.l10n.cancel)),
                      ),
                    ],
                  ),
                ],
              )
            : ListTile(
                title: Text(widget.templateProperty.propertyName),
                trailing: Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _isEditing = true;
                      });
                    },
                    icon: const Icon(Icons.edit),
                  ),
                  IconButton(
                    onPressed: () => widget.onDelete(widget.templateProperty.propertyName),
                    icon: const Icon(Icons.delete),
                  )
                ]),
              ),
        transitionBuilder: (child, animation, secondaryAnimation) {
          return SharedAxisTransition(
            fillColor: Colors.transparent,
            animation: animation,
            secondaryAnimation: secondaryAnimation,
            child: child,
            transitionType: SharedAxisTransitionType.scaled,
          );
        },
      ),
    );
  }
}
