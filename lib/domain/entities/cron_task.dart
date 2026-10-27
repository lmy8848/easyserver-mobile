import 'package:freezed_annotation/freezed_annotation.dart';

part 'cron_task.freezed.dart';
part 'cron_task.g.dart';

/// 定时任务（后端 internal/domain/cron.CronTask）
@freezed
class CronTask with _$CronTask {
  const factory CronTask({
    required String name,
    @Default('') String description,
    required String schedule,
    @Default(false) bool persistent,
    @Default(false) bool enabled,
    @Default('') String status,
    @JsonKey(name: 'last_run') @Default('') String lastRun,
    @JsonKey(name: 'last_result') @Default('') String lastResult,
    @JsonKey(name: 'next_run') @Default('') String nextRun,
    @Default('') String command,
    @Default(0) int timeout,
    @JsonKey(name: 'max_retry') @Default(0) int maxRetry,
    @JsonKey(name: 'env_vars') @Default('') String envVars,
    @JsonKey(name: 'work_dir') @Default('') String workDir,
    @Default('') String runtime,
  }) = _CronTask;

  factory CronTask.fromJson(Map<String, dynamic> json) =>
      _$CronTaskFromJson(json);
}

/// 一次执行记录（后端 cron.CronRun）
@freezed
class CronRun with _$CronRun {
  const factory CronRun({
    @JsonKey(name: 'invocation_id') @Default('') String invocationId,
    @JsonKey(name: 'started_at') @Default('') String startedAt,
    @Default('') String status,
    @Default(<CronLogLine>[]) List<CronLogLine> logs,
  }) = _CronRun;

  factory CronRun.fromJson(Map<String, dynamic> json) =>
      _$CronRunFromJson(json);
}

/// 执行日志行（journald）
@freezed
class CronLogLine with _$CronLogLine {
  const factory CronLogLine({
    @Default('') String time,
    @Default('') String message,
    @Default('') String priority,
  }) = _CronLogLine;

  factory CronLogLine.fromJson(Map<String, dynamic> json) =>
      _$CronLogLineFromJson(json);
}

/// 新建/更新任务的请求体。更新时后端按字段可选处理，这里统一发全量。
class CronTaskInput {
  final String name;
  final String description;
  final String schedule;
  final String command;
  final bool persistent;
  final int timeout;
  final int maxRetry;
  final String envVars;
  final String workDir;

  const CronTaskInput({
    required this.name,
    this.description = '',
    required this.schedule,
    required this.command,
    this.persistent = false,
    this.timeout = 0,
    this.maxRetry = 0,
    this.envVars = '',
    this.workDir = '',
  });

  factory CronTaskInput.fromTask(CronTask t) => CronTaskInput(
        name: t.name,
        description: t.description,
        schedule: t.schedule,
        command: t.command,
        persistent: t.persistent,
        timeout: t.timeout,
        maxRetry: t.maxRetry,
        envVars: t.envVars,
        workDir: t.workDir,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'schedule': schedule,
        'command': command,
        'persistent': persistent,
        'timeout': timeout,
        'max_retry': maxRetry,
        'env_vars': envVars,
        'work_dir': workDir,
      };
}
