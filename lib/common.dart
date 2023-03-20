import 'dart:async';
import 'dart:convert';
import 'dart:ffi' hide Size;
import 'dart:io';
import 'dart:math';

import '../consts.dart';

final isAndroid = Platform.isAndroid;
final isIOS = Platform.isIOS;
final isDesktop = Platform.isWindows || Platform.isMacOS || Platform.isLinux;
var isWeb = false;
var isWebDesktop = false;
var version = "";
int androidVersion = 0;

/// * debug or test only, DO NOT enable in release build
bool isTest = false;

typedef F = String Function(String);
typedef FMethod = String Function(String, dynamic);

typedef StreamEventHandler = Future<void> Function(Map<String, dynamic>);
