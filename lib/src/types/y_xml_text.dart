import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../document/y_doc.dart';
import '../document/transaction.dart';
import '../native/yrs_native.dart';

/// A shared XML text node type.
///
/// Corresponds to `Y.XmlText` in Yjs and `YXmlText` in YDotNet.
class YXmlText {
  final Pointer<BranchNative> _handle;
  final YDoc _doc;
  final YrsNative _native = YrsNative.instance;

  YXmlText(this._handle, this._doc);

  Pointer<BranchNative> get handle => _handle;
  YDoc get doc => _doc;

  /// Inserts [value] at [index] with optional formatting [attributes].
  void insert(
    WriteTransaction txn,
    int index,
    String value, {
    Pointer<YInputNative>? attributes,
  }) {
    final valuePtr = value.toNativeUtf8();
    _native.yxmltextInsert(
      _handle,
      txn.handle,
      index,
      valuePtr,
      attributes ?? nullptr.cast<YInputNative>(),
    );
    calloc.free(valuePtr);
  }

  /// Deletes [length] characters starting at [index].
  void delete(WriteTransaction txn, int index, int length) {
    _native.yxmltextDelete(_handle, txn.handle, index, length);
  }

  /// Returns the full text content.
  String getString(ReadTransaction txn) {
    final ptr = _native.yxmltextString(_handle, txn.handle);
    final result = ptr.toDartString();
    _native.ystringDestroy(ptr);
    return result;
  }

  /// Returns the length of this text.
  int length(ReadTransaction txn) {
    return _native.yxmltextLen(_handle, txn.handle);
  }

  /// Sets an attribute [name] to [value].
  void insertAttribute(WriteTransaction txn, String name, String value) {
    final namePtr = name.toNativeUtf8();
    final valuePtr = value.toNativeUtf8();
    _native.yxmltextInsertAttr(_handle, txn.handle, namePtr, valuePtr);
    calloc.free(namePtr);
    calloc.free(valuePtr);
  }

  /// Removes the attribute with [name].
  void removeAttribute(WriteTransaction txn, String name) {
    final namePtr = name.toNativeUtf8();
    _native.yxmltextRemoveAttr(_handle, txn.handle, namePtr);
    calloc.free(namePtr);
  }

  /// Returns the value of attribute [name], or null if absent.
  String? getAttribute(ReadTransaction txn, String name) {
    final namePtr = name.toNativeUtf8();
    final ptr = _native.yxmltextGetAttr(_handle, txn.handle, namePtr);
    calloc.free(namePtr);
    if (ptr == nullptr) return null;
    final result = ptr.toDartString();
    _native.ystringDestroy(ptr);
    return result;
  }

  @override
  String toString() => 'YXmlText($_handle)';
}
