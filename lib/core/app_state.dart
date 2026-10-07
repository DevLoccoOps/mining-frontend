import 'package:flutter/material.dart';

import 'page_type.dart';

class AppState extends ChangeNotifier {
  bool isLoggedIn = false;
  PageKey currentPage = PageKey.dashboard;
  bool collapsed = false;
  bool darkMode = false;

  /// Global search query set from the top bar; consumed by Live Tracking.
  String searchQuery = '';

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

  void setSearch(String q) {
    if (searchQuery == q) return;
    searchQuery = q;
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