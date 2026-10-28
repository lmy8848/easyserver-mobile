import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

final _lastPush = <String, DateTime>{};

/// 防连点的 push：同一 location 在 [window] 内只入栈一次。
///
/// 抽屉/列表项等入口双击会 push 两个相同页面，此封装按 location 去重。
/// 需要传参的 location 自带 query，天然按参数区分。
void pushOnce(BuildContext context, String location, {Duration window = const Duration(milliseconds: 600)}) {
  final now = DateTime.now();
  final last = _lastPush[location];
  if (last != null && now.difference(last) < window) return;
  _lastPush[location] = now;
  context.push(location);
}
