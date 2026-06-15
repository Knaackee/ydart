/// Benchmarks for ydart, modeled after the crdt-benchmarks suite.
///
/// Run in a Flutter mobile integration environment with libyrs bundled.

import 'package:ydart/ydart.dart';

void main() {
  print('============================================================');
  print(' ydart Benchmarks - Dart FFI bindings for yrs (y-crdt)');
  print('============================================================');
  print('');

  _benchmarkB1();
  _benchmarkB2();
  _benchmarkB3();
  _benchmarkSync();
  _benchmarkLargeArray();
  _benchmarkLargeMap();
}

void _benchmarkB1() {
  const n = 6000;
  final doc = YDoc();
  final text = doc.getText('text');

  final sw = Stopwatch()..start();
  doc.transact((txn) {
    for (var i = 0; i < n; i++) {
      text.insert(txn, i, 'a');
    }
  });
  sw.stop();

  final content = doc.readTransact((txn) => text.getString(txn));
  _printResult('B1 append $n chars', sw, content.length == n);
  doc.dispose();
}

void _benchmarkB2() {
  const n = 6000;
  final doc = YDoc();
  final text = doc.getText('text');

  final sw = Stopwatch()..start();
  doc.transact((txn) {
    for (var i = 0; i < n; i++) {
      text.insert(txn, i ~/ 2, 'b');
    }
  });
  sw.stop();

  final content = doc.readTransact((txn) => text.getString(txn));
  _printResult('B2 middle insert $n chars', sw, content.length == n);
  doc.dispose();
}

void _benchmarkB3() {
  const n = 6000;
  final doc = YDoc();
  final text = doc.getText('text');

  final sw = Stopwatch()..start();
  doc.transact((txn) {
    for (var i = 0; i < n; i++) {
      text.insert(txn, 0, 'c');
    }
  });
  sw.stop();

  final content = doc.readTransact((txn) => text.getString(txn));
  _printResult('B3 prepend $n chars', sw, content.length == n);
  doc.dispose();
}

void _benchmarkSync() {
  const n = 5000;
  final docA = YDoc();
  final textA = docA.getText('text');

  docA.transact((txn) {
    for (var i = 0; i < n; i++) {
      textA.insert(txn, i, 'x');
    }
  });

  final docB = YDoc();
  final textB = docB.getText('text');

  final sw = Stopwatch()..start();
  final diff = docA.stateDiffV1(docB.stateVectorV1());
  docB.applyV1(diff);
  sw.stop();

  final contentB = docB.readTransact((txn) => textB.getString(txn));
  _printResult('Sync $n-char document', sw, contentB.length == n);
  print('     Diff size: ${diff.length} bytes');

  docA.dispose();
  docB.dispose();
}

void _benchmarkLargeArray() {
  const n = 10000;
  final doc = YDoc();
  final array = doc.getArray('arr');

  final sw = Stopwatch()..start();
  doc.transact((txn) {
    for (var i = 0; i < n; i++) {
      array.insertValues(txn, i, [i]);
    }
  });
  sw.stop();

  final len = doc.readTransact((txn) => array.length(txn));
  _printResult('Array insert $n integers', sw, len == n);
  doc.dispose();
}

void _benchmarkLargeMap() {
  const n = 10000;
  final doc = YDoc();
  final map = doc.getMap('map');

  final sw = Stopwatch()..start();
  doc.transact((txn) {
    for (var i = 0; i < n; i++) {
      map.set(txn, 'key_$i', i);
    }
  });
  sw.stop();

  final len = doc.readTransact((txn) => map.length(txn));
  _printResult('Map insert $n entries', sw, len == n);
  doc.dispose();
}

void _printResult(String name, Stopwatch sw, bool ok) {
  final timeMs = sw.elapsedMicroseconds / 1000.0;
  print('[$name]');
  print('     Time: ${timeMs.toStringAsFixed(2)} ms');
  print('     OK:   $ok');
  print('');
}
