// Tiny static file server for the built web app (build/web).
// Runs on dart:io HttpServer — no stdin dependency, so it never dies
// silently the way `flutter run` background sessions do.
//
//   dart run tool/serve_web.dart            # serves on port 8090
//   dart run tool/serve_web.dart 8091       # custom port
import 'dart:io';

const _mime = <String, String>{
  '.html': 'text/html; charset=utf-8',
  '.js': 'application/javascript; charset=utf-8',
  '.mjs': 'application/javascript; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.json': 'application/json',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.gif': 'image/gif',
  '.svg': 'image/svg+xml',
  '.ico': 'image/x-icon',
  '.webp': 'image/webp',
  '.wasm': 'application/wasm',
  '.ttf': 'font/ttf',
  '.otf': 'font/otf',
  '.woff': 'font/woff',
  '.woff2': 'font/woff2',
  '.map': 'application/json',
  '.txt': 'text/plain; charset=utf-8',
  '.webmanifest': 'application/manifest+json',
};

Future<void> main([List<String> args = const []]) async {
  final port = args.isNotEmpty ? int.tryParse(args[0]) ?? 8090 : 8090;
  final root = Directory('build/web').absolute.path;
  final server =
      await HttpServer.bind(InternetAddress.loopbackIPv4, port, shared: true);
  stdout.writeln('Serving $root at http://localhost:$port');

  await for (final req in server) {
    try {
      final path = req.uri.path == '/' ? '/index.html' : req.uri.path;
      var file = File('$root/${Uri.decodeComponent(path)}');
      if (await file.exists()) {
        final ext = file.path.contains('.')
            ? file.path.substring(file.path.lastIndexOf('.'))
            : '';
        req.response.headers.contentType = ContentType.parse(_mime[ext] ?? 'application/octet-stream');
        await file.openRead().pipe(req.response);
      } else if (path != '/index.html' && await File('$root/index.html').exists()) {
        // SPA fallback: unknown paths get the app shell.
        final r = req.response..headers.contentType = ContentType.parse('text/html; charset=utf-8');
        await r.addStream(File('$root/index.html').openRead());
        await r.close();
      } else {
        req.response.statusCode = HttpStatus.notFound;
        await req.response.close();
      }
    } catch (e) {
      // Safe-shell: never let a broken pipe crash the server.
      try {
        await req.response.close();
      } catch (_) {}
    }
  }
}
