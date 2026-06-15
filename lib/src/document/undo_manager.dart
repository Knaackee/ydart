import 'dart:ffi';

import '../native/yrs_native.dart';

/// Wraps the yrs UndoManager for undo/redo on a shared type scope.
class UndoManager {
  final Pointer<YUndoManagerNative> _handle;
  final YrsNative _native = YrsNative.instance;
  bool _disposed = false;

  UndoManager(Pointer<YDocNative> doc, Pointer<BranchNative> branch)
      : _handle = YrsNative.instance.yundoManager(doc, branch, nullptr);

  bool undo() {
    _checkDisposed();
    return _native.yundoManagerUndo(_handle) != 0;
  }

  bool redo() {
    _checkDisposed();
    return _native.yundoManagerRedo(_handle) != 0;
  }

  bool get canUndo {
    _checkDisposed();
    return _native.yundoManagerCanUndo(_handle) != 0;
  }

  bool get canRedo {
    _checkDisposed();
    return _native.yundoManagerCanRedo(_handle) != 0;
  }

  void clear() {
    _checkDisposed();
    _native.yundoManagerClear(_handle);
  }

  void dispose() {
    if (!_disposed) {
      _native.yundoManagerDestroy(_handle);
      _disposed = true;
    }
  }

  void _checkDisposed() {
    if (_disposed) throw StateError('UndoManager has been disposed');
  }
}
