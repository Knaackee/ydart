import 'dart:ffi';
import 'dart:convert';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

import '../native/yrs_native.dart';

/// Helpers for constructing [YInputNative] values from Dart objects.
///
/// These mirror YDotNet's `Input` factory methods.
class YInput {
  YInput._();

  /// Allocates a YInput for [value], runs [fn], then frees the input.
  static T withValue<T>(Object? value, T Function(Pointer<YInputNative>) fn) {
    final input = fromValue(value);
    try {
      return fn(input);
    } finally {
      destroy(input);
    }
  }

  /// Allocates a YInput for a supported Dart value.
  static Pointer<YInputNative> fromValue(Object? value) {
    final ptr = calloc<YInputNative>();
    try {
      writeValue(ptr, value);
      return ptr;
    } catch (_) {
      calloc.free(ptr);
      rethrow;
    }
  }

  /// Writes a supported Dart [value] into an existing YInput cell.
  static void writeValue(Pointer<YInputNative> ptr, Object? value) {
    if (value == null) return writeNull(ptr);
    if (value is bool) return writeBoolean(ptr, value);
    if (value is int) return writeInteger(ptr, value);
    if (value is double) return writeNumber(ptr, value);
    if (value is String) return writeString(ptr, value);
    if (value is Map<String, Object?>) return writeJson(ptr, value);
    throw ArgumentError.value(
      value,
      'value',
      'Unsupported YInput value. Supported values are null, bool, int, double, and String.',
    );
  }

  /// Allocates a YInput for a JSON object.
  static Pointer<YInputNative> json(Map<String, Object?> value) {
    final ptr = calloc<YInputNative>();
    writeJson(ptr, value);
    return ptr;
  }

  /// Writes a JSON object into [ptr].
  static void writeJson(Pointer<YInputNative> ptr, Map<String, Object?> value) {
    final strPtr = jsonEncode(value).toNativeUtf8();
    ptr.ref.tag = YVal.json;
    ptr.ref.len = 1;
    ptr.ref.value = strPtr.cast();
  }

  /// Allocates a YInput for a boolean value.
  static Pointer<YInputNative> boolean(bool value) {
    final ptr = calloc<YInputNative>();
    writeBoolean(ptr, value);
    return ptr;
  }

  /// Writes a boolean value into [ptr].
  static void writeBoolean(Pointer<YInputNative> ptr, bool value) {
    ptr.ref.tag = YVal.jsonBool;
    ptr.ref.len = 1;
    ptr.ref.value = Pointer.fromAddress(value ? 1 : 0);
  }

  /// Allocates a YInput for a double value.
  static Pointer<YInputNative> number(double value) {
    final ptr = calloc<YInputNative>();
    writeNumber(ptr, value);
    return ptr;
  }

  /// Writes a double value into [ptr].
  static void writeNumber(Pointer<YInputNative> ptr, double value) {
    ptr.ref.tag = YVal.jsonNum;
    ptr.ref.len = 1;
    _valueBytes(ptr).setFloat64(0, value, Endian.host);
  }

  /// Allocates a YInput for an integer value.
  static Pointer<YInputNative> integer(int value) {
    final ptr = calloc<YInputNative>();
    writeInteger(ptr, value);
    return ptr;
  }

  /// Writes an integer value into [ptr].
  static void writeInteger(Pointer<YInputNative> ptr, int value) {
    ptr.ref.tag = YVal.jsonInt;
    ptr.ref.len = 1;
    _valueBytes(ptr).setInt64(0, value, Endian.host);
  }

  /// Allocates a YInput for a string value.
  static Pointer<YInputNative> string(String value) {
    final ptr = calloc<YInputNative>();
    writeString(ptr, value);
    return ptr;
  }

  /// Writes a string value into [ptr].
  static void writeString(Pointer<YInputNative> ptr, String value) {
    final strPtr = value.toNativeUtf8();
    ptr.ref.tag = YVal.jsonStr;
    ptr.ref.len = 1;
    ptr.ref.value = strPtr.cast();
  }

  /// Allocates a YInput for a null value.
  static Pointer<YInputNative> nullValue() {
    final ptr = calloc<YInputNative>();
    writeNull(ptr);
    return ptr;
  }

  /// Writes a null value into [ptr].
  static void writeNull(Pointer<YInputNative> ptr) {
    ptr.ref.tag = YVal.jsonNull;
    ptr.ref.len = 0;
    ptr.ref.value = nullptr;
  }

  /// Allocates a YInput for an undefined value.
  static Pointer<YInputNative> undefined() {
    final ptr = calloc<YInputNative>();
    writeUndefined(ptr);
    return ptr;
  }

  /// Writes an undefined value into [ptr].
  static void writeUndefined(Pointer<YInputNative> ptr) {
    ptr.ref.tag = YVal.jsonUndef;
    ptr.ref.len = 0;
    ptr.ref.value = nullptr;
  }

  /// Frees a YInput pointer (and nested content based on tag).
  static void destroy(Pointer<YInputNative> ptr) {
    if (ptr == nullptr) return;
    destroyContent(ptr);
    calloc.free(ptr);
  }

  /// Frees nested content for a YInput cell without freeing the cell itself.
  static void destroyContent(Pointer<YInputNative> ptr) {
    final tag = ptr.ref.tag;
    if (tag == YVal.json || tag == YVal.jsonStr || tag == YVal.jsonBuf) {
      calloc.free(ptr.ref.value);
    }
  }

  static ByteData _valueBytes(Pointer<YInputNative> ptr) {
    return ByteData.sublistView(ptr.cast<Uint8>().asTypedList(16), 8, 16);
  }
}

/// Helpers for reading [YOutputNative] values into Dart objects.
class YOutput {
  YOutput._();

  /// Reads a YOutput value into a Dart object.
  /// Returns null, bool, double, int, String, or the raw pointer for
  /// shared types (YText, YArray, YMap, etc.).
  static Object? read(Pointer<YOutputNative> ptr) {
    if (ptr == nullptr) return null;
    final tag = ptr.ref.tag;
    switch (tag) {
      case YVal.jsonNull:
        return null;
      case YVal.jsonUndef:
        return null;
      case YVal.jsonBool:
        return ptr.ref.value.address != 0;
      case YVal.jsonNum:
        return _valueBytes(ptr).getFloat64(0, Endian.host);
      case YVal.jsonInt:
        return _valueBytes(ptr).getInt64(0, Endian.host);
      case YVal.jsonStr:
        return ptr.ref.value.cast<Utf8>().toDartString();
      default:
        // For shared types, return the raw native pointer
        return ptr.ref.value;
    }
  }

  /// Reads a YOutput value and then releases the native output.
  static Object? readAndDestroy(
    Pointer<YOutputNative> ptr,
    void Function(Pointer<YOutputNative>) destroy,
  ) {
    if (ptr == nullptr) return null;
    final value = read(ptr);
    destroy(ptr);
    return value;
  }

  static ByteData _valueBytes(Pointer<YOutputNative> ptr) {
    return ByteData.sublistView(ptr.cast<Uint8>().asTypedList(16), 8, 16);
  }
}
