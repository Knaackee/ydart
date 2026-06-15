import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:test/test.dart';
import 'package:ydart/ydart.dart';

void main() {
  group('YInput', () {
    test('allocates primitive values with expected tags', () {
      final values = <Object?>[null, true, 1, 1.5, 'text'];
      final tags = <int>[
        YVal.jsonNull,
        YVal.jsonBool,
        YVal.jsonInt,
        YVal.jsonNum,
        YVal.jsonStr,
      ];

      for (var i = 0; i < values.length; i++) {
        final input = YInput.fromValue(values[i]);
        try {
          expect(input.ref.tag, tags[i]);
        } finally {
          YInput.destroy(input);
        }
      }
    });

    test('withValue frees after callback and returns callback value', () {
      final result = YInput.withValue('abc', (input) {
        expect(input, isNot(nullptr));
        expect(input.ref.tag, YVal.jsonStr);
        return input.ref.value.cast<Utf8>().toDartString();
      });

      expect(result, 'abc');
    });

    test('rejects unsupported values', () {
      expect(() => YInput.fromValue(<String>[]), throwsArgumentError);
      expect(() => YInput.fromValue(<String, Object?>{}), throwsArgumentError);
    });
  });

  group('YrsException', () {
    test('includes operation and code', () {
      expect(
        const YrsException('applyV1', 1).toString(),
        contains('applyV1 failed with code 1'),
      );
    });
  });
}
