import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 主页当前选中 tab 的索引（IndexedStack 常驻所有 tab，各 tab 据此实现
/// 懒加载/暂停后台轮询等可见性相关逻辑）。
final homeTabProvider = StateProvider<int>((_) => 0);
