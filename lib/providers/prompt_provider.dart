import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/models/prompt_model.dart';
import '../../data/repositories/prompt_repository.dart';
import '../../data/repositories/firestore_repository.dart';

class PromptProvider extends ChangeNotifier {
  final PromptRepository _promptRepository = PromptRepository();
  final FirestoreRepository _firestoreRepository = FirestoreRepository();

  List<PromptModel> _prompts = [];
  StreamSubscription<List<PromptModel>>? _subscription;
  String? _currentUserId;

  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  String _selectedCategoryFilter = 'All';

  List<PromptModel> get prompts {
    var filtered = _prompts;
    if (_selectedCategoryFilter != 'All') {
      filtered = filtered.where((p) => p.category == _selectedCategoryFilter).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((p) =>
        p.originalText.toLowerCase().contains(query) ||
        p.enhancedPrompt.toLowerCase().contains(query)
      ).toList();
    }
    return filtered;
  }

  List<PromptModel> get favouritePrompts => prompts.where((p) => p.isFavourite).toList();
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get selectedCategoryFilter => _selectedCategoryFilter;

  void _setError(String? message) {
    _error = message;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void updateUser(User? user) {
    final newUserId = user?.uid;
    debugPrint('PromptProvider.updateUser called. New userId: $newUserId, Current: $_currentUserId');

    if (_currentUserId == newUserId) {
      debugPrint('Same user, skipping update');
      return;
    }

    _currentUserId = newUserId;
    _subscription?.cancel();
    _subscription = null;

    if (user != null) {
      _isLoading = true;
      notifyListeners();
      debugPrint('Setting up prompts stream for user: ${user.uid}');

      _subscription = _promptRepository.watchPrompts(user.uid).listen(
        (data) {
          debugPrint('Received ${data.length} prompts from stream');
          _prompts = data;
          _isLoading = false;
          notifyListeners();
        },
        onError: (error) {
          debugPrint('Error loading prompts: $error');
          _prompts = [];
          _isLoading = false;
          notifyListeners();
        },
        onDone: () {
          debugPrint('Prompts stream done');
          _isLoading = false;
          notifyListeners();
        },
      );
    } else {
      debugPrint('No user, clearing prompts');
      _prompts = [];
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setCategoryFilter(String category) {
    _selectedCategoryFilter = category;
    notifyListeners();
  }

  Future<bool> savePrompt(User? user, PromptModel prompt) async {
    if (user == null) {
      _setError('You must be signed in to save prompts');
      return false;
    }
    try {
      _setError(null);
      await _promptRepository.savePrompt(user.uid, prompt);
      await _firestoreRepository.incrementTotalPrompts(user.uid);
      return true;
    } catch (e) {
      debugPrint('Error saving prompt: $e');
      _setError('Failed to save prompt. Please try again.');
      return false;
    }
  }

  Future<bool> toggleFavourite(User? user, PromptModel prompt) async {
    if (user == null) {
      _setError('You must be signed in to use favourites');
      return false;
    }
    try {
      _setError(null);
      await _promptRepository.toggleFavourite(user.uid, prompt.id, prompt.isFavourite);
      return true;
    } catch (e) {
      debugPrint('Error toggling favourite: $e');
      _setError('Failed to update favourite. Please try again.');
      return false;
    }
  }

  Future<bool> deletePrompt(User? user, String promptId) async {
    if (user == null) {
      _setError('You must be signed in to delete prompts');
      return false;
    }
    try {
      _setError(null);
      await _promptRepository.deletePrompt(user.uid, promptId);
      return true;
    } catch (e) {
      debugPrint('Error deleting prompt: $e');
      _setError('Failed to delete prompt. Please try again.');
      return false;
    }
  }

  Future<bool> clearAllHistory(User? user) async {
    if (user == null) {
      _setError('You must be signed in to clear history');
      return false;
    }
    try {
      _setError(null);
      await _promptRepository.clearAllHistory(user.uid);
      return true;
    } catch (e) {
      debugPrint('Error clearing history: $e');
      _setError('Failed to clear history. Please try again.');
      return false;
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
