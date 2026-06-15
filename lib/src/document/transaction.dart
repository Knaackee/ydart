import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

import '../native/yrs_exception.dart';
import '../native/yrs_native.dart';

/// Read-only transaction. Obtain via [YDoc.readTransaction].
class ReadTransaction {
  final Pointer<TransactionNative> _handle;
  final YrsNative _native = YrsNative.instance;
  bool _committed = false;

  ReadTransaction(this._handle);

  /// The native handle. Throws if already committed.
  Pointer<TransactionNative> get handle {
    _checkCommitted();
    return _handle;
  }

  /// Encodes the current state vector as a V1 binary blob.
  Uint8List stateVectorV1() {
    _checkCommitted();
    final lenPtr = calloc<Uint32>();
    try {
      final dataPtr = _native.ytransactionStateVectorV1(_handle, lenPtr);
      final len = lenPtr.value;
      if (dataPtr == nullptr) return Uint8List(0);
      final result = Uint8List.fromList(dataPtr.asTypedList(len));
      _native.ybinaryDestroy(dataPtr, len);
      return result;
    } finally {
      calloc.free(lenPtr);
    }
  }

  /// Computes the state diff between this document and a remote [stateVector].
  Uint8List stateDiffV1(Uint8List stateVector) {
    _checkCommitted();
    final svPtr = calloc<Uint8>(stateVector.length);
    final lenPtr = calloc<Uint32>();
    try {
      svPtr.asTypedList(stateVector.length).setAll(0, stateVector);
      final dataPtr = _native.ytransactionStateDiffV1(
        _handle,
        svPtr,
        stateVector.length,
        lenPtr,
      );
      final len = lenPtr.value;
      if (dataPtr == nullptr) return Uint8List(0);
      final result = Uint8List.fromList(dataPtr.asTypedList(len));
      _native.ybinaryDestroy(dataPtr, len);
      return result;
    } finally {
      calloc.free(lenPtr);
      calloc.free(svPtr);
    }
  }

  /// Commits (releases) this read transaction.
  void commit() {
    if (!_committed) {
      _native.ytransactionReadCommit(_handle);
      _committed = true;
    }
  }

  void _checkCommitted() {
    if (_committed) {
      throw StateError('Transaction has already been committed');
    }
  }

  /// Whether this transaction has been committed.
  bool get isCommitted => _committed;
}

/// Read-write transaction. Obtain via [YDoc.writeTransaction].
class WriteTransaction {
  final Pointer<TransactionMutNative> _handle;
  final YrsNative _native = YrsNative.instance;
  bool _committed = false;

  WriteTransaction(this._handle);

  /// The native handle. Throws if already committed.
  Pointer<TransactionMutNative> get handle {
    _checkCommitted();
    return _handle;
  }

  /// Applies a V1-encoded binary update from a remote peer.
  ///
  /// Throws [YrsException] when yffi rejects the update payload.
  void applyV1(Uint8List update) {
    _checkCommitted();
    final updatePtr = calloc<Uint8>(update.length);
    try {
      updatePtr.asTypedList(update.length).setAll(0, update);
      final result = _native.ytransactionApplyV1(
        _handle,
        updatePtr,
        update.length,
      );
      if (result != 0) {
        throw YrsException('applyV1', result);
      }
    } finally {
      calloc.free(updatePtr);
    }
  }

  /// The native pointer cast to a read-only view for operations that
  /// accept either transaction type.
  Pointer<TransactionNative> get readHandle =>
      _handle.cast<TransactionNative>();

  /// Encodes the current state vector as a V1 binary blob.
  Uint8List stateVectorV1() {
    _checkCommitted();
    final lenPtr = calloc<Uint32>();
    try {
      final dataPtr = _native.ytransactionStateVectorV1(readHandle, lenPtr);
      final len = lenPtr.value;
      if (dataPtr == nullptr) return Uint8List(0);
      final result = Uint8List.fromList(dataPtr.asTypedList(len));
      _native.ybinaryDestroy(dataPtr, len);
      return result;
    } finally {
      calloc.free(lenPtr);
    }
  }

  /// Computes the state diff between this document and a remote [stateVector].
  Uint8List stateDiffV1(Uint8List stateVector) {
    _checkCommitted();
    final svPtr = calloc<Uint8>(stateVector.length);
    final lenPtr = calloc<Uint32>();
    try {
      svPtr.asTypedList(stateVector.length).setAll(0, stateVector);
      final dataPtr = _native.ytransactionStateDiffV1(
        readHandle,
        svPtr,
        stateVector.length,
        lenPtr,
      );
      final len = lenPtr.value;
      if (dataPtr == nullptr) return Uint8List(0);
      final result = Uint8List.fromList(dataPtr.asTypedList(len));
      _native.ybinaryDestroy(dataPtr, len);
      return result;
    } finally {
      calloc.free(lenPtr);
      calloc.free(svPtr);
    }
  }

  /// Commits (releases) this write transaction.
  void commit() {
    if (!_committed) {
      _native.ytransactionCommit(_handle);
      _committed = true;
    }
  }

  void _checkCommitted() {
    if (_committed) {
      throw StateError('Transaction has already been committed');
    }
  }

  bool get isCommitted => _committed;
}
