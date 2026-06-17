import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:ydart/ydart.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('native text map array and state sync work on device', (_) async {
    final a = YDoc();
    final b = YDoc();
    try {
      final textA = a.getText('content');
      final textB = b.getText('content');
      final mapA = a.getMap('meta');
      final arrayA = a.getArray('items');

      a.transact((txn) {
        textA.insert(txn, 0, 'Hello');
        textA.insert(txn, 5, ' mobile');
        mapA.set(txn, 'count', 2);
        mapA.set(txn, 'ok', true);
        mapA.set(txn, 'name', 'ydart');
        arrayA.insertValues(txn, 0, ['a', 2, true, null]);
      });

      expect(a.readTransact((txn) => textA.getString(txn)), 'Hello mobile');
      expect(a.readTransact((txn) => mapA.toMap(txn)), {
        'count': 2,
        'ok': true,
        'name': 'ydart',
      });
      expect(a.readTransact((txn) => arrayA.toList(txn)), [
        'a',
        2,
        true,
        null,
      ]);

      b.applyV1(a.stateDiffV1(b.stateVectorV1()));

      expect(b.readTransact((txn) => textB.getString(txn)), 'Hello mobile');
      expect(a.stateVectorV1(), isNotEmpty);
    } finally {
      a.dispose();
      b.dispose();
    }
  });

  testWidgets('applies Yjs V1 update fixture on device', (_) async {
    final doc = YDoc();
    try {
      final update = Uint8List.fromList(base64Decode(_yjsUpdateV1));
      doc.applyV1(update);

      final text = doc.getText('content');
      final meta = doc.getMap('meta');

      expect(
        doc.readTransact((txn) => text.getString(txn)),
        'hello from yjs',
      );
      expect(doc.readTransact((txn) => meta.toMap(txn)), {
        'source': 'yjs',
        'version': 1,
      });
    } finally {
      doc.dispose();
    }
  });

  testWidgets('xml fragment works on device', (_) async {
    final a = YDoc();
    final b = YDoc();
    try {
      final fragmentA = a.getXmlFragment('content');
      final fragmentB = b.getXmlFragment('content');
      a.transact((txn) {
        final paragraph = fragmentA.insertElement(txn, 0, 'paragraph');
        paragraph.insertText(txn, 0).insert(txn, 0, 'Hello fragment');
      });

      expect(
        a.readTransact((txn) => fragmentA.getString(txn)),
        '<paragraph>Hello fragment</paragraph>',
      );

      b.applyV1(a.stateDiffV1(b.stateVectorV1()));

      expect(
        b.readTransact((txn) => fragmentB.getString(txn)),
        '<paragraph>Hello fragment</paragraph>',
      );
    } finally {
      a.dispose();
      b.dispose();
    }
  });

  testWidgets('xml attributes work on device', (_) async {
    final a = YDoc();
    final b = YDoc();
    try {
      final fragmentA = a.getXmlFragment('content');
      final fragmentB = b.getXmlFragment('content');
      a.transact((txn) {
        final heading = fragmentA.insertElement(txn, 0, 'heading');
        heading.insertAttribute(txn, 'level', '1');
        heading.insertText(txn, 0).insert(txn, 0, 'Heading');
        final taskList = fragmentA.insertElement(txn, 1, 'taskList');
        final taskItem = taskList.insertElement(txn, 0, 'taskItem');
        taskItem.insertAttribute(txn, 'checked', 'true');
        taskItem.insertElement(txn, 0, 'paragraph')
          ..insertText(txn, 0).insert(txn, 0, 'Done');
      });

      expect(a.readTransact((txn) => fragmentA.getString(txn)),
          contains('level="1"'));
      expect(a.readTransact((txn) => fragmentA.getString(txn)),
          contains('checked="true"'));

      b.applyV1(a.stateDiffV1(b.stateVectorV1()));

      final values = b.readTransact((txn) {
        final heading = fragmentB.getNode(txn, 0) as YXmlElement;
        final taskList = fragmentB.getNode(txn, 1) as YXmlElement;
        final taskItem = taskList.getNode(txn, 0) as YXmlElement;
        return [
          heading.getAttribute(txn, 'level'),
          taskItem.getAttribute(txn, 'checked'),
        ];
      });
      expect(values, ['1', 'true']);
    } finally {
      a.dispose();
      b.dispose();
    }
  });
}

const _yjsUpdateV1 =
    'AQMBAAQBB2NvbnRlbnQOaGVsbG8gZnJvbSB5anMoAQRtZXRhBnNvdXJjZQF3A3lqcygBBG1ldGEHdmVyc2lvbgF9AQA=';
