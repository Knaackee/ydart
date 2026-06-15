import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../document/y_doc.dart';
import '../document/transaction.dart';
import '../native/yrs_native.dart';
import 'y_input.dart';
import 'y_xml_text.dart';

/// A shared XML element type.
///
/// Corresponds to `Y.XmlElement` in Yjs and `YXmlElement` in YDotNet.
class YXmlElement {
  final Pointer<BranchNative> _handle;
  final YDoc _doc;
  final YrsNative _native = YrsNative.instance;

  YXmlElement(this._handle, this._doc);

  Pointer<BranchNative> get handle => _handle;
  YDoc get doc => _doc;

  /// Inserts a child XML element with [name] at [index].
  YXmlElement insertElement(WriteTransaction txn, int index, String name) {
    final namePtr = name.toNativeUtf8();
    final child = _native.yxmlelemInsert(_handle, txn.handle, index, namePtr);
    calloc.free(namePtr);
    return YXmlElement(child, _doc);
  }

  /// Inserts a child XML text node at [index].
  YXmlText insertText(WriteTransaction txn, int index) {
    final child = _native.yxmlelemInsertText(_handle, txn.handle, index);
    return YXmlText(child, _doc);
  }

  /// Removes [length] child nodes starting at [index].
  void removeRange(WriteTransaction txn, int index, int length) {
    _native.yxmlelemRemoveRange(_handle, txn.handle, index, length);
  }

  /// Returns the child at [index].
  Object? get(ReadTransaction txn, int index) {
    final ptr = _native.yxmlelemGet(_handle, txn.handle, index);
    return YOutput.readAndDestroy(ptr, _native.youtputDestroy);
  }

  /// Returns the number of child nodes.
  int length(ReadTransaction txn) {
    return _native.yxmlelemLen(_handle, txn.handle);
  }

  /// Sets an attribute [name] to [value].
  void insertAttribute(WriteTransaction txn, String name, String value) {
    final namePtr = name.toNativeUtf8();
    final valuePtr = value.toNativeUtf8();
    _native.yxmlelemInsertAttr(_handle, txn.handle, namePtr, valuePtr);
    calloc.free(namePtr);
    calloc.free(valuePtr);
  }

  /// Removes the attribute with [name].
  void removeAttribute(WriteTransaction txn, String name) {
    final namePtr = name.toNativeUtf8();
    _native.yxmlelemRemoveAttr(_handle, txn.handle, namePtr);
    calloc.free(namePtr);
  }

  /// Returns the value of attribute [name], or null if absent.
  String? getAttribute(ReadTransaction txn, String name) {
    final namePtr = name.toNativeUtf8();
    final ptr = _native.yxmlelemGetAttr(_handle, txn.handle, namePtr);
    calloc.free(namePtr);
    if (ptr == nullptr) return null;
    final result = ptr.toDartString();
    _native.ystringDestroy(ptr);
    return result;
  }

  /// Returns the tag name of this element.
  String get tag {
    final ptr = _native.yxmlelemTag(_handle);
    final result = ptr.toDartString();
    _native.ystringDestroy(ptr);
    return result;
  }

  /// Returns the XML string representation.
  String getString(ReadTransaction txn) {
    final ptr = _native.yxmlelemString(_handle, txn.handle);
    final result = ptr.toDartString();
    _native.ystringDestroy(ptr);
    return result;
  }

  @override
  String toString() => 'YXmlElement($_handle)';
}
