import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:super_logger/core/loggables_types.dart';
import 'package:super_logger/core/loggable_ui_helper.dart';
import 'package:super_logger/core/main_factory.dart';
import 'package:super_logger/features/choice/models/choice_properties.dart';
import 'package:super_logger/locator.dart';
import 'package:super_logger/utils/extensions.dart';
import 'package:super_logger/utils/id_generator.dart';
import 'package:super_logger/utils/value_controller.dart';

class EditChoiceOptionPage extends StatefulWidget {
  const EditChoiceOptionPage({
    Key? key,
    required this.uiHelper,
    required this.option,
    required this.type,
    required this.metadataTemplate,
  }) : super(key: key);

  final LoggableUiHelper uiHelper;
  final ChoiceOption? option;
  final LoggableType type;
  final IList<ChoiceOptionMetadataPropertyTemplate> metadataTemplate;

  @override
  _EditChoiceOptionPageState createState() => _EditChoiceOptionPageState();
}

class _EditChoiceOptionPageState extends State<EditChoiceOptionPage> {
  late ValueEitherController _valueController;

  late bool _isValid;

  late ChoiceOption _option;

  void _evaluateValidity() {
    _valueController.value.fold(
      (l) {
        if (_isValid) {
          setState(() {
            _isValid = false;
          });
        }
      },
      (r) {
        _option = _option.copyWith(value: r);

        bool oldValid = _isValid;
        if (widget.option == null) {
          _isValid = true;
        } else {
          _isValid = _option != widget.option;
        }
        if (oldValid != _isValid) {
          setState(() {});
        }
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _valueController = locator.get<MainFactory>().makeValueController(widget.type);
    _isValid = false;

    if (widget.option != null) {
      _option = widget.option!;
    } else {
      var metadataList = <ChoiceOptionMetadataProperty>[].lock;
      for (final propertyMetadata in widget.metadataTemplate) {
        metadataList = metadataList.add(
          ChoiceOptionMetadataProperty(propertyName: propertyMetadata.propertyName, value: 0),
        );
      }
      _option = ChoiceOption(metadata: metadataList, id: generateSmallId(), value: null);
    }

    _valueController.addListener(_evaluateValidity);
  }

  @override
  void dispose() {
    _valueController.removeListener(_evaluateValidity);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.option == null ? "New Option" : "Edit Option"),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 4),
                    child: Text(
                      "Option Value",
                      style: TextStyle(
                        color: Color.lerp(Theme.of(context).colorScheme.onBackground,
                                Theme.of(context).colorScheme.primary, 0.4)!
                            .withOpacity(0.7),
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 4, 24, 12),
                    child: widget.uiHelper.getEditEntryValueWidget(
                      locator.get<MainFactory>().makeDefaultProperties(widget.type),
                      _valueController,
                      _option.value,
                    ),
                  ),
                  if (_option.metadata.isNotEmpty)
                    ListView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _option.metadata.length,
                      shrinkWrap: true,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                          child: TextFormField(
                            initialValue: _option.metadata[index].value.toString(),
                            decoration: InputDecoration(
                              label: Text(_option.metadata[index].propertyName),
                              isDense: true,
                            ),
                            keyboardType:
                                const TextInputType.numberWithOptions(decimal: true, signed: false),
                            inputFormatters: <TextInputFormatter>[
                              FilteringTextInputFormatter.allow(RegExp(r'^-?\d{0,6}\.?\d{0,3}')),
                            ],
                            onChanged: (s) {
                              _option = _option.copyWith(
                                metadata: _option.metadata.put(
                                  index,
                                  _option.metadata[index].copyWith(
                                    value: double.tryParse(s) ?? 0,
                                  ),
                                ),
                              );
                              _evaluateValidity();
                            },
                          ),
                        );
                      },
                    )
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: ElevatedButton(
              onPressed: !_isValid
                  ? null
                  : () {
                      Navigator.pop(context, _option);
                    },
              child: SizedBox(
                width: double.maxFinite,
                child: Center(
                  child: Text(context.l10n.addOption),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
