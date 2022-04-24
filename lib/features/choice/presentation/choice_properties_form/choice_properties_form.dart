import 'dart:ui';

import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/material.dart';
import 'package:fpdart/fpdart.dart' show Right, Left;

import 'package:super_logger/core/loggables_types.dart';
import 'package:super_logger/core/loggable_ui_helper.dart';
import 'package:super_logger/core/main_factory.dart';
import 'package:super_logger/core/models/mappable_object.dart';
import 'package:super_logger/features/choice/models/choice_properties.dart';
import 'package:super_logger/features/choice/presentation/choice_properties_form/edit_choice_option_page.dart';
import 'package:super_logger/features/choice/presentation/choice_properties_form/metadata_list_tile.dart';
import 'package:super_logger/locator.dart';
import 'package:super_logger/utils/extensions.dart';
import 'package:super_logger/utils/value_controller.dart';

class ChoicePropertiesForm extends StatefulWidget {
  const ChoicePropertiesForm({Key? key, this.choiceProperties, required this.propertiesController})
      : super(key: key);
  final ChoiceProperties? choiceProperties;
  final ValueEitherValidOrErrController<MappableObject> propertiesController;

  @override
  _ChoicePropertiesFormState createState() => _ChoicePropertiesFormState();
}

class _ChoicePropertiesFormState extends State<ChoicePropertiesForm> {
  ChoiceProperties get _currentProperties {
    return widget.propertiesController.valueNoValidation as ChoiceProperties;
  }

  void _setProperties(ChoiceProperties properties) {
    if ((properties.isRanked == false || properties.options.length > 16) && properties.useSlider) {
      properties = properties.copyWith(useSlider: false);
    }
    setState(() {
      if (properties.options.length > 1) {
        widget.propertiesController.setRightValue(properties);
      } else {
        widget.propertiesController
            .setErrorValue(ValueErr("more than one option needed", properties));
      }
    });
  }

  late LoggableUiHelper _uiHelper;

  String _generateNewTemplatePropertyName() {
    int count = 1;
    String initialName = "New Property";
    while (_currentProperties.metadataTemplate
        .map((element) => element.propertyName)
        .contains(initialName + count.toString())) {
      count++;
    }
    return initialName + count.toString();
  }

  @override
  void initState() {
    super.initState();

    // use state from other instance when possible
    if (!widget.propertiesController.isSetUp) {
      if (widget.choiceProperties != null) {
        widget.propertiesController.setValue(
          Right(widget.choiceProperties!),
        );
      } else {
        widget.propertiesController.setValue(
          Left(
            ValueErr(
              "No option",
              locator
                  .get<MainFactory>()
                  .getFactoryFor(LoggableType.choice)
                  .createDefaultProperties(),
            ),
          ),
        );
      }
    }

    LoggableType type = _currentProperties.optionType;
    _uiHelper = locator.get<MainFactory>().getUiHelper(type);
  }

  @override
  Widget build(BuildContext context) {
    final currentCatDescription =
        locator.get<MainFactory>().getLoggableTypeDescription(_currentProperties.optionType);
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const SizedBox(
            height: 16,
          ),
          SwitchListTile(
            contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 22),
            secondary: const Icon(Icons.leaderboard_rounded),
            title: Text(context.l10n.ranked),
            value: _currentProperties.isRanked,
            onChanged: (val) {
              _setProperties(_currentProperties.copyWith(isRanked: val));
            },
          ),
          SwitchListTile(
            contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 22),
            secondary: const Icon(Icons.linear_scale),
            title: Text(context.l10n.useSliderControlLabel),
            value: _currentProperties.useSlider,
            onChanged: _currentProperties.canUseSlider
                ? (val) {
                    _setProperties(_currentProperties.copyWith(useSlider: val));
                  }
                : null,
          ),
          const Divider(),
          const SizedBox(
            height: 8,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  context.l10n.choiceLoggableType,
                  style: Theme.of(context).textTheme.headline6,
                )),
          ),
          const SizedBox(
            height: 8,
          ),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 22),
            title: Text(currentCatDescription.title),
            leading: Icon(currentCatDescription.icon),
            trailing: const Icon(
              Icons.keyboard_arrow_right,
            ),
            onTap: () async {
              final selectedType = await showDialog<LoggableType>(
                context: context,
                builder: (BuildContext context) {
                  return SimpleDialog(
                    title: Text(context.l10n.selectAnOption),
                    children: ChoiceProperties.supportedTypes.map(
                      (type) {
                        final catDescription =
                            locator.get<MainFactory>().getLoggableTypeDescription(type);
                        return SimpleDialogOption(
                          child: ListTile(
                            leading: Icon(catDescription.icon),
                            title: Text(catDescription.title),
                          ),
                          onPressed: () => Navigator.pop(context, type),
                        );
                      },
                    ).toList(),
                  );
                },
              );

              if (selectedType == null) return;

              if (selectedType != _currentProperties.optionType) {
                // warning dialog
                if (_currentProperties.options.isNotEmpty) {
                  final shouldContinue = await showDialog<bool>(
                    context: context,
                    builder: (BuildContext context) => AlertDialog(
                      title: Text(context.l10n.warning),
                      content: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.warning_rounded,
                            color: Colors.amber,
                            size: 48,
                          ),
                          const SizedBox(
                            width: 8,
                          ),
                          Expanded(
                            child: Text(context.l10n.choiceTypeChangeWarning),
                          ),
                        ],
                      ),
                      actions: <Widget>[
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text(context.l10n.no),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: Text(context.l10n.yes),
                        ),
                      ],
                    ),
                  );
                  if (shouldContinue == null || shouldContinue == false) return;
                }

                _uiHelper = locator.get<MainFactory>().getUiHelper(selectedType);
                _setProperties(
                  _currentProperties.copyWith(
                      optionType: selectedType, options: <ChoiceOption>[].lock),
                );
              }
            },
          ),
          const SizedBox(
            height: 16,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Row(
              children: [
                Text(
                  context.l10n.options,
                  style: Theme.of(context).textTheme.headline6,
                ),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      icon: const Icon(Icons.add),
                      onPressed: () async {
                        //String? choiceName = await _showAddDialog();

                        ChoiceOption? option = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditChoiceOptionPage(
                              uiHelper: _uiHelper,
                              option: null,
                              type: _currentProperties.optionType,
                              metadataTemplate: _currentProperties.metadataTemplate,
                            ),
                          ),
                        );

                        if (option != null) {
                          _setProperties(
                            _currentProperties.copyWith(
                              options: _currentProperties.options.add(option),
                            ),
                          );
                        }
                      },
                      label: Text(context.l10n.addOption),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Material(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
                child: ReorderableListView.builder(
                  reverse: true,
                  itemBuilder: buildItem,
                  itemCount: _currentProperties.options.length,
                  onReorder: (oldIndex, newIndex) {
                    // why this if? stupid bug: https://github.com/flutter/flutter/issues/24786
                    if (oldIndex < newIndex) {
                      newIndex -= 1;
                    }

                    final options = _currentProperties.options.unlock;
                    final element = options.removeAt(oldIndex);
                    options.insert(newIndex, element);
                    _setProperties(
                      _currentProperties.copyWith(
                        options: options.lock,
                      ),
                    );
                  },
                  proxyDecorator: (Widget child, int index, Animation<double> animation) {
                    return AnimatedBuilder(
                      animation: animation,
                      builder: (BuildContext context, Widget? child) {
                        final double animValue = Curves.easeInOut.transform(animation.value);
                        final double elevation = lerpDouble(0, 6, animValue)!;
                        return Material(
                          borderRadius: BorderRadius.circular(12),
                          color: Color.lerp(Theme.of(context).colorScheme.primary,
                              Theme.of(context).scaffoldBackgroundColor, 0.94 + 0.06 * animValue),
                          elevation: elevation,
                          child: child,
                        );
                      },
                      child: child,
                    );
                  },
                  shrinkWrap: true,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Row(
              children: [
                Text(
                  context.l10n.metadata,
                  style: const TextStyle(fontSize: 24.0),
                ),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      icon: const Icon(Icons.add),
                      onPressed: () {
                        String propertyName = _generateNewTemplatePropertyName();

                        final options = _currentProperties.options.unlock;

                        List<ChoiceOption> updatedOptions = [];
                        for (final option in options) {
                          updatedOptions.add(
                            option.copyWith(
                              metadata: option.metadata.add(
                                ChoiceOptionMetadataProperty(propertyName: propertyName, value: 0),
                              ),
                            ),
                          );
                        }
                        _setProperties(
                          _currentProperties.copyWith(
                            options: updatedOptions.lock,
                            metadataTemplate: _currentProperties.metadataTemplate.add(
                              ChoiceOptionMetadataPropertyTemplate(
                                propertyName: propertyName,
                                isRequired: false,
                                suffix: "",
                                prefix: "",
                              ),
                            ),
                          ),
                        );
                      },
                      label: FittedBox(
                        child: Text(
                          context.l10n.addMetadataProperty,
                        ),
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Material(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
              child: ListView.builder(
                //clipBehavior: null,
                shrinkWrap: true,
                physics: const ClampingScrollPhysics(),
                itemBuilder: (context, index) {
                  return MetadataListTile(
                    templateProperty: _currentProperties.metadataTemplate[index],
                    onConfirmEdit: (oldName, newName) {
                      final options = _currentProperties.options.unlock;
                      List<ChoiceOption> updatedOptions = [];
                      for (final option in options) {
                        int metadataIndex = option.metadata
                            .indexWhere((element) => element.propertyName == oldName);

                        // TODO: handle error
                        if (metadataIndex < 0) return;
                        updatedOptions.add(
                          option.copyWith(
                            metadata: option.metadata.put(
                              metadataIndex,
                              ChoiceOptionMetadataProperty(propertyName: newName, value: 0),
                            ),
                          ),
                        );
                      }

                      int templateMetadataIndex = _currentProperties.metadataTemplate
                          .indexWhere((element) => element.propertyName == oldName);
                      // TODO: handle error
                      if (templateMetadataIndex < 0) return;

                      _setProperties(
                        _currentProperties.copyWith(
                          options: updatedOptions.lock,
                          metadataTemplate: _currentProperties.metadataTemplate.put(
                            templateMetadataIndex,
                            ChoiceOptionMetadataPropertyTemplate(
                              propertyName: newName,
                              isRequired: false,
                              suffix: "",
                              prefix: "",
                            ),
                          ),
                        ),
                      );
                    },
                    onDelete: (propertyName) {
                      final options = _currentProperties.options.unlock;
                      List<ChoiceOption> updatedOptions = [];
                      for (final option in options) {
                        updatedOptions.add(
                          option.copyWith(
                            metadata: option.metadata
                                .removeWhere((element) => element.propertyName == propertyName),
                          ),
                        );
                      }
                      _setProperties(
                        _currentProperties.copyWith(
                          options: updatedOptions.lock,
                          metadataTemplate: _currentProperties.metadataTemplate.removeWhere(
                            (element) => element.propertyName == propertyName,
                          ),
                        ),
                      );
                    },
                  );
                },
                itemCount: _currentProperties.metadataTemplate.length,
              ),
            ),
          ),
          const SizedBox(
            height: 16,
          ),
        ],
      ),
    );
  }

  Widget buildItem(BuildContext context, int index) {
    return ListTile(
      key: ValueKey(_currentProperties.options[index].id),
      title: _uiHelper.getDisplayLogValueWidget(
        _currentProperties.options[index].value,
      ),
      //title: Text(_currentProperties.options[index]),
      leading: _currentProperties.isRanked
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  (index + 1).toString(),
                  style:
                      TextStyle(color: Theme.of(context).colorScheme.onBackground.withOpacity(0.5)),
                ),
              ],
            )
          : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _setProperties(
              _currentProperties.copyWith(
                options: _currentProperties.options.removeAt(index),
              ),
            ),
          ),
        ],
      ),
      onTap: () async {
        ChoiceOption? editedOption = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EditChoiceOptionPage(
              uiHelper: _uiHelper,
              option: _currentProperties.options[index],
              type: _currentProperties.optionType,
              metadataTemplate: _currentProperties.metadataTemplate,
            ),
          ),
        );
        FocusScope.of(context).unfocus();
        if (editedOption != null) {
          _setProperties(
            _currentProperties.copyWith(
              options: _currentProperties.options.put(index, editedOption),
            ),
          );
        }
      },
    );
  }
}
