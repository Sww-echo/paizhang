// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $CachedUsersTable extends CachedUsers
    with TableInfo<$CachedUsersTable, CachedUser> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedUsersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _actorIdMeta = const VerificationMeta(
    'actorId',
  );
  @override
  late final GeneratedColumn<String> actorId = GeneratedColumn<String>(
    'actor_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nicknameMeta = const VerificationMeta(
    'nickname',
  );
  @override
  late final GeneratedColumn<String> nickname = GeneratedColumn<String>(
    'nickname',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _avatarKeyMeta = const VerificationMeta(
    'avatarKey',
  );
  @override
  late final GeneratedColumn<String> avatarKey = GeneratedColumn<String>(
    'avatar_key',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _avatarUrlMeta = const VerificationMeta(
    'avatarUrl',
  );
  @override
  late final GeneratedColumn<String> avatarUrl = GeneratedColumn<String>(
    'avatar_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  @override
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
    'phone',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
    'email',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    actorId,
    id,
    nickname,
    avatarKey,
    avatarUrl,
    phone,
    email,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_users';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedUser> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('actor_id')) {
      context.handle(
        _actorIdMeta,
        actorId.isAcceptableOrUnknown(data['actor_id']!, _actorIdMeta),
      );
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('nickname')) {
      context.handle(
        _nicknameMeta,
        nickname.isAcceptableOrUnknown(data['nickname']!, _nicknameMeta),
      );
    } else if (isInserting) {
      context.missing(_nicknameMeta);
    }
    if (data.containsKey('avatar_key')) {
      context.handle(
        _avatarKeyMeta,
        avatarKey.isAcceptableOrUnknown(data['avatar_key']!, _avatarKeyMeta),
      );
    }
    if (data.containsKey('avatar_url')) {
      context.handle(
        _avatarUrlMeta,
        avatarUrl.isAcceptableOrUnknown(data['avatar_url']!, _avatarUrlMeta),
      );
    }
    if (data.containsKey('phone')) {
      context.handle(
        _phoneMeta,
        phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta),
      );
    }
    if (data.containsKey('email')) {
      context.handle(
        _emailMeta,
        email.isAcceptableOrUnknown(data['email']!, _emailMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {actorId, id};
  @override
  CachedUser map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedUser(
      actorId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}actor_id'],
      )!,
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      nickname: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nickname'],
      )!,
      avatarKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}avatar_key'],
      ),
      avatarUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}avatar_url'],
      ),
      phone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phone'],
      ),
      email: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}email'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $CachedUsersTable createAlias(String alias) {
    return $CachedUsersTable(attachedDatabase, alias);
  }
}

class CachedUser extends DataClass implements Insertable<CachedUser> {
  final String actorId;
  final String id;
  final String nickname;
  final String? avatarKey;
  final String? avatarUrl;
  final String? phone;
  final String? email;
  final DateTime updatedAt;
  const CachedUser({
    required this.actorId,
    required this.id,
    required this.nickname,
    this.avatarKey,
    this.avatarUrl,
    this.phone,
    this.email,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['actor_id'] = Variable<String>(actorId);
    map['id'] = Variable<String>(id);
    map['nickname'] = Variable<String>(nickname);
    if (!nullToAbsent || avatarKey != null) {
      map['avatar_key'] = Variable<String>(avatarKey);
    }
    if (!nullToAbsent || avatarUrl != null) {
      map['avatar_url'] = Variable<String>(avatarUrl);
    }
    if (!nullToAbsent || phone != null) {
      map['phone'] = Variable<String>(phone);
    }
    if (!nullToAbsent || email != null) {
      map['email'] = Variable<String>(email);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  CachedUsersCompanion toCompanion(bool nullToAbsent) {
    return CachedUsersCompanion(
      actorId: Value(actorId),
      id: Value(id),
      nickname: Value(nickname),
      avatarKey: avatarKey == null && nullToAbsent
          ? const Value.absent()
          : Value(avatarKey),
      avatarUrl: avatarUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(avatarUrl),
      phone: phone == null && nullToAbsent
          ? const Value.absent()
          : Value(phone),
      email: email == null && nullToAbsent
          ? const Value.absent()
          : Value(email),
      updatedAt: Value(updatedAt),
    );
  }

  factory CachedUser.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedUser(
      actorId: serializer.fromJson<String>(json['actorId']),
      id: serializer.fromJson<String>(json['id']),
      nickname: serializer.fromJson<String>(json['nickname']),
      avatarKey: serializer.fromJson<String?>(json['avatarKey']),
      avatarUrl: serializer.fromJson<String?>(json['avatarUrl']),
      phone: serializer.fromJson<String?>(json['phone']),
      email: serializer.fromJson<String?>(json['email']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'actorId': serializer.toJson<String>(actorId),
      'id': serializer.toJson<String>(id),
      'nickname': serializer.toJson<String>(nickname),
      'avatarKey': serializer.toJson<String?>(avatarKey),
      'avatarUrl': serializer.toJson<String?>(avatarUrl),
      'phone': serializer.toJson<String?>(phone),
      'email': serializer.toJson<String?>(email),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  CachedUser copyWith({
    String? actorId,
    String? id,
    String? nickname,
    Value<String?> avatarKey = const Value.absent(),
    Value<String?> avatarUrl = const Value.absent(),
    Value<String?> phone = const Value.absent(),
    Value<String?> email = const Value.absent(),
    DateTime? updatedAt,
  }) => CachedUser(
    actorId: actorId ?? this.actorId,
    id: id ?? this.id,
    nickname: nickname ?? this.nickname,
    avatarKey: avatarKey.present ? avatarKey.value : this.avatarKey,
    avatarUrl: avatarUrl.present ? avatarUrl.value : this.avatarUrl,
    phone: phone.present ? phone.value : this.phone,
    email: email.present ? email.value : this.email,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  CachedUser copyWithCompanion(CachedUsersCompanion data) {
    return CachedUser(
      actorId: data.actorId.present ? data.actorId.value : this.actorId,
      id: data.id.present ? data.id.value : this.id,
      nickname: data.nickname.present ? data.nickname.value : this.nickname,
      avatarKey: data.avatarKey.present ? data.avatarKey.value : this.avatarKey,
      avatarUrl: data.avatarUrl.present ? data.avatarUrl.value : this.avatarUrl,
      phone: data.phone.present ? data.phone.value : this.phone,
      email: data.email.present ? data.email.value : this.email,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedUser(')
          ..write('actorId: $actorId, ')
          ..write('id: $id, ')
          ..write('nickname: $nickname, ')
          ..write('avatarKey: $avatarKey, ')
          ..write('avatarUrl: $avatarUrl, ')
          ..write('phone: $phone, ')
          ..write('email: $email, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    actorId,
    id,
    nickname,
    avatarKey,
    avatarUrl,
    phone,
    email,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedUser &&
          other.actorId == this.actorId &&
          other.id == this.id &&
          other.nickname == this.nickname &&
          other.avatarKey == this.avatarKey &&
          other.avatarUrl == this.avatarUrl &&
          other.phone == this.phone &&
          other.email == this.email &&
          other.updatedAt == this.updatedAt);
}

class CachedUsersCompanion extends UpdateCompanion<CachedUser> {
  final Value<String> actorId;
  final Value<String> id;
  final Value<String> nickname;
  final Value<String?> avatarKey;
  final Value<String?> avatarUrl;
  final Value<String?> phone;
  final Value<String?> email;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const CachedUsersCompanion({
    this.actorId = const Value.absent(),
    this.id = const Value.absent(),
    this.nickname = const Value.absent(),
    this.avatarKey = const Value.absent(),
    this.avatarUrl = const Value.absent(),
    this.phone = const Value.absent(),
    this.email = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedUsersCompanion.insert({
    this.actorId = const Value.absent(),
    required String id,
    required String nickname,
    this.avatarKey = const Value.absent(),
    this.avatarUrl = const Value.absent(),
    this.phone = const Value.absent(),
    this.email = const Value.absent(),
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       nickname = Value(nickname),
       updatedAt = Value(updatedAt);
  static Insertable<CachedUser> custom({
    Expression<String>? actorId,
    Expression<String>? id,
    Expression<String>? nickname,
    Expression<String>? avatarKey,
    Expression<String>? avatarUrl,
    Expression<String>? phone,
    Expression<String>? email,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (actorId != null) 'actor_id': actorId,
      if (id != null) 'id': id,
      if (nickname != null) 'nickname': nickname,
      if (avatarKey != null) 'avatar_key': avatarKey,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      if (phone != null) 'phone': phone,
      if (email != null) 'email': email,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedUsersCompanion copyWith({
    Value<String>? actorId,
    Value<String>? id,
    Value<String>? nickname,
    Value<String?>? avatarKey,
    Value<String?>? avatarUrl,
    Value<String?>? phone,
    Value<String?>? email,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return CachedUsersCompanion(
      actorId: actorId ?? this.actorId,
      id: id ?? this.id,
      nickname: nickname ?? this.nickname,
      avatarKey: avatarKey ?? this.avatarKey,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (actorId.present) {
      map['actor_id'] = Variable<String>(actorId.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (nickname.present) {
      map['nickname'] = Variable<String>(nickname.value);
    }
    if (avatarKey.present) {
      map['avatar_key'] = Variable<String>(avatarKey.value);
    }
    if (avatarUrl.present) {
      map['avatar_url'] = Variable<String>(avatarUrl.value);
    }
    if (phone.present) {
      map['phone'] = Variable<String>(phone.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedUsersCompanion(')
          ..write('actorId: $actorId, ')
          ..write('id: $id, ')
          ..write('nickname: $nickname, ')
          ..write('avatarKey: $avatarKey, ')
          ..write('avatarUrl: $avatarUrl, ')
          ..write('phone: $phone, ')
          ..write('email: $email, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedRoomsTable extends CachedRooms
    with TableInfo<$CachedRoomsTable, CachedRoom> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedRoomsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _actorIdMeta = const VerificationMeta(
    'actorId',
  );
  @override
  late final GeneratedColumn<String> actorId = GeneratedColumn<String>(
    'actor_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ownerIdMeta = const VerificationMeta(
    'ownerId',
  );
  @override
  late final GeneratedColumn<String> ownerId = GeneratedColumn<String>(
    'owner_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _gameTypeMeta = const VerificationMeta(
    'gameType',
  );
  @override
  late final GeneratedColumn<String> gameType = GeneratedColumn<String>(
    'game_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scoringModeMeta = const VerificationMeta(
    'scoringMode',
  );
  @override
  late final GeneratedColumn<String> scoringMode = GeneratedColumn<String>(
    'scoring_mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _inputPermissionMeta = const VerificationMeta(
    'inputPermission',
  );
  @override
  late final GeneratedColumn<String> inputPermission = GeneratedColumn<String>(
    'input_permission',
    aliasedName,
    false,
    type: DriftSqlType.string,
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
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _closeVoteJsonMeta = const VerificationMeta(
    'closeVoteJson',
  );
  @override
  late final GeneratedColumn<String> closeVoteJson = GeneratedColumn<String>(
    'close_vote_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _snapshotAtMeta = const VerificationMeta(
    'snapshotAt',
  );
  @override
  late final GeneratedColumn<DateTime> snapshotAt = GeneratedColumn<DateTime>(
    'snapshot_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isAccessibleMeta = const VerificationMeta(
    'isAccessible',
  );
  @override
  late final GeneratedColumn<bool> isAccessible = GeneratedColumn<bool>(
    'is_accessible',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_accessible" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    actorId,
    id,
    name,
    ownerId,
    gameType,
    scoringMode,
    status,
    inputPermission,
    createdAt,
    updatedAt,
    version,
    closeVoteJson,
    snapshotAt,
    isAccessible,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_rooms';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedRoom> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('actor_id')) {
      context.handle(
        _actorIdMeta,
        actorId.isAcceptableOrUnknown(data['actor_id']!, _actorIdMeta),
      );
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('owner_id')) {
      context.handle(
        _ownerIdMeta,
        ownerId.isAcceptableOrUnknown(data['owner_id']!, _ownerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_ownerIdMeta);
    }
    if (data.containsKey('game_type')) {
      context.handle(
        _gameTypeMeta,
        gameType.isAcceptableOrUnknown(data['game_type']!, _gameTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_gameTypeMeta);
    }
    if (data.containsKey('scoring_mode')) {
      context.handle(
        _scoringModeMeta,
        scoringMode.isAcceptableOrUnknown(
          data['scoring_mode']!,
          _scoringModeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_scoringModeMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('input_permission')) {
      context.handle(
        _inputPermissionMeta,
        inputPermission.isAcceptableOrUnknown(
          data['input_permission']!,
          _inputPermissionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_inputPermissionMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    }
    if (data.containsKey('close_vote_json')) {
      context.handle(
        _closeVoteJsonMeta,
        closeVoteJson.isAcceptableOrUnknown(
          data['close_vote_json']!,
          _closeVoteJsonMeta,
        ),
      );
    }
    if (data.containsKey('snapshot_at')) {
      context.handle(
        _snapshotAtMeta,
        snapshotAt.isAcceptableOrUnknown(data['snapshot_at']!, _snapshotAtMeta),
      );
    }
    if (data.containsKey('is_accessible')) {
      context.handle(
        _isAccessibleMeta,
        isAccessible.isAcceptableOrUnknown(
          data['is_accessible']!,
          _isAccessibleMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {actorId, id};
  @override
  CachedRoom map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedRoom(
      actorId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}actor_id'],
      )!,
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      ownerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner_id'],
      )!,
      gameType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}game_type'],
      )!,
      scoringMode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}scoring_mode'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      inputPermission: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}input_permission'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      closeVoteJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}close_vote_json'],
      ),
      snapshotAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}snapshot_at'],
      ),
      isAccessible: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_accessible'],
      )!,
    );
  }

  @override
  $CachedRoomsTable createAlias(String alias) {
    return $CachedRoomsTable(attachedDatabase, alias);
  }
}

class CachedRoom extends DataClass implements Insertable<CachedRoom> {
  final String actorId;
  final String id;
  final String name;
  final String ownerId;
  final String gameType;
  final String scoringMode;
  final String status;
  final String inputPermission;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int version;
  final String? closeVoteJson;
  final DateTime? snapshotAt;
  final bool isAccessible;
  const CachedRoom({
    required this.actorId,
    required this.id,
    required this.name,
    required this.ownerId,
    required this.gameType,
    required this.scoringMode,
    required this.status,
    required this.inputPermission,
    required this.createdAt,
    required this.updatedAt,
    required this.version,
    this.closeVoteJson,
    this.snapshotAt,
    required this.isAccessible,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['actor_id'] = Variable<String>(actorId);
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['owner_id'] = Variable<String>(ownerId);
    map['game_type'] = Variable<String>(gameType);
    map['scoring_mode'] = Variable<String>(scoringMode);
    map['status'] = Variable<String>(status);
    map['input_permission'] = Variable<String>(inputPermission);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['version'] = Variable<int>(version);
    if (!nullToAbsent || closeVoteJson != null) {
      map['close_vote_json'] = Variable<String>(closeVoteJson);
    }
    if (!nullToAbsent || snapshotAt != null) {
      map['snapshot_at'] = Variable<DateTime>(snapshotAt);
    }
    map['is_accessible'] = Variable<bool>(isAccessible);
    return map;
  }

  CachedRoomsCompanion toCompanion(bool nullToAbsent) {
    return CachedRoomsCompanion(
      actorId: Value(actorId),
      id: Value(id),
      name: Value(name),
      ownerId: Value(ownerId),
      gameType: Value(gameType),
      scoringMode: Value(scoringMode),
      status: Value(status),
      inputPermission: Value(inputPermission),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      version: Value(version),
      closeVoteJson: closeVoteJson == null && nullToAbsent
          ? const Value.absent()
          : Value(closeVoteJson),
      snapshotAt: snapshotAt == null && nullToAbsent
          ? const Value.absent()
          : Value(snapshotAt),
      isAccessible: Value(isAccessible),
    );
  }

  factory CachedRoom.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedRoom(
      actorId: serializer.fromJson<String>(json['actorId']),
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      ownerId: serializer.fromJson<String>(json['ownerId']),
      gameType: serializer.fromJson<String>(json['gameType']),
      scoringMode: serializer.fromJson<String>(json['scoringMode']),
      status: serializer.fromJson<String>(json['status']),
      inputPermission: serializer.fromJson<String>(json['inputPermission']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      version: serializer.fromJson<int>(json['version']),
      closeVoteJson: serializer.fromJson<String?>(json['closeVoteJson']),
      snapshotAt: serializer.fromJson<DateTime?>(json['snapshotAt']),
      isAccessible: serializer.fromJson<bool>(json['isAccessible']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'actorId': serializer.toJson<String>(actorId),
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'ownerId': serializer.toJson<String>(ownerId),
      'gameType': serializer.toJson<String>(gameType),
      'scoringMode': serializer.toJson<String>(scoringMode),
      'status': serializer.toJson<String>(status),
      'inputPermission': serializer.toJson<String>(inputPermission),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'version': serializer.toJson<int>(version),
      'closeVoteJson': serializer.toJson<String?>(closeVoteJson),
      'snapshotAt': serializer.toJson<DateTime?>(snapshotAt),
      'isAccessible': serializer.toJson<bool>(isAccessible),
    };
  }

  CachedRoom copyWith({
    String? actorId,
    String? id,
    String? name,
    String? ownerId,
    String? gameType,
    String? scoringMode,
    String? status,
    String? inputPermission,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? version,
    Value<String?> closeVoteJson = const Value.absent(),
    Value<DateTime?> snapshotAt = const Value.absent(),
    bool? isAccessible,
  }) => CachedRoom(
    actorId: actorId ?? this.actorId,
    id: id ?? this.id,
    name: name ?? this.name,
    ownerId: ownerId ?? this.ownerId,
    gameType: gameType ?? this.gameType,
    scoringMode: scoringMode ?? this.scoringMode,
    status: status ?? this.status,
    inputPermission: inputPermission ?? this.inputPermission,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    version: version ?? this.version,
    closeVoteJson: closeVoteJson.present
        ? closeVoteJson.value
        : this.closeVoteJson,
    snapshotAt: snapshotAt.present ? snapshotAt.value : this.snapshotAt,
    isAccessible: isAccessible ?? this.isAccessible,
  );
  CachedRoom copyWithCompanion(CachedRoomsCompanion data) {
    return CachedRoom(
      actorId: data.actorId.present ? data.actorId.value : this.actorId,
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      ownerId: data.ownerId.present ? data.ownerId.value : this.ownerId,
      gameType: data.gameType.present ? data.gameType.value : this.gameType,
      scoringMode: data.scoringMode.present
          ? data.scoringMode.value
          : this.scoringMode,
      status: data.status.present ? data.status.value : this.status,
      inputPermission: data.inputPermission.present
          ? data.inputPermission.value
          : this.inputPermission,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      version: data.version.present ? data.version.value : this.version,
      closeVoteJson: data.closeVoteJson.present
          ? data.closeVoteJson.value
          : this.closeVoteJson,
      snapshotAt: data.snapshotAt.present
          ? data.snapshotAt.value
          : this.snapshotAt,
      isAccessible: data.isAccessible.present
          ? data.isAccessible.value
          : this.isAccessible,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedRoom(')
          ..write('actorId: $actorId, ')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('ownerId: $ownerId, ')
          ..write('gameType: $gameType, ')
          ..write('scoringMode: $scoringMode, ')
          ..write('status: $status, ')
          ..write('inputPermission: $inputPermission, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('version: $version, ')
          ..write('closeVoteJson: $closeVoteJson, ')
          ..write('snapshotAt: $snapshotAt, ')
          ..write('isAccessible: $isAccessible')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    actorId,
    id,
    name,
    ownerId,
    gameType,
    scoringMode,
    status,
    inputPermission,
    createdAt,
    updatedAt,
    version,
    closeVoteJson,
    snapshotAt,
    isAccessible,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedRoom &&
          other.actorId == this.actorId &&
          other.id == this.id &&
          other.name == this.name &&
          other.ownerId == this.ownerId &&
          other.gameType == this.gameType &&
          other.scoringMode == this.scoringMode &&
          other.status == this.status &&
          other.inputPermission == this.inputPermission &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.version == this.version &&
          other.closeVoteJson == this.closeVoteJson &&
          other.snapshotAt == this.snapshotAt &&
          other.isAccessible == this.isAccessible);
}

class CachedRoomsCompanion extends UpdateCompanion<CachedRoom> {
  final Value<String> actorId;
  final Value<String> id;
  final Value<String> name;
  final Value<String> ownerId;
  final Value<String> gameType;
  final Value<String> scoringMode;
  final Value<String> status;
  final Value<String> inputPermission;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> version;
  final Value<String?> closeVoteJson;
  final Value<DateTime?> snapshotAt;
  final Value<bool> isAccessible;
  final Value<int> rowid;
  const CachedRoomsCompanion({
    this.actorId = const Value.absent(),
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.ownerId = const Value.absent(),
    this.gameType = const Value.absent(),
    this.scoringMode = const Value.absent(),
    this.status = const Value.absent(),
    this.inputPermission = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.version = const Value.absent(),
    this.closeVoteJson = const Value.absent(),
    this.snapshotAt = const Value.absent(),
    this.isAccessible = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedRoomsCompanion.insert({
    this.actorId = const Value.absent(),
    required String id,
    required String name,
    required String ownerId,
    required String gameType,
    required String scoringMode,
    required String status,
    required String inputPermission,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.version = const Value.absent(),
    this.closeVoteJson = const Value.absent(),
    this.snapshotAt = const Value.absent(),
    this.isAccessible = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       ownerId = Value(ownerId),
       gameType = Value(gameType),
       scoringMode = Value(scoringMode),
       status = Value(status),
       inputPermission = Value(inputPermission),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<CachedRoom> custom({
    Expression<String>? actorId,
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? ownerId,
    Expression<String>? gameType,
    Expression<String>? scoringMode,
    Expression<String>? status,
    Expression<String>? inputPermission,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? version,
    Expression<String>? closeVoteJson,
    Expression<DateTime>? snapshotAt,
    Expression<bool>? isAccessible,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (actorId != null) 'actor_id': actorId,
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (ownerId != null) 'owner_id': ownerId,
      if (gameType != null) 'game_type': gameType,
      if (scoringMode != null) 'scoring_mode': scoringMode,
      if (status != null) 'status': status,
      if (inputPermission != null) 'input_permission': inputPermission,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (version != null) 'version': version,
      if (closeVoteJson != null) 'close_vote_json': closeVoteJson,
      if (snapshotAt != null) 'snapshot_at': snapshotAt,
      if (isAccessible != null) 'is_accessible': isAccessible,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedRoomsCompanion copyWith({
    Value<String>? actorId,
    Value<String>? id,
    Value<String>? name,
    Value<String>? ownerId,
    Value<String>? gameType,
    Value<String>? scoringMode,
    Value<String>? status,
    Value<String>? inputPermission,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? version,
    Value<String?>? closeVoteJson,
    Value<DateTime?>? snapshotAt,
    Value<bool>? isAccessible,
    Value<int>? rowid,
  }) {
    return CachedRoomsCompanion(
      actorId: actorId ?? this.actorId,
      id: id ?? this.id,
      name: name ?? this.name,
      ownerId: ownerId ?? this.ownerId,
      gameType: gameType ?? this.gameType,
      scoringMode: scoringMode ?? this.scoringMode,
      status: status ?? this.status,
      inputPermission: inputPermission ?? this.inputPermission,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      version: version ?? this.version,
      closeVoteJson: closeVoteJson ?? this.closeVoteJson,
      snapshotAt: snapshotAt ?? this.snapshotAt,
      isAccessible: isAccessible ?? this.isAccessible,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (actorId.present) {
      map['actor_id'] = Variable<String>(actorId.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (ownerId.present) {
      map['owner_id'] = Variable<String>(ownerId.value);
    }
    if (gameType.present) {
      map['game_type'] = Variable<String>(gameType.value);
    }
    if (scoringMode.present) {
      map['scoring_mode'] = Variable<String>(scoringMode.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (inputPermission.present) {
      map['input_permission'] = Variable<String>(inputPermission.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (closeVoteJson.present) {
      map['close_vote_json'] = Variable<String>(closeVoteJson.value);
    }
    if (snapshotAt.present) {
      map['snapshot_at'] = Variable<DateTime>(snapshotAt.value);
    }
    if (isAccessible.present) {
      map['is_accessible'] = Variable<bool>(isAccessible.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedRoomsCompanion(')
          ..write('actorId: $actorId, ')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('ownerId: $ownerId, ')
          ..write('gameType: $gameType, ')
          ..write('scoringMode: $scoringMode, ')
          ..write('status: $status, ')
          ..write('inputPermission: $inputPermission, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('version: $version, ')
          ..write('closeVoteJson: $closeVoteJson, ')
          ..write('snapshotAt: $snapshotAt, ')
          ..write('isAccessible: $isAccessible, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedRoomMembersTable extends CachedRoomMembers
    with TableInfo<$CachedRoomMembersTable, CachedRoomMember> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedRoomMembersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _actorIdMeta = const VerificationMeta(
    'actorId',
  );
  @override
  late final GeneratedColumn<String> actorId = GeneratedColumn<String>(
    'actor_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _roomIdMeta = const VerificationMeta('roomId');
  @override
  late final GeneratedColumn<String> roomId = GeneratedColumn<String>(
    'room_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
    'role',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _inputPermissionMeta = const VerificationMeta(
    'inputPermission',
  );
  @override
  late final GeneratedColumn<String> inputPermission = GeneratedColumn<String>(
    'input_permission',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _joinedAtMeta = const VerificationMeta(
    'joinedAt',
  );
  @override
  late final GeneratedColumn<DateTime> joinedAt = GeneratedColumn<DateTime>(
    'joined_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _leftAtMeta = const VerificationMeta('leftAt');
  @override
  late final GeneratedColumn<DateTime> leftAt = GeneratedColumn<DateTime>(
    'left_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    actorId,
    roomId,
    userId,
    role,
    inputPermission,
    joinedAt,
    leftAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_room_members';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedRoomMember> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('actor_id')) {
      context.handle(
        _actorIdMeta,
        actorId.isAcceptableOrUnknown(data['actor_id']!, _actorIdMeta),
      );
    }
    if (data.containsKey('room_id')) {
      context.handle(
        _roomIdMeta,
        roomId.isAcceptableOrUnknown(data['room_id']!, _roomIdMeta),
      );
    } else if (isInserting) {
      context.missing(_roomIdMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('role')) {
      context.handle(
        _roleMeta,
        role.isAcceptableOrUnknown(data['role']!, _roleMeta),
      );
    } else if (isInserting) {
      context.missing(_roleMeta);
    }
    if (data.containsKey('input_permission')) {
      context.handle(
        _inputPermissionMeta,
        inputPermission.isAcceptableOrUnknown(
          data['input_permission']!,
          _inputPermissionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_inputPermissionMeta);
    }
    if (data.containsKey('joined_at')) {
      context.handle(
        _joinedAtMeta,
        joinedAt.isAcceptableOrUnknown(data['joined_at']!, _joinedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_joinedAtMeta);
    }
    if (data.containsKey('left_at')) {
      context.handle(
        _leftAtMeta,
        leftAt.isAcceptableOrUnknown(data['left_at']!, _leftAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {actorId, roomId, userId};
  @override
  CachedRoomMember map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedRoomMember(
      actorId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}actor_id'],
      )!,
      roomId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}room_id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      role: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}role'],
      )!,
      inputPermission: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}input_permission'],
      )!,
      joinedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}joined_at'],
      )!,
      leftAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}left_at'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $CachedRoomMembersTable createAlias(String alias) {
    return $CachedRoomMembersTable(attachedDatabase, alias);
  }
}

class CachedRoomMember extends DataClass
    implements Insertable<CachedRoomMember> {
  final String actorId;
  final String roomId;
  final String userId;
  final String role;
  final String inputPermission;
  final DateTime joinedAt;
  final DateTime? leftAt;
  final DateTime updatedAt;
  const CachedRoomMember({
    required this.actorId,
    required this.roomId,
    required this.userId,
    required this.role,
    required this.inputPermission,
    required this.joinedAt,
    this.leftAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['actor_id'] = Variable<String>(actorId);
    map['room_id'] = Variable<String>(roomId);
    map['user_id'] = Variable<String>(userId);
    map['role'] = Variable<String>(role);
    map['input_permission'] = Variable<String>(inputPermission);
    map['joined_at'] = Variable<DateTime>(joinedAt);
    if (!nullToAbsent || leftAt != null) {
      map['left_at'] = Variable<DateTime>(leftAt);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  CachedRoomMembersCompanion toCompanion(bool nullToAbsent) {
    return CachedRoomMembersCompanion(
      actorId: Value(actorId),
      roomId: Value(roomId),
      userId: Value(userId),
      role: Value(role),
      inputPermission: Value(inputPermission),
      joinedAt: Value(joinedAt),
      leftAt: leftAt == null && nullToAbsent
          ? const Value.absent()
          : Value(leftAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory CachedRoomMember.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedRoomMember(
      actorId: serializer.fromJson<String>(json['actorId']),
      roomId: serializer.fromJson<String>(json['roomId']),
      userId: serializer.fromJson<String>(json['userId']),
      role: serializer.fromJson<String>(json['role']),
      inputPermission: serializer.fromJson<String>(json['inputPermission']),
      joinedAt: serializer.fromJson<DateTime>(json['joinedAt']),
      leftAt: serializer.fromJson<DateTime?>(json['leftAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'actorId': serializer.toJson<String>(actorId),
      'roomId': serializer.toJson<String>(roomId),
      'userId': serializer.toJson<String>(userId),
      'role': serializer.toJson<String>(role),
      'inputPermission': serializer.toJson<String>(inputPermission),
      'joinedAt': serializer.toJson<DateTime>(joinedAt),
      'leftAt': serializer.toJson<DateTime?>(leftAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  CachedRoomMember copyWith({
    String? actorId,
    String? roomId,
    String? userId,
    String? role,
    String? inputPermission,
    DateTime? joinedAt,
    Value<DateTime?> leftAt = const Value.absent(),
    DateTime? updatedAt,
  }) => CachedRoomMember(
    actorId: actorId ?? this.actorId,
    roomId: roomId ?? this.roomId,
    userId: userId ?? this.userId,
    role: role ?? this.role,
    inputPermission: inputPermission ?? this.inputPermission,
    joinedAt: joinedAt ?? this.joinedAt,
    leftAt: leftAt.present ? leftAt.value : this.leftAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  CachedRoomMember copyWithCompanion(CachedRoomMembersCompanion data) {
    return CachedRoomMember(
      actorId: data.actorId.present ? data.actorId.value : this.actorId,
      roomId: data.roomId.present ? data.roomId.value : this.roomId,
      userId: data.userId.present ? data.userId.value : this.userId,
      role: data.role.present ? data.role.value : this.role,
      inputPermission: data.inputPermission.present
          ? data.inputPermission.value
          : this.inputPermission,
      joinedAt: data.joinedAt.present ? data.joinedAt.value : this.joinedAt,
      leftAt: data.leftAt.present ? data.leftAt.value : this.leftAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedRoomMember(')
          ..write('actorId: $actorId, ')
          ..write('roomId: $roomId, ')
          ..write('userId: $userId, ')
          ..write('role: $role, ')
          ..write('inputPermission: $inputPermission, ')
          ..write('joinedAt: $joinedAt, ')
          ..write('leftAt: $leftAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    actorId,
    roomId,
    userId,
    role,
    inputPermission,
    joinedAt,
    leftAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedRoomMember &&
          other.actorId == this.actorId &&
          other.roomId == this.roomId &&
          other.userId == this.userId &&
          other.role == this.role &&
          other.inputPermission == this.inputPermission &&
          other.joinedAt == this.joinedAt &&
          other.leftAt == this.leftAt &&
          other.updatedAt == this.updatedAt);
}

class CachedRoomMembersCompanion extends UpdateCompanion<CachedRoomMember> {
  final Value<String> actorId;
  final Value<String> roomId;
  final Value<String> userId;
  final Value<String> role;
  final Value<String> inputPermission;
  final Value<DateTime> joinedAt;
  final Value<DateTime?> leftAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const CachedRoomMembersCompanion({
    this.actorId = const Value.absent(),
    this.roomId = const Value.absent(),
    this.userId = const Value.absent(),
    this.role = const Value.absent(),
    this.inputPermission = const Value.absent(),
    this.joinedAt = const Value.absent(),
    this.leftAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedRoomMembersCompanion.insert({
    this.actorId = const Value.absent(),
    required String roomId,
    required String userId,
    required String role,
    required String inputPermission,
    required DateTime joinedAt,
    this.leftAt = const Value.absent(),
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : roomId = Value(roomId),
       userId = Value(userId),
       role = Value(role),
       inputPermission = Value(inputPermission),
       joinedAt = Value(joinedAt),
       updatedAt = Value(updatedAt);
  static Insertable<CachedRoomMember> custom({
    Expression<String>? actorId,
    Expression<String>? roomId,
    Expression<String>? userId,
    Expression<String>? role,
    Expression<String>? inputPermission,
    Expression<DateTime>? joinedAt,
    Expression<DateTime>? leftAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (actorId != null) 'actor_id': actorId,
      if (roomId != null) 'room_id': roomId,
      if (userId != null) 'user_id': userId,
      if (role != null) 'role': role,
      if (inputPermission != null) 'input_permission': inputPermission,
      if (joinedAt != null) 'joined_at': joinedAt,
      if (leftAt != null) 'left_at': leftAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedRoomMembersCompanion copyWith({
    Value<String>? actorId,
    Value<String>? roomId,
    Value<String>? userId,
    Value<String>? role,
    Value<String>? inputPermission,
    Value<DateTime>? joinedAt,
    Value<DateTime?>? leftAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return CachedRoomMembersCompanion(
      actorId: actorId ?? this.actorId,
      roomId: roomId ?? this.roomId,
      userId: userId ?? this.userId,
      role: role ?? this.role,
      inputPermission: inputPermission ?? this.inputPermission,
      joinedAt: joinedAt ?? this.joinedAt,
      leftAt: leftAt ?? this.leftAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (actorId.present) {
      map['actor_id'] = Variable<String>(actorId.value);
    }
    if (roomId.present) {
      map['room_id'] = Variable<String>(roomId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (inputPermission.present) {
      map['input_permission'] = Variable<String>(inputPermission.value);
    }
    if (joinedAt.present) {
      map['joined_at'] = Variable<DateTime>(joinedAt.value);
    }
    if (leftAt.present) {
      map['left_at'] = Variable<DateTime>(leftAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedRoomMembersCompanion(')
          ..write('actorId: $actorId, ')
          ..write('roomId: $roomId, ')
          ..write('userId: $userId, ')
          ..write('role: $role, ')
          ..write('inputPermission: $inputPermission, ')
          ..write('joinedAt: $joinedAt, ')
          ..write('leftAt: $leftAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedGameSessionsTable extends CachedGameSessions
    with TableInfo<$CachedGameSessionsTable, CachedGameSession> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedGameSessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _actorIdMeta = const VerificationMeta(
    'actorId',
  );
  @override
  late final GeneratedColumn<String> actorId = GeneratedColumn<String>(
    'actor_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _roomIdMeta = const VerificationMeta('roomId');
  @override
  late final GeneratedColumn<String> roomId = GeneratedColumn<String>(
    'room_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
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
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _finishedAtMeta = const VerificationMeta(
    'finishedAt',
  );
  @override
  late final GeneratedColumn<DateTime> finishedAt = GeneratedColumn<DateTime>(
    'finished_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  @override
  List<GeneratedColumn> get $columns => [
    actorId,
    id,
    roomId,
    name,
    status,
    createdAt,
    startedAt,
    finishedAt,
    updatedAt,
    version,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_game_sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedGameSession> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('actor_id')) {
      context.handle(
        _actorIdMeta,
        actorId.isAcceptableOrUnknown(data['actor_id']!, _actorIdMeta),
      );
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('room_id')) {
      context.handle(
        _roomIdMeta,
        roomId.isAcceptableOrUnknown(data['room_id']!, _roomIdMeta),
      );
    } else if (isInserting) {
      context.missing(_roomIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    }
    if (data.containsKey('finished_at')) {
      context.handle(
        _finishedAtMeta,
        finishedAt.isAcceptableOrUnknown(data['finished_at']!, _finishedAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {actorId, id};
  @override
  CachedGameSession map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedGameSession(
      actorId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}actor_id'],
      )!,
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      roomId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}room_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      ),
      finishedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}finished_at'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
    );
  }

  @override
  $CachedGameSessionsTable createAlias(String alias) {
    return $CachedGameSessionsTable(attachedDatabase, alias);
  }
}

class CachedGameSession extends DataClass
    implements Insertable<CachedGameSession> {
  final String actorId;
  final String id;
  final String roomId;
  final String name;
  final String status;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? finishedAt;
  final DateTime updatedAt;
  final int version;
  const CachedGameSession({
    required this.actorId,
    required this.id,
    required this.roomId,
    required this.name,
    required this.status,
    required this.createdAt,
    this.startedAt,
    this.finishedAt,
    required this.updatedAt,
    required this.version,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['actor_id'] = Variable<String>(actorId);
    map['id'] = Variable<String>(id);
    map['room_id'] = Variable<String>(roomId);
    map['name'] = Variable<String>(name);
    map['status'] = Variable<String>(status);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || startedAt != null) {
      map['started_at'] = Variable<DateTime>(startedAt);
    }
    if (!nullToAbsent || finishedAt != null) {
      map['finished_at'] = Variable<DateTime>(finishedAt);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['version'] = Variable<int>(version);
    return map;
  }

  CachedGameSessionsCompanion toCompanion(bool nullToAbsent) {
    return CachedGameSessionsCompanion(
      actorId: Value(actorId),
      id: Value(id),
      roomId: Value(roomId),
      name: Value(name),
      status: Value(status),
      createdAt: Value(createdAt),
      startedAt: startedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(startedAt),
      finishedAt: finishedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(finishedAt),
      updatedAt: Value(updatedAt),
      version: Value(version),
    );
  }

  factory CachedGameSession.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedGameSession(
      actorId: serializer.fromJson<String>(json['actorId']),
      id: serializer.fromJson<String>(json['id']),
      roomId: serializer.fromJson<String>(json['roomId']),
      name: serializer.fromJson<String>(json['name']),
      status: serializer.fromJson<String>(json['status']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      startedAt: serializer.fromJson<DateTime?>(json['startedAt']),
      finishedAt: serializer.fromJson<DateTime?>(json['finishedAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      version: serializer.fromJson<int>(json['version']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'actorId': serializer.toJson<String>(actorId),
      'id': serializer.toJson<String>(id),
      'roomId': serializer.toJson<String>(roomId),
      'name': serializer.toJson<String>(name),
      'status': serializer.toJson<String>(status),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'startedAt': serializer.toJson<DateTime?>(startedAt),
      'finishedAt': serializer.toJson<DateTime?>(finishedAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'version': serializer.toJson<int>(version),
    };
  }

  CachedGameSession copyWith({
    String? actorId,
    String? id,
    String? roomId,
    String? name,
    String? status,
    DateTime? createdAt,
    Value<DateTime?> startedAt = const Value.absent(),
    Value<DateTime?> finishedAt = const Value.absent(),
    DateTime? updatedAt,
    int? version,
  }) => CachedGameSession(
    actorId: actorId ?? this.actorId,
    id: id ?? this.id,
    roomId: roomId ?? this.roomId,
    name: name ?? this.name,
    status: status ?? this.status,
    createdAt: createdAt ?? this.createdAt,
    startedAt: startedAt.present ? startedAt.value : this.startedAt,
    finishedAt: finishedAt.present ? finishedAt.value : this.finishedAt,
    updatedAt: updatedAt ?? this.updatedAt,
    version: version ?? this.version,
  );
  CachedGameSession copyWithCompanion(CachedGameSessionsCompanion data) {
    return CachedGameSession(
      actorId: data.actorId.present ? data.actorId.value : this.actorId,
      id: data.id.present ? data.id.value : this.id,
      roomId: data.roomId.present ? data.roomId.value : this.roomId,
      name: data.name.present ? data.name.value : this.name,
      status: data.status.present ? data.status.value : this.status,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      finishedAt: data.finishedAt.present
          ? data.finishedAt.value
          : this.finishedAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      version: data.version.present ? data.version.value : this.version,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedGameSession(')
          ..write('actorId: $actorId, ')
          ..write('id: $id, ')
          ..write('roomId: $roomId, ')
          ..write('name: $name, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('startedAt: $startedAt, ')
          ..write('finishedAt: $finishedAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('version: $version')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    actorId,
    id,
    roomId,
    name,
    status,
    createdAt,
    startedAt,
    finishedAt,
    updatedAt,
    version,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedGameSession &&
          other.actorId == this.actorId &&
          other.id == this.id &&
          other.roomId == this.roomId &&
          other.name == this.name &&
          other.status == this.status &&
          other.createdAt == this.createdAt &&
          other.startedAt == this.startedAt &&
          other.finishedAt == this.finishedAt &&
          other.updatedAt == this.updatedAt &&
          other.version == this.version);
}

class CachedGameSessionsCompanion extends UpdateCompanion<CachedGameSession> {
  final Value<String> actorId;
  final Value<String> id;
  final Value<String> roomId;
  final Value<String> name;
  final Value<String> status;
  final Value<DateTime> createdAt;
  final Value<DateTime?> startedAt;
  final Value<DateTime?> finishedAt;
  final Value<DateTime> updatedAt;
  final Value<int> version;
  final Value<int> rowid;
  const CachedGameSessionsCompanion({
    this.actorId = const Value.absent(),
    this.id = const Value.absent(),
    this.roomId = const Value.absent(),
    this.name = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.finishedAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.version = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedGameSessionsCompanion.insert({
    this.actorId = const Value.absent(),
    required String id,
    required String roomId,
    required String name,
    required String status,
    required DateTime createdAt,
    this.startedAt = const Value.absent(),
    this.finishedAt = const Value.absent(),
    required DateTime updatedAt,
    this.version = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       roomId = Value(roomId),
       name = Value(name),
       status = Value(status),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<CachedGameSession> custom({
    Expression<String>? actorId,
    Expression<String>? id,
    Expression<String>? roomId,
    Expression<String>? name,
    Expression<String>? status,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? finishedAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? version,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (actorId != null) 'actor_id': actorId,
      if (id != null) 'id': id,
      if (roomId != null) 'room_id': roomId,
      if (name != null) 'name': name,
      if (status != null) 'status': status,
      if (createdAt != null) 'created_at': createdAt,
      if (startedAt != null) 'started_at': startedAt,
      if (finishedAt != null) 'finished_at': finishedAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (version != null) 'version': version,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedGameSessionsCompanion copyWith({
    Value<String>? actorId,
    Value<String>? id,
    Value<String>? roomId,
    Value<String>? name,
    Value<String>? status,
    Value<DateTime>? createdAt,
    Value<DateTime?>? startedAt,
    Value<DateTime?>? finishedAt,
    Value<DateTime>? updatedAt,
    Value<int>? version,
    Value<int>? rowid,
  }) {
    return CachedGameSessionsCompanion(
      actorId: actorId ?? this.actorId,
      id: id ?? this.id,
      roomId: roomId ?? this.roomId,
      name: name ?? this.name,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      startedAt: startedAt ?? this.startedAt,
      finishedAt: finishedAt ?? this.finishedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      version: version ?? this.version,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (actorId.present) {
      map['actor_id'] = Variable<String>(actorId.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (roomId.present) {
      map['room_id'] = Variable<String>(roomId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (finishedAt.present) {
      map['finished_at'] = Variable<DateTime>(finishedAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedGameSessionsCompanion(')
          ..write('actorId: $actorId, ')
          ..write('id: $id, ')
          ..write('roomId: $roomId, ')
          ..write('name: $name, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('startedAt: $startedAt, ')
          ..write('finishedAt: $finishedAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('version: $version, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedRoundsTable extends CachedRounds
    with TableInfo<$CachedRoundsTable, CachedRound> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedRoundsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _actorIdMeta = const VerificationMeta(
    'actorId',
  );
  @override
  late final GeneratedColumn<String> actorId = GeneratedColumn<String>(
    'actor_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _roundNumberMeta = const VerificationMeta(
    'roundNumber',
  );
  @override
  late final GeneratedColumn<int> roundNumber = GeneratedColumn<int>(
    'round_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdByMeta = const VerificationMeta(
    'createdBy',
  );
  @override
  late final GeneratedColumn<String> createdBy = GeneratedColumn<String>(
    'created_by',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  @override
  List<GeneratedColumn> get $columns => [
    actorId,
    id,
    sessionId,
    roundNumber,
    createdBy,
    note,
    createdAt,
    deletedAt,
    updatedAt,
    version,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_rounds';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedRound> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('actor_id')) {
      context.handle(
        _actorIdMeta,
        actorId.isAcceptableOrUnknown(data['actor_id']!, _actorIdMeta),
      );
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('round_number')) {
      context.handle(
        _roundNumberMeta,
        roundNumber.isAcceptableOrUnknown(
          data['round_number']!,
          _roundNumberMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_roundNumberMeta);
    }
    if (data.containsKey('created_by')) {
      context.handle(
        _createdByMeta,
        createdBy.isAcceptableOrUnknown(data['created_by']!, _createdByMeta),
      );
    } else if (isInserting) {
      context.missing(_createdByMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {actorId, id};
  @override
  CachedRound map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedRound(
      actorId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}actor_id'],
      )!,
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_id'],
      )!,
      roundNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}round_number'],
      )!,
      createdBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_by'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
    );
  }

  @override
  $CachedRoundsTable createAlias(String alias) {
    return $CachedRoundsTable(attachedDatabase, alias);
  }
}

class CachedRound extends DataClass implements Insertable<CachedRound> {
  final String actorId;
  final String id;
  final String sessionId;
  final int roundNumber;
  final String createdBy;
  final String? note;
  final DateTime createdAt;
  final DateTime? deletedAt;
  final DateTime updatedAt;
  final int version;
  const CachedRound({
    required this.actorId,
    required this.id,
    required this.sessionId,
    required this.roundNumber,
    required this.createdBy,
    this.note,
    required this.createdAt,
    this.deletedAt,
    required this.updatedAt,
    required this.version,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['actor_id'] = Variable<String>(actorId);
    map['id'] = Variable<String>(id);
    map['session_id'] = Variable<String>(sessionId);
    map['round_number'] = Variable<int>(roundNumber);
    map['created_by'] = Variable<String>(createdBy);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['version'] = Variable<int>(version);
    return map;
  }

  CachedRoundsCompanion toCompanion(bool nullToAbsent) {
    return CachedRoundsCompanion(
      actorId: Value(actorId),
      id: Value(id),
      sessionId: Value(sessionId),
      roundNumber: Value(roundNumber),
      createdBy: Value(createdBy),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      createdAt: Value(createdAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      updatedAt: Value(updatedAt),
      version: Value(version),
    );
  }

  factory CachedRound.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedRound(
      actorId: serializer.fromJson<String>(json['actorId']),
      id: serializer.fromJson<String>(json['id']),
      sessionId: serializer.fromJson<String>(json['sessionId']),
      roundNumber: serializer.fromJson<int>(json['roundNumber']),
      createdBy: serializer.fromJson<String>(json['createdBy']),
      note: serializer.fromJson<String?>(json['note']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      version: serializer.fromJson<int>(json['version']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'actorId': serializer.toJson<String>(actorId),
      'id': serializer.toJson<String>(id),
      'sessionId': serializer.toJson<String>(sessionId),
      'roundNumber': serializer.toJson<int>(roundNumber),
      'createdBy': serializer.toJson<String>(createdBy),
      'note': serializer.toJson<String?>(note),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'version': serializer.toJson<int>(version),
    };
  }

  CachedRound copyWith({
    String? actorId,
    String? id,
    String? sessionId,
    int? roundNumber,
    String? createdBy,
    Value<String?> note = const Value.absent(),
    DateTime? createdAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    DateTime? updatedAt,
    int? version,
  }) => CachedRound(
    actorId: actorId ?? this.actorId,
    id: id ?? this.id,
    sessionId: sessionId ?? this.sessionId,
    roundNumber: roundNumber ?? this.roundNumber,
    createdBy: createdBy ?? this.createdBy,
    note: note.present ? note.value : this.note,
    createdAt: createdAt ?? this.createdAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    updatedAt: updatedAt ?? this.updatedAt,
    version: version ?? this.version,
  );
  CachedRound copyWithCompanion(CachedRoundsCompanion data) {
    return CachedRound(
      actorId: data.actorId.present ? data.actorId.value : this.actorId,
      id: data.id.present ? data.id.value : this.id,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      roundNumber: data.roundNumber.present
          ? data.roundNumber.value
          : this.roundNumber,
      createdBy: data.createdBy.present ? data.createdBy.value : this.createdBy,
      note: data.note.present ? data.note.value : this.note,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      version: data.version.present ? data.version.value : this.version,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedRound(')
          ..write('actorId: $actorId, ')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('roundNumber: $roundNumber, ')
          ..write('createdBy: $createdBy, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('version: $version')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    actorId,
    id,
    sessionId,
    roundNumber,
    createdBy,
    note,
    createdAt,
    deletedAt,
    updatedAt,
    version,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedRound &&
          other.actorId == this.actorId &&
          other.id == this.id &&
          other.sessionId == this.sessionId &&
          other.roundNumber == this.roundNumber &&
          other.createdBy == this.createdBy &&
          other.note == this.note &&
          other.createdAt == this.createdAt &&
          other.deletedAt == this.deletedAt &&
          other.updatedAt == this.updatedAt &&
          other.version == this.version);
}

class CachedRoundsCompanion extends UpdateCompanion<CachedRound> {
  final Value<String> actorId;
  final Value<String> id;
  final Value<String> sessionId;
  final Value<int> roundNumber;
  final Value<String> createdBy;
  final Value<String?> note;
  final Value<DateTime> createdAt;
  final Value<DateTime?> deletedAt;
  final Value<DateTime> updatedAt;
  final Value<int> version;
  final Value<int> rowid;
  const CachedRoundsCompanion({
    this.actorId = const Value.absent(),
    this.id = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.roundNumber = const Value.absent(),
    this.createdBy = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.version = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedRoundsCompanion.insert({
    this.actorId = const Value.absent(),
    required String id,
    required String sessionId,
    required int roundNumber,
    required String createdBy,
    this.note = const Value.absent(),
    required DateTime createdAt,
    this.deletedAt = const Value.absent(),
    required DateTime updatedAt,
    this.version = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       sessionId = Value(sessionId),
       roundNumber = Value(roundNumber),
       createdBy = Value(createdBy),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<CachedRound> custom({
    Expression<String>? actorId,
    Expression<String>? id,
    Expression<String>? sessionId,
    Expression<int>? roundNumber,
    Expression<String>? createdBy,
    Expression<String>? note,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? deletedAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? version,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (actorId != null) 'actor_id': actorId,
      if (id != null) 'id': id,
      if (sessionId != null) 'session_id': sessionId,
      if (roundNumber != null) 'round_number': roundNumber,
      if (createdBy != null) 'created_by': createdBy,
      if (note != null) 'note': note,
      if (createdAt != null) 'created_at': createdAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (version != null) 'version': version,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedRoundsCompanion copyWith({
    Value<String>? actorId,
    Value<String>? id,
    Value<String>? sessionId,
    Value<int>? roundNumber,
    Value<String>? createdBy,
    Value<String?>? note,
    Value<DateTime>? createdAt,
    Value<DateTime?>? deletedAt,
    Value<DateTime>? updatedAt,
    Value<int>? version,
    Value<int>? rowid,
  }) {
    return CachedRoundsCompanion(
      actorId: actorId ?? this.actorId,
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      roundNumber: roundNumber ?? this.roundNumber,
      createdBy: createdBy ?? this.createdBy,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      deletedAt: deletedAt ?? this.deletedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      version: version ?? this.version,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (actorId.present) {
      map['actor_id'] = Variable<String>(actorId.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (roundNumber.present) {
      map['round_number'] = Variable<int>(roundNumber.value);
    }
    if (createdBy.present) {
      map['created_by'] = Variable<String>(createdBy.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedRoundsCompanion(')
          ..write('actorId: $actorId, ')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('roundNumber: $roundNumber, ')
          ..write('createdBy: $createdBy, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('version: $version, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedScoreChangesTable extends CachedScoreChanges
    with TableInfo<$CachedScoreChangesTable, CachedScoreChange> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedScoreChangesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _actorIdMeta = const VerificationMeta(
    'actorId',
  );
  @override
  late final GeneratedColumn<String> actorId = GeneratedColumn<String>(
    'actor_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _roundIdMeta = const VerificationMeta(
    'roundId',
  );
  @override
  late final GeneratedColumn<String> roundId = GeneratedColumn<String>(
    'round_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _playerIdMeta = const VerificationMeta(
    'playerId',
  );
  @override
  late final GeneratedColumn<String> playerId = GeneratedColumn<String>(
    'player_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<int> value = GeneratedColumn<int>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    actorId,
    id,
    roundId,
    playerId,
    value,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_score_changes';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedScoreChange> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('actor_id')) {
      context.handle(
        _actorIdMeta,
        actorId.isAcceptableOrUnknown(data['actor_id']!, _actorIdMeta),
      );
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('round_id')) {
      context.handle(
        _roundIdMeta,
        roundId.isAcceptableOrUnknown(data['round_id']!, _roundIdMeta),
      );
    } else if (isInserting) {
      context.missing(_roundIdMeta);
    }
    if (data.containsKey('player_id')) {
      context.handle(
        _playerIdMeta,
        playerId.isAcceptableOrUnknown(data['player_id']!, _playerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_playerIdMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {actorId, id};
  @override
  CachedScoreChange map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedScoreChange(
      actorId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}actor_id'],
      )!,
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      roundId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}round_id'],
      )!,
      playerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}player_id'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}value'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $CachedScoreChangesTable createAlias(String alias) {
    return $CachedScoreChangesTable(attachedDatabase, alias);
  }
}

class CachedScoreChange extends DataClass
    implements Insertable<CachedScoreChange> {
  final String actorId;
  final String id;
  final String roundId;
  final String playerId;
  final int value;
  final DateTime updatedAt;
  const CachedScoreChange({
    required this.actorId,
    required this.id,
    required this.roundId,
    required this.playerId,
    required this.value,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['actor_id'] = Variable<String>(actorId);
    map['id'] = Variable<String>(id);
    map['round_id'] = Variable<String>(roundId);
    map['player_id'] = Variable<String>(playerId);
    map['value'] = Variable<int>(value);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  CachedScoreChangesCompanion toCompanion(bool nullToAbsent) {
    return CachedScoreChangesCompanion(
      actorId: Value(actorId),
      id: Value(id),
      roundId: Value(roundId),
      playerId: Value(playerId),
      value: Value(value),
      updatedAt: Value(updatedAt),
    );
  }

  factory CachedScoreChange.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedScoreChange(
      actorId: serializer.fromJson<String>(json['actorId']),
      id: serializer.fromJson<String>(json['id']),
      roundId: serializer.fromJson<String>(json['roundId']),
      playerId: serializer.fromJson<String>(json['playerId']),
      value: serializer.fromJson<int>(json['value']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'actorId': serializer.toJson<String>(actorId),
      'id': serializer.toJson<String>(id),
      'roundId': serializer.toJson<String>(roundId),
      'playerId': serializer.toJson<String>(playerId),
      'value': serializer.toJson<int>(value),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  CachedScoreChange copyWith({
    String? actorId,
    String? id,
    String? roundId,
    String? playerId,
    int? value,
    DateTime? updatedAt,
  }) => CachedScoreChange(
    actorId: actorId ?? this.actorId,
    id: id ?? this.id,
    roundId: roundId ?? this.roundId,
    playerId: playerId ?? this.playerId,
    value: value ?? this.value,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  CachedScoreChange copyWithCompanion(CachedScoreChangesCompanion data) {
    return CachedScoreChange(
      actorId: data.actorId.present ? data.actorId.value : this.actorId,
      id: data.id.present ? data.id.value : this.id,
      roundId: data.roundId.present ? data.roundId.value : this.roundId,
      playerId: data.playerId.present ? data.playerId.value : this.playerId,
      value: data.value.present ? data.value.value : this.value,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedScoreChange(')
          ..write('actorId: $actorId, ')
          ..write('id: $id, ')
          ..write('roundId: $roundId, ')
          ..write('playerId: $playerId, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(actorId, id, roundId, playerId, value, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedScoreChange &&
          other.actorId == this.actorId &&
          other.id == this.id &&
          other.roundId == this.roundId &&
          other.playerId == this.playerId &&
          other.value == this.value &&
          other.updatedAt == this.updatedAt);
}

class CachedScoreChangesCompanion extends UpdateCompanion<CachedScoreChange> {
  final Value<String> actorId;
  final Value<String> id;
  final Value<String> roundId;
  final Value<String> playerId;
  final Value<int> value;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const CachedScoreChangesCompanion({
    this.actorId = const Value.absent(),
    this.id = const Value.absent(),
    this.roundId = const Value.absent(),
    this.playerId = const Value.absent(),
    this.value = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedScoreChangesCompanion.insert({
    this.actorId = const Value.absent(),
    required String id,
    required String roundId,
    required String playerId,
    required int value,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       roundId = Value(roundId),
       playerId = Value(playerId),
       value = Value(value),
       updatedAt = Value(updatedAt);
  static Insertable<CachedScoreChange> custom({
    Expression<String>? actorId,
    Expression<String>? id,
    Expression<String>? roundId,
    Expression<String>? playerId,
    Expression<int>? value,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (actorId != null) 'actor_id': actorId,
      if (id != null) 'id': id,
      if (roundId != null) 'round_id': roundId,
      if (playerId != null) 'player_id': playerId,
      if (value != null) 'value': value,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedScoreChangesCompanion copyWith({
    Value<String>? actorId,
    Value<String>? id,
    Value<String>? roundId,
    Value<String>? playerId,
    Value<int>? value,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return CachedScoreChangesCompanion(
      actorId: actorId ?? this.actorId,
      id: id ?? this.id,
      roundId: roundId ?? this.roundId,
      playerId: playerId ?? this.playerId,
      value: value ?? this.value,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (actorId.present) {
      map['actor_id'] = Variable<String>(actorId.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (roundId.present) {
      map['round_id'] = Variable<String>(roundId.value);
    }
    if (playerId.present) {
      map['player_id'] = Variable<String>(playerId.value);
    }
    if (value.present) {
      map['value'] = Variable<int>(value.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedScoreChangesCompanion(')
          ..write('actorId: $actorId, ')
          ..write('id: $id, ')
          ..write('roundId: $roundId, ')
          ..write('playerId: $playerId, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncQueueEntriesTable extends SyncQueueEntries
    with TableInfo<$SyncQueueEntriesTable, SyncQueueEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncQueueEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _operationIdMeta = const VerificationMeta(
    'operationId',
  );
  @override
  late final GeneratedColumn<String> operationId = GeneratedColumn<String>(
    'operation_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _actorIdMeta = const VerificationMeta(
    'actorId',
  );
  @override
  late final GeneratedColumn<String> actorId = GeneratedColumn<String>(
    'actor_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _roomIdMeta = const VerificationMeta('roomId');
  @override
  late final GeneratedColumn<String> roomId = GeneratedColumn<String>(
    'room_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _entityTypeMeta = const VerificationMeta(
    'entityType',
  );
  @override
  late final GeneratedColumn<String> entityType = GeneratedColumn<String>(
    'entity_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityIdMeta = const VerificationMeta(
    'entityId',
  );
  @override
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
    'entity_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _operationMeta = const VerificationMeta(
    'operation',
  );
  @override
  late final GeneratedColumn<String> operation = GeneratedColumn<String>(
    'operation',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta(
    'payloadJson',
  );
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
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
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sequenceMeta = const VerificationMeta(
    'sequence',
  );
  @override
  late final GeneratedColumn<int> sequence = GeneratedColumn<int>(
    'sequence',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _attemptCountMeta = const VerificationMeta(
    'attemptCount',
  );
  @override
  late final GeneratedColumn<int> attemptCount = GeneratedColumn<int>(
    'attempt_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _baseVersionMeta = const VerificationMeta(
    'baseVersion',
  );
  @override
  late final GeneratedColumn<int> baseVersion = GeneratedColumn<int>(
    'base_version',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dependsOnMeta = const VerificationMeta(
    'dependsOn',
  );
  @override
  late final GeneratedColumn<String> dependsOn = GeneratedColumn<String>(
    'depends_on',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ackJsonMeta = const VerificationMeta(
    'ackJson',
  );
  @override
  late final GeneratedColumn<String> ackJson = GeneratedColumn<String>(
    'ack_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nextAttemptAtMeta = const VerificationMeta(
    'nextAttemptAt',
  );
  @override
  late final GeneratedColumn<DateTime> nextAttemptAt =
      GeneratedColumn<DateTime>(
        'next_attempt_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _syncedAtMeta = const VerificationMeta(
    'syncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
    'synced_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    operationId,
    actorId,
    roomId,
    entityType,
    entityId,
    operation,
    payloadJson,
    createdAt,
    sequence,
    attemptCount,
    status,
    baseVersion,
    dependsOn,
    ackJson,
    lastError,
    nextAttemptAt,
    syncedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_queue_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncQueueEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('operation_id')) {
      context.handle(
        _operationIdMeta,
        operationId.isAcceptableOrUnknown(
          data['operation_id']!,
          _operationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_operationIdMeta);
    }
    if (data.containsKey('actor_id')) {
      context.handle(
        _actorIdMeta,
        actorId.isAcceptableOrUnknown(data['actor_id']!, _actorIdMeta),
      );
    }
    if (data.containsKey('room_id')) {
      context.handle(
        _roomIdMeta,
        roomId.isAcceptableOrUnknown(data['room_id']!, _roomIdMeta),
      );
    }
    if (data.containsKey('entity_type')) {
      context.handle(
        _entityTypeMeta,
        entityType.isAcceptableOrUnknown(data['entity_type']!, _entityTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_entityTypeMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(
        _entityIdMeta,
        entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('operation')) {
      context.handle(
        _operationMeta,
        operation.isAcceptableOrUnknown(data['operation']!, _operationMeta),
      );
    } else if (isInserting) {
      context.missing(_operationMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
        _payloadJsonMeta,
        payloadJson.isAcceptableOrUnknown(
          data['payload_json']!,
          _payloadJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('sequence')) {
      context.handle(
        _sequenceMeta,
        sequence.isAcceptableOrUnknown(data['sequence']!, _sequenceMeta),
      );
    }
    if (data.containsKey('attempt_count')) {
      context.handle(
        _attemptCountMeta,
        attemptCount.isAcceptableOrUnknown(
          data['attempt_count']!,
          _attemptCountMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('base_version')) {
      context.handle(
        _baseVersionMeta,
        baseVersion.isAcceptableOrUnknown(
          data['base_version']!,
          _baseVersionMeta,
        ),
      );
    }
    if (data.containsKey('depends_on')) {
      context.handle(
        _dependsOnMeta,
        dependsOn.isAcceptableOrUnknown(data['depends_on']!, _dependsOnMeta),
      );
    }
    if (data.containsKey('ack_json')) {
      context.handle(
        _ackJsonMeta,
        ackJson.isAcceptableOrUnknown(data['ack_json']!, _ackJsonMeta),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    if (data.containsKey('next_attempt_at')) {
      context.handle(
        _nextAttemptAtMeta,
        nextAttemptAt.isAcceptableOrUnknown(
          data['next_attempt_at']!,
          _nextAttemptAtMeta,
        ),
      );
    }
    if (data.containsKey('synced_at')) {
      context.handle(
        _syncedAtMeta,
        syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {operationId};
  @override
  SyncQueueEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncQueueEntry(
      operationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}operation_id'],
      )!,
      actorId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}actor_id'],
      )!,
      roomId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}room_id'],
      )!,
      entityType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_type'],
      )!,
      entityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_id'],
      )!,
      operation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}operation'],
      )!,
      payloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_json'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      sequence: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sequence'],
      )!,
      attemptCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempt_count'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      baseVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}base_version'],
      ),
      dependsOn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}depends_on'],
      ),
      ackJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ack_json'],
      ),
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
      nextAttemptAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}next_attempt_at'],
      ),
      syncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}synced_at'],
      ),
    );
  }

  @override
  $SyncQueueEntriesTable createAlias(String alias) {
    return $SyncQueueEntriesTable(attachedDatabase, alias);
  }
}

class SyncQueueEntry extends DataClass implements Insertable<SyncQueueEntry> {
  final String operationId;
  final String actorId;
  final String roomId;
  final String entityType;
  final String entityId;
  final String operation;
  final String payloadJson;
  final DateTime createdAt;
  final int sequence;
  final int attemptCount;
  final String status;
  final int? baseVersion;
  final String? dependsOn;
  final String? ackJson;
  final String? lastError;
  final DateTime? nextAttemptAt;
  final DateTime? syncedAt;
  const SyncQueueEntry({
    required this.operationId,
    required this.actorId,
    required this.roomId,
    required this.entityType,
    required this.entityId,
    required this.operation,
    required this.payloadJson,
    required this.createdAt,
    required this.sequence,
    required this.attemptCount,
    required this.status,
    this.baseVersion,
    this.dependsOn,
    this.ackJson,
    this.lastError,
    this.nextAttemptAt,
    this.syncedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['operation_id'] = Variable<String>(operationId);
    map['actor_id'] = Variable<String>(actorId);
    map['room_id'] = Variable<String>(roomId);
    map['entity_type'] = Variable<String>(entityType);
    map['entity_id'] = Variable<String>(entityId);
    map['operation'] = Variable<String>(operation);
    map['payload_json'] = Variable<String>(payloadJson);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['sequence'] = Variable<int>(sequence);
    map['attempt_count'] = Variable<int>(attemptCount);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || baseVersion != null) {
      map['base_version'] = Variable<int>(baseVersion);
    }
    if (!nullToAbsent || dependsOn != null) {
      map['depends_on'] = Variable<String>(dependsOn);
    }
    if (!nullToAbsent || ackJson != null) {
      map['ack_json'] = Variable<String>(ackJson);
    }
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    if (!nullToAbsent || nextAttemptAt != null) {
      map['next_attempt_at'] = Variable<DateTime>(nextAttemptAt);
    }
    if (!nullToAbsent || syncedAt != null) {
      map['synced_at'] = Variable<DateTime>(syncedAt);
    }
    return map;
  }

  SyncQueueEntriesCompanion toCompanion(bool nullToAbsent) {
    return SyncQueueEntriesCompanion(
      operationId: Value(operationId),
      actorId: Value(actorId),
      roomId: Value(roomId),
      entityType: Value(entityType),
      entityId: Value(entityId),
      operation: Value(operation),
      payloadJson: Value(payloadJson),
      createdAt: Value(createdAt),
      sequence: Value(sequence),
      attemptCount: Value(attemptCount),
      status: Value(status),
      baseVersion: baseVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(baseVersion),
      dependsOn: dependsOn == null && nullToAbsent
          ? const Value.absent()
          : Value(dependsOn),
      ackJson: ackJson == null && nullToAbsent
          ? const Value.absent()
          : Value(ackJson),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
      nextAttemptAt: nextAttemptAt == null && nullToAbsent
          ? const Value.absent()
          : Value(nextAttemptAt),
      syncedAt: syncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(syncedAt),
    );
  }

  factory SyncQueueEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncQueueEntry(
      operationId: serializer.fromJson<String>(json['operationId']),
      actorId: serializer.fromJson<String>(json['actorId']),
      roomId: serializer.fromJson<String>(json['roomId']),
      entityType: serializer.fromJson<String>(json['entityType']),
      entityId: serializer.fromJson<String>(json['entityId']),
      operation: serializer.fromJson<String>(json['operation']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      sequence: serializer.fromJson<int>(json['sequence']),
      attemptCount: serializer.fromJson<int>(json['attemptCount']),
      status: serializer.fromJson<String>(json['status']),
      baseVersion: serializer.fromJson<int?>(json['baseVersion']),
      dependsOn: serializer.fromJson<String?>(json['dependsOn']),
      ackJson: serializer.fromJson<String?>(json['ackJson']),
      lastError: serializer.fromJson<String?>(json['lastError']),
      nextAttemptAt: serializer.fromJson<DateTime?>(json['nextAttemptAt']),
      syncedAt: serializer.fromJson<DateTime?>(json['syncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'operationId': serializer.toJson<String>(operationId),
      'actorId': serializer.toJson<String>(actorId),
      'roomId': serializer.toJson<String>(roomId),
      'entityType': serializer.toJson<String>(entityType),
      'entityId': serializer.toJson<String>(entityId),
      'operation': serializer.toJson<String>(operation),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'sequence': serializer.toJson<int>(sequence),
      'attemptCount': serializer.toJson<int>(attemptCount),
      'status': serializer.toJson<String>(status),
      'baseVersion': serializer.toJson<int?>(baseVersion),
      'dependsOn': serializer.toJson<String?>(dependsOn),
      'ackJson': serializer.toJson<String?>(ackJson),
      'lastError': serializer.toJson<String?>(lastError),
      'nextAttemptAt': serializer.toJson<DateTime?>(nextAttemptAt),
      'syncedAt': serializer.toJson<DateTime?>(syncedAt),
    };
  }

  SyncQueueEntry copyWith({
    String? operationId,
    String? actorId,
    String? roomId,
    String? entityType,
    String? entityId,
    String? operation,
    String? payloadJson,
    DateTime? createdAt,
    int? sequence,
    int? attemptCount,
    String? status,
    Value<int?> baseVersion = const Value.absent(),
    Value<String?> dependsOn = const Value.absent(),
    Value<String?> ackJson = const Value.absent(),
    Value<String?> lastError = const Value.absent(),
    Value<DateTime?> nextAttemptAt = const Value.absent(),
    Value<DateTime?> syncedAt = const Value.absent(),
  }) => SyncQueueEntry(
    operationId: operationId ?? this.operationId,
    actorId: actorId ?? this.actorId,
    roomId: roomId ?? this.roomId,
    entityType: entityType ?? this.entityType,
    entityId: entityId ?? this.entityId,
    operation: operation ?? this.operation,
    payloadJson: payloadJson ?? this.payloadJson,
    createdAt: createdAt ?? this.createdAt,
    sequence: sequence ?? this.sequence,
    attemptCount: attemptCount ?? this.attemptCount,
    status: status ?? this.status,
    baseVersion: baseVersion.present ? baseVersion.value : this.baseVersion,
    dependsOn: dependsOn.present ? dependsOn.value : this.dependsOn,
    ackJson: ackJson.present ? ackJson.value : this.ackJson,
    lastError: lastError.present ? lastError.value : this.lastError,
    nextAttemptAt: nextAttemptAt.present
        ? nextAttemptAt.value
        : this.nextAttemptAt,
    syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
  );
  SyncQueueEntry copyWithCompanion(SyncQueueEntriesCompanion data) {
    return SyncQueueEntry(
      operationId: data.operationId.present
          ? data.operationId.value
          : this.operationId,
      actorId: data.actorId.present ? data.actorId.value : this.actorId,
      roomId: data.roomId.present ? data.roomId.value : this.roomId,
      entityType: data.entityType.present
          ? data.entityType.value
          : this.entityType,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      operation: data.operation.present ? data.operation.value : this.operation,
      payloadJson: data.payloadJson.present
          ? data.payloadJson.value
          : this.payloadJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      sequence: data.sequence.present ? data.sequence.value : this.sequence,
      attemptCount: data.attemptCount.present
          ? data.attemptCount.value
          : this.attemptCount,
      status: data.status.present ? data.status.value : this.status,
      baseVersion: data.baseVersion.present
          ? data.baseVersion.value
          : this.baseVersion,
      dependsOn: data.dependsOn.present ? data.dependsOn.value : this.dependsOn,
      ackJson: data.ackJson.present ? data.ackJson.value : this.ackJson,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
      nextAttemptAt: data.nextAttemptAt.present
          ? data.nextAttemptAt.value
          : this.nextAttemptAt,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueEntry(')
          ..write('operationId: $operationId, ')
          ..write('actorId: $actorId, ')
          ..write('roomId: $roomId, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('operation: $operation, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('sequence: $sequence, ')
          ..write('attemptCount: $attemptCount, ')
          ..write('status: $status, ')
          ..write('baseVersion: $baseVersion, ')
          ..write('dependsOn: $dependsOn, ')
          ..write('ackJson: $ackJson, ')
          ..write('lastError: $lastError, ')
          ..write('nextAttemptAt: $nextAttemptAt, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    operationId,
    actorId,
    roomId,
    entityType,
    entityId,
    operation,
    payloadJson,
    createdAt,
    sequence,
    attemptCount,
    status,
    baseVersion,
    dependsOn,
    ackJson,
    lastError,
    nextAttemptAt,
    syncedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncQueueEntry &&
          other.operationId == this.operationId &&
          other.actorId == this.actorId &&
          other.roomId == this.roomId &&
          other.entityType == this.entityType &&
          other.entityId == this.entityId &&
          other.operation == this.operation &&
          other.payloadJson == this.payloadJson &&
          other.createdAt == this.createdAt &&
          other.sequence == this.sequence &&
          other.attemptCount == this.attemptCount &&
          other.status == this.status &&
          other.baseVersion == this.baseVersion &&
          other.dependsOn == this.dependsOn &&
          other.ackJson == this.ackJson &&
          other.lastError == this.lastError &&
          other.nextAttemptAt == this.nextAttemptAt &&
          other.syncedAt == this.syncedAt);
}

class SyncQueueEntriesCompanion extends UpdateCompanion<SyncQueueEntry> {
  final Value<String> operationId;
  final Value<String> actorId;
  final Value<String> roomId;
  final Value<String> entityType;
  final Value<String> entityId;
  final Value<String> operation;
  final Value<String> payloadJson;
  final Value<DateTime> createdAt;
  final Value<int> sequence;
  final Value<int> attemptCount;
  final Value<String> status;
  final Value<int?> baseVersion;
  final Value<String?> dependsOn;
  final Value<String?> ackJson;
  final Value<String?> lastError;
  final Value<DateTime?> nextAttemptAt;
  final Value<DateTime?> syncedAt;
  final Value<int> rowid;
  const SyncQueueEntriesCompanion({
    this.operationId = const Value.absent(),
    this.actorId = const Value.absent(),
    this.roomId = const Value.absent(),
    this.entityType = const Value.absent(),
    this.entityId = const Value.absent(),
    this.operation = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.sequence = const Value.absent(),
    this.attemptCount = const Value.absent(),
    this.status = const Value.absent(),
    this.baseVersion = const Value.absent(),
    this.dependsOn = const Value.absent(),
    this.ackJson = const Value.absent(),
    this.lastError = const Value.absent(),
    this.nextAttemptAt = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncQueueEntriesCompanion.insert({
    required String operationId,
    this.actorId = const Value.absent(),
    this.roomId = const Value.absent(),
    required String entityType,
    required String entityId,
    required String operation,
    required String payloadJson,
    required DateTime createdAt,
    this.sequence = const Value.absent(),
    this.attemptCount = const Value.absent(),
    this.status = const Value.absent(),
    this.baseVersion = const Value.absent(),
    this.dependsOn = const Value.absent(),
    this.ackJson = const Value.absent(),
    this.lastError = const Value.absent(),
    this.nextAttemptAt = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : operationId = Value(operationId),
       entityType = Value(entityType),
       entityId = Value(entityId),
       operation = Value(operation),
       payloadJson = Value(payloadJson),
       createdAt = Value(createdAt);
  static Insertable<SyncQueueEntry> custom({
    Expression<String>? operationId,
    Expression<String>? actorId,
    Expression<String>? roomId,
    Expression<String>? entityType,
    Expression<String>? entityId,
    Expression<String>? operation,
    Expression<String>? payloadJson,
    Expression<DateTime>? createdAt,
    Expression<int>? sequence,
    Expression<int>? attemptCount,
    Expression<String>? status,
    Expression<int>? baseVersion,
    Expression<String>? dependsOn,
    Expression<String>? ackJson,
    Expression<String>? lastError,
    Expression<DateTime>? nextAttemptAt,
    Expression<DateTime>? syncedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (operationId != null) 'operation_id': operationId,
      if (actorId != null) 'actor_id': actorId,
      if (roomId != null) 'room_id': roomId,
      if (entityType != null) 'entity_type': entityType,
      if (entityId != null) 'entity_id': entityId,
      if (operation != null) 'operation': operation,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (createdAt != null) 'created_at': createdAt,
      if (sequence != null) 'sequence': sequence,
      if (attemptCount != null) 'attempt_count': attemptCount,
      if (status != null) 'status': status,
      if (baseVersion != null) 'base_version': baseVersion,
      if (dependsOn != null) 'depends_on': dependsOn,
      if (ackJson != null) 'ack_json': ackJson,
      if (lastError != null) 'last_error': lastError,
      if (nextAttemptAt != null) 'next_attempt_at': nextAttemptAt,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncQueueEntriesCompanion copyWith({
    Value<String>? operationId,
    Value<String>? actorId,
    Value<String>? roomId,
    Value<String>? entityType,
    Value<String>? entityId,
    Value<String>? operation,
    Value<String>? payloadJson,
    Value<DateTime>? createdAt,
    Value<int>? sequence,
    Value<int>? attemptCount,
    Value<String>? status,
    Value<int?>? baseVersion,
    Value<String?>? dependsOn,
    Value<String?>? ackJson,
    Value<String?>? lastError,
    Value<DateTime?>? nextAttemptAt,
    Value<DateTime?>? syncedAt,
    Value<int>? rowid,
  }) {
    return SyncQueueEntriesCompanion(
      operationId: operationId ?? this.operationId,
      actorId: actorId ?? this.actorId,
      roomId: roomId ?? this.roomId,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      operation: operation ?? this.operation,
      payloadJson: payloadJson ?? this.payloadJson,
      createdAt: createdAt ?? this.createdAt,
      sequence: sequence ?? this.sequence,
      attemptCount: attemptCount ?? this.attemptCount,
      status: status ?? this.status,
      baseVersion: baseVersion ?? this.baseVersion,
      dependsOn: dependsOn ?? this.dependsOn,
      ackJson: ackJson ?? this.ackJson,
      lastError: lastError ?? this.lastError,
      nextAttemptAt: nextAttemptAt ?? this.nextAttemptAt,
      syncedAt: syncedAt ?? this.syncedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (operationId.present) {
      map['operation_id'] = Variable<String>(operationId.value);
    }
    if (actorId.present) {
      map['actor_id'] = Variable<String>(actorId.value);
    }
    if (roomId.present) {
      map['room_id'] = Variable<String>(roomId.value);
    }
    if (entityType.present) {
      map['entity_type'] = Variable<String>(entityType.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (operation.present) {
      map['operation'] = Variable<String>(operation.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (sequence.present) {
      map['sequence'] = Variable<int>(sequence.value);
    }
    if (attemptCount.present) {
      map['attempt_count'] = Variable<int>(attemptCount.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (baseVersion.present) {
      map['base_version'] = Variable<int>(baseVersion.value);
    }
    if (dependsOn.present) {
      map['depends_on'] = Variable<String>(dependsOn.value);
    }
    if (ackJson.present) {
      map['ack_json'] = Variable<String>(ackJson.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (nextAttemptAt.present) {
      map['next_attempt_at'] = Variable<DateTime>(nextAttemptAt.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueEntriesCompanion(')
          ..write('operationId: $operationId, ')
          ..write('actorId: $actorId, ')
          ..write('roomId: $roomId, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('operation: $operation, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('sequence: $sequence, ')
          ..write('attemptCount: $attemptCount, ')
          ..write('status: $status, ')
          ..write('baseVersion: $baseVersion, ')
          ..write('dependsOn: $dependsOn, ')
          ..write('ackJson: $ackJson, ')
          ..write('lastError: $lastError, ')
          ..write('nextAttemptAt: $nextAttemptAt, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $CachedUsersTable cachedUsers = $CachedUsersTable(this);
  late final $CachedRoomsTable cachedRooms = $CachedRoomsTable(this);
  late final $CachedRoomMembersTable cachedRoomMembers =
      $CachedRoomMembersTable(this);
  late final $CachedGameSessionsTable cachedGameSessions =
      $CachedGameSessionsTable(this);
  late final $CachedRoundsTable cachedRounds = $CachedRoundsTable(this);
  late final $CachedScoreChangesTable cachedScoreChanges =
      $CachedScoreChangesTable(this);
  late final $SyncQueueEntriesTable syncQueueEntries = $SyncQueueEntriesTable(
    this,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    cachedUsers,
    cachedRooms,
    cachedRoomMembers,
    cachedGameSessions,
    cachedRounds,
    cachedScoreChanges,
    syncQueueEntries,
  ];
}

typedef $$CachedUsersTableCreateCompanionBuilder =
    CachedUsersCompanion Function({
      Value<String> actorId,
      required String id,
      required String nickname,
      Value<String?> avatarKey,
      Value<String?> avatarUrl,
      Value<String?> phone,
      Value<String?> email,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$CachedUsersTableUpdateCompanionBuilder =
    CachedUsersCompanion Function({
      Value<String> actorId,
      Value<String> id,
      Value<String> nickname,
      Value<String?> avatarKey,
      Value<String?> avatarUrl,
      Value<String?> phone,
      Value<String?> email,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$CachedUsersTableFilterComposer
    extends Composer<_$AppDatabase, $CachedUsersTable> {
  $$CachedUsersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get actorId => $composableBuilder(
    column: $table.actorId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nickname => $composableBuilder(
    column: $table.nickname,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get avatarKey => $composableBuilder(
    column: $table.avatarKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get avatarUrl => $composableBuilder(
    column: $table.avatarUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedUsersTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedUsersTable> {
  $$CachedUsersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get actorId => $composableBuilder(
    column: $table.actorId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nickname => $composableBuilder(
    column: $table.nickname,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get avatarKey => $composableBuilder(
    column: $table.avatarKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get avatarUrl => $composableBuilder(
    column: $table.avatarUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedUsersTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedUsersTable> {
  $$CachedUsersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get actorId =>
      $composableBuilder(column: $table.actorId, builder: (column) => column);

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get nickname =>
      $composableBuilder(column: $table.nickname, builder: (column) => column);

  GeneratedColumn<String> get avatarKey =>
      $composableBuilder(column: $table.avatarKey, builder: (column) => column);

  GeneratedColumn<String> get avatarUrl =>
      $composableBuilder(column: $table.avatarUrl, builder: (column) => column);

  GeneratedColumn<String> get phone =>
      $composableBuilder(column: $table.phone, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$CachedUsersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedUsersTable,
          CachedUser,
          $$CachedUsersTableFilterComposer,
          $$CachedUsersTableOrderingComposer,
          $$CachedUsersTableAnnotationComposer,
          $$CachedUsersTableCreateCompanionBuilder,
          $$CachedUsersTableUpdateCompanionBuilder,
          (
            CachedUser,
            BaseReferences<_$AppDatabase, $CachedUsersTable, CachedUser>,
          ),
          CachedUser,
          PrefetchHooks Function()
        > {
  $$CachedUsersTableTableManager(_$AppDatabase db, $CachedUsersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedUsersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedUsersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedUsersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> actorId = const Value.absent(),
                Value<String> id = const Value.absent(),
                Value<String> nickname = const Value.absent(),
                Value<String?> avatarKey = const Value.absent(),
                Value<String?> avatarUrl = const Value.absent(),
                Value<String?> phone = const Value.absent(),
                Value<String?> email = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedUsersCompanion(
                actorId: actorId,
                id: id,
                nickname: nickname,
                avatarKey: avatarKey,
                avatarUrl: avatarUrl,
                phone: phone,
                email: email,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> actorId = const Value.absent(),
                required String id,
                required String nickname,
                Value<String?> avatarKey = const Value.absent(),
                Value<String?> avatarUrl = const Value.absent(),
                Value<String?> phone = const Value.absent(),
                Value<String?> email = const Value.absent(),
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => CachedUsersCompanion.insert(
                actorId: actorId,
                id: id,
                nickname: nickname,
                avatarKey: avatarKey,
                avatarUrl: avatarUrl,
                phone: phone,
                email: email,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CachedUsersTable, CachedUser>(table),
                  BaseReferences<_$AppDatabase, $CachedUsersTable, CachedUser>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedUsersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedUsersTable,
      CachedUser,
      $$CachedUsersTableFilterComposer,
      $$CachedUsersTableOrderingComposer,
      $$CachedUsersTableAnnotationComposer,
      $$CachedUsersTableCreateCompanionBuilder,
      $$CachedUsersTableUpdateCompanionBuilder,
      (
        CachedUser,
        BaseReferences<_$AppDatabase, $CachedUsersTable, CachedUser>,
      ),
      CachedUser,
      PrefetchHooks Function()
    >;
typedef $$CachedRoomsTableCreateCompanionBuilder =
    CachedRoomsCompanion Function({
      Value<String> actorId,
      required String id,
      required String name,
      required String ownerId,
      required String gameType,
      required String scoringMode,
      required String status,
      required String inputPermission,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> version,
      Value<String?> closeVoteJson,
      Value<DateTime?> snapshotAt,
      Value<bool> isAccessible,
      Value<int> rowid,
    });
typedef $$CachedRoomsTableUpdateCompanionBuilder =
    CachedRoomsCompanion Function({
      Value<String> actorId,
      Value<String> id,
      Value<String> name,
      Value<String> ownerId,
      Value<String> gameType,
      Value<String> scoringMode,
      Value<String> status,
      Value<String> inputPermission,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> version,
      Value<String?> closeVoteJson,
      Value<DateTime?> snapshotAt,
      Value<bool> isAccessible,
      Value<int> rowid,
    });

class $$CachedRoomsTableFilterComposer
    extends Composer<_$AppDatabase, $CachedRoomsTable> {
  $$CachedRoomsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get actorId => $composableBuilder(
    column: $table.actorId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ownerId => $composableBuilder(
    column: $table.ownerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get gameType => $composableBuilder(
    column: $table.gameType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get scoringMode => $composableBuilder(
    column: $table.scoringMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get inputPermission => $composableBuilder(
    column: $table.inputPermission,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get closeVoteJson => $composableBuilder(
    column: $table.closeVoteJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get snapshotAt => $composableBuilder(
    column: $table.snapshotAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isAccessible => $composableBuilder(
    column: $table.isAccessible,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedRoomsTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedRoomsTable> {
  $$CachedRoomsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get actorId => $composableBuilder(
    column: $table.actorId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ownerId => $composableBuilder(
    column: $table.ownerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get gameType => $composableBuilder(
    column: $table.gameType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get scoringMode => $composableBuilder(
    column: $table.scoringMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get inputPermission => $composableBuilder(
    column: $table.inputPermission,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get closeVoteJson => $composableBuilder(
    column: $table.closeVoteJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get snapshotAt => $composableBuilder(
    column: $table.snapshotAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isAccessible => $composableBuilder(
    column: $table.isAccessible,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedRoomsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedRoomsTable> {
  $$CachedRoomsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get actorId =>
      $composableBuilder(column: $table.actorId, builder: (column) => column);

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get ownerId =>
      $composableBuilder(column: $table.ownerId, builder: (column) => column);

  GeneratedColumn<String> get gameType =>
      $composableBuilder(column: $table.gameType, builder: (column) => column);

  GeneratedColumn<String> get scoringMode => $composableBuilder(
    column: $table.scoringMode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get inputPermission => $composableBuilder(
    column: $table.inputPermission,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<String> get closeVoteJson => $composableBuilder(
    column: $table.closeVoteJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get snapshotAt => $composableBuilder(
    column: $table.snapshotAt,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isAccessible => $composableBuilder(
    column: $table.isAccessible,
    builder: (column) => column,
  );
}

class $$CachedRoomsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedRoomsTable,
          CachedRoom,
          $$CachedRoomsTableFilterComposer,
          $$CachedRoomsTableOrderingComposer,
          $$CachedRoomsTableAnnotationComposer,
          $$CachedRoomsTableCreateCompanionBuilder,
          $$CachedRoomsTableUpdateCompanionBuilder,
          (
            CachedRoom,
            BaseReferences<_$AppDatabase, $CachedRoomsTable, CachedRoom>,
          ),
          CachedRoom,
          PrefetchHooks Function()
        > {
  $$CachedRoomsTableTableManager(_$AppDatabase db, $CachedRoomsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedRoomsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedRoomsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedRoomsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> actorId = const Value.absent(),
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> ownerId = const Value.absent(),
                Value<String> gameType = const Value.absent(),
                Value<String> scoringMode = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> inputPermission = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<String?> closeVoteJson = const Value.absent(),
                Value<DateTime?> snapshotAt = const Value.absent(),
                Value<bool> isAccessible = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedRoomsCompanion(
                actorId: actorId,
                id: id,
                name: name,
                ownerId: ownerId,
                gameType: gameType,
                scoringMode: scoringMode,
                status: status,
                inputPermission: inputPermission,
                createdAt: createdAt,
                updatedAt: updatedAt,
                version: version,
                closeVoteJson: closeVoteJson,
                snapshotAt: snapshotAt,
                isAccessible: isAccessible,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> actorId = const Value.absent(),
                required String id,
                required String name,
                required String ownerId,
                required String gameType,
                required String scoringMode,
                required String status,
                required String inputPermission,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> version = const Value.absent(),
                Value<String?> closeVoteJson = const Value.absent(),
                Value<DateTime?> snapshotAt = const Value.absent(),
                Value<bool> isAccessible = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedRoomsCompanion.insert(
                actorId: actorId,
                id: id,
                name: name,
                ownerId: ownerId,
                gameType: gameType,
                scoringMode: scoringMode,
                status: status,
                inputPermission: inputPermission,
                createdAt: createdAt,
                updatedAt: updatedAt,
                version: version,
                closeVoteJson: closeVoteJson,
                snapshotAt: snapshotAt,
                isAccessible: isAccessible,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CachedRoomsTable, CachedRoom>(table),
                  BaseReferences<_$AppDatabase, $CachedRoomsTable, CachedRoom>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedRoomsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedRoomsTable,
      CachedRoom,
      $$CachedRoomsTableFilterComposer,
      $$CachedRoomsTableOrderingComposer,
      $$CachedRoomsTableAnnotationComposer,
      $$CachedRoomsTableCreateCompanionBuilder,
      $$CachedRoomsTableUpdateCompanionBuilder,
      (
        CachedRoom,
        BaseReferences<_$AppDatabase, $CachedRoomsTable, CachedRoom>,
      ),
      CachedRoom,
      PrefetchHooks Function()
    >;
typedef $$CachedRoomMembersTableCreateCompanionBuilder =
    CachedRoomMembersCompanion Function({
      Value<String> actorId,
      required String roomId,
      required String userId,
      required String role,
      required String inputPermission,
      required DateTime joinedAt,
      Value<DateTime?> leftAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$CachedRoomMembersTableUpdateCompanionBuilder =
    CachedRoomMembersCompanion Function({
      Value<String> actorId,
      Value<String> roomId,
      Value<String> userId,
      Value<String> role,
      Value<String> inputPermission,
      Value<DateTime> joinedAt,
      Value<DateTime?> leftAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$CachedRoomMembersTableFilterComposer
    extends Composer<_$AppDatabase, $CachedRoomMembersTable> {
  $$CachedRoomMembersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get actorId => $composableBuilder(
    column: $table.actorId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get roomId => $composableBuilder(
    column: $table.roomId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get inputPermission => $composableBuilder(
    column: $table.inputPermission,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get joinedAt => $composableBuilder(
    column: $table.joinedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get leftAt => $composableBuilder(
    column: $table.leftAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedRoomMembersTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedRoomMembersTable> {
  $$CachedRoomMembersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get actorId => $composableBuilder(
    column: $table.actorId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get roomId => $composableBuilder(
    column: $table.roomId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get inputPermission => $composableBuilder(
    column: $table.inputPermission,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get joinedAt => $composableBuilder(
    column: $table.joinedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get leftAt => $composableBuilder(
    column: $table.leftAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedRoomMembersTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedRoomMembersTable> {
  $$CachedRoomMembersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get actorId =>
      $composableBuilder(column: $table.actorId, builder: (column) => column);

  GeneratedColumn<String> get roomId =>
      $composableBuilder(column: $table.roomId, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<String> get inputPermission => $composableBuilder(
    column: $table.inputPermission,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get joinedAt =>
      $composableBuilder(column: $table.joinedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get leftAt =>
      $composableBuilder(column: $table.leftAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$CachedRoomMembersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedRoomMembersTable,
          CachedRoomMember,
          $$CachedRoomMembersTableFilterComposer,
          $$CachedRoomMembersTableOrderingComposer,
          $$CachedRoomMembersTableAnnotationComposer,
          $$CachedRoomMembersTableCreateCompanionBuilder,
          $$CachedRoomMembersTableUpdateCompanionBuilder,
          (
            CachedRoomMember,
            BaseReferences<
              _$AppDatabase,
              $CachedRoomMembersTable,
              CachedRoomMember
            >,
          ),
          CachedRoomMember,
          PrefetchHooks Function()
        > {
  $$CachedRoomMembersTableTableManager(
    _$AppDatabase db,
    $CachedRoomMembersTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedRoomMembersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedRoomMembersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedRoomMembersTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> actorId = const Value.absent(),
                Value<String> roomId = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> role = const Value.absent(),
                Value<String> inputPermission = const Value.absent(),
                Value<DateTime> joinedAt = const Value.absent(),
                Value<DateTime?> leftAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedRoomMembersCompanion(
                actorId: actorId,
                roomId: roomId,
                userId: userId,
                role: role,
                inputPermission: inputPermission,
                joinedAt: joinedAt,
                leftAt: leftAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> actorId = const Value.absent(),
                required String roomId,
                required String userId,
                required String role,
                required String inputPermission,
                required DateTime joinedAt,
                Value<DateTime?> leftAt = const Value.absent(),
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => CachedRoomMembersCompanion.insert(
                actorId: actorId,
                roomId: roomId,
                userId: userId,
                role: role,
                inputPermission: inputPermission,
                joinedAt: joinedAt,
                leftAt: leftAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CachedRoomMembersTable, CachedRoomMember>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $CachedRoomMembersTable,
                    CachedRoomMember
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedRoomMembersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedRoomMembersTable,
      CachedRoomMember,
      $$CachedRoomMembersTableFilterComposer,
      $$CachedRoomMembersTableOrderingComposer,
      $$CachedRoomMembersTableAnnotationComposer,
      $$CachedRoomMembersTableCreateCompanionBuilder,
      $$CachedRoomMembersTableUpdateCompanionBuilder,
      (
        CachedRoomMember,
        BaseReferences<
          _$AppDatabase,
          $CachedRoomMembersTable,
          CachedRoomMember
        >,
      ),
      CachedRoomMember,
      PrefetchHooks Function()
    >;
typedef $$CachedGameSessionsTableCreateCompanionBuilder =
    CachedGameSessionsCompanion Function({
      Value<String> actorId,
      required String id,
      required String roomId,
      required String name,
      required String status,
      required DateTime createdAt,
      Value<DateTime?> startedAt,
      Value<DateTime?> finishedAt,
      required DateTime updatedAt,
      Value<int> version,
      Value<int> rowid,
    });
typedef $$CachedGameSessionsTableUpdateCompanionBuilder =
    CachedGameSessionsCompanion Function({
      Value<String> actorId,
      Value<String> id,
      Value<String> roomId,
      Value<String> name,
      Value<String> status,
      Value<DateTime> createdAt,
      Value<DateTime?> startedAt,
      Value<DateTime?> finishedAt,
      Value<DateTime> updatedAt,
      Value<int> version,
      Value<int> rowid,
    });

class $$CachedGameSessionsTableFilterComposer
    extends Composer<_$AppDatabase, $CachedGameSessionsTable> {
  $$CachedGameSessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get actorId => $composableBuilder(
    column: $table.actorId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get roomId => $composableBuilder(
    column: $table.roomId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get finishedAt => $composableBuilder(
    column: $table.finishedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedGameSessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedGameSessionsTable> {
  $$CachedGameSessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get actorId => $composableBuilder(
    column: $table.actorId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get roomId => $composableBuilder(
    column: $table.roomId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get finishedAt => $composableBuilder(
    column: $table.finishedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedGameSessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedGameSessionsTable> {
  $$CachedGameSessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get actorId =>
      $composableBuilder(column: $table.actorId, builder: (column) => column);

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get roomId =>
      $composableBuilder(column: $table.roomId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get finishedAt => $composableBuilder(
    column: $table.finishedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);
}

class $$CachedGameSessionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedGameSessionsTable,
          CachedGameSession,
          $$CachedGameSessionsTableFilterComposer,
          $$CachedGameSessionsTableOrderingComposer,
          $$CachedGameSessionsTableAnnotationComposer,
          $$CachedGameSessionsTableCreateCompanionBuilder,
          $$CachedGameSessionsTableUpdateCompanionBuilder,
          (
            CachedGameSession,
            BaseReferences<
              _$AppDatabase,
              $CachedGameSessionsTable,
              CachedGameSession
            >,
          ),
          CachedGameSession,
          PrefetchHooks Function()
        > {
  $$CachedGameSessionsTableTableManager(
    _$AppDatabase db,
    $CachedGameSessionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedGameSessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedGameSessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedGameSessionsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> actorId = const Value.absent(),
                Value<String> id = const Value.absent(),
                Value<String> roomId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> startedAt = const Value.absent(),
                Value<DateTime?> finishedAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedGameSessionsCompanion(
                actorId: actorId,
                id: id,
                roomId: roomId,
                name: name,
                status: status,
                createdAt: createdAt,
                startedAt: startedAt,
                finishedAt: finishedAt,
                updatedAt: updatedAt,
                version: version,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> actorId = const Value.absent(),
                required String id,
                required String roomId,
                required String name,
                required String status,
                required DateTime createdAt,
                Value<DateTime?> startedAt = const Value.absent(),
                Value<DateTime?> finishedAt = const Value.absent(),
                required DateTime updatedAt,
                Value<int> version = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedGameSessionsCompanion.insert(
                actorId: actorId,
                id: id,
                roomId: roomId,
                name: name,
                status: status,
                createdAt: createdAt,
                startedAt: startedAt,
                finishedAt: finishedAt,
                updatedAt: updatedAt,
                version: version,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CachedGameSessionsTable, CachedGameSession>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $CachedGameSessionsTable,
                    CachedGameSession
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedGameSessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedGameSessionsTable,
      CachedGameSession,
      $$CachedGameSessionsTableFilterComposer,
      $$CachedGameSessionsTableOrderingComposer,
      $$CachedGameSessionsTableAnnotationComposer,
      $$CachedGameSessionsTableCreateCompanionBuilder,
      $$CachedGameSessionsTableUpdateCompanionBuilder,
      (
        CachedGameSession,
        BaseReferences<
          _$AppDatabase,
          $CachedGameSessionsTable,
          CachedGameSession
        >,
      ),
      CachedGameSession,
      PrefetchHooks Function()
    >;
typedef $$CachedRoundsTableCreateCompanionBuilder =
    CachedRoundsCompanion Function({
      Value<String> actorId,
      required String id,
      required String sessionId,
      required int roundNumber,
      required String createdBy,
      Value<String?> note,
      required DateTime createdAt,
      Value<DateTime?> deletedAt,
      required DateTime updatedAt,
      Value<int> version,
      Value<int> rowid,
    });
typedef $$CachedRoundsTableUpdateCompanionBuilder =
    CachedRoundsCompanion Function({
      Value<String> actorId,
      Value<String> id,
      Value<String> sessionId,
      Value<int> roundNumber,
      Value<String> createdBy,
      Value<String?> note,
      Value<DateTime> createdAt,
      Value<DateTime?> deletedAt,
      Value<DateTime> updatedAt,
      Value<int> version,
      Value<int> rowid,
    });

class $$CachedRoundsTableFilterComposer
    extends Composer<_$AppDatabase, $CachedRoundsTable> {
  $$CachedRoundsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get actorId => $composableBuilder(
    column: $table.actorId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get roundNumber => $composableBuilder(
    column: $table.roundNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdBy => $composableBuilder(
    column: $table.createdBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedRoundsTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedRoundsTable> {
  $$CachedRoundsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get actorId => $composableBuilder(
    column: $table.actorId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get roundNumber => $composableBuilder(
    column: $table.roundNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdBy => $composableBuilder(
    column: $table.createdBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedRoundsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedRoundsTable> {
  $$CachedRoundsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get actorId =>
      $composableBuilder(column: $table.actorId, builder: (column) => column);

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sessionId =>
      $composableBuilder(column: $table.sessionId, builder: (column) => column);

  GeneratedColumn<int> get roundNumber => $composableBuilder(
    column: $table.roundNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get createdBy =>
      $composableBuilder(column: $table.createdBy, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);
}

class $$CachedRoundsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedRoundsTable,
          CachedRound,
          $$CachedRoundsTableFilterComposer,
          $$CachedRoundsTableOrderingComposer,
          $$CachedRoundsTableAnnotationComposer,
          $$CachedRoundsTableCreateCompanionBuilder,
          $$CachedRoundsTableUpdateCompanionBuilder,
          (
            CachedRound,
            BaseReferences<_$AppDatabase, $CachedRoundsTable, CachedRound>,
          ),
          CachedRound,
          PrefetchHooks Function()
        > {
  $$CachedRoundsTableTableManager(_$AppDatabase db, $CachedRoundsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedRoundsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedRoundsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedRoundsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> actorId = const Value.absent(),
                Value<String> id = const Value.absent(),
                Value<String> sessionId = const Value.absent(),
                Value<int> roundNumber = const Value.absent(),
                Value<String> createdBy = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedRoundsCompanion(
                actorId: actorId,
                id: id,
                sessionId: sessionId,
                roundNumber: roundNumber,
                createdBy: createdBy,
                note: note,
                createdAt: createdAt,
                deletedAt: deletedAt,
                updatedAt: updatedAt,
                version: version,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> actorId = const Value.absent(),
                required String id,
                required String sessionId,
                required int roundNumber,
                required String createdBy,
                Value<String?> note = const Value.absent(),
                required DateTime createdAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                required DateTime updatedAt,
                Value<int> version = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedRoundsCompanion.insert(
                actorId: actorId,
                id: id,
                sessionId: sessionId,
                roundNumber: roundNumber,
                createdBy: createdBy,
                note: note,
                createdAt: createdAt,
                deletedAt: deletedAt,
                updatedAt: updatedAt,
                version: version,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CachedRoundsTable, CachedRound>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $CachedRoundsTable,
                    CachedRound
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedRoundsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedRoundsTable,
      CachedRound,
      $$CachedRoundsTableFilterComposer,
      $$CachedRoundsTableOrderingComposer,
      $$CachedRoundsTableAnnotationComposer,
      $$CachedRoundsTableCreateCompanionBuilder,
      $$CachedRoundsTableUpdateCompanionBuilder,
      (
        CachedRound,
        BaseReferences<_$AppDatabase, $CachedRoundsTable, CachedRound>,
      ),
      CachedRound,
      PrefetchHooks Function()
    >;
typedef $$CachedScoreChangesTableCreateCompanionBuilder =
    CachedScoreChangesCompanion Function({
      Value<String> actorId,
      required String id,
      required String roundId,
      required String playerId,
      required int value,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$CachedScoreChangesTableUpdateCompanionBuilder =
    CachedScoreChangesCompanion Function({
      Value<String> actorId,
      Value<String> id,
      Value<String> roundId,
      Value<String> playerId,
      Value<int> value,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$CachedScoreChangesTableFilterComposer
    extends Composer<_$AppDatabase, $CachedScoreChangesTable> {
  $$CachedScoreChangesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get actorId => $composableBuilder(
    column: $table.actorId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get roundId => $composableBuilder(
    column: $table.roundId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get playerId => $composableBuilder(
    column: $table.playerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedScoreChangesTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedScoreChangesTable> {
  $$CachedScoreChangesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get actorId => $composableBuilder(
    column: $table.actorId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get roundId => $composableBuilder(
    column: $table.roundId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get playerId => $composableBuilder(
    column: $table.playerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedScoreChangesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedScoreChangesTable> {
  $$CachedScoreChangesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get actorId =>
      $composableBuilder(column: $table.actorId, builder: (column) => column);

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get roundId =>
      $composableBuilder(column: $table.roundId, builder: (column) => column);

  GeneratedColumn<String> get playerId =>
      $composableBuilder(column: $table.playerId, builder: (column) => column);

  GeneratedColumn<int> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$CachedScoreChangesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedScoreChangesTable,
          CachedScoreChange,
          $$CachedScoreChangesTableFilterComposer,
          $$CachedScoreChangesTableOrderingComposer,
          $$CachedScoreChangesTableAnnotationComposer,
          $$CachedScoreChangesTableCreateCompanionBuilder,
          $$CachedScoreChangesTableUpdateCompanionBuilder,
          (
            CachedScoreChange,
            BaseReferences<
              _$AppDatabase,
              $CachedScoreChangesTable,
              CachedScoreChange
            >,
          ),
          CachedScoreChange,
          PrefetchHooks Function()
        > {
  $$CachedScoreChangesTableTableManager(
    _$AppDatabase db,
    $CachedScoreChangesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedScoreChangesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedScoreChangesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedScoreChangesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> actorId = const Value.absent(),
                Value<String> id = const Value.absent(),
                Value<String> roundId = const Value.absent(),
                Value<String> playerId = const Value.absent(),
                Value<int> value = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedScoreChangesCompanion(
                actorId: actorId,
                id: id,
                roundId: roundId,
                playerId: playerId,
                value: value,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> actorId = const Value.absent(),
                required String id,
                required String roundId,
                required String playerId,
                required int value,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => CachedScoreChangesCompanion.insert(
                actorId: actorId,
                id: id,
                roundId: roundId,
                playerId: playerId,
                value: value,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CachedScoreChangesTable, CachedScoreChange>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $CachedScoreChangesTable,
                    CachedScoreChange
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedScoreChangesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedScoreChangesTable,
      CachedScoreChange,
      $$CachedScoreChangesTableFilterComposer,
      $$CachedScoreChangesTableOrderingComposer,
      $$CachedScoreChangesTableAnnotationComposer,
      $$CachedScoreChangesTableCreateCompanionBuilder,
      $$CachedScoreChangesTableUpdateCompanionBuilder,
      (
        CachedScoreChange,
        BaseReferences<
          _$AppDatabase,
          $CachedScoreChangesTable,
          CachedScoreChange
        >,
      ),
      CachedScoreChange,
      PrefetchHooks Function()
    >;
typedef $$SyncQueueEntriesTableCreateCompanionBuilder =
    SyncQueueEntriesCompanion Function({
      required String operationId,
      Value<String> actorId,
      Value<String> roomId,
      required String entityType,
      required String entityId,
      required String operation,
      required String payloadJson,
      required DateTime createdAt,
      Value<int> sequence,
      Value<int> attemptCount,
      Value<String> status,
      Value<int?> baseVersion,
      Value<String?> dependsOn,
      Value<String?> ackJson,
      Value<String?> lastError,
      Value<DateTime?> nextAttemptAt,
      Value<DateTime?> syncedAt,
      Value<int> rowid,
    });
typedef $$SyncQueueEntriesTableUpdateCompanionBuilder =
    SyncQueueEntriesCompanion Function({
      Value<String> operationId,
      Value<String> actorId,
      Value<String> roomId,
      Value<String> entityType,
      Value<String> entityId,
      Value<String> operation,
      Value<String> payloadJson,
      Value<DateTime> createdAt,
      Value<int> sequence,
      Value<int> attemptCount,
      Value<String> status,
      Value<int?> baseVersion,
      Value<String?> dependsOn,
      Value<String?> ackJson,
      Value<String?> lastError,
      Value<DateTime?> nextAttemptAt,
      Value<DateTime?> syncedAt,
      Value<int> rowid,
    });

class $$SyncQueueEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $SyncQueueEntriesTable> {
  $$SyncQueueEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get operationId => $composableBuilder(
    column: $table.operationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get actorId => $composableBuilder(
    column: $table.actorId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get roomId => $composableBuilder(
    column: $table.roomId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get operation => $composableBuilder(
    column: $table.operation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sequence => $composableBuilder(
    column: $table.sequence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attemptCount => $composableBuilder(
    column: $table.attemptCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get baseVersion => $composableBuilder(
    column: $table.baseVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dependsOn => $composableBuilder(
    column: $table.dependsOn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ackJson => $composableBuilder(
    column: $table.ackJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncQueueEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncQueueEntriesTable> {
  $$SyncQueueEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get operationId => $composableBuilder(
    column: $table.operationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get actorId => $composableBuilder(
    column: $table.actorId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get roomId => $composableBuilder(
    column: $table.roomId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get operation => $composableBuilder(
    column: $table.operation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sequence => $composableBuilder(
    column: $table.sequence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attemptCount => $composableBuilder(
    column: $table.attemptCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get baseVersion => $composableBuilder(
    column: $table.baseVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dependsOn => $composableBuilder(
    column: $table.dependsOn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ackJson => $composableBuilder(
    column: $table.ackJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncQueueEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncQueueEntriesTable> {
  $$SyncQueueEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get operationId => $composableBuilder(
    column: $table.operationId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get actorId =>
      $composableBuilder(column: $table.actorId, builder: (column) => column);

  GeneratedColumn<String> get roomId =>
      $composableBuilder(column: $table.roomId, builder: (column) => column);

  GeneratedColumn<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<String> get operation =>
      $composableBuilder(column: $table.operation, builder: (column) => column);

  GeneratedColumn<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get sequence =>
      $composableBuilder(column: $table.sequence, builder: (column) => column);

  GeneratedColumn<int> get attemptCount => $composableBuilder(
    column: $table.attemptCount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get baseVersion => $composableBuilder(
    column: $table.baseVersion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get dependsOn =>
      $composableBuilder(column: $table.dependsOn, builder: (column) => column);

  GeneratedColumn<String> get ackJson =>
      $composableBuilder(column: $table.ackJson, builder: (column) => column);

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);

  GeneratedColumn<DateTime> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);
}

class $$SyncQueueEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncQueueEntriesTable,
          SyncQueueEntry,
          $$SyncQueueEntriesTableFilterComposer,
          $$SyncQueueEntriesTableOrderingComposer,
          $$SyncQueueEntriesTableAnnotationComposer,
          $$SyncQueueEntriesTableCreateCompanionBuilder,
          $$SyncQueueEntriesTableUpdateCompanionBuilder,
          (
            SyncQueueEntry,
            BaseReferences<
              _$AppDatabase,
              $SyncQueueEntriesTable,
              SyncQueueEntry
            >,
          ),
          SyncQueueEntry,
          PrefetchHooks Function()
        > {
  $$SyncQueueEntriesTableTableManager(
    _$AppDatabase db,
    $SyncQueueEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncQueueEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncQueueEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncQueueEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> operationId = const Value.absent(),
                Value<String> actorId = const Value.absent(),
                Value<String> roomId = const Value.absent(),
                Value<String> entityType = const Value.absent(),
                Value<String> entityId = const Value.absent(),
                Value<String> operation = const Value.absent(),
                Value<String> payloadJson = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> sequence = const Value.absent(),
                Value<int> attemptCount = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int?> baseVersion = const Value.absent(),
                Value<String?> dependsOn = const Value.absent(),
                Value<String?> ackJson = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<DateTime?> nextAttemptAt = const Value.absent(),
                Value<DateTime?> syncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncQueueEntriesCompanion(
                operationId: operationId,
                actorId: actorId,
                roomId: roomId,
                entityType: entityType,
                entityId: entityId,
                operation: operation,
                payloadJson: payloadJson,
                createdAt: createdAt,
                sequence: sequence,
                attemptCount: attemptCount,
                status: status,
                baseVersion: baseVersion,
                dependsOn: dependsOn,
                ackJson: ackJson,
                lastError: lastError,
                nextAttemptAt: nextAttemptAt,
                syncedAt: syncedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String operationId,
                Value<String> actorId = const Value.absent(),
                Value<String> roomId = const Value.absent(),
                required String entityType,
                required String entityId,
                required String operation,
                required String payloadJson,
                required DateTime createdAt,
                Value<int> sequence = const Value.absent(),
                Value<int> attemptCount = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int?> baseVersion = const Value.absent(),
                Value<String?> dependsOn = const Value.absent(),
                Value<String?> ackJson = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<DateTime?> nextAttemptAt = const Value.absent(),
                Value<DateTime?> syncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncQueueEntriesCompanion.insert(
                operationId: operationId,
                actorId: actorId,
                roomId: roomId,
                entityType: entityType,
                entityId: entityId,
                operation: operation,
                payloadJson: payloadJson,
                createdAt: createdAt,
                sequence: sequence,
                attemptCount: attemptCount,
                status: status,
                baseVersion: baseVersion,
                dependsOn: dependsOn,
                ackJson: ackJson,
                lastError: lastError,
                nextAttemptAt: nextAttemptAt,
                syncedAt: syncedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SyncQueueEntriesTable, SyncQueueEntry>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $SyncQueueEntriesTable,
                    SyncQueueEntry
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncQueueEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncQueueEntriesTable,
      SyncQueueEntry,
      $$SyncQueueEntriesTableFilterComposer,
      $$SyncQueueEntriesTableOrderingComposer,
      $$SyncQueueEntriesTableAnnotationComposer,
      $$SyncQueueEntriesTableCreateCompanionBuilder,
      $$SyncQueueEntriesTableUpdateCompanionBuilder,
      (
        SyncQueueEntry,
        BaseReferences<_$AppDatabase, $SyncQueueEntriesTable, SyncQueueEntry>,
      ),
      SyncQueueEntry,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$CachedUsersTableTableManager get cachedUsers =>
      $$CachedUsersTableTableManager(_db, _db.cachedUsers);
  $$CachedRoomsTableTableManager get cachedRooms =>
      $$CachedRoomsTableTableManager(_db, _db.cachedRooms);
  $$CachedRoomMembersTableTableManager get cachedRoomMembers =>
      $$CachedRoomMembersTableTableManager(_db, _db.cachedRoomMembers);
  $$CachedGameSessionsTableTableManager get cachedGameSessions =>
      $$CachedGameSessionsTableTableManager(_db, _db.cachedGameSessions);
  $$CachedRoundsTableTableManager get cachedRounds =>
      $$CachedRoundsTableTableManager(_db, _db.cachedRounds);
  $$CachedScoreChangesTableTableManager get cachedScoreChanges =>
      $$CachedScoreChangesTableTableManager(_db, _db.cachedScoreChanges);
  $$SyncQueueEntriesTableTableManager get syncQueueEntries =>
      $$SyncQueueEntriesTableTableManager(_db, _db.syncQueueEntries);
}
