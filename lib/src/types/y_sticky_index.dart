import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

import '../document/transaction.dart';
import '../native/yrs_native.dart';
import 'y_xml_element.dart';
import 'y_xml_fragment.dart';
import 'y_xml_text.dart';

/// A stable CRDT position inside a shared sequence.
///
/// This wraps yrs' `StickyIndex`, the y-crdt counterpart of Yjs relative
/// positions. A sticky index keeps pointing at the same logical location as
/// concurrent inserts/deletes are integrated.
class YStickyIndex {
  YStickyIndex._(this._handle);

  final Pointer<StickyIndexNative> _handle;
  final YrsNative _native = YrsNative.instance;
  var _disposed = false;

  /// Creates a sticky index inside [branch] at [index].
  ///
  /// [assoc] follows Yjs/yrs semantics: negative values stick before
  /// concurrent inserts, positive values stick after them.
  factory YStickyIndex.fromXmlFragment(
    YXmlFragment branch,
    ReadTransaction txn,
    int index, {
    int assoc = 0,
  }) {
    return YStickyIndex._(
      YrsNative.instance.ystickyIndexFromIndex(
        branch.handle,
        txn.handle,
        index,
        assoc,
      ),
    );
  }

  /// Creates a sticky index inside [branch] at [index].
  factory YStickyIndex.fromXmlElement(
    YXmlElement branch,
    ReadTransaction txn,
    int index, {
    int assoc = 0,
  }) {
    return YStickyIndex._(
      YrsNative.instance.ystickyIndexFromIndex(
        branch.handle,
        txn.handle,
        index,
        assoc,
      ),
    );
  }

  /// Creates a sticky index inside [branch] at [index].
  factory YStickyIndex.fromXmlText(
    YXmlText branch,
    ReadTransaction txn,
    int index, {
    int assoc = 0,
  }) {
    return YStickyIndex._(
      YrsNative.instance.ystickyIndexFromIndex(
        branch.handle,
        txn.handle,
        index,
        assoc,
      ),
    );
  }

  /// Decodes a sticky index from its binary representation.
  factory YStickyIndex.decode(Uint8List data) {
    final dataPtr = calloc<Uint8>(data.length);
    try {
      dataPtr.asTypedList(data.length).setAll(0, data);
      return YStickyIndex._(
        YrsNative.instance.ystickyIndexRead(dataPtr, data.length),
      );
    } finally {
      calloc.free(dataPtr);
    }
  }

  /// Encodes this sticky index to a binary representation.
  Uint8List encode() {
    _checkDisposed();
    final lenPtr = calloc<Uint32>();
    try {
      final dataPtr = _native.ystickyIndexEncode(_handle, lenPtr);
      final len = lenPtr.value;
      if (dataPtr == nullptr) return Uint8List(0);
      final result = Uint8List.fromList(dataPtr.asTypedList(len));
      _native.ybinaryDestroy(dataPtr, len);
      return result;
    } finally {
      calloc.free(lenPtr);
    }
  }

  /// Resolves this sticky index to the current absolute index.
  int getIndex(ReadTransaction txn) {
    _checkDisposed();
    return _native.ystickyIndexGetIndex(_handle, txn.handle);
  }

  void dispose() {
    if (!_disposed) {
      _native.ystickyIndexDestroy(_handle);
      _disposed = true;
    }
  }

  void _checkDisposed() {
    if (_disposed) throw StateError('YStickyIndex has been disposed');
  }
}
