# FFI ownership audit

This audit tracks the ownership rules used by the Dart wrapper around yffi.

## Inputs allocated by Dart

| Dart allocation | Used by | Release rule |
| --- | --- | --- |
| `String.toNativeUtf8()` for keys/names/text | Root type lookup, map keys, text insertion, XML attributes | Free with `calloc.free` immediately after the native call returns. |
| `YInput.fromValue` primitive allocations | Map/array inserts and rich-text attributes | Prefer `YInput.withValue`, `YMap.set`, and `YArray.insertValues`; they release nested allocations in `finally`. Primitive union values are written inline, not through heap pointers. |
| `Uint8` buffers for updates/state vectors | `applyV1`, `stateDiffV1` | Free with `calloc.free` in `finally`. |
| `Uint32` length pointers | yffi binary-return APIs | Free with `calloc.free` in `finally`. |

## Values returned by yffi

| yffi return | Dart wrapper | Release rule |
| --- | --- | --- |
| `char*` from `ydoc_guid`, `ytext_string`, XML string/attribute APIs | `YDoc.guid`, `YText.getString`, XML getters | Convert immediately, then call `ystring_destroy`. |
| `uint8_t*` binary blobs | state vector/diff APIs | Copy to `Uint8List`, then call `ybinary_destroy`. |
| `YOutput*` from array/map/XML getters | `YOutput.readAndDestroy` | Read immediately, then call `youtput_destroy`. |
| `YArrayIter*`, `YMapIter*` | `toList`, `toMap` | Destroy iterator in `finally`. |
| `YMapEntry*` | `YMap.toMap` | Read key/value, then call `ymap_entry_destroy`. |
| `YUndoManager*` | `UndoManager` | Caller must call `dispose`; wrapper guards double dispose. |
| `YDoc*` | `YDoc` | Caller must call `dispose`; wrapper guards double dispose. |

## Transaction rules

`y-crdt/main` exposes a single `ytransaction_commit` function for both read and
write transactions. The Dart wrapper must use that symbol for `ReadTransaction`
and `WriteTransaction`; otherwise read transactions remain open and later write
transactions can return `NULL`.

`YDoc.readTransaction` and `YDoc.writeTransaction` fail fast with `StateError`
when yffi returns `NULL`, rather than passing null transactions into native
calls that would abort the process.

## Known limits

- Nested JSON arrays/maps are not exposed through the safe Dart-value API yet.
- Observer callbacks are bound at the FFI layer but do not yet have a safe Dart subscription API.
- `YDocOptions` is defined but not wired to `ydoc_new_with_options` yet.
- `NativeFinalizer` is not enabled; explicit `dispose` remains required for deterministic native cleanup.
