import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

import '../native/yrs_native.dart';
import 'transaction.dart';
import '../types/y_text.dart';
import '../types/y_array.dart';
import '../types/y_map.dart';
import '../types/y_xml_element.dart';
import '../types/y_xml_text.dart';
import 'undo_manager.dart';

/// Configuration options for creating a [YDoc].
class YDocOptions {
  /// Client id — must be unique per replica. If null, a random id is assigned.
  final int? id;

  /// Optional UUID v4 string for the document.
  final String? guid;

  /// Optional collection name (used by providers).
  final String? collectionId;

  /// Text encoding: [YEncoding.bytes] or [YEncoding.utf16].
  final int encoding;

  /// Whether to skip garbage collection of deleted blocks.
  final bool skipGc;

  /// Whether sub-documents should auto-load.
  final bool autoLoad;

  /// Whether the document should be synced immediately.
  final bool shouldLoad;

  const YDocOptions({
    this.id,
    this.guid,
    this.collectionId,
    this.encoding = YEncoding.utf16,
    this.skipGc = false,
    this.autoLoad = false,
    this.shouldLoad = true,
  });
}

/// A Yrs document — the top-level collaborative unit.
///
/// All shared types ([YText], [YArray], [YMap], etc.) live within a [YDoc].
/// All mutations happen inside a [Transaction] obtained from this document.
///
/// ```dart
/// final doc = YDoc();
/// final text = doc.getText('my-text');
/// doc.transact((txn) {
///   text.insert(txn, 0, 'Hello');
/// });
/// doc.dispose();
/// ```
class YDoc {
  final Pointer<YDocNative> _handle;
  final YrsNative _native = YrsNative.instance;
  bool _disposed = false;

  /// Creates a new document with default options.
  YDoc() : _handle = YrsNative.instance.ydocNew();

  /// Creates a document from an existing native pointer (internal use).
  YDoc.fromNative(this._handle);

  /// The underlying native handle. Throws if disposed.
  Pointer<YDocNative> get handle {
    _checkDisposed();
    return _handle;
  }

  /// Unique client ID of this document replica.
  int get id {
    _checkDisposed();
    return _native.ydocId(_handle);
  }

  /// UUID of this document.
  String get guid {
    _checkDisposed();
    final ptr = _native.ydocGuid(_handle);
    final result = ptr.toDartString();
    _native.ystringDestroy(ptr);
    return result;
  }

  // ---------- Root shared types ----------

  /// Returns a root-level [YText] shared type with the given [name].
  YText getText(String name) {
    _checkDisposed();
    final namePtr = name.toNativeUtf8();
    final branch = _native.ytext(_handle, namePtr);
    calloc.free(namePtr);
    return YText(branch, this);
  }

  /// Returns a root-level [YArray] shared type with the given [name].
  YArray getArray(String name) {
    _checkDisposed();
    final namePtr = name.toNativeUtf8();
    final branch = _native.yarray(_handle, namePtr);
    calloc.free(namePtr);
    return YArray(branch, this);
  }

  /// Returns a root-level [YMap] shared type with the given [name].
  YMap getMap(String name) {
    _checkDisposed();
    final namePtr = name.toNativeUtf8();
    final branch = _native.ymap(_handle, namePtr);
    calloc.free(namePtr);
    return YMap(branch, this);
  }

  /// Returns a root-level [YXmlElement] shared type with the given [name].
  YXmlElement getXmlElement(String name) {
    _checkDisposed();
    final namePtr = name.toNativeUtf8();
    final branch = _native.yxmlelem(_handle, namePtr);
    calloc.free(namePtr);
    return YXmlElement(branch, this);
  }

  /// Returns a root-level [YXmlText] shared type with the given [name].
  YXmlText getXmlText(String name) {
    _checkDisposed();
    final namePtr = name.toNativeUtf8();
    final branch = _native.yxmltext(_handle, namePtr);
    calloc.free(namePtr);
    return YXmlText(branch, this);
  }

  // ---------- Transactions ----------

  /// Opens a read-only transaction.
  ReadTransaction readTransaction() {
    _checkDisposed();
    final txn = _native.ydocReadTransaction(_handle);
    return ReadTransaction(txn);
  }

  /// Opens a read-write transaction.
  WriteTransaction writeTransaction({String? origin}) {
    _checkDisposed();
    final originPtr = origin?.toNativeUtf8() ?? nullptr.cast<Utf8>();
    final originLen = origin?.length ?? 0;
    final txn = _native.ydocWriteTransaction(_handle, originLen, originPtr);
    if (origin != null) calloc.free(originPtr);
    return WriteTransaction(txn);
  }

  /// Convenience: opens a write transaction, executes [fn], then commits.
  void transact(void Function(WriteTransaction txn) fn, {String? origin}) {
    final txn = writeTransaction(origin: origin);
    try {
      fn(txn);
    } finally {
      txn.commit();
    }
  }

  /// Convenience: opens a read transaction, executes [fn], then commits.
  T readTransact<T>(T Function(ReadTransaction txn) fn) {
    final txn = readTransaction();
    try {
      return fn(txn);
    } finally {
      txn.commit();
    }
  }

  // ---------- State sync ----------

  /// Returns the state vector of this document as a binary blob (V1 encoding).
  Uint8List stateVectorV1() {
    return readTransact((txn) => txn.stateVectorV1());
  }

  /// Computes the diff between this document's state and a remote [stateVector].
  Uint8List stateDiffV1(Uint8List stateVector) {
    return readTransact((txn) => txn.stateDiffV1(stateVector));
  }

  /// Applies a binary update (V1 encoding) from a remote peer.
  void applyV1(Uint8List update) {
    transact((txn) => txn.applyV1(update));
  }

  // ---------- UndoManager ----------

  /// Creates an [UndoManager] scoped to the given shared type [branch].
  UndoManager undoManager(Pointer<BranchNative> branch) {
    _checkDisposed();
    return UndoManager(_handle, branch);
  }

  // ---------- Lifecycle ----------

  /// Releases native resources. The document must not be used after this.
  void dispose() {
    if (!_disposed) {
      _native.ydocDestroy(_handle);
      _disposed = true;
    }
  }

  void _checkDisposed() {
    if (_disposed) {
      throw StateError('YDoc has been disposed');
    }
  }

  /// Whether this document has been disposed.
  bool get isDisposed => _disposed;
}
