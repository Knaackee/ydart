// ignore_for_file: unused_element

// Dart FFI bindings for libyrs (yffi crate of y-crdt).
// Modeled after YDotNet's Channel.cs — maps 1:1 to the yffi C API.
//
// Reference: https://github.com/y-crdt/y-crdt/blob/main/tests-ffi/include/libyrs.h

import 'dart:ffi';
import 'dart:io' show File, Platform;

import 'package:ffi/ffi.dart';

// ---------------------------------------------------------------------------
// Constants mirroring libyrs.h #defines
// ---------------------------------------------------------------------------

/// JSON / type tags used by YInput and YOutput.
abstract final class YVal {
  static const int json = -9;
  static const int jsonBool = -8;
  static const int jsonNum = -7;
  static const int jsonInt = -6;
  static const int jsonStr = -5;
  static const int jsonBuf = -4;
  static const int jsonArr = -3;
  static const int jsonMap = -2;
  static const int jsonNull = -1;
  static const int jsonUndef = 0;

  static const int array = 1;
  static const int map = 2;
  static const int text = 3;
  static const int xmlElem = 4;
  static const int xmlText = 5;
  static const int xmlFrag = 6;
  static const int doc = 7;
  static const int weakLink = 8;
  static const int undefined = 9;
}

/// Event change tags.
abstract final class YEventChangeTag {
  static const int add = 1;
  static const int delete = 2;
  static const int retain = 3;
}

/// Event key-change tags.
abstract final class YEventKeyChangeTag {
  static const int add = 4;
  static const int delete = 5;
  static const int update = 6;
}

/// Path segment tags.
abstract final class YPathSegmentTag {
  static const int key = 1;
  static const int index = 2;
}

/// Encoding offsets.
abstract final class YEncoding {
  static const int bytes = 0;
  static const int utf16 = 1;
}

// ---------------------------------------------------------------------------
// Opaque pointer typedefs
// ---------------------------------------------------------------------------

/// Opaque YDoc handle.
final class YDocNative extends Opaque {}

/// Opaque Branch handle (shared type: Text, Array, Map, Xml…).
final class BranchNative extends Opaque {}

/// Opaque read-only transaction.
final class TransactionNative extends Opaque {}

/// Opaque read-write transaction.
final class TransactionMutNative extends Opaque {}

/// Opaque subscription handle.
final class YSubscriptionNative extends Opaque {}

/// Opaque UndoManager handle.
final class YUndoManagerNative extends Opaque {}

/// Opaque StickyIndex handle.
final class StickyIndexNative extends Opaque {}

/// Opaque iterator handles.
final class YArrayIterNative extends Opaque {}

final class YMapIterNative extends Opaque {}

final class YXmlAttrIterNative extends Opaque {}

final class YXmlTreeWalkerNative extends Opaque {}

// ---------------------------------------------------------------------------
// Struct definitions
// ---------------------------------------------------------------------------

/// Corresponds to `YOptions` in libyrs.h.
final class YOptionsNative extends Struct {
  @Uint64()
  external int id;

  external Pointer<Utf8> guid;
  external Pointer<Utf8> collectionId;

  @Uint8()
  external int encoding;

  @Uint8()
  external int skipGc;

  @Uint8()
  external int autoLoad;

  @Uint8()
  external int shouldLoad;
}

/// Corresponds to `YOutput` in libyrs.h.
final class YOutputNative extends Struct {
  @Int8()
  external int tag;

  @Uint32()
  external int len;

  // Union content — we model it as the largest variant (Pointer).
  // Callers must interpret based on `tag`.
  external Pointer<Void> value;
}

/// Corresponds to `YInput` in libyrs.h.
final class YInputNative extends Struct {
  @Int8()
  external int tag;

  @Uint32()
  external int len;

  // Union content — modeled as opaque pointer, interpreted based on `tag`.
  external Pointer<Void> value;
}

/// Corresponds to `YMapEntry` in libyrs.h.
final class YMapEntryNative extends Struct {
  external Pointer<Utf8> key;
  external Pointer<YOutputNative> value;
}

/// Corresponds to `YEventChange` in libyrs.h.
final class YEventChangeNative extends Struct {
  @Uint8()
  external int tag;

  @Uint32()
  external int len;

  external Pointer<YOutputNative> values;
}

/// Corresponds to `YEventKeyChange` in libyrs.h.
final class YEventKeyChangeNative extends Struct {
  @Uint8()
  external int tag;

  external Pointer<Utf8> key;
  external Pointer<YOutputNative> oldValue;
  external Pointer<YOutputNative> newValue;
}

/// Corresponds to `YDeltaOut` in libyrs.h.
final class YDeltaOutNative extends Struct {
  @Uint8()
  external int tag;

  @Uint32()
  external int len;

  @Uint32()
  external int attributesLen;

  external Pointer<Void> attributes; // YDeltaAttr*
  external Pointer<YOutputNative> insert;
}

/// Corresponds to `YStateVector` in libyrs.h.
final class YStateVectorNative extends Struct {
  @Uint32()
  external int entriesCount;

  external Pointer<Uint64> clientIds;
  external Pointer<Uint32> clocks;
}

// ---------------------------------------------------------------------------
// Native function typedefs
// ---------------------------------------------------------------------------

// Doc lifecycle
typedef _ydoc_new_c = Pointer<YDocNative> Function();
typedef _ydoc_new_dart = Pointer<YDocNative> Function();

typedef _ydoc_new_with_options_c = Pointer<YDocNative> Function(
    YOptionsNative opts);
typedef _ydoc_new_with_options_dart = Pointer<YDocNative> Function(
    YOptionsNative opts);

typedef _ydoc_destroy_c = Void Function(Pointer<YDocNative> doc);
typedef _ydoc_destroy_dart = void Function(Pointer<YDocNative> doc);

typedef _ydoc_id_c = Uint64 Function(Pointer<YDocNative> doc);
typedef _ydoc_id_dart = int Function(Pointer<YDocNative> doc);

typedef _ydoc_guid_c = Pointer<Utf8> Function(Pointer<YDocNative> doc);
typedef _ydoc_guid_dart = Pointer<Utf8> Function(Pointer<YDocNative> doc);

typedef _ydoc_clone_c = Pointer<YDocNative> Function(Pointer<YDocNative> doc);
typedef _ydoc_clone_dart = Pointer<YDocNative> Function(
    Pointer<YDocNative> doc);

// Transactions
typedef _ydoc_read_transaction_c = Pointer<TransactionNative> Function(
    Pointer<YDocNative> doc);
typedef _ydoc_read_transaction_dart = Pointer<TransactionNative> Function(
    Pointer<YDocNative> doc);

typedef _ydoc_write_transaction_c = Pointer<TransactionMutNative> Function(
  Pointer<YDocNative> doc,
  Uint32 originLen,
  Pointer<Utf8> origin,
);
typedef _ydoc_write_transaction_dart = Pointer<TransactionMutNative> Function(
  Pointer<YDocNative> doc,
  int originLen,
  Pointer<Utf8> origin,
);

typedef _ytransaction_commit_c = Void Function(
    Pointer<TransactionMutNative> txn);
typedef _ytransaction_commit_dart = void Function(
    Pointer<TransactionMutNative> txn);

typedef _ytransaction_read_commit_c = Void Function(
    Pointer<TransactionNative> txn);
typedef _ytransaction_read_commit_dart = void Function(
    Pointer<TransactionNative> txn);

// State
typedef _ytransaction_state_vector_v1_c = Pointer<Uint8> Function(
  Pointer<TransactionNative> txn,
  Pointer<Uint32> len,
);
typedef _ytransaction_state_vector_v1_dart = Pointer<Uint8> Function(
  Pointer<TransactionNative> txn,
  Pointer<Uint32> len,
);

typedef _ytransaction_state_diff_v1_c = Pointer<Uint8> Function(
  Pointer<TransactionNative> txn,
  Pointer<Uint8> sv,
  Uint32 svLen,
  Pointer<Uint32> len,
);
typedef _ytransaction_state_diff_v1_dart = Pointer<Uint8> Function(
  Pointer<TransactionNative> txn,
  Pointer<Uint8> sv,
  int svLen,
  Pointer<Uint32> len,
);

typedef _ytransaction_apply_v1_c = Uint32 Function(
  Pointer<TransactionMutNative> txn,
  Pointer<Uint8> update,
  Uint32 updateLen,
);
typedef _ytransaction_apply_v1_dart = int Function(
  Pointer<TransactionMutNative> txn,
  Pointer<Uint8> update,
  int updateLen,
);

// Encode / Decode
typedef _ydoc_encode_state_as_update_v1_c = Pointer<Uint8> Function(
  Pointer<TransactionNative> txn,
  Pointer<Uint8> sv,
  Uint32 svLen,
  Pointer<Uint32> len,
);
typedef _ydoc_encode_state_as_update_v1_dart = Pointer<Uint8> Function(
  Pointer<TransactionNative> txn,
  Pointer<Uint8> sv,
  int svLen,
  Pointer<Uint32> len,
);

// Root types
typedef _ytext_c = Pointer<BranchNative> Function(
    Pointer<YDocNative> doc, Pointer<Utf8> name);
typedef _ytext_dart = Pointer<BranchNative> Function(
    Pointer<YDocNative> doc, Pointer<Utf8> name);

typedef _yarray_c = Pointer<BranchNative> Function(
    Pointer<YDocNative> doc, Pointer<Utf8> name);
typedef _yarray_dart = Pointer<BranchNative> Function(
    Pointer<YDocNative> doc, Pointer<Utf8> name);

typedef _ymap_c = Pointer<BranchNative> Function(
    Pointer<YDocNative> doc, Pointer<Utf8> name);
typedef _ymap_dart = Pointer<BranchNative> Function(
    Pointer<YDocNative> doc, Pointer<Utf8> name);

typedef _yxmlelem_c = Pointer<BranchNative> Function(
    Pointer<YDocNative> doc, Pointer<Utf8> name);
typedef _yxmlelem_dart = Pointer<BranchNative> Function(
    Pointer<YDocNative> doc, Pointer<Utf8> name);

typedef _yxmltext_c = Pointer<BranchNative> Function(
    Pointer<YDocNative> doc, Pointer<Utf8> name);
typedef _yxmltext_dart = Pointer<BranchNative> Function(
    Pointer<YDocNative> doc, Pointer<Utf8> name);

// YText operations
typedef _ytext_insert_c = Void Function(
  Pointer<BranchNative> txt,
  Pointer<TransactionMutNative> txn,
  Uint32 index,
  Pointer<Utf8> value,
  Pointer<YInputNative> attrs,
);
typedef _ytext_insert_dart = void Function(
  Pointer<BranchNative> txt,
  Pointer<TransactionMutNative> txn,
  int index,
  Pointer<Utf8> value,
  Pointer<YInputNative> attrs,
);

typedef _ytext_insert_embed_c = Void Function(
  Pointer<BranchNative> txt,
  Pointer<TransactionMutNative> txn,
  Uint32 index,
  Pointer<YInputNative> embed,
  Pointer<YInputNative> attrs,
);
typedef _ytext_insert_embed_dart = void Function(
  Pointer<BranchNative> txt,
  Pointer<TransactionMutNative> txn,
  int index,
  Pointer<YInputNative> embed,
  Pointer<YInputNative> attrs,
);

typedef _ytext_delete_c = Void Function(
  Pointer<BranchNative> txt,
  Pointer<TransactionMutNative> txn,
  Uint32 index,
  Uint32 len,
);
typedef _ytext_delete_dart = void Function(
  Pointer<BranchNative> txt,
  Pointer<TransactionMutNative> txn,
  int index,
  int len,
);

typedef _ytext_format_c = Void Function(
  Pointer<BranchNative> txt,
  Pointer<TransactionMutNative> txn,
  Uint32 index,
  Uint32 len,
  Pointer<YInputNative> attrs,
);
typedef _ytext_format_dart = void Function(
  Pointer<BranchNative> txt,
  Pointer<TransactionMutNative> txn,
  int index,
  int len,
  Pointer<YInputNative> attrs,
);

typedef _ytext_string_c = Pointer<Utf8> Function(
  Pointer<BranchNative> txt,
  Pointer<TransactionNative> txn,
);
typedef _ytext_string_dart = Pointer<Utf8> Function(
  Pointer<BranchNative> txt,
  Pointer<TransactionNative> txn,
);

typedef _ytext_len_c = Uint32 Function(
    Pointer<BranchNative> txt, Pointer<TransactionNative> txn);
typedef _ytext_len_dart = int Function(
    Pointer<BranchNative> txt, Pointer<TransactionNative> txn);

// YArray operations
typedef _yarray_insert_range_c = Void Function(
  Pointer<BranchNative> arr,
  Pointer<TransactionMutNative> txn,
  Uint32 index,
  Pointer<YInputNative> values,
  Uint32 len,
);
typedef _yarray_insert_range_dart = void Function(
  Pointer<BranchNative> arr,
  Pointer<TransactionMutNative> txn,
  int index,
  Pointer<YInputNative> values,
  int len,
);

typedef _yarray_remove_range_c = Void Function(
  Pointer<BranchNative> arr,
  Pointer<TransactionMutNative> txn,
  Uint32 index,
  Uint32 len,
);
typedef _yarray_remove_range_dart = void Function(
  Pointer<BranchNative> arr,
  Pointer<TransactionMutNative> txn,
  int index,
  int len,
);

typedef _yarray_get_c = Pointer<YOutputNative> Function(
  Pointer<BranchNative> arr,
  Pointer<TransactionNative> txn,
  Uint32 index,
);
typedef _yarray_get_dart = Pointer<YOutputNative> Function(
  Pointer<BranchNative> arr,
  Pointer<TransactionNative> txn,
  int index,
);

typedef _yarray_len_c = Uint32 Function(
    Pointer<BranchNative> arr, Pointer<TransactionNative> txn);
typedef _yarray_len_dart = int Function(
    Pointer<BranchNative> arr, Pointer<TransactionNative> txn);

typedef _yarray_iter_c = Pointer<YArrayIterNative> Function(
  Pointer<BranchNative> arr,
  Pointer<TransactionNative> txn,
);
typedef _yarray_iter_dart = Pointer<YArrayIterNative> Function(
  Pointer<BranchNative> arr,
  Pointer<TransactionNative> txn,
);

typedef _yarray_iter_next_c = Pointer<YOutputNative> Function(
    Pointer<YArrayIterNative> iter);
typedef _yarray_iter_next_dart = Pointer<YOutputNative> Function(
    Pointer<YArrayIterNative> iter);

typedef _yarray_iter_destroy_c = Void Function(Pointer<YArrayIterNative> iter);
typedef _yarray_iter_destroy_dart = void Function(
    Pointer<YArrayIterNative> iter);

// YMap operations
typedef _ymap_insert_c = Void Function(
  Pointer<BranchNative> map,
  Pointer<TransactionMutNative> txn,
  Pointer<Utf8> key,
  Pointer<YInputNative> value,
);
typedef _ymap_insert_dart = void Function(
  Pointer<BranchNative> map,
  Pointer<TransactionMutNative> txn,
  Pointer<Utf8> key,
  Pointer<YInputNative> value,
);

typedef _ymap_remove_c = Uint8 Function(
  Pointer<BranchNative> map,
  Pointer<TransactionMutNative> txn,
  Pointer<Utf8> key,
);
typedef _ymap_remove_dart = int Function(
  Pointer<BranchNative> map,
  Pointer<TransactionMutNative> txn,
  Pointer<Utf8> key,
);

typedef _ymap_get_c = Pointer<YOutputNative> Function(
  Pointer<BranchNative> map,
  Pointer<TransactionNative> txn,
  Pointer<Utf8> key,
);
typedef _ymap_get_dart = Pointer<YOutputNative> Function(
  Pointer<BranchNative> map,
  Pointer<TransactionNative> txn,
  Pointer<Utf8> key,
);

typedef _ymap_len_c = Uint32 Function(
    Pointer<BranchNative> map, Pointer<TransactionNative> txn);
typedef _ymap_len_dart = int Function(
    Pointer<BranchNative> map, Pointer<TransactionNative> txn);

typedef _ymap_iter_c = Pointer<YMapIterNative> Function(
  Pointer<BranchNative> map,
  Pointer<TransactionNative> txn,
);
typedef _ymap_iter_dart = Pointer<YMapIterNative> Function(
  Pointer<BranchNative> map,
  Pointer<TransactionNative> txn,
);

typedef _ymap_iter_next_c = Pointer<YMapEntryNative> Function(
    Pointer<YMapIterNative> iter);
typedef _ymap_iter_next_dart = Pointer<YMapEntryNative> Function(
    Pointer<YMapIterNative> iter);

typedef _ymap_iter_destroy_c = Void Function(Pointer<YMapIterNative> iter);
typedef _ymap_iter_destroy_dart = void Function(Pointer<YMapIterNative> iter);

// Observe callbacks
typedef YTextObserveCallback = Void Function(
    Pointer<Void> state, Pointer<Void> event);
typedef YArrayObserveCallback = Void Function(
    Pointer<Void> state, Pointer<Void> event);
typedef YMapObserveCallback = Void Function(
    Pointer<Void> state, Pointer<Void> event);
typedef YDocUpdateCallback = Void Function(
    Pointer<Void> state, Uint32 len, Pointer<Uint8> data);

typedef _ytext_observe_c = Pointer<YSubscriptionNative> Function(
  Pointer<BranchNative> txt,
  Pointer<Void> state,
  Pointer<NativeFunction<YTextObserveCallback>> cb,
);
typedef _ytext_observe_dart = Pointer<YSubscriptionNative> Function(
  Pointer<BranchNative> txt,
  Pointer<Void> state,
  Pointer<NativeFunction<YTextObserveCallback>> cb,
);

typedef _yarray_observe_c = Pointer<YSubscriptionNative> Function(
  Pointer<BranchNative> arr,
  Pointer<Void> state,
  Pointer<NativeFunction<YArrayObserveCallback>> cb,
);
typedef _yarray_observe_dart = Pointer<YSubscriptionNative> Function(
  Pointer<BranchNative> arr,
  Pointer<Void> state,
  Pointer<NativeFunction<YArrayObserveCallback>> cb,
);

typedef _ymap_observe_c = Pointer<YSubscriptionNative> Function(
  Pointer<BranchNative> map,
  Pointer<Void> state,
  Pointer<NativeFunction<YMapObserveCallback>> cb,
);
typedef _ymap_observe_dart = Pointer<YSubscriptionNative> Function(
  Pointer<BranchNative> map,
  Pointer<Void> state,
  Pointer<NativeFunction<YMapObserveCallback>> cb,
);

typedef _ydoc_observe_updates_v1_c = Pointer<YSubscriptionNative> Function(
  Pointer<YDocNative> doc,
  Pointer<Void> state,
  Pointer<NativeFunction<YDocUpdateCallback>> cb,
);
typedef _ydoc_observe_updates_v1_dart = Pointer<YSubscriptionNative> Function(
  Pointer<YDocNative> doc,
  Pointer<Void> state,
  Pointer<NativeFunction<YDocUpdateCallback>> cb,
);

typedef _yunobserve_c = Void Function(Pointer<YSubscriptionNative> sub);
typedef _yunobserve_dart = void Function(Pointer<YSubscriptionNative> sub);

// Event introspection
typedef _ytext_event_delta_c = Pointer<YDeltaOutNative> Function(
    Pointer<Void> event, Pointer<Uint32> len);
typedef _ytext_event_delta_dart = Pointer<YDeltaOutNative> Function(
    Pointer<Void> event, Pointer<Uint32> len);

typedef _yarray_event_delta_c = Pointer<YEventChangeNative> Function(
  Pointer<Void> event,
  Pointer<Uint32> len,
);
typedef _yarray_event_delta_dart = Pointer<YEventChangeNative> Function(
  Pointer<Void> event,
  Pointer<Uint32> len,
);

typedef _ymap_event_keys_c = Pointer<YEventKeyChangeNative> Function(
  Pointer<Void> event,
  Pointer<Uint32> len,
);
typedef _ymap_event_keys_dart = Pointer<YEventKeyChangeNative> Function(
  Pointer<Void> event,
  Pointer<Uint32> len,
);

typedef _yevent_path_c = Pointer<Void> Function(
    Pointer<Void> event, Pointer<Uint32> len);
typedef _yevent_path_dart = Pointer<Void> Function(
    Pointer<Void> event, Pointer<Uint32> len);

// UndoManager
typedef _yundo_manager_c = Pointer<YUndoManagerNative> Function(
  Pointer<YDocNative> doc,
  Pointer<BranchNative> branch,
  Pointer<Void> options,
);
typedef _yundo_manager_dart = Pointer<YUndoManagerNative> Function(
  Pointer<YDocNative> doc,
  Pointer<BranchNative> branch,
  Pointer<Void> options,
);

typedef _yundo_manager_undo_c = Uint8 Function(Pointer<YUndoManagerNative> mgr);
typedef _yundo_manager_undo_dart = int Function(
    Pointer<YUndoManagerNative> mgr);

typedef _yundo_manager_redo_c = Uint8 Function(Pointer<YUndoManagerNative> mgr);
typedef _yundo_manager_redo_dart = int Function(
    Pointer<YUndoManagerNative> mgr);

typedef _yundo_manager_destroy_c = Void Function(
    Pointer<YUndoManagerNative> mgr);
typedef _yundo_manager_destroy_dart = void Function(
    Pointer<YUndoManagerNative> mgr);

typedef _yundo_manager_can_undo_c = Uint8 Function(
    Pointer<YUndoManagerNative> mgr);
typedef _yundo_manager_can_undo_dart = int Function(
    Pointer<YUndoManagerNative> mgr);

typedef _yundo_manager_can_redo_c = Uint8 Function(
    Pointer<YUndoManagerNative> mgr);
typedef _yundo_manager_can_redo_dart = int Function(
    Pointer<YUndoManagerNative> mgr);

typedef _yundo_manager_clear_c = Void Function(Pointer<YUndoManagerNative> mgr);
typedef _yundo_manager_clear_dart = void Function(
    Pointer<YUndoManagerNative> mgr);

// Memory deallocation
typedef _ystring_destroy_c = Void Function(Pointer<Utf8> str);
typedef _ystring_destroy_dart = void Function(Pointer<Utf8> str);

typedef _ybinary_destroy_c = Void Function(Pointer<Uint8> buf, Uint32 len);
typedef _ybinary_destroy_dart = void Function(Pointer<Uint8> buf, int len);

typedef _youtput_destroy_c = Void Function(Pointer<YOutputNative> output);
typedef _youtput_destroy_dart = void Function(Pointer<YOutputNative> output);

typedef _ymap_entry_destroy_c = Void Function(Pointer<YMapEntryNative> entry);
typedef _ymap_entry_destroy_dart = void Function(
    Pointer<YMapEntryNative> entry);

// XmlElement
typedef _yxmlelem_insert_c = Pointer<BranchNative> Function(
  Pointer<BranchNative> xml,
  Pointer<TransactionMutNative> txn,
  Uint32 index,
  Pointer<Utf8> name,
);
typedef _yxmlelem_insert_dart = Pointer<BranchNative> Function(
  Pointer<BranchNative> xml,
  Pointer<TransactionMutNative> txn,
  int index,
  Pointer<Utf8> name,
);

typedef _yxmlelem_remove_range_c = Void Function(
  Pointer<BranchNative> xml,
  Pointer<TransactionMutNative> txn,
  Uint32 index,
  Uint32 len,
);
typedef _yxmlelem_remove_range_dart = void Function(
  Pointer<BranchNative> xml,
  Pointer<TransactionMutNative> txn,
  int index,
  int len,
);

typedef _yxmlelem_insert_text_c = Pointer<BranchNative> Function(
  Pointer<BranchNative> xml,
  Pointer<TransactionMutNative> txn,
  Uint32 index,
);
typedef _yxmlelem_insert_text_dart = Pointer<BranchNative> Function(
  Pointer<BranchNative> xml,
  Pointer<TransactionMutNative> txn,
  int index,
);

typedef _yxmlelem_get_c = Pointer<YOutputNative> Function(
  Pointer<BranchNative> xml,
  Pointer<TransactionNative> txn,
  Uint32 index,
);
typedef _yxmlelem_get_dart = Pointer<YOutputNative> Function(
  Pointer<BranchNative> xml,
  Pointer<TransactionNative> txn,
  int index,
);

typedef _yxmlelem_len_c = Uint32 Function(
    Pointer<BranchNative> xml, Pointer<TransactionNative> txn);
typedef _yxmlelem_len_dart = int Function(
    Pointer<BranchNative> xml, Pointer<TransactionNative> txn);

typedef _yxmlelem_insert_attr_c = Void Function(
  Pointer<BranchNative> xml,
  Pointer<TransactionMutNative> txn,
  Pointer<Utf8> name,
  Pointer<Utf8> value,
);
typedef _yxmlelem_insert_attr_dart = void Function(
  Pointer<BranchNative> xml,
  Pointer<TransactionMutNative> txn,
  Pointer<Utf8> name,
  Pointer<Utf8> value,
);

typedef _yxmlelem_remove_attr_c = Void Function(
  Pointer<BranchNative> xml,
  Pointer<TransactionMutNative> txn,
  Pointer<Utf8> name,
);
typedef _yxmlelem_remove_attr_dart = void Function(
  Pointer<BranchNative> xml,
  Pointer<TransactionMutNative> txn,
  Pointer<Utf8> name,
);

typedef _yxmlelem_get_attr_c = Pointer<Utf8> Function(
  Pointer<BranchNative> xml,
  Pointer<TransactionNative> txn,
  Pointer<Utf8> name,
);
typedef _yxmlelem_get_attr_dart = Pointer<Utf8> Function(
  Pointer<BranchNative> xml,
  Pointer<TransactionNative> txn,
  Pointer<Utf8> name,
);

typedef _yxmlelem_tag_c = Pointer<Utf8> Function(Pointer<BranchNative> xml);
typedef _yxmlelem_tag_dart = Pointer<Utf8> Function(Pointer<BranchNative> xml);

typedef _yxmlelem_string_c = Pointer<Utf8> Function(
  Pointer<BranchNative> xml,
  Pointer<TransactionNative> txn,
);
typedef _yxmlelem_string_dart = Pointer<Utf8> Function(
  Pointer<BranchNative> xml,
  Pointer<TransactionNative> txn,
);

// XmlText
typedef _yxmltext_insert_c = Void Function(
  Pointer<BranchNative> txt,
  Pointer<TransactionMutNative> txn,
  Uint32 index,
  Pointer<Utf8> value,
  Pointer<YInputNative> attrs,
);
typedef _yxmltext_insert_dart = void Function(
  Pointer<BranchNative> txt,
  Pointer<TransactionMutNative> txn,
  int index,
  Pointer<Utf8> value,
  Pointer<YInputNative> attrs,
);

typedef _yxmltext_delete_c = Void Function(
  Pointer<BranchNative> txt,
  Pointer<TransactionMutNative> txn,
  Uint32 index,
  Uint32 len,
);
typedef _yxmltext_delete_dart = void Function(
  Pointer<BranchNative> txt,
  Pointer<TransactionMutNative> txn,
  int index,
  int len,
);

typedef _yxmltext_string_c = Pointer<Utf8> Function(
  Pointer<BranchNative> txt,
  Pointer<TransactionNative> txn,
);
typedef _yxmltext_string_dart = Pointer<Utf8> Function(
  Pointer<BranchNative> txt,
  Pointer<TransactionNative> txn,
);

typedef _yxmltext_len_c = Uint32 Function(
    Pointer<BranchNative> txt, Pointer<TransactionNative> txn);
typedef _yxmltext_len_dart = int Function(
    Pointer<BranchNative> txt, Pointer<TransactionNative> txn);

typedef _yxmltext_insert_attr_c = Void Function(
  Pointer<BranchNative> txt,
  Pointer<TransactionMutNative> txn,
  Pointer<Utf8> name,
  Pointer<Utf8> value,
);
typedef _yxmltext_insert_attr_dart = void Function(
  Pointer<BranchNative> txt,
  Pointer<TransactionMutNative> txn,
  Pointer<Utf8> name,
  Pointer<Utf8> value,
);

typedef _yxmltext_remove_attr_c = Void Function(
  Pointer<BranchNative> txt,
  Pointer<TransactionMutNative> txn,
  Pointer<Utf8> name,
);
typedef _yxmltext_remove_attr_dart = void Function(
  Pointer<BranchNative> txt,
  Pointer<TransactionMutNative> txn,
  Pointer<Utf8> name,
);

typedef _yxmltext_get_attr_c = Pointer<Utf8> Function(
  Pointer<BranchNative> txt,
  Pointer<TransactionNative> txn,
  Pointer<Utf8> name,
);
typedef _yxmltext_get_attr_dart = Pointer<Utf8> Function(
  Pointer<BranchNative> txt,
  Pointer<TransactionNative> txn,
  Pointer<Utf8> name,
);

// StickyIndex
typedef _ysticky_index_from_index_c = Pointer<StickyIndexNative> Function(
  Pointer<BranchNative> branch,
  Pointer<TransactionNative> txn,
  Uint32 index,
  Uint8 assoc,
);
typedef _ysticky_index_from_index_dart = Pointer<StickyIndexNative> Function(
  Pointer<BranchNative> branch,
  Pointer<TransactionNative> txn,
  int index,
  int assoc,
);

typedef _ysticky_index_read_c = Pointer<StickyIndexNative> Function(
    Pointer<Uint8> data, Uint32 len);
typedef _ysticky_index_read_dart = Pointer<StickyIndexNative> Function(
    Pointer<Uint8> data, int len);

typedef _ysticky_index_encode_c = Pointer<Uint8> Function(
  Pointer<StickyIndexNative> index,
  Pointer<Uint32> len,
);
typedef _ysticky_index_encode_dart = Pointer<Uint8> Function(
  Pointer<StickyIndexNative> index,
  Pointer<Uint32> len,
);

typedef _ysticky_index_get_index_c = Int32 Function(
  Pointer<StickyIndexNative> index,
  Pointer<TransactionNative> txn,
);
typedef _ysticky_index_get_index_dart = int Function(
  Pointer<StickyIndexNative> index,
  Pointer<TransactionNative> txn,
);

typedef _ysticky_index_destroy_c = Void Function(
    Pointer<StickyIndexNative> index);
typedef _ysticky_index_destroy_dart = void Function(
    Pointer<StickyIndexNative> index);

// Type introspection
typedef _ytype_kind_c = Uint8 Function(Pointer<BranchNative> branch);
typedef _ytype_kind_dart = int Function(Pointer<BranchNative> branch);

// ---------------------------------------------------------------------------
// Library loader
// ---------------------------------------------------------------------------

/// Resolves the dynamic library path for the current platform.
DynamicLibrary _openYrsLibrary() {
  final overridePath = Platform.environment['YDART_LIBYRS_PATH'];
  if (overridePath != null && overridePath.isNotEmpty) {
    if (!File(overridePath).existsSync()) {
      throw StateError(
        'YDART_LIBYRS_PATH is set, but the file does not exist: $overridePath',
      );
    }
    return DynamicLibrary.open(overridePath);
  }

  if (Platform.isAndroid) return DynamicLibrary.open('libyrs.so');
  if (Platform.isIOS) return DynamicLibrary.process();
  throw UnsupportedError(
    'ydart supports Android and iOS only. Current platform: '
    '${Platform.operatingSystem}.',
  );
}

/// Singleton accessor for the native yrs library bindings.
class YrsNative {
  YrsNative._();

  static final YrsNative instance = YrsNative._();

  final DynamicLibrary _lib = _openYrsLibrary();

  // ---- Doc ----
  late final ydocNew = _lib.lookupFunction<_ydoc_new_c, _ydoc_new_dart>(
    'ydoc_new',
  );
  late final ydocDestroy =
      _lib.lookupFunction<_ydoc_destroy_c, _ydoc_destroy_dart>('ydoc_destroy');
  late final ydocId = _lib.lookupFunction<_ydoc_id_c, _ydoc_id_dart>('ydoc_id');
  late final ydocGuid = _lib.lookupFunction<_ydoc_guid_c, _ydoc_guid_dart>(
    'ydoc_guid',
  );
  late final ydocClone = _lib.lookupFunction<_ydoc_clone_c, _ydoc_clone_dart>(
    'ydoc_clone',
  );

  // ---- Transactions ----
  late final ydocReadTransaction = _lib
      .lookupFunction<_ydoc_read_transaction_c, _ydoc_read_transaction_dart>(
    'ydoc_read_transaction',
  );
  late final ydocWriteTransaction = _lib
      .lookupFunction<_ydoc_write_transaction_c, _ydoc_write_transaction_dart>(
    'ydoc_write_transaction',
  );
  late final ytransactionCommit =
      _lib.lookupFunction<_ytransaction_commit_c, _ytransaction_commit_dart>(
    'ytransaction_commit',
  );
  late final ytransactionReadCommit = _lib.lookupFunction<
      _ytransaction_read_commit_c,
      _ytransaction_read_commit_dart>('ytransaction_commit');

  // ---- State sync ----
  late final ytransactionStateVectorV1 = _lib.lookupFunction<
      _ytransaction_state_vector_v1_c,
      _ytransaction_state_vector_v1_dart>('ytransaction_state_vector_v1');
  late final ytransactionStateDiffV1 = _lib.lookupFunction<
      _ytransaction_state_diff_v1_c,
      _ytransaction_state_diff_v1_dart>('ytransaction_state_diff_v1');
  late final ytransactionApplyV1 = _lib
      .lookupFunction<_ytransaction_apply_v1_c, _ytransaction_apply_v1_dart>(
    'ytransaction_apply',
  );

  // ---- Root types ----
  late final ytext = _lib.lookupFunction<_ytext_c, _ytext_dart>('ytext');
  late final yarray = _lib.lookupFunction<_yarray_c, _yarray_dart>('yarray');
  late final ymap = _lib.lookupFunction<_ymap_c, _ymap_dart>('ymap');
  late final yxmlelem = _lib.lookupFunction<_yxmlelem_c, _yxmlelem_dart>(
    'yxmlelem',
  );
  late final yxmltext = _lib.lookupFunction<_yxmltext_c, _yxmltext_dart>(
    'yxmltext',
  );

  // ---- YText ----
  late final ytextInsert =
      _lib.lookupFunction<_ytext_insert_c, _ytext_insert_dart>('ytext_insert');
  late final ytextInsertEmbed =
      _lib.lookupFunction<_ytext_insert_embed_c, _ytext_insert_embed_dart>(
    'ytext_insert_embed',
  );
  late final ytextDelete =
      _lib.lookupFunction<_ytext_delete_c, _ytext_delete_dart>('ytext_delete');
  late final ytextFormat =
      _lib.lookupFunction<_ytext_format_c, _ytext_format_dart>('ytext_format');
  late final ytextString =
      _lib.lookupFunction<_ytext_string_c, _ytext_string_dart>('ytext_string');
  late final ytextLen = _lib.lookupFunction<_ytext_len_c, _ytext_len_dart>(
    'ytext_len',
  );

  // ---- YArray ----
  late final yarrayInsertRange =
      _lib.lookupFunction<_yarray_insert_range_c, _yarray_insert_range_dart>(
    'yarray_insert_range',
  );
  late final yarrayRemoveRange =
      _lib.lookupFunction<_yarray_remove_range_c, _yarray_remove_range_dart>(
    'yarray_remove_range',
  );
  late final yarrayGet = _lib.lookupFunction<_yarray_get_c, _yarray_get_dart>(
    'yarray_get',
  );
  late final yarrayLen = _lib.lookupFunction<_yarray_len_c, _yarray_len_dart>(
    'yarray_len',
  );
  late final yarrayIter =
      _lib.lookupFunction<_yarray_iter_c, _yarray_iter_dart>('yarray_iter');
  late final yarrayIterNext =
      _lib.lookupFunction<_yarray_iter_next_c, _yarray_iter_next_dart>(
    'yarray_iter_next',
  );
  late final yarrayIterDestroy =
      _lib.lookupFunction<_yarray_iter_destroy_c, _yarray_iter_destroy_dart>(
    'yarray_iter_destroy',
  );

  // ---- YMap ----
  late final ymapInsert =
      _lib.lookupFunction<_ymap_insert_c, _ymap_insert_dart>('ymap_insert');
  late final ymapRemove =
      _lib.lookupFunction<_ymap_remove_c, _ymap_remove_dart>('ymap_remove');
  late final ymapGet = _lib.lookupFunction<_ymap_get_c, _ymap_get_dart>(
    'ymap_get',
  );
  late final ymapLen = _lib.lookupFunction<_ymap_len_c, _ymap_len_dart>(
    'ymap_len',
  );
  late final ymapIter = _lib.lookupFunction<_ymap_iter_c, _ymap_iter_dart>(
    'ymap_iter',
  );
  late final ymapIterNext =
      _lib.lookupFunction<_ymap_iter_next_c, _ymap_iter_next_dart>(
    'ymap_iter_next',
  );
  late final ymapIterDestroy =
      _lib.lookupFunction<_ymap_iter_destroy_c, _ymap_iter_destroy_dart>(
    'ymap_iter_destroy',
  );

  // ---- XmlElement ----
  late final yxmlelemInsert =
      _lib.lookupFunction<_yxmlelem_insert_c, _yxmlelem_insert_dart>(
    'yxmlelem_insert',
  );
  late final yxmlelemRemoveRange = _lib
      .lookupFunction<_yxmlelem_remove_range_c, _yxmlelem_remove_range_dart>(
    'yxmlelem_remove_range',
  );
  late final yxmlelemInsertText =
      _lib.lookupFunction<_yxmlelem_insert_text_c, _yxmlelem_insert_text_dart>(
    'yxmlelem_insert_text',
  );
  late final yxmlelemGet =
      _lib.lookupFunction<_yxmlelem_get_c, _yxmlelem_get_dart>('yxmlelem_get');
  late final yxmlelemLen =
      _lib.lookupFunction<_yxmlelem_len_c, _yxmlelem_len_dart>('yxmlelem_len');
  late final yxmlelemInsertAttr =
      _lib.lookupFunction<_yxmlelem_insert_attr_c, _yxmlelem_insert_attr_dart>(
    'yxmlelem_insert_attr',
  );
  late final yxmlelemRemoveAttr =
      _lib.lookupFunction<_yxmlelem_remove_attr_c, _yxmlelem_remove_attr_dart>(
    'yxmlelem_remove_attr',
  );
  late final yxmlelemGetAttr =
      _lib.lookupFunction<_yxmlelem_get_attr_c, _yxmlelem_get_attr_dart>(
    'yxmlelem_get_attr',
  );
  late final yxmlelemTag =
      _lib.lookupFunction<_yxmlelem_tag_c, _yxmlelem_tag_dart>('yxmlelem_tag');
  late final yxmlelemString =
      _lib.lookupFunction<_yxmlelem_string_c, _yxmlelem_string_dart>(
    'yxmlelem_string',
  );

  // ---- XmlText ----
  late final yxmltextInsert =
      _lib.lookupFunction<_yxmltext_insert_c, _yxmltext_insert_dart>(
    'yxmltext_insert',
  );
  late final yxmltextDelete =
      _lib.lookupFunction<_yxmltext_delete_c, _yxmltext_delete_dart>(
    'yxmltext_delete',
  );
  late final yxmltextString =
      _lib.lookupFunction<_yxmltext_string_c, _yxmltext_string_dart>(
    'yxmltext_string',
  );
  late final yxmltextLen =
      _lib.lookupFunction<_yxmltext_len_c, _yxmltext_len_dart>('yxmltext_len');
  late final yxmltextInsertAttr =
      _lib.lookupFunction<_yxmltext_insert_attr_c, _yxmltext_insert_attr_dart>(
    'yxmltext_insert_attr',
  );
  late final yxmltextRemoveAttr =
      _lib.lookupFunction<_yxmltext_remove_attr_c, _yxmltext_remove_attr_dart>(
    'yxmltext_remove_attr',
  );
  late final yxmltextGetAttr =
      _lib.lookupFunction<_yxmltext_get_attr_c, _yxmltext_get_attr_dart>(
    'yxmltext_get_attr',
  );

  // ---- Observe ----
  late final ytextObserve = _lib
      .lookupFunction<_ytext_observe_c, _ytext_observe_dart>('ytext_observe');
  late final yarrayObserve =
      _lib.lookupFunction<_yarray_observe_c, _yarray_observe_dart>(
    'yarray_observe',
  );
  late final ymapObserve =
      _lib.lookupFunction<_ymap_observe_c, _ymap_observe_dart>('ymap_observe');
  late final ydocObserveUpdatesV1 = _lib.lookupFunction<
      _ydoc_observe_updates_v1_c,
      _ydoc_observe_updates_v1_dart>('ydoc_observe_updates_v1');
  late final yunobserve = _lib.lookupFunction<_yunobserve_c, _yunobserve_dart>(
    'yunobserve',
  );

  // ---- Event introspection ----
  late final ytextEventDelta =
      _lib.lookupFunction<_ytext_event_delta_c, _ytext_event_delta_dart>(
    'ytext_event_delta',
  );
  late final yarrayEventDelta =
      _lib.lookupFunction<_yarray_event_delta_c, _yarray_event_delta_dart>(
    'yarray_event_delta',
  );
  late final ymapEventKeys =
      _lib.lookupFunction<_ymap_event_keys_c, _ymap_event_keys_dart>(
    'ymap_event_keys',
  );

  // ---- UndoManager ----
  late final yundoManager = _lib
      .lookupFunction<_yundo_manager_c, _yundo_manager_dart>('yundo_manager');
  late final yundoManagerUndo =
      _lib.lookupFunction<_yundo_manager_undo_c, _yundo_manager_undo_dart>(
    'yundo_manager_undo',
  );
  late final yundoManagerRedo =
      _lib.lookupFunction<_yundo_manager_redo_c, _yundo_manager_redo_dart>(
    'yundo_manager_redo',
  );
  late final yundoManagerDestroy = _lib
      .lookupFunction<_yundo_manager_destroy_c, _yundo_manager_destroy_dart>(
    'yundo_manager_destroy',
  );
  late final yundoManagerCanUndo = _lib
      .lookupFunction<_yundo_manager_can_undo_c, _yundo_manager_can_undo_dart>(
    'yundo_manager_can_undo',
  );
  late final yundoManagerCanRedo = _lib
      .lookupFunction<_yundo_manager_can_redo_c, _yundo_manager_can_redo_dart>(
    'yundo_manager_can_redo',
  );
  late final yundoManagerClear =
      _lib.lookupFunction<_yundo_manager_clear_c, _yundo_manager_clear_dart>(
    'yundo_manager_clear',
  );

  // ---- StickyIndex ----
  late final ystickyIndexFromIndex = _lib.lookupFunction<
      _ysticky_index_from_index_c,
      _ysticky_index_from_index_dart>('ysticky_index_from_index');
  late final ystickyIndexRead =
      _lib.lookupFunction<_ysticky_index_read_c, _ysticky_index_read_dart>(
    'ysticky_index_read',
  );
  late final ystickyIndexEncode =
      _lib.lookupFunction<_ysticky_index_encode_c, _ysticky_index_encode_dart>(
    'ysticky_index_encode',
  );
  late final ystickyIndexGetIndex = _lib.lookupFunction<
      _ysticky_index_get_index_c,
      _ysticky_index_get_index_dart>('ysticky_index_get_index');
  late final ystickyIndexDestroy = _lib
      .lookupFunction<_ysticky_index_destroy_c, _ysticky_index_destroy_dart>(
    'ysticky_index_destroy',
  );

  // ---- Type introspection ----
  late final ytypeKind = _lib.lookupFunction<_ytype_kind_c, _ytype_kind_dart>(
    'ytype_kind',
  );

  // ---- Memory ----
  late final ystringDestroy =
      _lib.lookupFunction<_ystring_destroy_c, _ystring_destroy_dart>(
    'ystring_destroy',
  );
  late final ybinaryDestroy =
      _lib.lookupFunction<_ybinary_destroy_c, _ybinary_destroy_dart>(
    'ybinary_destroy',
  );
  late final youtputDestroy =
      _lib.lookupFunction<_youtput_destroy_c, _youtput_destroy_dart>(
    'youtput_destroy',
  );
  late final ymapEntryDestroy =
      _lib.lookupFunction<_ymap_entry_destroy_c, _ymap_entry_destroy_dart>(
    'ymap_entry_destroy',
  );
}
