// Native runtime tests for ydart.
//
// These tests require libyrs to be available. They are skipped on host desktop
// by default because ydart intentionally supports Android and iOS only.

import 'dart:io';
import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:ydart/ydart.dart';

void main() {
  final canRunNativeTests = Platform.isAndroid ||
      Platform.isIOS ||
      Platform.environment['YDART_LIBYRS_PATH']?.isNotEmpty == true;

  group('ydart native API', skip: canRunNativeTests ? false : _skipReason, () {
    group('YDoc', () {
      test('creates with unique id and guid', () {
        final doc = YDoc();
        expect(doc.id, isNonZero);
        expect(doc.guid, isNotEmpty);
        doc.dispose();
      });

      test('throws after dispose', () {
        final doc = YDoc();
        doc.dispose();
        expect(() => doc.id, throwsStateError);
      });

      test('dispose is idempotent', () {
        final doc = YDoc();
        doc.dispose();
        doc.dispose();
      });
    });

    group('YText', () {
      late YDoc doc;
      late YText text;

      setUp(() {
        doc = YDoc();
        text = doc.getText('test');
      });

      tearDown(() => doc.dispose());

      test('insert and read', () {
        doc.transact((txn) {
          text.insert(txn, 0, 'Hello');
        });
        expect(doc.readTransact((txn) => text.getString(txn)), 'Hello');
      });

      test('insert at offset', () {
        doc.transact((txn) {
          text.insert(txn, 0, 'Hllo');
          text.insert(txn, 1, 'e');
        });
        expect(doc.readTransact((txn) => text.getString(txn)), 'Hello');
      });

      test('delete range', () {
        doc.transact((txn) {
          text.insert(txn, 0, 'Hello, world!');
          text.delete(txn, 5, 8);
        });
        expect(doc.readTransact((txn) => text.getString(txn)), 'Hello');
      });

      test('unicode text', () {
        const value = 'Rocket: hello world - Nihongo';
        doc.transact((txn) {
          text.insert(txn, 0, value);
        });
        expect(doc.readTransact((txn) => text.getString(txn)), value);
      });
    });

    group('YArray', () {
      late YDoc doc;
      late YArray array;

      setUp(() {
        doc = YDoc();
        array = doc.getArray('test');
      });

      tearDown(() => doc.dispose());

      test('insert and read', () {
        doc.transact((txn) {
          array.insertValues(txn, 0, ['a', 'b', 'c']);
        });
        expect(doc.readTransact((txn) => array.length(txn)), 3);
        expect(doc.readTransact((txn) => array.toList(txn)), ['a', 'b', 'c']);
      });

      test('remove range', () {
        doc.transact((txn) {
          array.insertValues(txn, 0, [1, 2, 3]);
          array.removeRange(txn, 1, 1);
        });
        expect(doc.readTransact((txn) => array.length(txn)), 2);
      });
    });

    group('YMap', () {
      late YDoc doc;
      late YMap map;

      setUp(() {
        doc = YDoc();
        map = doc.getMap('test');
      });

      tearDown(() => doc.dispose());

      test('insert and get', () {
        doc.transact((txn) {
          map.set(txn, 'key', 'value');
        });
        expect(doc.readTransact((txn) => map.get(txn, 'key')), 'value');
      });

      test('length', () {
        doc.transact((txn) {
          map.set(txn, 'a', 1);
          map.set(txn, 'b', 2);
        });
        expect(doc.readTransact((txn) => map.length(txn)), 2);
      });

      test('remove', () {
        doc.transact((txn) {
          map.set(txn, 'key', 'value');
        });
        doc.transact((txn) {
          expect(map.remove(txn, 'key'), isTrue);
        });
        expect(doc.readTransact((txn) => map.length(txn)), 0);
      });

      test('overwrite', () {
        doc.transact((txn) {
          map.set(txn, 'key', 'old');
        });
        doc.transact((txn) {
          map.set(txn, 'key', 'new');
        });
        expect(doc.readTransact((txn) => map.get(txn, 'key')), 'new');
      });
    });

    group('State sync', () {
      test('sync two docs via state vector and diff', () {
        final docA = YDoc();
        final docB = YDoc();

        final textA = docA.getText('content');
        final textB = docB.getText('content');

        docA.transact((txn) {
          textA.insert(txn, 0, 'Hello from A');
        });

        final diffA = docA.stateDiffV1(docB.stateVectorV1());
        docB.applyV1(diffA);

        expect(
          docB.readTransact((txn) => textB.getString(txn)),
          'Hello from A',
        );

        docA.dispose();
        docB.dispose();
      });

      test('bidirectional sync', () {
        final docA = YDoc();
        final docB = YDoc();

        final textA = docA.getText('content');
        final textB = docB.getText('content');

        docA.transact((txn) {
          textA.insert(txn, 0, 'Hello');
        });

        docB.applyV1(docA.stateDiffV1(docB.stateVectorV1()));

        docB.transact((txn) {
          textB.insert(txn, 5, ' World');
        });

        docA.applyV1(docB.stateDiffV1(docA.stateVectorV1()));

        expect(docA.readTransact((txn) => textA.getString(txn)), 'Hello World');
        expect(docB.readTransact((txn) => textB.getString(txn)), 'Hello World');

        docA.dispose();
        docB.dispose();
      });

      test('empty state vector produces full update', () {
        final doc = YDoc();
        final text = doc.getText('t');
        doc.transact((txn) {
          text.insert(txn, 0, 'data');
        });

        final diff = doc.stateDiffV1(Uint8List(0));
        expect(diff, isNotEmpty);

        doc.dispose();
      });
    });

    group('YXmlElement', () {
      late YDoc doc;
      late YXmlElement xml;

      setUp(() {
        doc = YDoc();
        xml = doc.getXmlElement('test');
      });

      tearDown(() => doc.dispose());

      test('insert child element', () {
        doc.transact((txn) {
          xml.insertElement(txn, 0, 'div');
        });
        expect(doc.readTransact((txn) => xml.length(txn)), 1);
      });

      test('attributes', () {
        doc.transact((txn) {
          xml.insertAttribute(txn, 'class', 'container');
        });
        expect(
          doc.readTransact((txn) => xml.getAttribute(txn, 'class')),
          'container',
        );
        doc.transact((txn) {
          xml.removeAttribute(txn, 'class');
        });
        expect(doc.readTransact((txn) => xml.getAttribute(txn, 'class')), null);
      });
    });

    group('YXmlText', () {
      late YDoc doc;
      late YXmlText xmlText;

      setUp(() {
        doc = YDoc();
        xmlText = doc.getXmlText('test');
      });

      tearDown(() => doc.dispose());

      test('insert and read', () {
        doc.transact((txn) {
          xmlText.insert(txn, 0, 'Hello XML');
        });
        expect(doc.readTransact((txn) => xmlText.getString(txn)), 'Hello XML');
      });

      test('attributes', () {
        doc.transact((txn) {
          xmlText.insertAttribute(txn, 'lang', 'en');
        });
        expect(
          doc.readTransact((txn) => xmlText.getAttribute(txn, 'lang')),
          'en',
        );
      });
    });

    test('mixed shared types in one doc', () {
      final doc = YDoc();
      final text = doc.getText('title');
      final array = doc.getArray('items');
      final map = doc.getMap('meta');

      doc.transact((txn) {
        text.insert(txn, 0, 'My Doc');
        array.insertValues(txn, 0, [42]);
        map.set(txn, 'version', 1);
      });

      expect(doc.readTransact((txn) => text.getString(txn)), 'My Doc');
      expect(doc.readTransact((txn) => array.length(txn)), 1);
      expect(doc.readTransact((txn) => map.get(txn, 'version')), 1);

      doc.dispose();
    });
  });
}

const _skipReason =
    'Native libyrs tests run only on Android/iOS or with YDART_LIBYRS_PATH set.';
