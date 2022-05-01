import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:super_logger/core/loggables_types.dart';
import 'package:super_logger/core/main_controller.dart';
import 'package:super_logger/core/models/loggable.dart';
import 'package:super_logger/core/models/loggable_settings.dart';
import 'package:super_logger/core/models/loggable_tag.dart';
import 'package:super_logger/core/models/mappable_object.dart';
import 'package:super_logger/features/choice/models/choice_properties.dart';
import 'package:super_logger/features/composite/models/base_loggable_for_composite.dart';
import 'package:super_logger/features/composite/models/composite_properties.dart';
import 'package:super_logger/features/composite/models/computations.dart';
import 'package:super_logger/features/number/models/number_properties.dart';
import 'package:super_logger/features/text/models/text_properties.dart';
import 'package:super_logger/locator.dart';
import 'package:super_logger/utils/extensions.dart';
import 'package:super_logger/utils/id_generator.dart';

class TemplateLoggablesScreen extends StatelessWidget {
  const TemplateLoggablesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final templates = generateTemplates(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.templates),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: ListView.builder(
              itemCount: templates.length,
              itemBuilder: (context, index) {
                final template = templates[index];
                final symbol = template.loggable.loggableSettings.symbol;
                return Card(
                  elevation: 4,
                  shadowColor: Theme.of(context).colorScheme.primary.darken(20).withOpacity(0.08),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: InkWell(
                    onTap: () async {
                      final mainController = locator.get<MainController>();

                      final hasExistingLoggable = mainController.loggablesList
                          .any((loggable) => loggable.title == template.loggable.title);
                      if (hasExistingLoggable) {
                        final shouldContinue = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            content: Text(
                              "There already exists a loggable with the name ${template.loggable.title}, continue to add this new loggable with the same name?",
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: Text(context.l10n.cancel),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: Text(context.l10n.continueLabel),
                              )
                            ],
                          ),
                        );
                        if (shouldContinue == null || shouldContinue == false) {
                          return;
                        }
                      }

                      await MainController.addLoggable(
                          template.loggable.copyWith(creationDate: DateTime.now()));
                      Navigator.pop(context);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              if (symbol.isNotEmpty) ...[
                                Container(
                                  height: 72,
                                  width: 72,
                                  //margin: const EdgeInsets.symmetric(horizontal: 16),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primary.withOpacity(0.06),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  padding: const EdgeInsets.all(12),
                                  child: FittedBox(
                                    child: Text(
                                      symbol,
                                      style: TextStyle(color: Theme.of(context).primaryColor),
                                    ),
                                  ),
                                ),
                                const SizedBox(
                                  width: 16,
                                )
                              ],
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      template.loggable.title,
                                      style: Theme.of(context).textTheme.headline6,
                                    ),
                                    const SizedBox(
                                      height: 4,
                                    ),
                                    template.description.isEmpty
                                        ? Text(
                                            "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Donec non dignissim urna. Aenean fermentum malesuada nibh. Nulla tincidunt dictum urna in finibus. In pharetra vulputate interdum. ")
                                        : Text(template.description),
                                  ],
                                ),
                              )
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}

class TemplateLoggable {
  final String description;
  final Loggable loggable;
  TemplateLoggable(this.description, this.loggable);
}

List<TemplateLoggable> generateTemplates(BuildContext context) {
  List<TemplateLoggable> templates = [];

  final now = DateTime.now();
  final tags = <LoggableTag>[].lock;
  final calculations = <NumericCalculation>[].lock;
  final defaultSettings = LoggableSettings.defauls();

  final metadataTemplate = <ChoiceOptionMetadataPropertyTemplate>[].lock;
  final metadata = <ChoiceOptionMetadataProperty>[].lock;

  // mood log
  templates.add(
    TemplateLoggable(
      "Select and log the emoji that better matches your current mood!",
      Loggable(
        loggableSettings: defaultSettings.copyWith(symbol: "😭😂"),
        loggableConfig: LoggableProperties(
          generalConfig: ChoiceProperties(
            isRanked: true,
            optionType: LoggableType.text,
            useSlider: true,
            options: [
              ChoiceOption(metadata: metadata, id: generateSmallId(), value: "😭"),
              ChoiceOption(metadata: metadata, id: generateSmallId(), value: "😞"),
              ChoiceOption(metadata: metadata, id: generateSmallId(), value: "😡"),
              ChoiceOption(metadata: metadata, id: generateSmallId(), value: "😤"),
              ChoiceOption(metadata: metadata, id: generateSmallId(), value: "😐"),
              ChoiceOption(metadata: metadata, id: generateSmallId(), value: "🙂"),
              ChoiceOption(metadata: metadata, id: generateSmallId(), value: "😃"),
              ChoiceOption(metadata: metadata, id: generateSmallId(), value: "😂"),
            ].lock,
            metadataTemplate: metadataTemplate,
          ),
          mainCardConfig: const EmptyProperty(),
          aggregationConfig: EmptyAggregationConfig(),
        ),
        type: LoggableType.choice,
        title: context.l10n.moodLog,
        creationDate: now,
        tags: tags,
        id: generateId(),
      ),
    ),
  );

  // Electric energy consuption
  templates.add(
    TemplateLoggable(
      context.l10n.electricEnergyConsumption,
      Loggable(
        loggableSettings: defaultSettings.copyWith(symbol: "⚡"),
        loggableConfig: LoggableProperties(
          generalConfig: const NumberProperties(
            min: 0,
            max: 50,
            prefix: "",
            suffix: "kW/h",
            allowDecimal: true,
            showMinusButton: false,
            showSlider: true,
            showTotalCount: true,
          ),
          mainCardConfig: const EmptyProperty(),
          aggregationConfig: EmptyAggregationConfig(),
        ),
        type: LoggableType.number,
        title: context.l10n.electricEnergyConsumption,
        creationDate: now,
        tags: tags,
        id: generateId(),
      ),
    ),
  );

  // workout log
  templates.add(
    TemplateLoggable(
      context.l10n.workout,
      Loggable(
        loggableSettings: defaultSettings.copyWith(symbol: "🏋️"),
        loggableConfig: LoggableProperties(
          generalConfig: CompositeProperties(
            loggables: [
              LoggableForComposite(
                properties: NumberProperties(
                  prefix: '',
                  suffix: context.l10n.minutes,
                  allowDecimal: false,
                  showMinusButton: false,
                  showSlider: false,
                  showTotalCount: false,
                ),
                type: LoggableType.number,
                title: context.l10n.duration,
                id: generateId(),
                isArrayable: false,
                isHiddenByDefault: false,
                isDismissible: false,
                hideTitle: false,
              ),
              LoggableForComposite(
                properties: CompositeProperties(
                  loggables: [
                    LoggableForComposite(
                      properties: ChoiceProperties(
                          isRanked: false,
                          optionType: LoggableType.text,
                          useSlider: false,
                          options: [
                            ChoiceOption(
                                metadata: metadata,
                                id: generateSmallId(),
                                value: context.l10n.deadlift),
                            ChoiceOption(
                                metadata: metadata,
                                id: generateSmallId(),
                                value: context.l10n.squat),
                            ChoiceOption(
                                metadata: metadata,
                                id: generateSmallId(),
                                value: context.l10n.benchPress),
                          ].lock,
                          metadataTemplate: metadataTemplate),
                      type: LoggableType.choice,
                      title: context.l10n.exerciseName,
                      id: generateId(),
                      isArrayable: false,
                      isHiddenByDefault: false,
                      isDismissible: false,
                      hideTitle: true,
                    ),
                    LoggableForComposite(
                      properties: CompositeProperties(
                        loggables: [
                          LoggableForComposite(
                            properties: const NumberProperties(
                              min: 0,
                              max: 30,
                              prefix: "",
                              suffix: "",
                              allowDecimal: false,
                              showMinusButton: false,
                              showSlider: false,
                              showTotalCount: false,
                            ),
                            type: LoggableType.number,
                            title: context.l10n.reps,
                            id: generateId(),
                            isArrayable: false,
                            isHiddenByDefault: false,
                            isDismissible: false,
                            hideTitle: false,
                          ),
                          LoggableForComposite(
                            properties: const NumberProperties(
                              min: 0,
                              max: 500,
                              prefix: "",
                              suffix: "kg",
                              allowDecimal: false,
                              showMinusButton: false,
                              showSlider: false,
                              showTotalCount: false,
                            ),
                            type: LoggableType.number,
                            title: context.l10n.weight,
                            id: generateId(),
                            isArrayable: false,
                            isHiddenByDefault: false,
                            isDismissible: false,
                            hideTitle: true,
                          ),
                        ].lock,
                        calculations: calculations,
                        displaySideBySide: true,
                        isOrGroup: false,
                        sideBySideDelimiter: " x ",
                        level: 2,
                      ),
                      type: LoggableType.composite,
                      title: context.l10n.sets,
                      id: generateId(),
                      isArrayable: true,
                      isHiddenByDefault: false,
                      isDismissible: false,
                      hideTitle: false,
                    )
                  ].lock,
                  calculations: calculations,
                  displaySideBySide: false,
                  isOrGroup: false,
                  sideBySideDelimiter: "",
                  level: 1,
                ),
                type: LoggableType.composite,
                title: context.l10n.exercises,
                id: generateId(),
                isArrayable: true,
                isHiddenByDefault: false,
                isDismissible: false,
                hideTitle: false,
              ),
              LoggableForComposite(
                properties: ChoiceProperties(
                  isRanked: true,
                  optionType: LoggableType.text,
                  useSlider: true,
                  options: [
                    ChoiceOption(
                        metadata: metadata, id: generateSmallId(), value: context.l10n.low),
                    ChoiceOption(
                        metadata: metadata, id: generateSmallId(), value: context.l10n.medium),
                    ChoiceOption(
                        metadata: metadata, id: generateSmallId(), value: context.l10n.high),
                  ].lock,
                  metadataTemplate: metadataTemplate,
                ),
                type: LoggableType.choice,
                title: context.l10n.exhaustion,
                id: generateId(),
                isArrayable: false,
                isHiddenByDefault: false,
                isDismissible: false,
                hideTitle: false,
              )
            ].lock,
            calculations: calculations,
            isOrGroup: false,
            displaySideBySide: false,
            sideBySideDelimiter: "",
            level: 0,
          ),
          mainCardConfig: const EmptyProperty(),
          aggregationConfig: EmptyAggregationConfig(),
        ),
        type: LoggableType.composite,
        title: context.l10n.workout,
        creationDate: now,
        tags: tags,
        id: generateId(),
      ),
    ),
  );

  // sleep log
  templates.add(
    TemplateLoggable(
      context.l10n.sleepLog,
      Loggable(
        loggableSettings: defaultSettings.copyWith(symbol: "💤"),
        loggableConfig: LoggableProperties(
          generalConfig: CompositeProperties(
            loggables: [
              LoggableForComposite(
                properties: NumberProperties(
                  min: 0,
                  max: 12,
                  prefix: "",
                  suffix: context.l10n.hours,
                  allowDecimal: true,
                  showMinusButton: false,
                  showSlider: true,
                  showTotalCount: false,
                ),
                type: LoggableType.number,
                title: context.l10n.duration,
                id: generateId(),
                isArrayable: false,
                isHiddenByDefault: false,
                isDismissible: false,
                hideTitle: false,
              ),
              LoggableForComposite(
                properties: ChoiceProperties(
                  isRanked: true,
                  optionType: LoggableType.text,
                  useSlider: true,
                  options: [
                    ChoiceOption(
                        metadata: metadata, id: generateSmallId(), value: context.l10n.bad),
                    ChoiceOption(
                        metadata: metadata, id: generateSmallId(), value: context.l10n.okay),
                    ChoiceOption(
                        metadata: metadata, id: generateSmallId(), value: context.l10n.good),
                    ChoiceOption(
                        metadata: metadata, id: generateSmallId(), value: context.l10n.awesome),
                  ].lock,
                  metadataTemplate: metadataTemplate,
                ),
                type: LoggableType.choice,
                title: context.l10n.overallQuality,
                id: generateId(),
                isArrayable: false,
                isHiddenByDefault: false,
                isDismissible: false,
                hideTitle: false,
              ),
              LoggableForComposite(
                properties: CompositeProperties(
                  loggables: [
                    LoggableForComposite(
                      properties: ChoiceProperties(
                        isRanked: false,
                        optionType: LoggableType.text,
                        useSlider: false,
                        options: [
                          ChoiceOption(
                              metadata: metadata,
                              id: generateSmallId(),
                              value: context.l10n.normal),
                          ChoiceOption(
                              metadata: metadata, id: generateSmallId(), value: context.l10n.weird),
                          ChoiceOption(
                              metadata: metadata,
                              id: generateSmallId(),
                              value: context.l10n.nightmare),
                          ChoiceOption(
                              metadata: metadata, id: generateSmallId(), value: context.l10n.other),
                        ].lock,
                        metadataTemplate: metadataTemplate,
                      ),
                      type: LoggableType.choice,
                      title: context.l10n.dreamType,
                      id: generateId(),
                      isArrayable: false,
                      isHiddenByDefault: false,
                      isDismissible: false,
                      hideTitle: false,
                    ),
                    LoggableForComposite(
                      properties: TextProperties(
                          maximumLength: 500, useLargeFont: false, suggestions: <String>[].lock),
                      type: LoggableType.text,
                      title: context.l10n.description,
                      id: generateId(),
                      isArrayable: false,
                      isHiddenByDefault: false,
                      isDismissible: false,
                      hideTitle: false,
                    ),
                  ].lock,
                  calculations: calculations,
                  displaySideBySide: false,
                  isOrGroup: false,
                  sideBySideDelimiter: "",
                  level: 1,
                ),
                type: LoggableType.composite,
                title: context.l10n.dreams,
                id: generateId(),
                isArrayable: true,
                isHiddenByDefault: false,
                isDismissible: true,
                hideTitle: false,
              ),
            ].lock,
            calculations: calculations,
            displaySideBySide: false,
            isOrGroup: false,
            sideBySideDelimiter: "",
            level: 0,
          ),
          mainCardConfig: const EmptyProperty(),
          aggregationConfig: EmptyAggregationConfig(),
        ),
        type: LoggableType.composite,
        title: context.l10n.sleepLog,
        creationDate: now,
        tags: tags,
        id: generateId(),
      ),
    ),
  );

  // weather log
  templates.add(
    TemplateLoggable(
      context.l10n.weatherLog,
      Loggable(
        loggableSettings: defaultSettings.copyWith(symbol: "⛅"),
        loggableConfig: LoggableProperties(
          generalConfig: CompositeProperties(
            loggables: [
              LoggableForComposite(
                properties: ChoiceProperties(
                  isRanked: false,
                  optionType: LoggableType.text,
                  useSlider: false,
                  options: [
                    ChoiceOption(
                        metadata: metadata,
                        id: generateSmallId(),
                        value: context.l10n.sunnyClearSky),
                    ChoiceOption(
                        metadata: metadata,
                        id: generateSmallId(),
                        value: context.l10n.partlyCloudy),
                    ChoiceOption(
                        metadata: metadata, id: generateSmallId(), value: context.l10n.cloudy),
                    ChoiceOption(
                        metadata: metadata, id: generateSmallId(), value: context.l10n.rainy),
                    ChoiceOption(
                        metadata: metadata, id: generateSmallId(), value: context.l10n.stormy),
                    ChoiceOption(
                        metadata: metadata, id: generateSmallId(), value: context.l10n.foggy),
                  ].lock,
                  metadataTemplate: metadataTemplate,
                ),
                type: LoggableType.choice,
                title: context.l10n.weatherType,
                id: generateId(),
                isArrayable: false,
                isHiddenByDefault: false,
                isDismissible: false,
                hideTitle: false,
              ),
              LoggableForComposite(
                properties: const NumberProperties(
                  min: -20,
                  max: 50,
                  prefix: "",
                  suffix: "c",
                  allowDecimal: false,
                  showMinusButton: false,
                  showSlider: true,
                  showTotalCount: false,
                ),
                type: LoggableType.number,
                title: context.l10n.temperature,
                id: generateId(),
                isArrayable: false,
                isHiddenByDefault: false,
                isDismissible: false,
                hideTitle: false,
              ),
              LoggableForComposite(
                properties: CompositeProperties(
                  loggables: [
                    LoggableForComposite(
                      properties: ChoiceProperties(
                        isRanked: false,
                        optionType: LoggableType.text,
                        useSlider: false,
                        options: [
                          ChoiceOption(
                              metadata: metadata, id: generateSmallId(), value: context.l10n.north),
                          ChoiceOption(
                              metadata: metadata, id: generateSmallId(), value: context.l10n.west),
                          ChoiceOption(
                              metadata: metadata, id: generateSmallId(), value: context.l10n.south),
                          ChoiceOption(
                              metadata: metadata, id: generateSmallId(), value: context.l10n.east),
                        ].lock,
                        metadataTemplate: metadataTemplate,
                      ),
                      type: LoggableType.choice,
                      title: context.l10n.direction,
                      id: generateId(),
                      isArrayable: false,
                      isHiddenByDefault: false,
                      isDismissible: false,
                      hideTitle: false,
                    ),
                    LoggableForComposite(
                      properties: const NumberProperties(
                        min: 0,
                        max: 300,
                        prefix: "",
                        suffix: "km/h",
                        allowDecimal: true,
                        showMinusButton: false,
                        showSlider: false,
                        showTotalCount: false,
                      ),
                      type: LoggableType.number,
                      title: context.l10n.speed,
                      id: generateId(),
                      isArrayable: false,
                      isHiddenByDefault: false,
                      isDismissible: false,
                      hideTitle: false,
                    ),
                  ].lock,
                  calculations: calculations,
                  displaySideBySide: false,
                  isOrGroup: false,
                  sideBySideDelimiter: "",
                  level: 1,
                ),
                type: LoggableType.composite,
                title: context.l10n.wind,
                id: generateId(),
                isArrayable: false,
                isHiddenByDefault: false,
                isDismissible: true,
                hideTitle: false,
              ),
            ].lock,
            calculations: calculations,
            displaySideBySide: false,
            isOrGroup: false,
            sideBySideDelimiter: "",
            level: 0,
          ),
          mainCardConfig: const EmptyProperty(),
          aggregationConfig: EmptyAggregationConfig(),
        ),
        type: LoggableType.composite,
        title: context.l10n.weatherLog,
        creationDate: now,
        tags: tags,
        id: generateId(),
      ),
    ),
  );

  // fuel log
  templates.add(
    TemplateLoggable(
      context.l10n.fuelLog,
      Loggable(
        loggableSettings: defaultSettings.copyWith(symbol: "⛽"),
        loggableConfig: LoggableProperties(
          generalConfig: CompositeProperties(
            loggables: [
              LoggableForComposite(
                properties: const NumberProperties(
                  prefix: "",
                  suffix: "km",
                  allowDecimal: false,
                  showMinusButton: false,
                  showSlider: false,
                  showTotalCount: false,
                ),
                type: LoggableType.number,
                title: context.l10n.distance,
                id: generateId(),
                isArrayable: false,
                isHiddenByDefault: false,
                isDismissible: false,
                hideTitle: false,
              ),
              LoggableForComposite(
                properties: CompositeProperties(
                  loggables: [
                    LoggableForComposite(
                      properties: NumberProperties(
                        min: 0,
                        prefix: "",
                        suffix: context.l10n.litters,
                        allowDecimal: true,
                        showMinusButton: false,
                        showSlider: false,
                        showTotalCount: false,
                      ),
                      type: LoggableType.number,
                      title: context.l10n.amount,
                      id: generateId(),
                      isArrayable: false,
                      isHiddenByDefault: false,
                      isDismissible: false,
                      hideTitle: false,
                    ),
                    LoggableForComposite(
                      properties: const NumberProperties(
                        min: 0,
                        prefix: "\$",
                        suffix: "",
                        allowDecimal: true,
                        showMinusButton: false,
                        showSlider: false,
                        showTotalCount: false,
                      ),
                      type: LoggableType.number,
                      title: context.l10n.totalPrice,
                      id: generateId(),
                      isArrayable: false,
                      isHiddenByDefault: false,
                      isDismissible: false,
                      hideTitle: false,
                    ),
                  ].lock,
                  calculations: calculations,
                  displaySideBySide: true,
                  isOrGroup: false,
                  sideBySideDelimiter: " | ",
                  level: 1,
                ),
                type: LoggableType.composite,
                title: context.l10n.fuel,
                id: generateId(),
                isArrayable: false,
                isHiddenByDefault: false,
                isDismissible: false,
                hideTitle: false,
              ),
              LoggableForComposite(
                properties: TextProperties(
                  maximumLength: 100,
                  useLargeFont: false,
                  suggestions: ['place1, place2'].lock,
                ),
                type: LoggableType.text,
                title: context.l10n.location,
                id: generateId(),
                isArrayable: false,
                isHiddenByDefault: false,
                isDismissible: false,
                hideTitle: false,
              ),
            ].lock,
            calculations: calculations,
            displaySideBySide: false,
            isOrGroup: false,
            sideBySideDelimiter: "",
            level: 0,
          ),
          mainCardConfig: const EmptyProperty(),
          aggregationConfig: EmptyAggregationConfig(),
        ),
        type: LoggableType.composite,
        title: context.l10n.fuelLog,
        creationDate: now,
        tags: tags,
        id: generateId(),
      ),
    ),
  );

  // spending log
  templates.add(
    TemplateLoggable(
      context.l10n.spendingLog,
      Loggable(
        loggableSettings: defaultSettings.copyWith(symbol: "💸"),
        loggableConfig: LoggableProperties(
          generalConfig: CompositeProperties(
            loggables: [
              LoggableForComposite(
                properties: ChoiceProperties(
                  isRanked: false,
                  optionType: LoggableType.text,
                  useSlider: false,
                  options: [
                    ChoiceOption(metadata: metadata, id: generateId(), value: context.l10n.housing),
                    ChoiceOption(
                        metadata: metadata, id: generateId(), value: context.l10n.transportation),
                    ChoiceOption(metadata: metadata, id: generateId(), value: context.l10n.food),
                    ChoiceOption(
                        metadata: metadata, id: generateId(), value: context.l10n.utilities),
                    ChoiceOption(
                        metadata: metadata, id: generateId(), value: context.l10n.insurance),
                    ChoiceOption(
                        metadata: metadata, id: generateId(), value: context.l10n.healthcare),
                    ChoiceOption(
                        metadata: metadata, id: generateId(), value: context.l10n.investment),
                    ChoiceOption(
                        metadata: metadata, id: generateId(), value: context.l10n.payments),
                    ChoiceOption(
                        metadata: metadata, id: generateId(), value: context.l10n.personalSpending),
                    ChoiceOption(
                        metadata: metadata, id: generateId(), value: context.l10n.entertainment),
                    ChoiceOption(metadata: metadata, id: generateId(), value: context.l10n.other),
                  ].lock,
                  metadataTemplate: metadataTemplate,
                ),
                type: LoggableType.choice,
                title: context.l10n.category,
                id: generateId(),
                isArrayable: false,
                isHiddenByDefault: false,
                isDismissible: false,
                hideTitle: false,
              ),
              LoggableForComposite(
                properties: TextProperties(
                  maximumLength: 100,
                  useLargeFont: false,
                  suggestions: <String>[].lock,
                ),
                type: LoggableType.text,
                title: context.l10n.itemName,
                id: generateId(),
                isArrayable: false,
                isHiddenByDefault: false,
                isDismissible: true,
                hideTitle: false,
              ),
              LoggableForComposite(
                properties: const NumberProperties(
                  min: 0,
                  prefix: "\$",
                  suffix: "",
                  allowDecimal: true,
                  showMinusButton: false,
                  showSlider: false,
                  showTotalCount: false,
                ),
                type: LoggableType.number,
                title: context.l10n.price,
                id: generateId(),
                isArrayable: false,
                isHiddenByDefault: false,
                isDismissible: false,
                hideTitle: false,
              ),
            ].lock,
            calculations: calculations,
            displaySideBySide: false,
            isOrGroup: false,
            sideBySideDelimiter: "",
            level: 0,
          ),
          mainCardConfig: const EmptyProperty(),
          aggregationConfig: EmptyAggregationConfig(),
        ),
        type: LoggableType.composite,
        title: context.l10n.spendingLog,
        creationDate: now,
        tags: tags,
        id: generateId(),
      ),
    ),
  );

  // blood pressure and heart rate
  templates.add(
    TemplateLoggable(
      context.l10n.bloodPressureAndHeartRate,
      Loggable(
        loggableSettings: defaultSettings.copyWith(symbol: "🫀"),
        loggableConfig: LoggableProperties(
          generalConfig: CompositeProperties(
            loggables: [
              LoggableForComposite(
                properties: const NumberProperties(
                  min: 80,
                  max: 180,
                  prefix: "",
                  suffix: "mm Hg",
                  allowDecimal: false,
                  showMinusButton: false,
                  showSlider: true,
                  showTotalCount: false,
                ),
                type: LoggableType.number,
                title: context.l10n.systolic,
                id: generateId(),
                isArrayable: false,
                isHiddenByDefault: false,
                isDismissible: false,
                hideTitle: false,
              ),
              LoggableForComposite(
                properties: const NumberProperties(
                  min: 60,
                  max: 160,
                  prefix: "",
                  suffix: "mm Hg",
                  allowDecimal: false,
                  showMinusButton: false,
                  showSlider: true,
                  showTotalCount: false,
                ),
                type: LoggableType.number,
                title: context.l10n.diastolic,
                id: generateId(),
                isArrayable: false,
                isHiddenByDefault: false,
                isDismissible: false,
                hideTitle: false,
              ),
              LoggableForComposite(
                properties: NumberProperties(
                  min: 20,
                  max: 220,
                  prefix: "",
                  suffix: context.l10n.bpm,
                  allowDecimal: false,
                  showMinusButton: false,
                  showSlider: false,
                  showTotalCount: false,
                ),
                type: LoggableType.number,
                title: context.l10n.heartRate,
                id: generateId(),
                isArrayable: false,
                isHiddenByDefault: false,
                isDismissible: false,
                hideTitle: false,
              ),
            ].lock,
            calculations: calculations,
            displaySideBySide: false,
            isOrGroup: false,
            sideBySideDelimiter: "",
            level: 0,
          ),
          mainCardConfig: const EmptyProperty(),
          aggregationConfig: EmptyAggregationConfig(),
        ),
        type: LoggableType.composite,
        title: context.l10n.bloodPressureAndHeartRate,
        creationDate: now,
        tags: tags,
        id: generateId(),
      ),
    ),
  );

  // tinnitus burst
  templates.add(
    TemplateLoggable(
      context.l10n.tinnitusBurst,
      Loggable(
        loggableSettings: defaultSettings.copyWith(symbol: "👂💥"),
        loggableConfig: LoggableProperties(
          generalConfig: CompositeProperties(
            loggables: [
              LoggableForComposite(
                properties: ChoiceProperties(
                  isRanked: false,
                  optionType: LoggableType.text,
                  useSlider: false,
                  options: [
                    ChoiceOption(metadata: metadata, id: generateId(), value: context.l10n.leftEar),
                    ChoiceOption(
                        metadata: metadata, id: generateId(), value: context.l10n.rightEar),
                    ChoiceOption(
                        metadata: metadata, id: generateId(), value: context.l10n.bothEars),
                  ].lock,
                  metadataTemplate: metadataTemplate,
                ),
                type: LoggableType.choice,
                title: context.l10n.ear,
                id: generateId(),
                isArrayable: false,
                isHiddenByDefault: false,
                isDismissible: false,
                hideTitle: true,
              ),
              LoggableForComposite(
                properties: const NumberProperties(
                  min: 1,
                  max: 10,
                  prefix: "",
                  suffix: "",
                  allowDecimal: false,
                  showMinusButton: false,
                  showSlider: true,
                  showTotalCount: false,
                ),
                type: LoggableType.number,
                title: context.l10n.intensity,
                id: generateId(),
                isArrayable: false,
                isHiddenByDefault: false,
                isDismissible: false,
                hideTitle: false,
              ),
              LoggableForComposite(
                properties: const NumberProperties(
                  min: 1,
                  max: 18,
                  prefix: "",
                  suffix: "khz",
                  allowDecimal: true,
                  showMinusButton: false,
                  showSlider: true,
                  showTotalCount: false,
                ),
                type: LoggableType.number,
                title: context.l10n.frequency,
                id: generateId(),
                isArrayable: false,
                isHiddenByDefault: false,
                isDismissible: true,
                hideTitle: false,
              ),
              LoggableForComposite(
                properties: NumberProperties(
                  min: 0,
                  prefix: "",
                  suffix: context.l10n.minutes,
                  allowDecimal: true,
                  showMinusButton: false,
                  showSlider: false,
                  showTotalCount: false,
                ),
                type: LoggableType.number,
                title: context.l10n.duration,
                id: generateId(),
                isArrayable: false,
                isHiddenByDefault: false,
                isDismissible: true,
                hideTitle: false,
              ),
            ].lock,
            calculations: calculations,
            displaySideBySide: false,
            isOrGroup: false,
            sideBySideDelimiter: "",
            level: 0,
          ),
          mainCardConfig: const EmptyProperty(),
          aggregationConfig: EmptyAggregationConfig(),
        ),
        type: LoggableType.composite,
        title: context.l10n.tinnitusBurst,
        creationDate: now,
        tags: tags,
        id: generateId(),
      ),
    ),
  );

  return templates;
}
