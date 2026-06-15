import 'dart:ffi';

import '../document/y_doc.dart';
import '../document/transaction.dart';
import '../native/yrs_native.dart';
import 'y_input.dart';

/// A shared array (ordered list) type.
///
/// Corresponds to `Y.Array` in Yjs and `YArray` in YDotNet.
class YArray {
  final Pointer<BranchNative> _handle;
  final YDoc _doc;
  final YrsNative _native = YrsNative.instance;

  YArray(this._handle, this._doc);

  Pointer<BranchNative> get handle => _handle;
  YDoc get doc => _doc;

  /// Inserts [values] at [index].
  void insertRange(
    WriteTransaction txn,
    int index,
    List<Pointer<YInputNative>> values,
  ) {
    if (values.isEmpty) return;
    for (var i = 0; i < values.length; i++) {
      _native.yarrayInsertRange(_handle, txn.handle, index + i, values[i], 1);
    }
  }

  /// Inserts supported Dart values at [index].
  void insertValues(WriteTransaction txn, int index, List<Object?> values) {
    if (values.isEmpty) return;
    for (var i = 0; i < values.length; i++) {
      YInput.withValue(values[i], (input) {
        _native.yarrayInsertRange(
          _handle,
          txn.handle,
          index + i,
          input,
          1,
        );
      });
    }
  }

  /// Removes [length] elements starting at [index].
  void removeRange(WriteTransaction txn, int index, int length) {
    _native.yarrayRemoveRange(_handle, txn.handle, index, length);
  }

  /// Returns the element at [index] as a Dart object.
  Object? get(ReadTransaction txn, int index) {
    final ptr = _native.yarrayGet(_handle, txn.handle, index);
    return YOutput.readAndDestroy(ptr, _native.youtputDestroy);
  }

  /// Returns the number of elements.
  int length(ReadTransaction txn) {
    return _native.yarrayLen(_handle, txn.handle);
  }

  /// Iterates over all elements and returns them as a list of Dart objects.
  List<Object?> toList(ReadTransaction txn) {
    final result = <Object?>[];
    final iter = _native.yarrayIter(_handle, txn.handle);
    try {
      while (true) {
        final item = _native.yarrayIterNext(iter);
        if (item == nullptr) break;
        result.add(YOutput.readAndDestroy(item, _native.youtputDestroy));
      }
    } finally {
      if (iter != nullptr) {
        _native.yarrayIterDestroy(iter);
      }
    }
    return result;
  }

  @override
  String toString() => 'YArray($_handle)';
}
