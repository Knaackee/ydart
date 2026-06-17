/// Flutter Android/iOS bindings for yrs (y-crdt), the Rust port of Yjs.
///
/// Port of [YDotNet](https://github.com/y-crdt/ydotnet) for Flutter mobile
/// applications, providing CRDT-based shared data types for collaborative,
/// offline-first apps.

// Document
export 'src/document/y_doc.dart';
export 'src/document/transaction.dart';
export 'src/document/undo_manager.dart';

// Shared types
export 'src/types/y_text.dart';
export 'src/types/y_array.dart';
export 'src/types/y_map.dart';
export 'src/types/y_xml_element.dart';
export 'src/types/y_xml_fragment.dart';
export 'src/types/y_xml_text.dart';
export 'src/types/y_input.dart';

// Native constants (for advanced use)
export 'src/native/yrs_native.dart' show YVal, YEncoding, YrsNative;
export 'src/native/yrs_exception.dart';
