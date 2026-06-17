import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../document/transaction.dart';
import '../document/y_doc.dart';
import '../native/yrs_native.dart';
import 'y_input.dart';
import 'y_xml_element.dart';
import 'y_xml_text.dart';

/// A shared XML fragment type.
///
/// Corresponds to `Y.XmlFragment` in Yjs and is the supported root XML
/// container in current y-crdt/yffi.
class YXmlFragment {
  final Pointer<BranchNative> _handle;
  final YDoc _doc;
  final YrsNative _native = YrsNative.instance;

  YXmlFragment(this._handle, this._doc);

  Pointer<BranchNative> get handle => _handle;
  YDoc get doc => _doc;

  /// Inserts a child XML element with [name] at [index].
  YXmlElement insertElement(WriteTransaction txn, int index, String name) {
    final namePtr = name.toNativeUtf8();
    try {
      final child = _native.yxmlelemInsert(_handle, txn.handle, index, namePtr);
      return YXmlElement(child, _doc);
    } finally {
      calloc.free(namePtr);
    }
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

  /// Returns the XML string representation of this fragment.
  String getString(ReadTransaction txn) {
    final buffer = StringBuffer();
    final childCount = length(txn);
    for (var index = 0; index < childCount; index++) {
      final output = _native.yxmlelemGet(_handle, txn.handle, index);
      if (output == nullptr) continue;
      try {
        final child = output.ref.value.cast<BranchNative>();
        Pointer<Utf8> stringPtr;
        if (output.ref.tag == YVal.xmlText) {
          stringPtr = _native.yxmltextString(child, txn.handle);
        } else if (output.ref.tag == YVal.xmlElem) {
          stringPtr = _native.yxmlelemString(child, txn.handle);
        } else {
          continue;
        }
        try {
          buffer.write(stringPtr.toDartString());
        } finally {
          _native.ystringDestroy(stringPtr);
        }
      } finally {
        _native.youtputDestroy(output);
      }
    }
    return buffer.toString();
  }

  @override
  String toString() => 'YXmlFragment($_handle)';
}
