import 'package:flutter/material.dart';

import 'page_type.dart';

class AppState extends ChangeNotifier {
  bool isLoggedIn = false;
  PageKey currentPage = PageKey.dashboard;
  bool collapsed = false;
  bool darkMode = false;

  void login() {
    isLoggedIn = true;
    notifyListeners();
  }

  void logout() {
    isLoggedIn = false;
    currentPage = PageKey.dashboard;
    notifyListeners();
  }

  void setPage(PageKey p) {
    currentPage = p;
    notifyListeners();
  }

  void toggleCollapsed() {
    collapsed = !collapsed;
    notifyListeners();
  }

  /// No-op when already in the requested state (used by responsive layout).
  void setCollapsed(bool v) {
    if (collapsed == v) return;
    collapsed = v;
    notifyListeners();
  }

  void toggleDarkMode() {
    darkMode = !darkMode;
    notifyListeners();
  }

  void setDarkMode(bool v) {
    if (darkMode == v) return;
    darkMode = v;
    notifyListeners();
  }
}