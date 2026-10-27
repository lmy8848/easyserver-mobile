// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cron_task.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CronTaskImpl _$$CronTaskImplFromJson(Map<String, dynamic> json) =>
    _$CronTaskImpl(
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      schedule: json['schedule'] as String,
      persistent: json['persistent'] as bool? ?? false,
      enabled: json['enabled'] as bool? ?? false,
      status: json['status'] as String? ?? '',
      lastRun: json['last_run'] as String? ?? '',
      lastResult: json['last_result'] as String? ?? '',
      nextRun: json['next_run'] as String? ?? '',
      command: json['command'] as String? ?? '',
      timeout: (json['timeout'] as num?)?.toInt() ?? 0,
      maxRetry: (json['max_retry'] as num?)?.toInt() ?? 0,
      envVars: json['env_vars'] as String? ?? '',
      workDir: json['work_dir'] as String? ?? '',
      runtime: json['runtime'] as String? ?? '',
    );

Map<String, dynamic> _$$CronTaskImplToJson(_$CronTaskImpl instance) =>
    <String, dynamic>{
      'name': instance.name,
      'description': instance.description,
      'schedule': instance.schedule,
      'persistent': instance.persistent,
      'enabled': instance.enabled,
      'status': instance.status,
      'last_run': instance.lastRun,
      'last_result': instance.lastResult,
      'next_run': instance.nextRun,
      'command': instance.command,
      'timeout': instance.timeout,
      'max_retry': instance.maxRetry,
      'env_vars': instance.envVars,
      'work_dir': instance.workDir,
      'runtime': instance.runtime,
    };

_$CronRunImpl _$$CronRunImplFromJson(Map<String, dynamic> json) =>
    _$CronRunImpl(
      invocationId: json['invocation_id'] as String? ?? '',
      startedAt: json['started_at'] as String? ?? '',
      status: json['status'] as String? ?? '',
      logs: (json['logs'] as List<dynamic>?)
              ?.map((e) => CronLogLine.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <CronLogLine>[],
    );

Map<String, dynamic> _$$CronRunImplToJson(_$CronRunImpl instance) =>
    <String, dynamic>{
      'invocation_id': instance.invocationId,
      'started_at': instance.startedAt,
      'status': instance.status,
      'logs': instance.logs,
    };

_$CronLogLineImpl _$$CronLogLineImplFromJson(Map<String, dynamic> json) =>
    _$CronLogLineImpl(
      time: json['time'] as String? ?? '',
      message: json['message'] as String? ?? '',
      priority: json['priority'] as String? ?? '',
    );

Map<String, dynamic> _$$CronLogLineImplToJson(_$CronLogLineImpl instance) =>
    <String, dynamic>{
      'time': instance.time,
      'message': instance.message,
      'priority': instance.priority,
    };
