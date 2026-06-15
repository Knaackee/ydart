import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:async/async.dart';
import 'package:test/test.dart';

void main() {
  test('relay forwards WebSocket messages between clients', () async {
    final port = await _freePort();
    final process = await Process.start(
      Platform.resolvedExecutable,
      ['run', 'tool/sync_relay_server.dart', '$port'],
    );

    try {
      final ready = process.stdout
          .transform(utf8.decoder)
          .firstWhere((line) => line.contains('ydart relay listening'))
          .timeout(const Duration(seconds: 20));
      await ready;

      final a = await WebSocket.connect('ws://127.0.0.1:$port');
      final b = await WebSocket.connect('ws://127.0.0.1:$port');
      final aMessages = StreamQueue<dynamic>(a);
      final bMessages = StreamQueue<dynamic>(b);
      try {
        await aMessages.next.timeout(const Duration(seconds: 5));
        await bMessages.next.timeout(const Duration(seconds: 5));

        a.add('update-from-a');
        expect(
          await bMessages.next.timeout(const Duration(seconds: 5)),
          'update-from-a',
        );

        b.add('update-from-b');
        expect(
          await aMessages.next.timeout(const Duration(seconds: 5)),
          'update-from-b',
        );
      } finally {
        await aMessages.cancel();
        await bMessages.cancel();
        await a.close();
        await b.close();
      }
    } finally {
      process.kill();
      await process.exitCode.timeout(
        const Duration(seconds: 5),
        onTimeout: () => -1,
      );
    }
  });
}

Future<int> _freePort() async {
  final socket = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
  final port = socket.port;
  await socket.close();
  return port;
}
