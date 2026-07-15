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