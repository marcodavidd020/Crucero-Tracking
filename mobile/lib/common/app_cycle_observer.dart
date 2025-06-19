import 'package:flutter/widgets.dart';

class AppLifecycleObserver with WidgetsBindingObserver {


  static final ValueNotifier<bool> isInForeground = ValueNotifier(true);

  void start() {
    WidgetsBinding.instance.addObserver(this);
  }

  void stop() {
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    isInForeground.value = state == AppLifecycleState.resumed;
  }
}
