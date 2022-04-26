import 'dart:io';

import 'package:drift/drift.dart';

import 'package:drift/native.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:path_provider/path_provider.dart';
import 'package:super_logger/core/models/loggable.dart';
import 'package:super_logger/core/models/db_helper_models.dart';
import 'package:super_logger/core/models/loggable_tag.dart';
import 'package:super_logger/core/repository/main_repository/drift/models/loggables.dart';
import 'package:super_logger/core/repository/main_repository/drift/models/loggable_and_tags.dart';
import 'package:super_logger/core/repository/main_repository/drift/models/logs.dart';
import 'package:super_logger/core/repository/main_repository/drift/models/tags.dart';
import 'package:rxdart/rxdart.dart';

import 'package:path/path.dart' as path;

part 'drift_db.g.dart';

LazyDatabase _openConnection() {
  // the LazyDatabase util lets us find the right location for the file async.
  return LazyDatabase(() async {
    // put the database file, called db.sqlite here, into the documents folder
    // for your app.
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(path.join(dbFolder.path, 'db.sqlite'));
    return NativeDatabase(file);
  });
}

@DriftDatabase(tables: [Loggables, Logs, Tags, LoggableAndTags], daos: [LoggableDao, LogEntryDao])
class AppDatabase extends _$AppDatabase {
  // we tell the database where to store the data with this constructor
  AppDatabase() : super(_openConnection());

  // you should bump this number whenever you change or add a table definition. Migrations
  // are covered later in this readme.
  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (migrator, from, to) async {
          // if (from == 1) {
          //   await migrator.createTable(tags);
          //   await migrator.addColumn(tasks, tasks.tagName);
          // }
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}

class LoggableWithTags {
  final LoggableEntry loggable;
  final List<Tag> tags;
  LoggableWithTags({
    required this.loggable,
    required this.tags,
  });

  factory LoggableWithTags.fromLoggable(Loggable loggable) {
    return LoggableWithTags(
      loggable: LoggableConverver.driftFromBaseLoggable(loggable),
      tags: loggable.tags.map((tag) => Tag(id: tag.id, name: tag.name)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    final loggableMap = LoggableConverver.driftLoggableToJson(loggable);
    loggableMap.putIfAbsent(
        'tags', () => tags.map((tag) => LoggableTag(name: tag.name, id: tag.id)).toList());
    return loggableMap;
  }
}

@DriftAccessor(tables: [Loggables, Logs, Tags, LoggableAndTags])
class LoggableDao extends DatabaseAccessor<AppDatabase> with _$LoggableDaoMixin {
  final AppDatabase db;
  LoggableDao(this.db) : super(db);

  Future<List<LoggableIdAndLastLogTime>> categoriesAndLastLogTime(String date) async {
    return (await customSelect(
                'SELECT loggables.id AS id, max(logs.timestamp) AS timestamp FROM loggables INNER JOIN logs ON loggables.id = logs.loggable_id WHERE logs.date = \'$date\' GROUP BY loggables.id ')
            .get())
        .map((row) =>
            LoggableIdAndLastLogTime(id: row.read('id'), lastLogTime: row.read('timestamp')))
        .toList();

    //   return (await customSelect(
    //                   'SELECT EXISTS(SELECT 1 FROM logs WHERE logs.loggable_id = \'$loggableId\' AND logs.date = \'$date\') AS isPresent;')
    //               .getSingle())
    //           .read<int>('isPresent') ==
    //       1;
    // }
  }

  Future<LoggableWithTags> getLoggable(String loggableId) async {
    LoggableEntry cat =
        await (select(loggables)..where((tbl) => tbl.id.equals(loggableId))).getSingle();

    final tagList = (await (select(loggableAndTags).join(
      [
        innerJoin(tags, tags.id.equalsExp(loggableAndTags.tag)),
      ],
    )..where(
                loggableAndTags.loggable.equals(loggableId),
              ))
            .get())
        .map((entry) => entry.readTable(tags))
        .toList();

    return LoggableWithTags(loggable: cat, tags: tagList);
  }

  Future<List<LoggableWithTags>> getLoggables() async {
    final loggableList = await select(loggables).get();

    final idToLoggable = {for (var loggable in loggableList) loggable.id: loggable};
    final ids = idToLoggable.keys;

    final entryQuery = await (select(loggableAndTags).join(
      [
        innerJoin(tags, tags.id.equalsExp(loggableAndTags.tag)),
      ],
    )..where(loggableAndTags.loggable.isIn(ids)))
        .get();

    Map<String, List<Tag>> idToTag = {};

    for (final entry in entryQuery) {
      final tag = entry.readTable(tags);
      final loggableId = entry.readTable(loggableAndTags).loggable;
      idToTag.putIfAbsent(loggableId, () => []).add(tag);
    }

    return loggableList.map((e) {
      return LoggableWithTags(loggable: e, tags: idToTag[e.id] ?? []);
    }).toList();
  }

  Stream<List<LoggableWithTags>> getCategoriesStream() {
    final categoriesStream = select(loggables).watch();

    return categoriesStream.switchMap((loggableList) {
      // this method is called whenever the list of categories changes. for each
      // loggable, now we want to load all the tags in it.
      // (we create a map from id to loggable here just for performance reasons)
      final idToLoggable = {for (var loggable in loggableList) loggable.id: loggable};
      final ids = idToLoggable.keys;

      // select all entries that are included in any cart that we found
      final entryQuery = select(loggableAndTags).join(
        [
          innerJoin(tags, tags.id.equalsExp(loggableAndTags.tag)),
        ],
      )..where(loggableAndTags.loggable.isIn(ids));

      return entryQuery.watch().map((rows) {
        // Store the list of entries for each loggable, again using maps for faster lookups
        final idToTags = <String, List<Tag>>{};

        // for each entry (row) that is included in a loggable, put it in the map
        // of items
        for (final row in rows) {
          final item = row.readTable(tags);
          final id = row.readTable(loggableAndTags).loggable;

          idToTags.putIfAbsent(id, () => []).add(item);
        }

        // finally, all that's left is to merge the map of carts with the map of
        // entries
        return [
          for (var id in ids)
            LoggableWithTags(loggable: idToLoggable[id]!, tags: idToTags[id] ?? [])
        ];
      });
    });
  }

  Future<void> addLoggable(LoggableWithTags loggableWithTags) async {
    await transaction(() async {
      final loggable = loggableWithTags.loggable;

      // first, we write the shopping cart
      await into(loggables).insert(loggable, mode: InsertMode.replace);

      // we replace the entries of the tag, so first delete the old ones
      await (delete(loggableAndTags)..where((tbl) => tbl.loggable.equals(loggable.id))).go();

      // and write the new ones
      for (final tag in loggableWithTags.tags) {
        await into(loggableAndTags).insert(LoggableAndTag(loggable: loggable.id, tag: tag.id));
      }
    });
  }

  Future<void> deleteLoggable(String loggableId) async {
    await transaction(() async {
      await (delete(loggableAndTags)..where((tbl) => tbl.loggable.equals(loggableId))).go();
      await (delete(logs)..where((tbl) => tbl.loggableId.equals(loggableId))).go();
      await (delete(loggables)..where((tbl) => tbl.id.equals(loggableId))).go();
    });
  }
}

@DriftAccessor(tables: [Logs])
class LogEntryDao extends DatabaseAccessor<AppDatabase> with _$LogEntryDaoMixin {
  final AppDatabase db;
  LogEntryDao(this.db) : super(db);

  Stream<int> getSingleDateAndLogCount(String date) {
    //Create expression of count
    print(date);
    var countExp = logs.id.count();
    var whereDate = logs.date.equals(date);
    final query = selectOnly(logs)
      ..addColumns([countExp])
      ..where(whereDate);
    return query.map((row) => row.read(countExp)).watchSingle();
  }

  Future<IMap<String, int>> getDateAndLogCount(String minDate, String maxDate) async {
    String whereClauses = "";
    if (minDate == maxDate) {
      whereClauses = "logs.date = '$minDate'";
    } else {
      whereClauses = "logs.date BETWEEN '$minDate' AND '$maxDate'";
    }
    final query = await customSelect(
            'SELECT date, COUNT(*) AS logCount FROM logs WHERE $whereClauses GROUP BY logs.date;')
        .get();
    Map<String, int> dateAndLogCount = {};
    for (final queryRow in query) {
      dateAndLogCount[queryRow.read<String>('date')] = queryRow.read<int>('logCount');
    }
    return dateAndLogCount.lock;
  }

  Future<bool> existsInDate(String loggableId, String date) async {
    return (await customSelect(
                    'SELECT EXISTS(SELECT 1 FROM logs WHERE logs.loggable_id = \'$loggableId\' AND logs.date = \'$date\') AS isPresent;')
                .getSingle())
            .read<int>('isPresent') ==
        1;
  }

  Future<int?> latestLogTimeOfDate(String loggableId, String date) async {
    try {
      final query = await customSelect(
              'SELECT timestamp FROM logs WHERE logs.loggable_id = \'$loggableId\' AND logs.date = \'$date\' ORDER BY logs.timestamp DESC LIMIT 1;')
          .getSingle();
      return query.read<int>('timestamp');
    } catch (e) {
      return null;
    }
  }

  Future<void> insertLog(LogEntry log) async {
    await into(logs).insert(log);
  }

  Future<void> updateLog(LogEntry log) async {
    await update(logs).replace(log);
  }

  Future<List<LogEntry>> getAllLogs(String loggableId) async {
    return (select(logs)..where((tbl) => tbl.loggableId.equals(loggableId))).get();
  }

  Future<void> deleteById(String id) async {
    await (delete(logs)..where((tbl) => tbl.id.equals(id))).go();
  }

  Stream<List<LogEntry>> getAllLogsStream(String loggableId,
      {String? maxDate, String? minDate, bool isDescending = true}) {
    final query = select(logs);
    query.where((tbl) => tbl.loggableId.equals(loggableId));

    if (maxDate != null && minDate != null) {
      query.where((tbl) => tbl.date.isBetweenValues(minDate, maxDate));
    } else if (maxDate != null) {
      query.where((tbl) => tbl.date.isSmallerOrEqualValue(maxDate));
    } else if (minDate != null) {
      query.where((tbl) => tbl.date.isBiggerOrEqualValue(minDate));
    }

    query.orderBy([
      (log) => OrderingTerm(
          expression: log.timestamp, mode: isDescending ? OrderingMode.desc : OrderingMode.asc)
    ]);

    return query.watch();
  }

  Stream<List<LogEntry>> getLogsForDateStream(String loggableId, String date) {
    return (select(logs)
          ..where((tbl) => tbl.loggableId.equals(loggableId))
          ..where((tbl) => tbl.date.equals(date))
          ..orderBy([(log) => OrderingTerm(expression: log.timestamp, mode: OrderingMode.asc)]))
        .watch();
  }

  Future<List<LogEntry>> getLogsForDate(String loggableId, String date) async {
    return (select(logs)
          ..where((tbl) => tbl.loggableId.equals(loggableId))
          ..where((tbl) => tbl.date.equals(date))
          ..orderBy([(log) => OrderingTerm(expression: log.timestamp, mode: OrderingMode.asc)]))
        .get();
  }

  Future<void> insertMultipleLogs(List<LogEntry> logList) async {
    await batch((batch) {
      batch.insertAll(logs, logList);
    });
  }
}
