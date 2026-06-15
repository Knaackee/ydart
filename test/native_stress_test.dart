import 'dart:io';

import 'package:test/test.dart';
import 'package:ydart/ydart.dart';

void main() {
  final canRunNativeTests = Platform.isAndroid ||
      Platform.isIOS ||
      Platform.environment['YDART_LIBYRS_PATH']?.isNotEmpty == true;

  group('native stress', skip: canRunNativeTests ? false : _skipReason, () {
    test('repeated create, edit, sync, dispose', () {
      for (var i = 0; i < 100; i++) {
        final a = YDoc();
        final b = YDoc();
        final textA = a.getText('text');
        final textB = b.getText('text');
        final mapA = a.getMap('meta');

        a.transact((txn) {
          textA.insert(txn, 0, 'message-$i');
          mapA.set(txn, 'iteration', i);
        });

        b.applyV1(a.stateDiffV1(b.stateVectorV1()));

        expect(b.readTransact((txn) => textB.getString(txn)), 'message-$i');

        a.dispose();
        b.dispose();
      }
    });

    test('large text converges after round trip sync', () {
      final a = YDoc();
      final b = YDoc();
      final textA = a.getText('content');
      final textB = b.getText('content');

      a.transact((txn) {
        for (var i = 0; i < 1000; i++) {
          textA.insert(txn, i, 'a');
        }
      });

      b.applyV1(a.stateDiffV1(b.stateVectorV1()));
      b.transact((txn) {
        textB.insert(txn, 1000, 'b');
      });
      a.applyV1(b.stateDiffV1(a.stateVectorV1()));

      expect(a.readTransact((txn) => textA.getString(txn)).length, 1001);
      expect(
        a.readTransact((txn) => textA.getString(txn)),
        b.readTransact((txn) => textB.getString(txn)),
      );

      a.dispose();
      b.dispose();
    });
  });
}

const _skipReason =
    'Native stress tests run only on Android/iOS or with YDART_LIBYRS_PATH set.';
