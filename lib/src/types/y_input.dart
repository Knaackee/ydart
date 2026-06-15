import 'dart:ffi';

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
    if (value == null) return nullValue();
    if (value is bool) return boolean(value);
    if (value is int) return integer(value);
    if (value is double) return number(value);
    if (value is String) return string(value);
    throw ArgumentError.value(
      value,
      'value',
      'Unsupported YInput value. Supported values are null, bool, int, double, and String.',
    );
  }

  /// Allocates a YInput for a boolean value.
  static Pointer<YInputNative> boolean(bool value) {
    final ptr = calloc<YInputNative>();
    ptr.ref.tag = YVal.jsonBool;
    ptr.ref.len = 1;
    ptr.ref.value = Pointer.fromAddress(value ? 1 : 0);
    return ptr;
  }

  /// Allocates a YInput for a double value.
  static Pointer<YInputNative> number(double value) {
    final doublePtr = calloc<Double>();
    doublePtr.value = value;
    final ptr = calloc<YInputNative>();
    ptr.ref.tag = YVal.jsonNum;
    ptr.ref.len = 1;
    ptr.ref.value = doublePtr.cast();
    return ptr;
  }

  /// Allocates a YInput for an integer value.
  static Pointer<YInputNative> integer(int value) {
    final intPtr = calloc<Int64>();
    intPtr.value = value;
    final ptr = calloc<YInputNative>();
    ptr.ref.tag = YVal.jsonInt;
    ptr.ref.len = 1;
    ptr.ref.value = intPtr.cast();
    return ptr;
  }

  /// Allocates a YInput for a string value.
  static Pointer<YInputNative> string(String value) {
    final strPtr = value.toNativeUtf8();
    final ptr = calloc<YInputNative>();
    ptr.ref.tag = YVal.jsonStr;
    ptr.ref.len = 1;
    ptr.ref.value = strPtr.cast();
    return ptr;
  }

  /// Allocates a YInput for a null value.
  static Pointer<YInputNative> nullValue() {
    final ptr = calloc<YInputNative>();
    ptr.ref.tag = YVal.jsonNull;
    ptr.ref.len = 0;
    ptr.ref.value = nullptr;
    return ptr;
  }

  /// Allocates a YInput for an undefined value.
  static Pointer<YInputNative> undefined() {
    final ptr = calloc<YInputNative>();
    ptr.ref.tag = YVal.jsonUndef;
    ptr.ref.len = 0;
    ptr.ref.value = nullptr;
    return ptr;
  }

  /// Frees a YInput pointer (and nested content based on tag).
  static void destroy(Pointer<YInputNative> ptr) {
    if (ptr == nullptr) return;
    final tag = ptr.ref.tag;
    if (tag == YVal.jsonStr || tag == YVal.jsonBuf) {
      calloc.free(ptr.ref.value);
    } else if (tag == YVal.jsonNum || tag == YVal.jsonInt) {
      calloc.free(ptr.ref.value);
    }
    calloc.free(ptr);
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
        return ptr.ref.value.cast<Double>().value;
      case YVal.jsonInt:
        return ptr.ref.value.cast<Int64>().value;
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
}
