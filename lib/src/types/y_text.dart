import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../document/y_doc.dart';
import '../document/transaction.dart';
import '../native/yrs_native.dart';

/// A shared text type supporting collaborative rich-text editing.
///
/// Corresponds to `Y.Text` in Yjs and `YText` in YDotNet.
///
/// ```dart
/// final doc = YDoc();
/// final text = doc.getText('content');
/// doc.transact((txn) {
///   text.insert(txn, 0, 'Hello, world!');
/// });
/// print(doc.readTransact((txn) => text.getString(txn))); // Hello, world!
/// ```
class YText {
  final Pointer<BranchNative> _handle;
  final YDoc _doc;
  final YrsNative _native = YrsNative.instance;

  YText(this._handle, this._doc);

  /// The underlying native branch handle.
  Pointer<BranchNative> get handle => _handle;

  /// The parent document.
  YDoc get doc => _doc;

  /// Inserts [value] at the given [index].
  ///
  /// Optional [attributes] can be provided for rich-text formatting.
  void insert(
    WriteTransaction txn,
    int index,
    String value, {
    Pointer<YInputNative>? attributes,
  }) {
    final valuePtr = value.toNativeUtf8();
    _native.ytextInsert(
      _handle,
      txn.handle,
      index,
      valuePtr,
      attributes ?? nullptr.cast<YInputNative>(),
    );
    calloc.free(valuePtr);
  }

  /// Inserts an embedded object at [index].
  void insertEmbed(
    WriteTransaction txn,
    int index,
    Pointer<YInputNative> embed, {
    Pointer<YInputNative>? attributes,
  }) {
    _native.ytextInsertEmbed(
      _handle,
      txn.handle,
      index,
      embed,
      attributes ?? nullptr.cast<YInputNative>(),
    );
  }

  /// Deletes [length] characters starting at [index].
  void delete(WriteTransaction txn, int index, int length) {
    _native.ytextDelete(_handle, txn.handle, index, length);
  }

  /// Applies formatting [attributes] to [length] characters starting at [index].
  void format(
    WriteTransaction txn,
    int index,
    int length,
    Pointer<YInputNative> attributes,
  ) {
    _native.ytextFormat(_handle, txn.handle, index, length, attributes);
  }

  /// Returns the full string content of this text.
  String getString(ReadTransaction txn) {
    final ptr = _native.ytextString(_handle, txn.handle);
    final result = ptr.toDartString();
    _native.ystringDestroy(ptr);
    return result;
  }

  /// Returns the length of this text (in the document's encoding).
  int length(ReadTransaction txn) {
    return _native.ytextLen(_handle, txn.handle);
  }

  @override
  String toString() => 'YText($_handle)';
}
