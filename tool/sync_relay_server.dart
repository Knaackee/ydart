import 'dart:convert';
import 'dart:io';

Future<void> main(List<String> args) async {
  final port = args.isEmpty ? 8080 : int.parse(args.first);
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
  final clients = <WebSocket>{};

  print('ydart relay listening on ws://${server.address.host}:$port');

  await for (final request in server) {
    if (!WebSocketTransformer.isUpgradeRequest(request)) {
      request.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType.text
        ..write('ydart relay is running\n');
      await request.response.close();
      continue;
    }

    final socket = await WebSocketTransformer.upgrade(request);
    clients.add(socket);
    socket.add(jsonEncode({'type': 'hello', 'clients': clients.length}));

    socket.listen(
      (message) {
        for (final client in clients) {
          if (client != socket && client.readyState == WebSocket.open) {
            client.add(message);
          }
        }
      },
      onDone: () => clients.remove(socket),
      onError: (_) => clients.remove(socket),
      cancelOnError: true,
    );
  }
}
