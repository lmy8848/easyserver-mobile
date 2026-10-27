// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'cron_task.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

CronTask _$CronTaskFromJson(Map<String, dynamic> json) {
  return _CronTask.fromJson(json);
}

/// @nodoc
mixin _$CronTask {
  String get name => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  String get schedule => throw _privateConstructorUsedError;
  bool get persistent => throw _privateConstructorUsedError;
  bool get enabled => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  @JsonKey(name: 'last_run')
  String get lastRun => throw _privateConstructorUsedError;
  @JsonKey(name: 'last_result')
  String get lastResult => throw _privateConstructorUsedError;
  @JsonKey(name: 'next_run')
  String get nextRun => throw _privateConstructorUsedError;
  String get command => throw _privateConstructorUsedError;
  int get timeout => throw _privateConstructorUsedError;
  @JsonKey(name: 'max_retry')
  int get maxRetry => throw _privateConstructorUsedError;
  @JsonKey(name: 'env_vars')
  String get envVars => throw _privateConstructorUsedError;
  @JsonKey(name: 'work_dir')
  String get workDir => throw _privateConstructorUsedError;
  String get runtime => throw _privateConstructorUsedError;

  /// Serializes this CronTask to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CronTask
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CronTaskCopyWith<CronTask> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CronTaskCopyWith<$Res> {
  factory $CronTaskCopyWith(CronTask value, $Res Function(CronTask) then) =
      _$CronTaskCopyWithImpl<$Res, CronTask>;
  @useResult
  $Res call(
      {String name,
      String description,
      String schedule,
      bool persistent,
      bool enabled,
      String status,
      @JsonKey(name: 'last_run') String lastRun,
      @JsonKey(name: 'last_result') String lastResult,
      @JsonKey(name: 'next_run') String nextRun,
      String command,
      int timeout,
      @JsonKey(name: 'max_retry') int maxRetry,
      @JsonKey(name: 'env_vars') String envVars,
      @JsonKey(name: 'work_dir') String workDir,
      String runtime});
}

/// @nodoc
class _$CronTaskCopyWithImpl<$Res, $Val extends CronTask>
    implements $CronTaskCopyWith<$Res> {
  _$CronTaskCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CronTask
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? description = null,
    Object? schedule = null,
    Object? persistent = null,
    Object? enabled = null,
    Object? status = null,
    Object? lastRun = null,
    Object? lastResult = null,
    Object? nextRun = null,
    Object? command = null,
    Object? timeout = null,
    Object? maxRetry = null,
    Object? envVars = null,
    Object? workDir = null,
    Object? runtime = null,
  }) {
    return _then(_value.copyWith(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      schedule: null == schedule
          ? _value.schedule
          : schedule // ignore: cast_nullable_to_non_nullable
              as String,
      persistent: null == persistent
          ? _value.persistent
          : persistent // ignore: cast_nullable_to_non_nullable
              as bool,
      enabled: null == enabled
          ? _value.enabled
          : enabled // ignore: cast_nullable_to_non_nullable
              as bool,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      lastRun: null == lastRun
          ? _value.lastRun
          : lastRun // ignore: cast_nullable_to_non_nullable
              as String,
      lastResult: null == lastResult
          ? _value.lastResult
          : lastResult // ignore: cast_nullable_to_non_nullable
              as String,
      nextRun: null == nextRun
          ? _value.nextRun
          : nextRun // ignore: cast_nullable_to_non_nullable
              as String,
      command: null == command
          ? _value.command
          : command // ignore: cast_nullable_to_non_nullable
              as String,
      timeout: null == timeout
          ? _value.timeout
          : timeout // ignore: cast_nullable_to_non_nullable
              as int,
      maxRetry: null == maxRetry
          ? _value.maxRetry
          : maxRetry // ignore: cast_nullable_to_non_nullable
              as int,
      envVars: null == envVars
          ? _value.envVars
          : envVars // ignore: cast_nullable_to_non_nullable
              as String,
      workDir: null == workDir
          ? _value.workDir
          : workDir // ignore: cast_nullable_to_non_nullable
              as String,
      runtime: null == runtime
          ? _value.runtime
          : runtime // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$CronTaskImplCopyWith<$Res>
    implements $CronTaskCopyWith<$Res> {
  factory _$$CronTaskImplCopyWith(
          _$CronTaskImpl value, $Res Function(_$CronTaskImpl) then) =
      __$$CronTaskImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String name,
      String description,
      String schedule,
      bool persistent,
      bool enabled,
      String status,
      @JsonKey(name: 'last_run') String lastRun,
      @JsonKey(name: 'last_result') String lastResult,
      @JsonKey(name: 'next_run') String nextRun,
      String command,
      int timeout,
      @JsonKey(name: 'max_retry') int maxRetry,
      @JsonKey(name: 'env_vars') String envVars,
      @JsonKey(name: 'work_dir') String workDir,
      String runtime});
}

/// @nodoc
class __$$CronTaskImplCopyWithImpl<$Res>
    extends _$CronTaskCopyWithImpl<$Res, _$CronTaskImpl>
    implements _$$CronTaskImplCopyWith<$Res> {
  __$$CronTaskImplCopyWithImpl(
      _$CronTaskImpl _value, $Res Function(_$CronTaskImpl) _then)
      : super(_value, _then);

  /// Create a copy of CronTask
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? description = null,
    Object? schedule = null,
    Object? persistent = null,
    Object? enabled = null,
    Object? status = null,
    Object? lastRun = null,
    Object? lastResult = null,
    Object? nextRun = null,
    Object? command = null,
    Object? timeout = null,
    Object? maxRetry = null,
    Object? envVars = null,
    Object? workDir = null,
    Object? runtime = null,
  }) {
    return _then(_$CronTaskImpl(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      schedule: null == schedule
          ? _value.schedule
          : schedule // ignore: cast_nullable_to_non_nullable
              as String,
      persistent: null == persistent
          ? _value.persistent
          : persistent // ignore: cast_nullable_to_non_nullable
              as bool,
      enabled: null == enabled
          ? _value.enabled
          : enabled // ignore: cast_nullable_to_non_nullable
              as bool,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      lastRun: null == lastRun
          ? _value.lastRun
          : lastRun // ignore: cast_nullable_to_non_nullable
              as String,
      lastResult: null == lastResult
          ? _value.lastResult
          : lastResult // ignore: cast_nullable_to_non_nullable
              as String,
      nextRun: null == nextRun
          ? _value.nextRun
          : nextRun // ignore: cast_nullable_to_non_nullable
              as String,
      command: null == command
          ? _value.command
          : command // ignore: cast_nullable_to_non_nullable
              as String,
      timeout: null == timeout
          ? _value.timeout
          : timeout // ignore: cast_nullable_to_non_nullable
              as int,
      maxRetry: null == maxRetry
          ? _value.maxRetry
          : maxRetry // ignore: cast_nullable_to_non_nullable
              as int,
      envVars: null == envVars
          ? _value.envVars
          : envVars // ignore: cast_nullable_to_non_nullable
              as String,
      workDir: null == workDir
          ? _value.workDir
          : workDir // ignore: cast_nullable_to_non_nullable
              as String,
      runtime: null == runtime
          ? _value.runtime
          : runtime // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$CronTaskImpl implements _CronTask {
  const _$CronTaskImpl(
      {required this.name,
      this.description = '',
      required this.schedule,
      this.persistent = false,
      this.enabled = false,
      this.status = '',
      @JsonKey(name: 'last_run') this.lastRun = '',
      @JsonKey(name: 'last_result') this.lastResult = '',
      @JsonKey(name: 'next_run') this.nextRun = '',
      this.command = '',
      this.timeout = 0,
      @JsonKey(name: 'max_retry') this.maxRetry = 0,
      @JsonKey(name: 'env_vars') this.envVars = '',
      @JsonKey(name: 'work_dir') this.workDir = '',
      this.runtime = ''});

  factory _$CronTaskImpl.fromJson(Map<String, dynamic> json) =>
      _$$CronTaskImplFromJson(json);

  @override
  final String name;
  @override
  @JsonKey()
  final String description;
  @override
  final String schedule;
  @override
  @JsonKey()
  final bool persistent;
  @override
  @JsonKey()
  final bool enabled;
  @override
  @JsonKey()
  final String status;
  @override
  @JsonKey(name: 'last_run')
  final String lastRun;
  @override
  @JsonKey(name: 'last_result')
  final String lastResult;
  @override
  @JsonKey(name: 'next_run')
  final String nextRun;
  @override
  @JsonKey()
  final String command;
  @override
  @JsonKey()
  final int timeout;
  @override
  @JsonKey(name: 'max_retry')
  final int maxRetry;
  @override
  @JsonKey(name: 'env_vars')
  final String envVars;
  @override
  @JsonKey(name: 'work_dir')
  final String workDir;
  @override
  @JsonKey()
  final String runtime;

  @override
  String toString() {
    return 'CronTask(name: $name, description: $description, schedule: $schedule, persistent: $persistent, enabled: $enabled, status: $status, lastRun: $lastRun, lastResult: $lastResult, nextRun: $nextRun, command: $command, timeout: $timeout, maxRetry: $maxRetry, envVars: $envVars, workDir: $workDir, runtime: $runtime)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CronTaskImpl &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.schedule, schedule) ||
                other.schedule == schedule) &&
            (identical(other.persistent, persistent) ||
                other.persistent == persistent) &&
            (identical(other.enabled, enabled) || other.enabled == enabled) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.lastRun, lastRun) || other.lastRun == lastRun) &&
            (identical(other.lastResult, lastResult) ||
                other.lastResult == lastResult) &&
            (identical(other.nextRun, nextRun) || other.nextRun == nextRun) &&
            (identical(other.command, command) || other.command == command) &&
            (identical(other.timeout, timeout) || other.timeout == timeout) &&
            (identical(other.maxRetry, maxRetry) ||
                other.maxRetry == maxRetry) &&
            (identical(other.envVars, envVars) || other.envVars == envVars) &&
            (identical(other.workDir, workDir) || other.workDir == workDir) &&
            (identical(other.runtime, runtime) || other.runtime == runtime));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      name,
      description,
      schedule,
      persistent,
      enabled,
      status,
      lastRun,
      lastResult,
      nextRun,
      command,
      timeout,
      maxRetry,
      envVars,
      workDir,
      runtime);

  /// Create a copy of CronTask
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CronTaskImplCopyWith<_$CronTaskImpl> get copyWith =>
      __$$CronTaskImplCopyWithImpl<_$CronTaskImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CronTaskImplToJson(
      this,
    );
  }
}

abstract class _CronTask implements CronTask {
  const factory _CronTask(
      {required final String name,
      final String description,
      required final String schedule,
      final bool persistent,
      final bool enabled,
      final String status,
      @JsonKey(name: 'last_run') final String lastRun,
      @JsonKey(name: 'last_result') final String lastResult,
      @JsonKey(name: 'next_run') final String nextRun,
      final String command,
      final int timeout,
      @JsonKey(name: 'max_retry') final int maxRetry,
      @JsonKey(name: 'env_vars') final String envVars,
      @JsonKey(name: 'work_dir') final String workDir,
      final String runtime}) = _$CronTaskImpl;

  factory _CronTask.fromJson(Map<String, dynamic> json) =
      _$CronTaskImpl.fromJson;

  @override
  String get name;
  @override
  String get description;
  @override
  String get schedule;
  @override
  bool get persistent;
  @override
  bool get enabled;
  @override
  String get status;
  @override
  @JsonKey(name: 'last_run')
  String get lastRun;
  @override
  @JsonKey(name: 'last_result')
  String get lastResult;
  @override
  @JsonKey(name: 'next_run')
  String get nextRun;
  @override
  String get command;
  @override
  int get timeout;
  @override
  @JsonKey(name: 'max_retry')
  int get maxRetry;
  @override
  @JsonKey(name: 'env_vars')
  String get envVars;
  @override
  @JsonKey(name: 'work_dir')
  String get workDir;
  @override
  String get runtime;

  /// Create a copy of CronTask
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CronTaskImplCopyWith<_$CronTaskImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

CronRun _$CronRunFromJson(Map<String, dynamic> json) {
  return _CronRun.fromJson(json);
}

/// @nodoc
mixin _$CronRun {
  @JsonKey(name: 'invocation_id')
  String get invocationId => throw _privateConstructorUsedError;
  @JsonKey(name: 'started_at')
  String get startedAt => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  List<CronLogLine> get logs => throw _privateConstructorUsedError;

  /// Serializes this CronRun to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CronRun
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CronRunCopyWith<CronRun> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CronRunCopyWith<$Res> {
  factory $CronRunCopyWith(CronRun value, $Res Function(CronRun) then) =
      _$CronRunCopyWithImpl<$Res, CronRun>;
  @useResult
  $Res call(
      {@JsonKey(name: 'invocation_id') String invocationId,
      @JsonKey(name: 'started_at') String startedAt,
      String status,
      List<CronLogLine> logs});
}

/// @nodoc
class _$CronRunCopyWithImpl<$Res, $Val extends CronRun>
    implements $CronRunCopyWith<$Res> {
  _$CronRunCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CronRun
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? invocationId = null,
    Object? startedAt = null,
    Object? status = null,
    Object? logs = null,
  }) {
    return _then(_value.copyWith(
      invocationId: null == invocationId
          ? _value.invocationId
          : invocationId // ignore: cast_nullable_to_non_nullable
              as String,
      startedAt: null == startedAt
          ? _value.startedAt
          : startedAt // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      logs: null == logs
          ? _value.logs
          : logs // ignore: cast_nullable_to_non_nullable
              as List<CronLogLine>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$CronRunImplCopyWith<$Res> implements $CronRunCopyWith<$Res> {
  factory _$$CronRunImplCopyWith(
          _$CronRunImpl value, $Res Function(_$CronRunImpl) then) =
      __$$CronRunImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'invocation_id') String invocationId,
      @JsonKey(name: 'started_at') String startedAt,
      String status,
      List<CronLogLine> logs});
}

/// @nodoc
class __$$CronRunImplCopyWithImpl<$Res>
    extends _$CronRunCopyWithImpl<$Res, _$CronRunImpl>
    implements _$$CronRunImplCopyWith<$Res> {
  __$$CronRunImplCopyWithImpl(
      _$CronRunImpl _value, $Res Function(_$CronRunImpl) _then)
      : super(_value, _then);

  /// Create a copy of CronRun
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? invocationId = null,
    Object? startedAt = null,
    Object? status = null,
    Object? logs = null,
  }) {
    return _then(_$CronRunImpl(
      invocationId: null == invocationId
          ? _value.invocationId
          : invocationId // ignore: cast_nullable_to_non_nullable
              as String,
      startedAt: null == startedAt
          ? _value.startedAt
          : startedAt // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      logs: null == logs
          ? _value._logs
          : logs // ignore: cast_nullable_to_non_nullable
              as List<CronLogLine>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$CronRunImpl implements _CronRun {
  const _$CronRunImpl(
      {@JsonKey(name: 'invocation_id') this.invocationId = '',
      @JsonKey(name: 'started_at') this.startedAt = '',
      this.status = '',
      final List<CronLogLine> logs = const <CronLogLine>[]})
      : _logs = logs;

  factory _$CronRunImpl.fromJson(Map<String, dynamic> json) =>
      _$$CronRunImplFromJson(json);

  @override
  @JsonKey(name: 'invocation_id')
  final String invocationId;
  @override
  @JsonKey(name: 'started_at')
  final String startedAt;
  @override
  @JsonKey()
  final String status;
  final List<CronLogLine> _logs;
  @override
  @JsonKey()
  List<CronLogLine> get logs {
    if (_logs is EqualUnmodifiableListView) return _logs;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_logs);
  }

  @override
  String toString() {
    return 'CronRun(invocationId: $invocationId, startedAt: $startedAt, status: $status, logs: $logs)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CronRunImpl &&
            (identical(other.invocationId, invocationId) ||
                other.invocationId == invocationId) &&
            (identical(other.startedAt, startedAt) ||
                other.startedAt == startedAt) &&
            (identical(other.status, status) || other.status == status) &&
            const DeepCollectionEquality().equals(other._logs, _logs));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, invocationId, startedAt, status,
      const DeepCollectionEquality().hash(_logs));

  /// Create a copy of CronRun
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CronRunImplCopyWith<_$CronRunImpl> get copyWith =>
      __$$CronRunImplCopyWithImpl<_$CronRunImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CronRunImplToJson(
      this,
    );
  }
}

abstract class _CronRun implements CronRun {
  const factory _CronRun(
      {@JsonKey(name: 'invocation_id') final String invocationId,
      @JsonKey(name: 'started_at') final String startedAt,
      final String status,
      final List<CronLogLine> logs}) = _$CronRunImpl;

  factory _CronRun.fromJson(Map<String, dynamic> json) = _$CronRunImpl.fromJson;

  @override
  @JsonKey(name: 'invocation_id')
  String get invocationId;
  @override
  @JsonKey(name: 'started_at')
  String get startedAt;
  @override
  String get status;
  @override
  List<CronLogLine> get logs;

  /// Create a copy of CronRun
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CronRunImplCopyWith<_$CronRunImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

CronLogLine _$CronLogLineFromJson(Map<String, dynamic> json) {
  return _CronLogLine.fromJson(json);
}

/// @nodoc
mixin _$CronLogLine {
  String get time => throw _privateConstructorUsedError;
  String get message => throw _privateConstructorUsedError;
  String get priority => throw _privateConstructorUsedError;

  /// Serializes this CronLogLine to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CronLogLine
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CronLogLineCopyWith<CronLogLine> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CronLogLineCopyWith<$Res> {
  factory $CronLogLineCopyWith(
          CronLogLine value, $Res Function(CronLogLine) then) =
      _$CronLogLineCopyWithImpl<$Res, CronLogLine>;
  @useResult
  $Res call({String time, String message, String priority});
}

/// @nodoc
class _$CronLogLineCopyWithImpl<$Res, $Val extends CronLogLine>
    implements $CronLogLineCopyWith<$Res> {
  _$CronLogLineCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CronLogLine
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? time = null,
    Object? message = null,
    Object? priority = null,
  }) {
    return _then(_value.copyWith(
      time: null == time
          ? _value.time
          : time // ignore: cast_nullable_to_non_nullable
              as String,
      message: null == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
      priority: null == priority
          ? _value.priority
          : priority // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$CronLogLineImplCopyWith<$Res>
    implements $CronLogLineCopyWith<$Res> {
  factory _$$CronLogLineImplCopyWith(
          _$CronLogLineImpl value, $Res Function(_$CronLogLineImpl) then) =
      __$$CronLogLineImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String time, String message, String priority});
}

/// @nodoc
class __$$CronLogLineImplCopyWithImpl<$Res>
    extends _$CronLogLineCopyWithImpl<$Res, _$CronLogLineImpl>
    implements _$$CronLogLineImplCopyWith<$Res> {
  __$$CronLogLineImplCopyWithImpl(
      _$CronLogLineImpl _value, $Res Function(_$CronLogLineImpl) _then)
      : super(_value, _then);

  /// Create a copy of CronLogLine
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? time = null,
    Object? message = null,
    Object? priority = null,
  }) {
    return _then(_$CronLogLineImpl(
      time: null == time
          ? _value.time
          : time // ignore: cast_nullable_to_non_nullable
              as String,
      message: null == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
      priority: null == priority
          ? _value.priority
          : priority // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$CronLogLineImpl implements _CronLogLine {
  const _$CronLogLineImpl(
      {this.time = '', this.message = '', this.priority = ''});

  factory _$CronLogLineImpl.fromJson(Map<String, dynamic> json) =>
      _$$CronLogLineImplFromJson(json);

  @override
  @JsonKey()
  final String time;
  @override
  @JsonKey()
  final String message;
  @override
  @JsonKey()
  final String priority;

  @override
  String toString() {
    return 'CronLogLine(time: $time, message: $message, priority: $priority)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CronLogLineImpl &&
            (identical(other.time, time) || other.time == time) &&
            (identical(other.message, message) || other.message == message) &&
            (identical(other.priority, priority) ||
                other.priority == priority));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, time, message, priority);

  /// Create a copy of CronLogLine
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CronLogLineImplCopyWith<_$CronLogLineImpl> get copyWith =>
      __$$CronLogLineImplCopyWithImpl<_$CronLogLineImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CronLogLineImplToJson(
      this,
    );
  }
}

abstract class _CronLogLine implements CronLogLine {
  const factory _CronLogLine(
      {final String time,
      final String message,
      final String priority}) = _$CronLogLineImpl;

  factory _CronLogLine.fromJson(Map<String, dynamic> json) =
      _$CronLogLineImpl.fromJson;

  @override
  String get time;
  @override
  String get message;
  @override
  String get priority;

  /// Create a copy of CronLogLine
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CronLogLineImplCopyWith<_$CronLogLineImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
