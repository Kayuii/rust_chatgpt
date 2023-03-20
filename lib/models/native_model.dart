import 'dart:convert';
import 'dart:ffi';
import 'dart:io' as io;
// import 'dart:typed_data';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:external_path/external_path.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:rust_chatgpt/bridge_definitions.dart';
// import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
// ignore: import_of_legacy_library_into_null_safe
import 'package:path_provider/path_provider.dart';

import '../common.dart';
import '../consts.dart';
import '../bridge_generated.dart';
// export '../bridge_generated.dart';

typedef HandleEvent = Future<void> Function(Map<String, dynamic> evt);

class PlatformFFI {
  String _dir = '';
  // _homeDir is only needed for Android and IOS.
  String _homeDir = '';
  final _eventHandlers = <String, Map<String, HandleEvent>>{};
  late NativeImpl _ffiBind;
  late String _appType;
  StreamEventHandler? _eventCallback;

  PlatformFFI._();

  static final PlatformFFI instance = PlatformFFI._();

  NativeImpl get ffiBind => _ffiBind;

  static get localeName => io.Platform.localeName;

  static get isMain => instance._appType == kAppTypeMain;

  static Future<String> getVersion() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version;
  }

  bool registerEventHandler(
      String eventName, String handlerName, HandleEvent handler) {
    debugPrint('registerEventHandler $eventName $handlerName');
    var handlers = _eventHandlers[eventName];
    if (handlers == null) {
      _eventHandlers[eventName] = {handlerName: handler};
      return true;
    } else {
      if (handlers.containsKey(handlerName)) {
        return false;
      } else {
        handlers[handlerName] = handler;
        return true;
      }
    }
  }

  void unregisterEventHandler(String eventName, String handlerName) {
    debugPrint('unregisterEventHandler $eventName $handlerName');
    var handlers = _eventHandlers[eventName];
    if (handlers != null) {
      handlers.remove(handlerName);
    }
  }

  /// Init the FFI class, loads the native Rust core library.
  Future<void> init(String appType) async {
    _appType = appType;

    // final path = Platform.isWindows
    //     ? '$kEnvDynamicLinkLibrary.dll'
    //     : Platform.isMacOS
    //         ? 'lib$kEnvDynamicLinkLibrary.dylib'
    //         : 'lib$kEnvDynamicLinkLibrary.so';
    final path = io.Platform.isWindows
        ? '$kEnvDynamicLinkLibrary.dll'
        : 'lib$kEnvDynamicLinkLibrary.so';

    late final dylib = io.Platform.isIOS || io.Platform.isMacOS
        ? DynamicLibrary.process()
        : DynamicLibrary.open(path);

    // final dylib = Platform.isAndroid
    //     ? DynamicLibrary.open('lib$kEnvDynamicLinkLibrary.so')
    //     : Platform.isLinux
    //         ? DynamicLibrary.open('lib$kEnvDynamicLinkLibrary.so')
    //         : Platform.isWindows
    //             ? DynamicLibrary.open('$kEnvDynamicLinkLibrary.dll')
    //             : Platform.isMacOS
    //                 ? DynamicLibrary.open("lib$kEnvDynamicLinkLibrary.dylib")
    //                 : DynamicLibrary.process();

    debugPrint('initializing FFI $_appType');
    try {
      try {
        // SYSTEM user failed
        _dir = (await getApplicationDocumentsDirectory()).path;
      } catch (e) {
        debugPrint('Failed to get documents directory: $e');
      }

      _ffiBind = NativeImpl(dylib);

      if (io.Platform.isLinux) {
      } else if (io.Platform.isMacOS && isMain) {
        // Future.wait([
        // Start dbus service.
        // _ffiBind.mainStartDbusServer(),
        // Start local audio pulseaudio server.
        // _ffiBind.mainStartPa()
        // ]);
      }
      _startListenEvent(_ffiBind); // global event
      try {
        if (isAndroid) {
          // only support for android
          _homeDir = (await ExternalPath.getExternalStorageDirectories())[0];
        } else if (isIOS) {
          // _homeDir = _ffiBind.mainGetDataDirIos();
        } else {
          // no need to set home dir
        }
      } catch (e) {
        debugPrintStack(label: 'initialize failed: $e');
      }
      String id = 'NA';
      String name = 'Flutter';
      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      if (io.Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        name = '${androidInfo.brand}-${androidInfo.model}';
        id = androidInfo.id.hashCode.toString();
        androidVersion = androidInfo.version.sdkInt ?? 0;
      } else if (io.Platform.isIOS) {
        IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        name = iosInfo.utsname.machine ?? '';
        id = iosInfo.identifierForVendor.hashCode.toString();
      } else if (io.Platform.isLinux) {
        LinuxDeviceInfo linuxInfo = await deviceInfo.linuxInfo;
        name = linuxInfo.name;
        id = linuxInfo.machineId ?? linuxInfo.id;
      } else if (io.Platform.isWindows) {
        try {
          // request windows build number to fix overflow on win7
          // windowsBuildNumber = getWindowsTargetBuildNumber();
          // windowsBuildNumber = 0;
          WindowsDeviceInfo winInfo = await deviceInfo.windowsInfo;
          name = winInfo.computerName;
          id = winInfo.computerName;
        } catch (e) {
          debugPrintStack(label: "get windows device info failed: $e");
          name = "unknown";
          id = "unknown";
        }
      } else if (io.Platform.isMacOS) {
        MacOsDeviceInfo macOsInfo = await deviceInfo.macOsInfo;
        name = macOsInfo.computerName;
        id = macOsInfo.systemGUID ?? '';
      }
      if (isAndroid || isIOS) {
        debugPrint(
            '_appType:$_appType,info1-id:$id,info2-name:$name,dir:$_dir,homeDir:$_homeDir');
      } else {
        debugPrint(
            '_appType:$_appType,info1-id:$id,info2-name:$name,dir:$_dir');
      }
      // if (desktopType == DesktopType.cm) {
      //   await _ffiBind.cmStartListenIpcThread();
      // }
      // await _ffiBind.mainDeviceId(id: id);
      // await _ffiBind.mainDeviceName(name: name);
      // await _ffiBind.mainSetHomeDir(home: _homeDir);
      // await _ffiBind.mainInit(appDir: _dir);
    } catch (e) {
      debugPrintStack(label: 'initialize failed: $e');
    }
    version = await getVersion();
  }

  Future<bool> _tryHandle(Map<String, dynamic> evt) async {
    final name = evt['name'];
    if (name != null) {
      final handlers = _eventHandlers[name];
      if (handlers != null) {
        if (handlers.isNotEmpty) {
          for (var handler in handlers.values) {
            await handler(evt);
          }
          return true;
        }
      }
    }
    return false;
  }

  /// Start listening to the Native core's events and frames.
  void _startListenEvent(NativeImpl ffiImpl) {
    () async {
      await for (final message
          in ffiImpl.startGlobalEventStream(appType: _appType)) {
        try {
          Map<String, dynamic> event = json.decode(message);
          // _tryHandle here may be more flexible than _eventCallback
          if (!await _tryHandle(event)) {
            if (_eventCallback != null) {
              await _eventCallback!(event);
            }
          }
        } catch (e) {
          debugPrint('json.decode fail(): $e');
        }
      }
    }();
  }

  Future<Platform> platform() {
    return _ffiBind.platform();
  }

  Future<bool> rustReleaseMode() {
    return _ffiBind.rustReleaseMode();
  }

  Future<String> getHelleworld() {
    return _ffiBind.getHelleworld();
  }
}
