import 'package:rust_chatgpt/bridge_generated.dart';
import 'native_model.dart' if (dart.library.html) 'web_model.dart';

final platformFFI = PlatformFFI.instance;
final localeName = PlatformFFI.localeName;

NativeImpl get bind => platformFFI.ffiBind;
