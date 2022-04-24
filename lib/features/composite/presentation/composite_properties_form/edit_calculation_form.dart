import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:super_logger/core/loggables_types.dart';
import 'package:super_logger/features/composite/models/base_loggable_for_composite.dart';
import 'package:super_logger/features/composite/models/composite_properties.dart';
import 'package:super_logger/features/composite/models/computations.dart';
import 'package:super_logger/utils/extensions.dart';

class EditCalculationForm extends StatefulWidget {
  const EditCalculationForm({
    Key? key,
    required this.computation,
    required this.index,
    required this.properties,
  }) : super(key: key);
  final NumericCalculation computation;

  /// null when creating new computations
  final int? index;
  final CompositeProperties properties;

  @override
  _EditCalculationFormState createState() => _EditCalculationFormState();
}

class _EditCalculationFormState extends State<EditCalculationForm> {
  late final TextEditingController _nameController;

  late IList<LoggableForComposite> _availableCategories;
  late IList<NumericCalculation> _availableComputations;

  late NumericCalculation _currentComputation;

  void _addComputable(Computable computable) {
    // setState(() {
    //   _currentComputation = _currentComputation.copyWith(
    //     computables: _currentComputation.computables.add(computable),
    //   );
    // });
  }

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.computation.name);

    _currentComputation = widget.computation;

    _availableCategories = <LoggableForComposite>[].lock;
    _availableComputations = <NumericCalculation>[].lock;

    for (final loggable in widget.properties.loggables) {
      if (loggable.type == LoggableType.number) {
        _availableCategories = _availableCategories.add(loggable);
      }
    }

    // no computation depends on it, so it can depend on all the others
    if (widget.index == null) {
      _availableComputations = widget.properties.calculations;
    } else {
      for (int i = 0; i < widget.properties.calculations.length; i++) {
        final computation = widget.properties.calculations[i];

        // exclude computations that could depended on it
        if (i < widget.index!) {
          _availableComputations = _availableComputations.add(computation);
        }
      }
    }

    _nameController.addListener(() {
      setState(() {
        //_currentComputation = _currentComputation.copyWith(name: _nameController.text);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.newCalculation),
      ),
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(24),
            child: TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                label: Text(context.l10n.loggableTitle),
              ),
            ),
          ),
          PopupMenuButton<ComputableOrigin>(
            icon: const Icon(Icons.add),
            onSelected: (type) async {
              switch (type) {
                case ComputableOrigin.loggable:
                  final loggableId = await _chooseLoggable(context);
                  if (loggableId != null) {
                    _addComputable(Computable.fromLoggableId(loggableId));
                  }
                  break;
                case ComputableOrigin.rawValue:
                  final val = await showDialog<double>(
                    context: context,
                    builder: (context) => const RawValuePickerDialog(initialValue: null),
                  );
                  if (val != null) {
                    _addComputable(Computable.fromValue(val));
                  }
                  break;
                case ComputableOrigin.computable:
                  final computationName = await _chooseComputable(context);
                  if (computationName != null) {
                    _addComputable(Computable.fromComputation(computationName));
                  }
                  break;
              }
            },
            itemBuilder: (BuildContext context) {
              List<PopupMenuEntry<ComputableOrigin>> entries = [];

              entries.add(
                PopupMenuItem<ComputableOrigin>(
                  value: ComputableOrigin.rawValue,
                  child: Text(context.l10n.numericValue),
                ),
              );

              if (_availableCategories.isNotEmpty) {
                entries.add(
                  PopupMenuItem<ComputableOrigin>(
                    value: ComputableOrigin.loggable,
                    child: Text(context.l10n.loggable),
                  ),
                );
              }

              if (_availableComputations.isNotEmpty) {
                entries.add(
                  PopupMenuItem<ComputableOrigin>(
                    value: ComputableOrigin.computable,
                    child: Text(context.l10n.anotherCalculation),
                  ),
                );
              }

              return entries;
            },
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _currentComputation.computables.length,
              itemBuilder: (context, index) {
                final computable = _currentComputation.computables[index];
                String title = computable.when(
                  loggableId: (loggableId) {
                    final loggable =
                        widget.properties.loggables.firstWhere((cat) => cat.id == loggableId);
                    return loggable.title;
                  },
                  value: (value) {
                    return value.toString();
                  },
                  computation: (computationName) {
                    return computationName;
                  },
                );
                String type = computable.when(
                  loggableId: (_) => context.l10n.loggable,
                  value: (_) => context.l10n.numericValue,
                  computation: (_) => context.l10n.anotherCalculation,
                );
                return ListTile(
                  title: Text(title),
                  trailing: Text(type),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _currentComputation.computables.isEmpty || _nameController.text.isEmpty
                ? null
                : () {
                    Navigator.pop(context, _currentComputation);
                  },
            child: SizedBox(
              width: double.maxFinite,
              child: Center(
                child: Text(context.l10n.addCalculation),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Future<String?> _chooseLoggable(BuildContext context) async {
    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: Text(context.l10n.selectLoggable),
          children: _availableCategories
              .map(
                (cat) => SimpleDialogOption(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(cat.title),
                  ),
                  onPressed: () => Navigator.pop(context, cat.id),
                ),
              )
              .toList(),
        );
      },
    );
  }

  Future<String?> _chooseComputable(BuildContext context) async {
    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: Text(context.l10n.selectCalculation),
          children: _availableComputations
              .map(
                (cat) => SimpleDialogOption(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(cat.name),
                  ),
                  onPressed: () => Navigator.pop(context, cat.name),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class RawValuePickerDialog extends StatefulWidget {
  const RawValuePickerDialog({Key? key, required this.initialValue}) : super(key: key);
  final double? initialValue;

  @override
  _RawValuePickerDialogState createState() => _RawValuePickerDialogState();
}

class _RawValuePickerDialogState extends State<RawValuePickerDialog> {
  late final TextEditingController _valueController;

  String? _errorText;
  bool _wasTouched = false;

  @override
  void initState() {
    super.initState();
    _valueController = TextEditingController(text: widget.initialValue?.toString());

    _valueController.addListener(() {
      double? val = double.tryParse(_valueController.text);
      if (_valueController.text.isEmpty && !_wasTouched) return;
      if (val == null) {
        setState(() {
          _errorText = "Invalid value";
        });
      } else if (val == 0) {
        setState(() {
          _errorText = "Cannot be 0";
        });
      } else {
        setState(() {
          _errorText = null;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.l10n.value),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text(context.l10n.cancel),
        ),
        TextButton(
          onPressed: _errorText != null || !_wasTouched
              ? null
              : () {
                  Navigator.pop(context, double.parse(_valueController.text));
                },
          child: Text(context.l10n.ok),
        ),
      ],
      content: TextFormField(
        controller: _valueController,
        decoration: InputDecoration(
          errorText: _errorText,
          label: Text(context.l10n.value),
        ),
        onChanged: (s) => _wasTouched = true,
        inputFormatters: <TextInputFormatter>[
          FilteringTextInputFormatter.allow(
            RegExp(r'^-?\d{0,6}\.?\d{0,3}'),
          ),
        ],
        keyboardType: const TextInputType.numberWithOptions(decimal: false, signed: true),
      ),
    );
  }
}
