# EasyServer Mobile

[EasyServer](https://github.com/lmy8848/easyserver) Linux 服务器管理面板的官方移动客户端（Flutter）。

## 功能

- **登录**：账号密码（含 TOTP 两步验证/备用码）+ 扫码授权 Web 端登录（扫面板二维码确认）
- **仪表盘**：CPU/内存/磁盘/网络实时监控与历史图表
- **服务**：systemd 服务启停/重启/开机自启/日志
- **终端**：Web 终端（WebSocket PTY，ANSI 行式展示）
- **文件**：浏览/编辑/上传/下载/压缩解压/权限修改
- **通知中心**：未读角标 + 30s 轮询 + 新通知提醒
- **账户与安全**：TOTP 启用/禁用（备用码展示）、登录会话管理（踢出）、修改密码

## 技术栈

Flutter 3.x · Riverpod（状态）· go_router（导航）· dio（REST）· web_socket_channel（WS）
· freezed/json_serializable（模型）· mobile_scanner（扫码）· flutter_secure_storage（token 加密存储）

## 架构（Clean Architecture）

```
lib/
├── data/           # 数据层：dio/web_socket 客户端、DTO、repository 实现
├── domain/         # 领域层：实体（freezed）、repository 接口、用例
├── presentation/   # 表现层：Riverpod providers、screens、widgets
└── di/             # 装配：providers（依赖注入）、router
```

## 与面板的对接协议

- **REST**：`POST /api/auth/login` 带 `client_type: "mobile"`（响应体返回 token；Web 端走 HttpOnly Cookie）+ `device_id`/`device_info`（设备绑定）；此后请求携带 `Authorization: Bearer <token>`
- **WS 认证**：`Sec-WebSocket-Protocol: token, <jwt>` 子协议携带凭据
- **终端**：`/ws/terminal`（服务端自动建会话；PTY 输出为原始文本帧，输入为 JSON `{type:'input'|'resize'}`）
- **扫码登录**：扫描 `esqr:<token>` 格式二维码 → `POST /api/auth/qr/confirm`（需已登录 JWT）

面板 API 详见 [API 参考](https://lmy8848.github.io/easyserver/api-reference)。

## 开发

```bash
flutter pub get
dart analyze          # 静态检查（0 issues 为基线）
flutter run           # 连接模拟器/设备运行
flutter test          # 单元与组件测试
```

配置服务器地址：App 内「服务器配置」页（持久化于 secure storage）。

## 目录约定

- 手写代码与生成代码并存：`*.freezed.dart` / `*.g.dart` 为 build_runner 产物，勿手改
  （模型变更后执行 `dart run build_runner build --delete-conflicting-outputs`）
- Widget 复用组件位于 `lib/presentation/widgets/`
