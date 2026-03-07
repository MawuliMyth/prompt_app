import 'package:flutter/material.dart';

class ComposerLaunchRequest {
  const ComposerLaunchRequest({
    required this.token,
    this.initialText,
    this.categoryId,
  });

  final int token;
  final String? initialText;
  final String? categoryId;
}

class ShellProvider extends ChangeNotifier {
  int _currentIndex = 0;
  int _composerToken = 0;
  ComposerLaunchRequest? _pendingComposerRequest;

  int get currentIndex => _currentIndex;
  ComposerLaunchRequest? get pendingComposerRequest => _pendingComposerRequest;

  void selectTab(int index) {
    if (_currentIndex == index) return;
    _currentIndex = index;
    notifyListeners();
  }

  void openComposer({String? initialText, String? categoryId}) {
    _currentIndex = 0;
    _composerToken += 1;
    _pendingComposerRequest = ComposerLaunchRequest(
      token: _composerToken,
      initialText: initialText,
      categoryId: categoryId,
    );
    notifyListeners();
  }

  void clearComposerRequest() {
    _pendingComposerRequest = null;
    notifyListeners();
  }
}
