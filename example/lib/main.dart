import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:ydart/ydart.dart';

void main() {
  runApp(const YdartExampleApp());
}

class YdartExampleApp extends StatelessWidget {
  const YdartExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ydart sync harness',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff0f766e)),
        useMaterial3: true,
      ),
      home: const SyncHarnessPage(),
    );
  }
}

class SyncHarnessPage extends StatefulWidget {
  const SyncHarnessPage({super.key});

  @override
  State<SyncHarnessPage> createState() => _SyncHarnessPageState();
}

class _SyncHarnessPageState extends State<SyncHarnessPage> {
  late YDoc _docA;
  late YDoc _docB;
  late YText _textA;
  late YText _textB;
  late YMap _metaA;
  late YMap _metaB;

  var _contentA = '';
  var _contentB = '';
  var _status = 'Ready';
  var _lastUpdateBytes = 0;
  var _editCounter = 0;
  var _initialized = false;

  @override
  void initState() {
    super.initState();
    _resetDocs();
  }

  @override
  void dispose() {
    _docA.dispose();
    _docB.dispose();
    super.dispose();
  }

  void _resetDocs() {
    if (_initialized) {
      _docA.dispose();
      _docB.dispose();
    }
    _docA = YDoc();
    _docB = YDoc();
    _textA = _docA.getText('content');
    _textB = _docB.getText('content');
    _metaA = _docA.getMap('meta');
    _metaB = _docB.getMap('meta');
    _contentA = '';
    _contentB = '';
    _status = 'Documents reset';
    _lastUpdateBytes = 0;
    _editCounter = 0;
    _initialized = true;
    if (mounted) setState(() {});
  }

  void _safeRun(String label, void Function() fn) {
    try {
      fn();
      _refresh(label);
    } catch (error) {
      setState(() {
        _status = '$label failed: $error';
      });
    }
  }

  void _editA() {
    _safeRun('Edited A', () {
      _editCounter++;
      _docA.transact((txn) {
        final currentLength = _contentA.length;
        final suffix = currentLength == 0 ? '' : ' ';
        _textA.insert(txn, currentLength, '${suffix}A$_editCounter');
        _metaA.set(txn, 'lastEditor', 'A');
        _metaA.set(txn, 'edits', _editCounter);
      });
    });
  }

  void _editB() {
    _safeRun('Edited B', () {
      _editCounter++;
      _docB.transact((txn) {
        final currentLength = _contentB.length;
        final suffix = currentLength == 0 ? '' : ' ';
        _textB.insert(txn, currentLength, '${suffix}B$_editCounter');
        _metaB.set(txn, 'lastEditor', 'B');
        _metaB.set(txn, 'edits', _editCounter);
      });
    });
  }

  void _syncAToB() {
    _safeRun('Synced A to B', () {
      final update = _docA.stateDiffV1(_docB.stateVectorV1());
      _lastUpdateBytes = update.length;
      _docB.applyV1(update);
    });
  }

  void _syncBToA() {
    _safeRun('Synced B to A', () {
      final update = _docB.stateDiffV1(_docA.stateVectorV1());
      _lastUpdateBytes = update.length;
      _docA.applyV1(update);
    });
  }

  void _roundTrip() {
    _safeRun('Round trip sync complete', () {
      final aToB = _docA.stateDiffV1(_docB.stateVectorV1());
      _docB.applyV1(aToB);
      final bToA = _docB.stateDiffV1(_docA.stateVectorV1());
      _docA.applyV1(bToA);
      _lastUpdateBytes = aToB.length + bToA.length;
    });
  }

  void _refresh(String status) {
    final contentA = _docA.readTransact((txn) => _textA.getString(txn));
    final contentB = _docB.readTransact((txn) => _textB.getString(txn));
    setState(() {
      _contentA = contentA;
      _contentB = contentB;
      _status = status;
    });
  }

  Uint8List _stateVector(YDoc doc) {
    try {
      return doc.stateVectorV1();
    } catch (_) {
      return Uint8List(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final converged = _contentA == _contentB;
    return Scaffold(
      appBar: AppBar(title: const Text('ydart sync harness')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton(onPressed: _editA, child: const Text('Edit A')),
              FilledButton(onPressed: _editB, child: const Text('Edit B')),
              OutlinedButton(
                onPressed: _syncAToB,
                child: const Text('Sync A to B'),
              ),
              OutlinedButton(
                onPressed: _syncBToA,
                child: const Text('Sync B to A'),
              ),
              OutlinedButton(
                onPressed: _roundTrip,
                child: const Text('Round trip'),
              ),
              TextButton(onPressed: _resetDocs, child: const Text('Reset')),
            ],
          ),
          const SizedBox(height: 16),
          _ReplicaPanel(
            title: 'Replica A',
            content: _contentA,
            stateVectorBytes: _stateVector(_docA).length,
          ),
          const SizedBox(height: 12),
          _ReplicaPanel(
            title: 'Replica B',
            content: _contentB,
            stateVectorBytes: _stateVector(_docB).length,
          ),
          const SizedBox(height: 16),
          Text('Status: $_status'),
          Text('Converged: $converged'),
          Text('Last update bytes: $_lastUpdateBytes'),
        ],
      ),
    );
  }
}

class _ReplicaPanel extends StatelessWidget {
  const _ReplicaPanel({
    required this.title,
    required this.content,
    required this.stateVectorBytes,
  });

  final String title;
  final String content;
  final int stateVectorBytes;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outline),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(content.isEmpty ? '(empty)' : content),
            const SizedBox(height: 8),
            Text('State vector bytes: $stateVectorBytes'),
          ],
        ),
      ),
    );
  }
}
