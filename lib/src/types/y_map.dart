import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../document/y_doc.dart';
import '../document/transaction.dart';
import '../native/yrs_native.dart';
import 'y_input.dart';

/// A shared map (key-value) type.
///
/// Corresponds to `Y.Map` in Yjs and `YMap` in YDotNet.
class YMap {
  final Pointer<BranchNative> _handle;
  final YDoc _doc;
  final YrsNative _native = YrsNative.instance;

  YMap(this._handle, this._doc);

  Pointer<BranchNative> get handle => _handle;
  YDoc get doc => _doc;

  /// Inserts or overwrites the value for [key].
  void insert(WriteTransaction txn, String key, Pointer<YInputNative> value) {
    final keyPtr = key.toNativeUtf8();
    _native.ymapInsert(_handle, txn.handle, keyPtr, value);
    calloc.free(keyPtr);
  }

  /// Inserts or overwrites [key] with a supported Dart value.
  void set(WriteTransaction txn, String key, Object? value) {
    YInput.withValue(value, (input) => insert(txn, key, input));
  }

  /// Removes the entry for [key]. Returns true if the entry existed.
  bool remove(WriteTransaction txn, String key) {
    final keyPtr = key.toNativeUtf8();
    final result = _native.ymapRemove(_handle, txn.handle, keyPtr);
    calloc.free(keyPtr);
    return result != 0;
  }

  /// Returns the value for [key], or null if not found.
  Object? get(ReadTransaction txn, String key) {
    final keyPtr = key.toNativeUtf8();
    final ptr = _native.ymapGet(_handle, txn.handle, keyPtr);
    calloc.free(keyPtr);
    return YOutput.readAndDestroy(ptr, _native.youtputDestroy);
  }

  /// Returns the number of entries.
  int length(ReadTransaction txn) {
    return _native.ymapLen(_handle, txn.handle);
  }

  /// Returns all entries as a Dart Map.
  Map<String, Object?> toMap(ReadTransaction txn) {
    final result = <String, Object?>{};
    final iter = _native.ymapIter(_handle, txn.handle);
    try {
      while (true) {
        final entry = _native.ymapIterNext(iter);
        if (entry == nullptr) break;
        final key = entry.ref.key.toDartString();
        result[key] = YOutput.read(entry.ref.value);
        _native.ymapEntryDestroy(entry);
      }
    } finally {
      if (iter != nullptr) {
        _native.ymapIterDestroy(iter);
      }
    }
    return result;
  }

  @override
  String toString() => 'YMap($_handle)';
}
