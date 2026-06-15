import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:ydart/ydart.dart';

void main() {
  final canRunNativeTests = Platform.isAndroid ||
      Platform.isIOS ||
      Platform.environment['YDART_LIBYRS_PATH']?.isNotEmpty == true;

  group('Yjs wire compatibility', skip: canRunNativeTests ? false : _skip, () {
    test('applies a Yjs V1 update fixture', () {
      final fixtureFile = File('test/fixtures/yjs_update_v1.json');
      final fixture =
          jsonDecode(fixtureFile.readAsStringSync()) as Map<String, Object?>;
      final update = base64Decode(fixture['updateBase64']! as String);

      final doc = YDoc();
      final text = doc.getText('content');
      final meta = doc.getMap('meta');

      doc.applyV1(update);

      expect(
        doc.readTransact((txn) => text.getString(txn)),
        fixture['content'],
      );
      expect(doc.readTransact((txn) => meta.get(txn, 'source')), 'yjs');
      expect(doc.readTransact((txn) => meta.get(txn, 'version')), 1);

      doc.dispose();
    });
  });
}

const _skip =
    'Yjs compatibility tests run only on Android/iOS or with YDART_LIBYRS_PATH set.';
