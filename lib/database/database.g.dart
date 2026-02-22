// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $PhotosTable extends Photos with TableInfo<$PhotosTable, Photo> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PhotosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _pathMeta = const VerificationMeta('path');
  @override
  late final GeneratedColumn<String> path = GeneratedColumn<String>(
    'path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _filenameMeta = const VerificationMeta(
    'filename',
  );
  @override
  late final GeneratedColumn<String> filename = GeneratedColumn<String>(
    'filename',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _directoryMeta = const VerificationMeta(
    'directory',
  );
  @override
  late final GeneratedColumn<String> directory = GeneratedColumn<String>(
    'directory',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateTakenMeta = const VerificationMeta(
    'dateTaken',
  );
  @override
  late final GeneratedColumn<DateTime> dateTaken = GeneratedColumn<DateTime>(
    'date_taken',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fileSizeMeta = const VerificationMeta(
    'fileSize',
  );
  @override
  late final GeneratedColumn<int> fileSize = GeneratedColumn<int>(
    'file_size',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _formatMeta = const VerificationMeta('format');
  @override
  late final GeneratedColumn<String> format = GeneratedColumn<String>(
    'format',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _widthMeta = const VerificationMeta('width');
  @override
  late final GeneratedColumn<int> width = GeneratedColumn<int>(
    'width',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _heightMeta = const VerificationMeta('height');
  @override
  late final GeneratedColumn<int> height = GeneratedColumn<int>(
    'height',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _thumbnailPathMeta = const VerificationMeta(
    'thumbnailPath',
  );
  @override
  late final GeneratedColumn<String> thumbnailPath = GeneratedColumn<String>(
    'thumbnail_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _yearMonthMeta = const VerificationMeta(
    'yearMonth',
  );
  @override
  late final GeneratedColumn<String> yearMonth = GeneratedColumn<String>(
    'year_month',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _orientationMeta = const VerificationMeta(
    'orientation',
  );
  @override
  late final GeneratedColumn<int> orientation = GeneratedColumn<int>(
    'orientation',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _isValidMeta = const VerificationMeta(
    'isValid',
  );
  @override
  late final GeneratedColumn<bool> isValid = GeneratedColumn<bool>(
    'is_valid',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_valid" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _fileModifiedAtMeta = const VerificationMeta(
    'fileModifiedAt',
  );
  @override
  late final GeneratedColumn<DateTime> fileModifiedAt =
      GeneratedColumn<DateTime>(
        'file_modified_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    path,
    filename,
    directory,
    dateTaken,
    fileSize,
    format,
    width,
    height,
    thumbnailPath,
    yearMonth,
    orientation,
    isValid,
    fileModifiedAt,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'photos';
  @override
  VerificationContext validateIntegrity(
    Insertable<Photo> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('path')) {
      context.handle(
        _pathMeta,
        path.isAcceptableOrUnknown(data['path']!, _pathMeta),
      );
    } else if (isInserting) {
      context.missing(_pathMeta);
    }
    if (data.containsKey('filename')) {
      context.handle(
        _filenameMeta,
        filename.isAcceptableOrUnknown(data['filename']!, _filenameMeta),
      );
    } else if (isInserting) {
      context.missing(_filenameMeta);
    }
    if (data.containsKey('directory')) {
      context.handle(
        _directoryMeta,
        directory.isAcceptableOrUnknown(data['directory']!, _directoryMeta),
      );
    } else if (isInserting) {
      context.missing(_directoryMeta);
    }
    if (data.containsKey('date_taken')) {
      context.handle(
        _dateTakenMeta,
        dateTaken.isAcceptableOrUnknown(data['date_taken']!, _dateTakenMeta),
      );
    } else if (isInserting) {
      context.missing(_dateTakenMeta);
    }
    if (data.containsKey('file_size')) {
      context.handle(
        _fileSizeMeta,
        fileSize.isAcceptableOrUnknown(data['file_size']!, _fileSizeMeta),
      );
    } else if (isInserting) {
      context.missing(_fileSizeMeta);
    }
    if (data.containsKey('format')) {
      context.handle(
        _formatMeta,
        format.isAcceptableOrUnknown(data['format']!, _formatMeta),
      );
    } else if (isInserting) {
      context.missing(_formatMeta);
    }
    if (data.containsKey('width')) {
      context.handle(
        _widthMeta,
        width.isAcceptableOrUnknown(data['width']!, _widthMeta),
      );
    }
    if (data.containsKey('height')) {
      context.handle(
        _heightMeta,
        height.isAcceptableOrUnknown(data['height']!, _heightMeta),
      );
    }
    if (data.containsKey('thumbnail_path')) {
      context.handle(
        _thumbnailPathMeta,
        thumbnailPath.isAcceptableOrUnknown(
          data['thumbnail_path']!,
          _thumbnailPathMeta,
        ),
      );
    }
    if (data.containsKey('year_month')) {
      context.handle(
        _yearMonthMeta,
        yearMonth.isAcceptableOrUnknown(data['year_month']!, _yearMonthMeta),
      );
    } else if (isInserting) {
      context.missing(_yearMonthMeta);
    }
    if (data.containsKey('orientation')) {
      context.handle(
        _orientationMeta,
        orientation.isAcceptableOrUnknown(
          data['orientation']!,
          _orientationMeta,
        ),
      );
    }
    if (data.containsKey('is_valid')) {
      context.handle(
        _isValidMeta,
        isValid.isAcceptableOrUnknown(data['is_valid']!, _isValidMeta),
      );
    }
    if (data.containsKey('file_modified_at')) {
      context.handle(
        _fileModifiedAtMeta,
        fileModifiedAt.isAcceptableOrUnknown(
          data['file_modified_at']!,
          _fileModifiedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_fileModifiedAtMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Photo map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Photo(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      path: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}path'],
      )!,
      filename: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}filename'],
      )!,
      directory: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}directory'],
      )!,
      dateTaken: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date_taken'],
      )!,
      fileSize: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}file_size'],
      )!,
      format: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}format'],
      )!,
      width: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}width'],
      ),
      height: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}height'],
      ),
      thumbnailPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}thumbnail_path'],
      ),
      yearMonth: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}year_month'],
      )!,
      orientation: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}orientation'],
      )!,
      isValid: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_valid'],
      )!,
      fileModifiedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}file_modified_at'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $PhotosTable createAlias(String alias) {
    return $PhotosTable(attachedDatabase, alias);
  }
}

class Photo extends DataClass implements Insertable<Photo> {
  final int id;
  final String path;
  final String filename;
  final String directory;
  final DateTime dateTaken;
  final int fileSize;
  final String format;
  final int? width;
  final int? height;
  final String? thumbnailPath;
  final String yearMonth;
  final int orientation;
  final bool isValid;
  final DateTime fileModifiedAt;
  final DateTime createdAt;
  const Photo({
    required this.id,
    required this.path,
    required this.filename,
    required this.directory,
    required this.dateTaken,
    required this.fileSize,
    required this.format,
    this.width,
    this.height,
    this.thumbnailPath,
    required this.yearMonth,
    required this.orientation,
    required this.isValid,
    required this.fileModifiedAt,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['path'] = Variable<String>(path);
    map['filename'] = Variable<String>(filename);
    map['directory'] = Variable<String>(directory);
    map['date_taken'] = Variable<DateTime>(dateTaken);
    map['file_size'] = Variable<int>(fileSize);
    map['format'] = Variable<String>(format);
    if (!nullToAbsent || width != null) {
      map['width'] = Variable<int>(width);
    }
    if (!nullToAbsent || height != null) {
      map['height'] = Variable<int>(height);
    }
    if (!nullToAbsent || thumbnailPath != null) {
      map['thumbnail_path'] = Variable<String>(thumbnailPath);
    }
    map['year_month'] = Variable<String>(yearMonth);
    map['orientation'] = Variable<int>(orientation);
    map['is_valid'] = Variable<bool>(isValid);
    map['file_modified_at'] = Variable<DateTime>(fileModifiedAt);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  PhotosCompanion toCompanion(bool nullToAbsent) {
    return PhotosCompanion(
      id: Value(id),
      path: Value(path),
      filename: Value(filename),
      directory: Value(directory),
      dateTaken: Value(dateTaken),
      fileSize: Value(fileSize),
      format: Value(format),
      width: width == null && nullToAbsent
          ? const Value.absent()
          : Value(width),
      height: height == null && nullToAbsent
          ? const Value.absent()
          : Value(height),
      thumbnailPath: thumbnailPath == null && nullToAbsent
          ? const Value.absent()
          : Value(thumbnailPath),
      yearMonth: Value(yearMonth),
      orientation: Value(orientation),
      isValid: Value(isValid),
      fileModifiedAt: Value(fileModifiedAt),
      createdAt: Value(createdAt),
    );
  }

  factory Photo.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Photo(
      id: serializer.fromJson<int>(json['id']),
      path: serializer.fromJson<String>(json['path']),
      filename: serializer.fromJson<String>(json['filename']),
      directory: serializer.fromJson<String>(json['directory']),
      dateTaken: serializer.fromJson<DateTime>(json['dateTaken']),
      fileSize: serializer.fromJson<int>(json['fileSize']),
      format: serializer.fromJson<String>(json['format']),
      width: serializer.fromJson<int?>(json['width']),
      height: serializer.fromJson<int?>(json['height']),
      thumbnailPath: serializer.fromJson<String?>(json['thumbnailPath']),
      yearMonth: serializer.fromJson<String>(json['yearMonth']),
      orientation: serializer.fromJson<int>(json['orientation']),
      isValid: serializer.fromJson<bool>(json['isValid']),
      fileModifiedAt: serializer.fromJson<DateTime>(json['fileModifiedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'path': serializer.toJson<String>(path),
      'filename': serializer.toJson<String>(filename),
      'directory': serializer.toJson<String>(directory),
      'dateTaken': serializer.toJson<DateTime>(dateTaken),
      'fileSize': serializer.toJson<int>(fileSize),
      'format': serializer.toJson<String>(format),
      'width': serializer.toJson<int?>(width),
      'height': serializer.toJson<int?>(height),
      'thumbnailPath': serializer.toJson<String?>(thumbnailPath),
      'yearMonth': serializer.toJson<String>(yearMonth),
      'orientation': serializer.toJson<int>(orientation),
      'isValid': serializer.toJson<bool>(isValid),
      'fileModifiedAt': serializer.toJson<DateTime>(fileModifiedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Photo copyWith({
    int? id,
    String? path,
    String? filename,
    String? directory,
    DateTime? dateTaken,
    int? fileSize,
    String? format,
    Value<int?> width = const Value.absent(),
    Value<int?> height = const Value.absent(),
    Value<String?> thumbnailPath = const Value.absent(),
    String? yearMonth,
    int? orientation,
    bool? isValid,
    DateTime? fileModifiedAt,
    DateTime? createdAt,
  }) => Photo(
    id: id ?? this.id,
    path: path ?? this.path,
    filename: filename ?? this.filename,
    directory: directory ?? this.directory,
    dateTaken: dateTaken ?? this.dateTaken,
    fileSize: fileSize ?? this.fileSize,
    format: format ?? this.format,
    width: width.present ? width.value : this.width,
    height: height.present ? height.value : this.height,
    thumbnailPath: thumbnailPath.present
        ? thumbnailPath.value
        : this.thumbnailPath,
    yearMonth: yearMonth ?? this.yearMonth,
    orientation: orientation ?? this.orientation,
    isValid: isValid ?? this.isValid,
    fileModifiedAt: fileModifiedAt ?? this.fileModifiedAt,
    createdAt: createdAt ?? this.createdAt,
  );
  Photo copyWithCompanion(PhotosCompanion data) {
    return Photo(
      id: data.id.present ? data.id.value : this.id,
      path: data.path.present ? data.path.value : this.path,
      filename: data.filename.present ? data.filename.value : this.filename,
      directory: data.directory.present ? data.directory.value : this.directory,
      dateTaken: data.dateTaken.present ? data.dateTaken.value : this.dateTaken,
      fileSize: data.fileSize.present ? data.fileSize.value : this.fileSize,
      format: data.format.present ? data.format.value : this.format,
      width: data.width.present ? data.width.value : this.width,
      height: data.height.present ? data.height.value : this.height,
      thumbnailPath: data.thumbnailPath.present
          ? data.thumbnailPath.value
          : this.thumbnailPath,
      yearMonth: data.yearMonth.present ? data.yearMonth.value : this.yearMonth,
      orientation: data.orientation.present
          ? data.orientation.value
          : this.orientation,
      isValid: data.isValid.present ? data.isValid.value : this.isValid,
      fileModifiedAt: data.fileModifiedAt.present
          ? data.fileModifiedAt.value
          : this.fileModifiedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Photo(')
          ..write('id: $id, ')
          ..write('path: $path, ')
          ..write('filename: $filename, ')
          ..write('directory: $directory, ')
          ..write('dateTaken: $dateTaken, ')
          ..write('fileSize: $fileSize, ')
          ..write('format: $format, ')
          ..write('width: $width, ')
          ..write('height: $height, ')
          ..write('thumbnailPath: $thumbnailPath, ')
          ..write('yearMonth: $yearMonth, ')
          ..write('orientation: $orientation, ')
          ..write('isValid: $isValid, ')
          ..write('fileModifiedAt: $fileModifiedAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    path,
    filename,
    directory,
    dateTaken,
    fileSize,
    format,
    width,
    height,
    thumbnailPath,
    yearMonth,
    orientation,
    isValid,
    fileModifiedAt,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Photo &&
          other.id == this.id &&
          other.path == this.path &&
          other.filename == this.filename &&
          other.directory == this.directory &&
          other.dateTaken == this.dateTaken &&
          other.fileSize == this.fileSize &&
          other.format == this.format &&
          other.width == this.width &&
          other.height == this.height &&
          other.thumbnailPath == this.thumbnailPath &&
          other.yearMonth == this.yearMonth &&
          other.orientation == this.orientation &&
          other.isValid == this.isValid &&
          other.fileModifiedAt == this.fileModifiedAt &&
          other.createdAt == this.createdAt);
}

class PhotosCompanion extends UpdateCompanion<Photo> {
  final Value<int> id;
  final Value<String> path;
  final Value<String> filename;
  final Value<String> directory;
  final Value<DateTime> dateTaken;
  final Value<int> fileSize;
  final Value<String> format;
  final Value<int?> width;
  final Value<int?> height;
  final Value<String?> thumbnailPath;
  final Value<String> yearMonth;
  final Value<int> orientation;
  final Value<bool> isValid;
  final Value<DateTime> fileModifiedAt;
  final Value<DateTime> createdAt;
  const PhotosCompanion({
    this.id = const Value.absent(),
    this.path = const Value.absent(),
    this.filename = const Value.absent(),
    this.directory = const Value.absent(),
    this.dateTaken = const Value.absent(),
    this.fileSize = const Value.absent(),
    this.format = const Value.absent(),
    this.width = const Value.absent(),
    this.height = const Value.absent(),
    this.thumbnailPath = const Value.absent(),
    this.yearMonth = const Value.absent(),
    this.orientation = const Value.absent(),
    this.isValid = const Value.absent(),
    this.fileModifiedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  PhotosCompanion.insert({
    this.id = const Value.absent(),
    required String path,
    required String filename,
    required String directory,
    required DateTime dateTaken,
    required int fileSize,
    required String format,
    this.width = const Value.absent(),
    this.height = const Value.absent(),
    this.thumbnailPath = const Value.absent(),
    required String yearMonth,
    this.orientation = const Value.absent(),
    this.isValid = const Value.absent(),
    required DateTime fileModifiedAt,
    this.createdAt = const Value.absent(),
  }) : path = Value(path),
       filename = Value(filename),
       directory = Value(directory),
       dateTaken = Value(dateTaken),
       fileSize = Value(fileSize),
       format = Value(format),
       yearMonth = Value(yearMonth),
       fileModifiedAt = Value(fileModifiedAt);
  static Insertable<Photo> custom({
    Expression<int>? id,
    Expression<String>? path,
    Expression<String>? filename,
    Expression<String>? directory,
    Expression<DateTime>? dateTaken,
    Expression<int>? fileSize,
    Expression<String>? format,
    Expression<int>? width,
    Expression<int>? height,
    Expression<String>? thumbnailPath,
    Expression<String>? yearMonth,
    Expression<int>? orientation,
    Expression<bool>? isValid,
    Expression<DateTime>? fileModifiedAt,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (path != null) 'path': path,
      if (filename != null) 'filename': filename,
      if (directory != null) 'directory': directory,
      if (dateTaken != null) 'date_taken': dateTaken,
      if (fileSize != null) 'file_size': fileSize,
      if (format != null) 'format': format,
      if (width != null) 'width': width,
      if (height != null) 'height': height,
      if (thumbnailPath != null) 'thumbnail_path': thumbnailPath,
      if (yearMonth != null) 'year_month': yearMonth,
      if (orientation != null) 'orientation': orientation,
      if (isValid != null) 'is_valid': isValid,
      if (fileModifiedAt != null) 'file_modified_at': fileModifiedAt,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  PhotosCompanion copyWith({
    Value<int>? id,
    Value<String>? path,
    Value<String>? filename,
    Value<String>? directory,
    Value<DateTime>? dateTaken,
    Value<int>? fileSize,
    Value<String>? format,
    Value<int?>? width,
    Value<int?>? height,
    Value<String?>? thumbnailPath,
    Value<String>? yearMonth,
    Value<int>? orientation,
    Value<bool>? isValid,
    Value<DateTime>? fileModifiedAt,
    Value<DateTime>? createdAt,
  }) {
    return PhotosCompanion(
      id: id ?? this.id,
      path: path ?? this.path,
      filename: filename ?? this.filename,
      directory: directory ?? this.directory,
      dateTaken: dateTaken ?? this.dateTaken,
      fileSize: fileSize ?? this.fileSize,
      format: format ?? this.format,
      width: width ?? this.width,
      height: height ?? this.height,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      yearMonth: yearMonth ?? this.yearMonth,
      orientation: orientation ?? this.orientation,
      isValid: isValid ?? this.isValid,
      fileModifiedAt: fileModifiedAt ?? this.fileModifiedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (path.present) {
      map['path'] = Variable<String>(path.value);
    }
    if (filename.present) {
      map['filename'] = Variable<String>(filename.value);
    }
    if (directory.present) {
      map['directory'] = Variable<String>(directory.value);
    }
    if (dateTaken.present) {
      map['date_taken'] = Variable<DateTime>(dateTaken.value);
    }
    if (fileSize.present) {
      map['file_size'] = Variable<int>(fileSize.value);
    }
    if (format.present) {
      map['format'] = Variable<String>(format.value);
    }
    if (width.present) {
      map['width'] = Variable<int>(width.value);
    }
    if (height.present) {
      map['height'] = Variable<int>(height.value);
    }
    if (thumbnailPath.present) {
      map['thumbnail_path'] = Variable<String>(thumbnailPath.value);
    }
    if (yearMonth.present) {
      map['year_month'] = Variable<String>(yearMonth.value);
    }
    if (orientation.present) {
      map['orientation'] = Variable<int>(orientation.value);
    }
    if (isValid.present) {
      map['is_valid'] = Variable<bool>(isValid.value);
    }
    if (fileModifiedAt.present) {
      map['file_modified_at'] = Variable<DateTime>(fileModifiedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PhotosCompanion(')
          ..write('id: $id, ')
          ..write('path: $path, ')
          ..write('filename: $filename, ')
          ..write('directory: $directory, ')
          ..write('dateTaken: $dateTaken, ')
          ..write('fileSize: $fileSize, ')
          ..write('format: $format, ')
          ..write('width: $width, ')
          ..write('height: $height, ')
          ..write('thumbnailPath: $thumbnailPath, ')
          ..write('yearMonth: $yearMonth, ')
          ..write('orientation: $orientation, ')
          ..write('isValid: $isValid, ')
          ..write('fileModifiedAt: $fileModifiedAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $ScanSettingsTable extends ScanSettings
    with TableInfo<$ScanSettingsTable, ScanSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ScanSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _folderPathMeta = const VerificationMeta(
    'folderPath',
  );
  @override
  late final GeneratedColumn<String> folderPath = GeneratedColumn<String>(
    'folder_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [id, folderPath, isActive];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'scan_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<ScanSetting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('folder_path')) {
      context.handle(
        _folderPathMeta,
        folderPath.isAcceptableOrUnknown(data['folder_path']!, _folderPathMeta),
      );
    } else if (isInserting) {
      context.missing(_folderPathMeta);
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ScanSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ScanSetting(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      folderPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}folder_path'],
      )!,
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
    );
  }

  @override
  $ScanSettingsTable createAlias(String alias) {
    return $ScanSettingsTable(attachedDatabase, alias);
  }
}

class ScanSetting extends DataClass implements Insertable<ScanSetting> {
  final int id;
  final String folderPath;
  final bool isActive;
  const ScanSetting({
    required this.id,
    required this.folderPath,
    required this.isActive,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['folder_path'] = Variable<String>(folderPath);
    map['is_active'] = Variable<bool>(isActive);
    return map;
  }

  ScanSettingsCompanion toCompanion(bool nullToAbsent) {
    return ScanSettingsCompanion(
      id: Value(id),
      folderPath: Value(folderPath),
      isActive: Value(isActive),
    );
  }

  factory ScanSetting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ScanSetting(
      id: serializer.fromJson<int>(json['id']),
      folderPath: serializer.fromJson<String>(json['folderPath']),
      isActive: serializer.fromJson<bool>(json['isActive']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'folderPath': serializer.toJson<String>(folderPath),
      'isActive': serializer.toJson<bool>(isActive),
    };
  }

  ScanSetting copyWith({int? id, String? folderPath, bool? isActive}) =>
      ScanSetting(
        id: id ?? this.id,
        folderPath: folderPath ?? this.folderPath,
        isActive: isActive ?? this.isActive,
      );
  ScanSetting copyWithCompanion(ScanSettingsCompanion data) {
    return ScanSetting(
      id: data.id.present ? data.id.value : this.id,
      folderPath: data.folderPath.present
          ? data.folderPath.value
          : this.folderPath,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ScanSetting(')
          ..write('id: $id, ')
          ..write('folderPath: $folderPath, ')
          ..write('isActive: $isActive')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, folderPath, isActive);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ScanSetting &&
          other.id == this.id &&
          other.folderPath == this.folderPath &&
          other.isActive == this.isActive);
}

class ScanSettingsCompanion extends UpdateCompanion<ScanSetting> {
  final Value<int> id;
  final Value<String> folderPath;
  final Value<bool> isActive;
  const ScanSettingsCompanion({
    this.id = const Value.absent(),
    this.folderPath = const Value.absent(),
    this.isActive = const Value.absent(),
  });
  ScanSettingsCompanion.insert({
    this.id = const Value.absent(),
    required String folderPath,
    this.isActive = const Value.absent(),
  }) : folderPath = Value(folderPath);
  static Insertable<ScanSetting> custom({
    Expression<int>? id,
    Expression<String>? folderPath,
    Expression<bool>? isActive,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (folderPath != null) 'folder_path': folderPath,
      if (isActive != null) 'is_active': isActive,
    });
  }

  ScanSettingsCompanion copyWith({
    Value<int>? id,
    Value<String>? folderPath,
    Value<bool>? isActive,
  }) {
    return ScanSettingsCompanion(
      id: id ?? this.id,
      folderPath: folderPath ?? this.folderPath,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (folderPath.present) {
      map['folder_path'] = Variable<String>(folderPath.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ScanSettingsCompanion(')
          ..write('id: $id, ')
          ..write('folderPath: $folderPath, ')
          ..write('isActive: $isActive')
          ..write(')'))
        .toString();
  }
}

class $AppSettingsTable extends AppSettings
    with TableInfo<$AppSettingsTable, AppSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppSetting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  AppSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSetting(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $AppSettingsTable createAlias(String alias) {
    return $AppSettingsTable(attachedDatabase, alias);
  }
}

class AppSetting extends DataClass implements Insertable<AppSetting> {
  final String key;
  final String value;
  const AppSetting({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  AppSettingsCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsCompanion(key: Value(key), value: Value(value));
  }

  factory AppSetting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSetting(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  AppSetting copyWith({String? key, String? value}) =>
      AppSetting(key: key ?? this.key, value: value ?? this.value);
  AppSetting copyWithCompanion(AppSettingsCompanion data) {
    return AppSetting(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSetting(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSetting &&
          other.key == this.key &&
          other.value == this.value);
}

class AppSettingsCompanion extends UpdateCompanion<AppSetting> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const AppSettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppSettingsCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<AppSetting> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppSettingsCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return AppSettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $PhotosTable photos = $PhotosTable(this);
  late final $ScanSettingsTable scanSettings = $ScanSettingsTable(this);
  late final $AppSettingsTable appSettings = $AppSettingsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    photos,
    scanSettings,
    appSettings,
  ];
}

typedef $$PhotosTableCreateCompanionBuilder =
    PhotosCompanion Function({
      Value<int> id,
      required String path,
      required String filename,
      required String directory,
      required DateTime dateTaken,
      required int fileSize,
      required String format,
      Value<int?> width,
      Value<int?> height,
      Value<String?> thumbnailPath,
      required String yearMonth,
      Value<int> orientation,
      Value<bool> isValid,
      required DateTime fileModifiedAt,
      Value<DateTime> createdAt,
    });
typedef $$PhotosTableUpdateCompanionBuilder =
    PhotosCompanion Function({
      Value<int> id,
      Value<String> path,
      Value<String> filename,
      Value<String> directory,
      Value<DateTime> dateTaken,
      Value<int> fileSize,
      Value<String> format,
      Value<int?> width,
      Value<int?> height,
      Value<String?> thumbnailPath,
      Value<String> yearMonth,
      Value<int> orientation,
      Value<bool> isValid,
      Value<DateTime> fileModifiedAt,
      Value<DateTime> createdAt,
    });

class $$PhotosTableFilterComposer
    extends Composer<_$AppDatabase, $PhotosTable> {
  $$PhotosTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get filename => $composableBuilder(
    column: $table.filename,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get directory => $composableBuilder(
    column: $table.directory,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get dateTaken => $composableBuilder(
    column: $table.dateTaken,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fileSize => $composableBuilder(
    column: $table.fileSize,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get format => $composableBuilder(
    column: $table.format,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get width => $composableBuilder(
    column: $table.width,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get height => $composableBuilder(
    column: $table.height,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get thumbnailPath => $composableBuilder(
    column: $table.thumbnailPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get yearMonth => $composableBuilder(
    column: $table.yearMonth,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get orientation => $composableBuilder(
    column: $table.orientation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isValid => $composableBuilder(
    column: $table.isValid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fileModifiedAt => $composableBuilder(
    column: $table.fileModifiedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PhotosTableOrderingComposer
    extends Composer<_$AppDatabase, $PhotosTable> {
  $$PhotosTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get filename => $composableBuilder(
    column: $table.filename,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get directory => $composableBuilder(
    column: $table.directory,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dateTaken => $composableBuilder(
    column: $table.dateTaken,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fileSize => $composableBuilder(
    column: $table.fileSize,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get format => $composableBuilder(
    column: $table.format,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get width => $composableBuilder(
    column: $table.width,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get height => $composableBuilder(
    column: $table.height,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get thumbnailPath => $composableBuilder(
    column: $table.thumbnailPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get yearMonth => $composableBuilder(
    column: $table.yearMonth,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get orientation => $composableBuilder(
    column: $table.orientation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isValid => $composableBuilder(
    column: $table.isValid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fileModifiedAt => $composableBuilder(
    column: $table.fileModifiedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PhotosTableAnnotationComposer
    extends Composer<_$AppDatabase, $PhotosTable> {
  $$PhotosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get path =>
      $composableBuilder(column: $table.path, builder: (column) => column);

  GeneratedColumn<String> get filename =>
      $composableBuilder(column: $table.filename, builder: (column) => column);

  GeneratedColumn<String> get directory =>
      $composableBuilder(column: $table.directory, builder: (column) => column);

  GeneratedColumn<DateTime> get dateTaken =>
      $composableBuilder(column: $table.dateTaken, builder: (column) => column);

  GeneratedColumn<int> get fileSize =>
      $composableBuilder(column: $table.fileSize, builder: (column) => column);

  GeneratedColumn<String> get format =>
      $composableBuilder(column: $table.format, builder: (column) => column);

  GeneratedColumn<int> get width =>
      $composableBuilder(column: $table.width, builder: (column) => column);

  GeneratedColumn<int> get height =>
      $composableBuilder(column: $table.height, builder: (column) => column);

  GeneratedColumn<String> get thumbnailPath => $composableBuilder(
    column: $table.thumbnailPath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get yearMonth =>
      $composableBuilder(column: $table.yearMonth, builder: (column) => column);

  GeneratedColumn<int> get orientation => $composableBuilder(
    column: $table.orientation,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isValid =>
      $composableBuilder(column: $table.isValid, builder: (column) => column);

  GeneratedColumn<DateTime> get fileModifiedAt => $composableBuilder(
    column: $table.fileModifiedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$PhotosTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PhotosTable,
          Photo,
          $$PhotosTableFilterComposer,
          $$PhotosTableOrderingComposer,
          $$PhotosTableAnnotationComposer,
          $$PhotosTableCreateCompanionBuilder,
          $$PhotosTableUpdateCompanionBuilder,
          (Photo, BaseReferences<_$AppDatabase, $PhotosTable, Photo>),
          Photo,
          PrefetchHooks Function()
        > {
  $$PhotosTableTableManager(_$AppDatabase db, $PhotosTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PhotosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PhotosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PhotosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> path = const Value.absent(),
                Value<String> filename = const Value.absent(),
                Value<String> directory = const Value.absent(),
                Value<DateTime> dateTaken = const Value.absent(),
                Value<int> fileSize = const Value.absent(),
                Value<String> format = const Value.absent(),
                Value<int?> width = const Value.absent(),
                Value<int?> height = const Value.absent(),
                Value<String?> thumbnailPath = const Value.absent(),
                Value<String> yearMonth = const Value.absent(),
                Value<int> orientation = const Value.absent(),
                Value<bool> isValid = const Value.absent(),
                Value<DateTime> fileModifiedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => PhotosCompanion(
                id: id,
                path: path,
                filename: filename,
                directory: directory,
                dateTaken: dateTaken,
                fileSize: fileSize,
                format: format,
                width: width,
                height: height,
                thumbnailPath: thumbnailPath,
                yearMonth: yearMonth,
                orientation: orientation,
                isValid: isValid,
                fileModifiedAt: fileModifiedAt,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String path,
                required String filename,
                required String directory,
                required DateTime dateTaken,
                required int fileSize,
                required String format,
                Value<int?> width = const Value.absent(),
                Value<int?> height = const Value.absent(),
                Value<String?> thumbnailPath = const Value.absent(),
                required String yearMonth,
                Value<int> orientation = const Value.absent(),
                Value<bool> isValid = const Value.absent(),
                required DateTime fileModifiedAt,
                Value<DateTime> createdAt = const Value.absent(),
              }) => PhotosCompanion.insert(
                id: id,
                path: path,
                filename: filename,
                directory: directory,
                dateTaken: dateTaken,
                fileSize: fileSize,
                format: format,
                width: width,
                height: height,
                thumbnailPath: thumbnailPath,
                yearMonth: yearMonth,
                orientation: orientation,
                isValid: isValid,
                fileModifiedAt: fileModifiedAt,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PhotosTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PhotosTable,
      Photo,
      $$PhotosTableFilterComposer,
      $$PhotosTableOrderingComposer,
      $$PhotosTableAnnotationComposer,
      $$PhotosTableCreateCompanionBuilder,
      $$PhotosTableUpdateCompanionBuilder,
      (Photo, BaseReferences<_$AppDatabase, $PhotosTable, Photo>),
      Photo,
      PrefetchHooks Function()
    >;
typedef $$ScanSettingsTableCreateCompanionBuilder =
    ScanSettingsCompanion Function({
      Value<int> id,
      required String folderPath,
      Value<bool> isActive,
    });
typedef $$ScanSettingsTableUpdateCompanionBuilder =
    ScanSettingsCompanion Function({
      Value<int> id,
      Value<String> folderPath,
      Value<bool> isActive,
    });

class $$ScanSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $ScanSettingsTable> {
  $$ScanSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get folderPath => $composableBuilder(
    column: $table.folderPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ScanSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $ScanSettingsTable> {
  $$ScanSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get folderPath => $composableBuilder(
    column: $table.folderPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ScanSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ScanSettingsTable> {
  $$ScanSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get folderPath => $composableBuilder(
    column: $table.folderPath,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);
}

class $$ScanSettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ScanSettingsTable,
          ScanSetting,
          $$ScanSettingsTableFilterComposer,
          $$ScanSettingsTableOrderingComposer,
          $$ScanSettingsTableAnnotationComposer,
          $$ScanSettingsTableCreateCompanionBuilder,
          $$ScanSettingsTableUpdateCompanionBuilder,
          (
            ScanSetting,
            BaseReferences<_$AppDatabase, $ScanSettingsTable, ScanSetting>,
          ),
          ScanSetting,
          PrefetchHooks Function()
        > {
  $$ScanSettingsTableTableManager(_$AppDatabase db, $ScanSettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ScanSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ScanSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ScanSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> folderPath = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
              }) => ScanSettingsCompanion(
                id: id,
                folderPath: folderPath,
                isActive: isActive,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String folderPath,
                Value<bool> isActive = const Value.absent(),
              }) => ScanSettingsCompanion.insert(
                id: id,
                folderPath: folderPath,
                isActive: isActive,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ScanSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ScanSettingsTable,
      ScanSetting,
      $$ScanSettingsTableFilterComposer,
      $$ScanSettingsTableOrderingComposer,
      $$ScanSettingsTableAnnotationComposer,
      $$ScanSettingsTableCreateCompanionBuilder,
      $$ScanSettingsTableUpdateCompanionBuilder,
      (
        ScanSetting,
        BaseReferences<_$AppDatabase, $ScanSettingsTable, ScanSetting>,
      ),
      ScanSetting,
      PrefetchHooks Function()
    >;
typedef $$AppSettingsTableCreateCompanionBuilder =
    AppSettingsCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$AppSettingsTableUpdateCompanionBuilder =
    AppSettingsCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$AppSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$AppSettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AppSettingsTable,
          AppSetting,
          $$AppSettingsTableFilterComposer,
          $$AppSettingsTableOrderingComposer,
          $$AppSettingsTableAnnotationComposer,
          $$AppSettingsTableCreateCompanionBuilder,
          $$AppSettingsTableUpdateCompanionBuilder,
          (
            AppSetting,
            BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>,
          ),
          AppSetting,
          PrefetchHooks Function()
        > {
  $$AppSettingsTableTableManager(_$AppDatabase db, $AppSettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AppSettingsCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => AppSettingsCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AppSettingsTable,
      AppSetting,
      $$AppSettingsTableFilterComposer,
      $$AppSettingsTableOrderingComposer,
      $$AppSettingsTableAnnotationComposer,
      $$AppSettingsTableCreateCompanionBuilder,
      $$AppSettingsTableUpdateCompanionBuilder,
      (
        AppSetting,
        BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>,
      ),
      AppSetting,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$PhotosTableTableManager get photos =>
      $$PhotosTableTableManager(_db, _db.photos);
  $$ScanSettingsTableTableManager get scanSettings =>
      $$ScanSettingsTableTableManager(_db, _db.scanSettings);
  $$AppSettingsTableTableManager get appSettings =>
      $$AppSettingsTableTableManager(_db, _db.appSettings);
}
