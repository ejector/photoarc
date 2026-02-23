import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;

part 'database.g.dart';

// ── Photos table ──────────────────────────────────────────────────────────────

class Photos extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get path => text().unique()();
  TextColumn get filename => text()();
  TextColumn get directory => text()();
  DateTimeColumn get dateTaken => dateTime()();
  IntColumn get fileSize => integer()();
  TextColumn get format => text()();
  IntColumn get width => integer().nullable()();
  IntColumn get height => integer().nullable()();
  TextColumn get thumbnailPath => text().nullable()();
  TextColumn get yearMonth => text()();
  IntColumn get orientation => integer().withDefault(const Constant(1))();
  BoolColumn get isValid => boolean().withDefault(const Constant(true))();
  DateTimeColumn get fileModifiedAt => dateTime()();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
}

// ── Scan settings table ───────────────────────────────────────────────────────

class ScanSettings extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get folderPath => text()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
}

// ── App settings table ────────────────────────────────────────────────────────

class AppSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

// ── Database ──────────────────────────────────────────────────────────────────

@DriftDatabase(tables: [Photos, ScanSettings, AppSettings])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  /// Opens an on-disk database at [dbFolder]/photoarc.db.
  /// If photoarc.db does not exist but legacy photo_feed.db does,
  /// renames the old file for backward compatibility.
  factory AppDatabase.onDisk(String dbFolder) {
    final newFile = File(p.join(dbFolder, 'photoarc.db'));
    if (!newFile.existsSync()) {
      final oldFile = File(p.join(dbFolder, 'photo_feed.db'));
      if (oldFile.existsSync()) {
        oldFile.renameSync(newFile.path);
      }
    }
    return AppDatabase(NativeDatabase.createInBackground(newFile));
  }

  /// Opens an in-memory database – useful for testing.
  factory AppDatabase.inMemory() {
    return AppDatabase(NativeDatabase.memory());
  }

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          // Create indexes not handled by drift annotations.
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_photos_date_taken ON photos (date_taken)',
          );
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_photos_year_month ON photos (year_month)',
          );
          // Note: idx_photos_path is not needed because path column has .unique()
          // which already creates a unique index.
        },
      );

  // ── Photo methods ─────────────────────────────────────────────────────────

  /// Insert a batch of photo companions in a single transaction.
  /// On conflict (same path), updates the existing row.
  Future<void> insertPhotoBatch(List<PhotosCompanion> photos) async {
    await batch((b) {
      for (final photo in photos) {
        b.insert(
          this.photos,
          photo,
          onConflict: DoUpdate(
            (old) => photo,
            target: [this.photos.path],
          ),
        );
      }
    });
  }

  /// Paginated query sorted by [dateTaken]. Only returns valid photos.
  /// [newestFirst] controls sort direction (default true = descending).
  Future<List<Photo>> getPhotosPaginated({
    required int limit,
    required int offset,
    bool newestFirst = true,
  }) {
    final query = select(photos)
      ..where((t) => t.isValid.equals(true))
      ..orderBy([
        (t) => OrderingTerm(
              expression: t.dateTaken,
              mode: newestFirst ? OrderingMode.desc : OrderingMode.asc,
            ),
      ])
      ..limit(limit, offset: offset);
    return query.get();
  }

  /// Returns all valid photos for a given [yearMonth] string (e.g. "2015-03").
  Future<List<Photo>> getPhotosByYearMonth(String yearMonth) {
    final query = select(photos)
      ..where(
          (t) => t.yearMonth.equals(yearMonth) & t.isValid.equals(true))
      ..orderBy([(t) => OrderingTerm.desc(t.dateTaken)]);
    return query.get();
  }

  /// Returns the total count of valid photos.
  Future<int> getValidPhotoCount() async {
    final countExp = photos.id.count();
    final query = selectOnly(photos)
      ..addColumns([countExp])
      ..where(photos.isValid.equals(true));
    final row = await query.getSingle();
    return row.read(countExp) ?? 0;
  }

  /// Returns distinct year_month values sorted descending.
  Future<List<String>> getDistinctYearMonths({bool newestFirst = true}) async {
    final query = selectOnly(photos, distinct: true)
      ..addColumns([photos.yearMonth])
      ..where(photos.isValid.equals(true))
      ..orderBy([
        OrderingTerm(
          expression: photos.yearMonth,
          mode: newestFirst ? OrderingMode.desc : OrderingMode.asc,
        ),
      ]);
    final rows = await query.get();
    return rows.map((r) => r.read(photos.yearMonth)!).toList();
  }

  /// Returns a map of photo path -> fileModifiedAt for incremental scanning.
  Future<Map<String, DateTime>> getExistingFileModifiedTimes() async {
    final query = selectOnly(photos)
      ..addColumns([photos.path, photos.fileModifiedAt]);
    final rows = await query.get();
    return {
      for (final row in rows)
        row.read(photos.path)!: row.read(photos.fileModifiedAt)!,
    };
  }

  // ── Scan settings methods ─────────────────────────────────────────────────

  /// Replaces all scan folder entries with [folders].
  Future<void> saveScanFolders(List<ScanSettingsCompanion> folders) async {
    await transaction(() async {
      await delete(scanSettings).go();
      await batch((b) {
        b.insertAll(scanSettings, folders);
      });
    });
  }

  /// Loads all scan folder entries.
  Future<List<ScanSetting>> loadScanFolders() {
    return select(scanSettings).get();
  }

  // ── App settings methods ──────────────────────────────────────────────────

  /// Returns the value for [settingKey], or null if not set.
  Future<String?> getSetting(String settingKey) async {
    final query = select(appSettings)
      ..where((t) => t.key.equals(settingKey));
    final row = await query.getSingleOrNull();
    return row?.value;
  }

  /// Upserts [settingKey] = [settingValue].
  Future<void> setSetting(String settingKey, String settingValue) async {
    await into(appSettings).insertOnConflictUpdate(
      AppSettingsCompanion(
        key: Value(settingKey),
        value: Value(settingValue),
      ),
    );
  }
}
