import 'dart:convert';
import 'dart:io';

import '../../core/logger/app_logger.dart';

/// 局域网传文件服务：手机上启动 HTTP 服务，电脑/其它设备通过浏览器
/// 访问即可浏览、下载、上传手机文件。
///
/// 安全模型：
/// - 访问令牌：所有请求必须携带 ?token=（或 X-Token 头），错误 403
/// - 路径穿越防护：规范化后必须位于共享根目录内
/// - 仅绑定局域网接口（0.0.0.0，路由器 NAT 下外网不可达）
class LanShareServer {
  LanShareServer._();
  static final LanShareServer instance = LanShareServer._();

  HttpServer? _server;
  String _token = '';
  String _root = '/storage/emulated/0';
  final _activeConnections = <int>{};

  bool get running => _server != null;
  String get token => _token;
  String get root => _root;

  Future<String> start({required String token, int port = 8090}) async {
    if (running) return 'already-running';
    _token = token;

    final rootDir = Directory(_root);
    if (!await rootDir.exists()) {
      _root = Directory.systemTemp.path;
    }

    final server = await HttpServer.bind(InternetAddress.anyIPv4, port);
    _server = server;
    server.listen(_handle, onError: (e) {
      AppLogger.w('局域网分享服务异常: $e');
    });
    AppLogger.i('局域网分享服务已启动 :$port');
    return 'started';
  }

  Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
    AppLogger.i('局域网分享服务已停止');
  }

  // ────────────────────────── 请求处理 ──────────────────────────

  Future<void> _handle(HttpRequest req) async {
    try {
      _activeConnections.add(req.hashCode);
      // 防浏览器缓存：令牌可能已重新生成，缓存的旧响应会造成困惑
      req.response.headers.set('Cache-Control', 'no-store');
      // 令牌校验（query 或 header）
      final t = req.uri.queryParameters['token'] ??
          req.headers.value('x-token') ??
          '';
      if (t != _token) {
        req.response.statusCode = 403;
        req.response.headers.contentType =
            ContentType('text', 'plain', charset: 'utf-8');
        req.response.write('令牌无效或已重新生成：请回到手机 App 的'
            '「局域网传文件」页复制最新地址重新打开');
        await req.response.close();
        return;
      }

      final path = req.uri.path;
      if (path == '/' || path == '/index.html') {
        await _html(req, _buildIndexHtml());
      } else if (path == '/api/list') {
        await _apiList(req);
      } else if (path == '/api/download') {
        await _apiDownload(req);
      } else if (path == '/api/upload' && req.method == 'POST') {
        await _apiUpload(req);
      } else if (path == '/api/mkdir' && req.method == 'POST') {
        await _apiMkdir(req);
      } else if (path == '/api/delete' && req.method == 'POST') {
        await _apiDelete(req);
      } else {
        req.response.statusCode = 404;
        await req.response.close();
      }
    } catch (e) {
      AppLogger.w('局域网分享请求处理失败: $e');
      try {
        req.response.statusCode = 500;
        req.response.write('$e');
        await req.response.close();
      } catch (_) {}
    } finally {
      _activeConnections.remove(req.hashCode);
    }
  }

  /// 路径安全化：必须位于根目录内；空 path = 根目录。
  /// 先做字符串级规范化（处理 ../ 与 .），resolveSymbolicLinksSync 仅作
  /// 回退——FUSE 存储上部分目录（中文/隐藏目录等）resolve 会抛异常，
  /// 直接一票否决会让这些目录全部 403。
  String? _safePath(String? raw) {
    var p = raw ?? '';
    if (p.isEmpty) return _root;

    String normalize(String path) {
      final out = <String>[];
      for (final seg in path.split('/')) {
        if (seg.isEmpty || seg == '.') continue;
        if (seg == '..') {
          if (out.isNotEmpty) out.removeLast();
          continue;
        }
        out.add(seg);
      }
      return '/${out.join('/')}';
    }

    final rootNorm = normalize(_root);
    final norm = normalize(p);
    if (norm == rootNorm || norm.startsWith('$rootNorm/')) {
      return norm;
    }

    // 回退：符号链接解析（处理根目录本身是链接的 ROM）
    try {
      final resolved = File(p).absolute.resolveSymbolicLinksSync();
      final resolvedRoot = Directory(_root).absolute.resolveSymbolicLinksSync();
      if (resolved == resolvedRoot || resolved.startsWith('$resolvedRoot/')) {
        return resolved;
      }
      AppLogger.w('路径越界拒绝: $p -> $resolved (root $resolvedRoot)');
    } catch (e) {
      AppLogger.w('路径解析失败: $p ($e)');
    }
    return null;
  }

  Future<void> _json(HttpRequest req, Object data, {int status = 200}) async {
    req.response.statusCode = status;
    req.response.headers.contentType = ContentType.json;
    req.response.write(jsonEncode(data));
    await req.response.close();
  }

  Future<void> _html(HttpRequest req, String html) async {
    req.response.headers.contentType =
        ContentType('text', 'html', charset: 'utf-8');
    req.response.write(html);
    await req.response.close();
  }

  Future<void> _apiList(HttpRequest req) async {
    final dirPath = _safePath(req.uri.queryParameters['path']);
    if (dirPath == null) {
      await _json(req, {'code': 403, 'message': '路径越界'}, status: 403);
      return;
    }
    final dir = Directory(dirPath);
    final entries = <Map<String, dynamic>>[];
    if (await dir.exists()) {
      await for (final e in dir.list(followLinks: false)) {
        try {
          final stat = await e.stat();
          entries.add({
            'name': e.uri.pathSegments.where((s) => s.isNotEmpty).last,
            'isDir': e is Directory,
            'size': stat.size,
            'modified': stat.modified.toIso8601String(),
          });
        } catch (_) {}
      }
    }
    // 文件夹在前，按名称排序
    entries.sort((a, b) {
      if (a['isDir'] != b['isDir']) return a['isDir'] ? -1 : 1;
      return (a['name'] as String)
          .toLowerCase()
          .compareTo((b['name'] as String).toLowerCase());
    });
    await _json(req, {'code': 0, 'path': dirPath, 'entries': entries});
  }

  Future<void> _apiDownload(HttpRequest req) async {
    final filePath = _safePath(req.uri.queryParameters['path']);
    if (filePath == null) {
      await _json(req, {'code': 403, 'message': '路径越界'}, status: 403);
      return;
    }
    final f = File(filePath);
    if (!await f.exists()) {
      await _json(req, {'code': 404, 'message': '文件不存在'}, status: 404);
      return;
    }
    final stat = await f.stat();
    final name = filePath.split('/').last;
    req.response.headers
      ..contentType = ContentType.binary
      ..contentLength = stat.size
      ..set('Content-Disposition',
          'attachment; filename="${Uri.encodeComponent(name)}"');
    await f.openRead().pipe(req.response);
  }

  Future<void> _apiUpload(HttpRequest req) async {
    final dirPath = _safePath(req.uri.queryParameters['path']) ?? _root;
    final rawName = req.uri.queryParameters['name'] ?? 'upload.bin';
    // 只取文件名部分，防目录注入
    final name = rawName.split('/').last.split('\\').last;
    if (name.isEmpty || name.startsWith('.')) {
      await _json(req, {'code': 400, 'message': '非法文件名'}, status: 400);
      return;
    }
    final target = File('$dirPath/$name');
    final sink = target.openWrite();
    var received = 0;
    await for (final chunk in req) {
      sink.add(chunk);
      received += chunk.length;
    }
    await sink.close();
    AppLogger.i('局域网上传 $name ($received bytes)');
    await _json(req, {'code': 0, 'message': 'ok', 'size': received});
  }

  Future<void> _apiMkdir(HttpRequest req) async {
    final body = await utf8.decoder.bind(req).join();
    final data = jsonDecode(body) as Map<String, dynamic>;
    final dirPath = _safePath(data['path'] as String?);
    final name =
        ((data['name'] as String?) ?? '').split('/').last.split('\\').last;
    if (dirPath == null || name.isEmpty || name.startsWith('.')) {
      await _json(req, {'code': 400, 'message': '非法参数'}, status: 400);
      return;
    }
    await Directory('$dirPath/$name').create(recursive: false);
    await _json(req, {'code': 0, 'message': 'ok'});
  }

  Future<void> _apiDelete(HttpRequest req) async {
    final body = await utf8.decoder.bind(req).join();
    final data = jsonDecode(body) as Map<String, dynamic>;
    final targetPath = _safePath(data['path'] as String?);
    if (targetPath == null || targetPath == _root) {
      await _json(req, {'code': 403, 'message': '非法路径'}, status: 403);
      return;
    }
    final type = FileSystemEntity.typeSync(targetPath);
    if (type == FileSystemEntityType.directory) {
      await Directory(targetPath).delete(recursive: true);
    } else if (type == FileSystemEntityType.file) {
      await File(targetPath).delete();
    } else {
      await _json(req, {'code': 404, 'message': '不存在'}, status: 404);
      return;
    }
    await _json(req, {'code': 0, 'message': 'ok'});
  }

  // ────────────────────────── Web 页面 ──────────────────────────

  String _buildIndexHtml() => '''
<!DOCTYPE html>
<html lang="zh">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>EasyServer 手机文件</title>
<style>
  body{font-family:system-ui,-apple-system,'Segoe UI',sans-serif;margin:0;background:#f5f6fa;color:#263238}
  header{background:#3949ab;color:#fff;padding:14px 18px;display:flex;justify-content:space-between;align-items:center;position:sticky;top:0;z-index:2}
  header h1{font-size:16px;margin:0}
  #crumbs{padding:10px 18px;font-size:13px;color:#5c6bc0;word-break:break-all}
  #crumbs a{color:#3949ab;text-decoration:none;margin-right:4px}
  ul{list-style:none;margin:0;padding:0 8px}
  li{display:flex;align-items:center;gap:10px;padding:10px 12px;border-bottom:1px solid #eceff1;border-radius:6px}
  li:hover{background:#e8eaf6}
  .icon{font-size:20px;width:24px;text-align:center}
  .name{flex:1;cursor:pointer;word-break:break-all}
  .meta{color:#90a4ae;font-size:12px;white-space:nowrap}
  a.dl{color:#3949ab;text-decoration:none;font-size:13px;padding:4px 10px;border:1px solid #c5cae9;border-radius:6px}
  a.dl:hover{background:#e8eaf6}
  .bar{padding:10px 18px;display:flex;gap:8px;align-items:center;flex-wrap:wrap}
  button{border:none;background:#3949ab;color:#fff;padding:8px 14px;border-radius:6px;cursor:pointer;font-size:13px}
  button.gray{background:#78909c}
  #tip{padding:8px 18px;font-size:12px;color:#43a047;min-height:18px}
  #drop{outline:2px dashed #c5cae9;outline-offset:-8px}
</style>
</head>
<body>
<header>
  <h1>📱 EasyServer 手机文件</h1>
  <span style="font-size:12px;opacity:.8">局域网直连 · 令牌已验证</span>
</header>
<div class="bar">
  <button onclick="mkdirPrompt()">新建文件夹</button>
  <button class="gray" onclick="document.getElementById('file').click()">上传文件</button>
  <button class="gray" onclick="reload()">刷新</button>
  <input type="file" id="file" multiple style="display:none" onchange="uploadFiles(this.files)">
</div>
<div id="tip"></div>
<div id="crumbs"></div>
<ul id="list"></ul>
<script>
const TOKEN = new URLSearchParams(location.search).get('token');
let CWD = '';

function fmtSize(n){ if(n===null||n===undefined) return ''; if(n<1024) return n+' B'; if(n<1048576) return (n/1024).toFixed(1)+' KB'; if(n<1073741824) return (n/1048576).toFixed(1)+' MB'; return (n/1073741824).toFixed(2)+' GB'; }
function fmtTime(s){ if(!s) return ''; return new Date(s).toLocaleString(); }
function tip(m, ok){ const el=document.getElementById('tip'); el.textContent=m; el.style.color = ok?'#43a047':'#e53935'; }

async function api(path, opt){ opt=opt||{}; const sep = path.includes('?')?'&':'?'; const r = await fetch(path+sep+'token='+encodeURIComponent(TOKEN), opt); if(r.status===403){ tip('访问令牌无效', false); throw new Error('403'); } return r; }

function crumbs(p){
  const el=document.getElementById('crumbs'); el.innerHTML='';
  const root=document.createElement('a'); root.textContent='🏠 存储根目录'; root.onclick=()=>go(''); el.appendChild(root);
  let acc='';
  p.split('/').filter(Boolean).forEach(seg=>{
    acc+='/'+seg;
    el.appendChild(document.createTextNode(' / '));
    const a=document.createElement('a'); a.textContent=seg; a.onclick=()=>go(acc); el.appendChild(a);
  });
}

async function go(p){
  const r = await api('/api/list?path='+encodeURIComponent(p));
  const d = await r.json();
  if(d.code!==0){ tip(d.message||'列表失败', false); return; }
  // 以服务端返回的实际路径为准（首页空路径 -> 手机存储根），
  // 否则 CWD 停留在空串，点子项会拼出无前缀路径被安全策略拒绝
  CWD = d.path || p;
  crumbs(CWD);
  const ul=document.getElementById('list'); ul.innerHTML='';
  if(!d.entries.length){ ul.innerHTML='<li style="justify-content:center;color:#90a4ae">空目录</li>'; }
  d.entries.forEach(e=>{
    const full = (CWD? CWD+'/'+e.name : '/'+e.name);
    const li=document.createElement('li');
    li.className='row'; li.dataset.path=full; li.dataset.isDir=e.isDir;
    li.innerHTML='<span class="icon">'+(e.isDir?'📁':'📄')+'</span>'+
      '<span class="name">'+e.name.replace(/</g,'&lt;')+'</span>'+
      '<span class="meta">'+(e.isDir?'':fmtSize(e.size)+' · ')+fmtTime(e.modified)+'</span>';
    if(e.isDir){ li.querySelector('.name').onclick=()=>go(full); }
    else {
      const a=document.createElement('a'); a.className='dl'; a.textContent='下载';
      a.href='/api/download?path='+encodeURIComponent(full)+'&token='+encodeURIComponent(TOKEN);
      li.appendChild(a);
    }
    const del=document.createElement('span'); del.className='icon'; del.title='删除'; del.style.cursor='pointer'; del.textContent='🗑';
    del.onclick=()=>{ if(confirm('删除 '+(e.isDir?'文件夹':'文件')+' '+e.name+' ？')) delPath(full); };
    li.appendChild(del);
    ul.appendChild(li);
  });
}
function reload(){ go(CWD); }

async function delPath(p){
  const r = await api('/api/delete', {method:'POST', headers:{'Content-Type':'application/json'}, body:JSON.stringify({path:p})});
  const d = await r.json();
  tip(d.code===0?'已删除':(d.message||'删除失败'), d.code===0);
  reload();
}

async function mkdirPrompt(){
  const name = prompt('新文件夹名称：');
  if(!name) return;
  const r = await api('/api/mkdir', {method:'POST', headers:{'Content-Type':'application/json'}, body:JSON.stringify({path:CWD, name})});
  const d = await r.json();
  tip(d.code===0?'已创建':(d.message||'创建失败'), d.code===0);
  reload();
}

async function uploadFiles(files){
  for(const f of files){
    tip('上传中 '+f.name+' …', true);
    const r = await api('/api/upload?path='+encodeURIComponent(CWD)+'&name='+encodeURIComponent(f.name),
      {method:'POST', body:f});
    const d = await r.json();
    if(d.code!==0){ tip('上传失败 '+f.name, false); return; }
  }
  tip('上传完成（'+files.length+' 个文件）', true);
  reload();
}

// 拖拽上传
document.body.addEventListener('dragover', e=>{ e.preventDefault(); document.body.id='drop'; });
document.body.addEventListener('dragleave', e=>{ document.body.id=''; });
document.body.addEventListener('drop', e=>{
  e.preventDefault(); document.body.id='';
  if(e.dataTransfer.files.length) uploadFiles(e.dataTransfer.files);
});

go('');
</script>
</body>
</html>
''';
}
