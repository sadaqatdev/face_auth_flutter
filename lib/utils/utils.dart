import 'package:flutter/foundation.dart';

dp(msg, arg) {
  debugPrint("\x1B[32m $msg   $arg", wrapWidth: 1500);
}

pe(msg, arg) {
  debugPrint("\x1B[31m $msg  ", wrapWidth: 1500);
  debugPrint("\x1B[31m $arg", wrapWidth: 1500);
}
