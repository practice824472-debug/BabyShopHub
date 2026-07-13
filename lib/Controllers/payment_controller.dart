import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../Models/card_model.dart';

class PaymentController with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<SavedCard> _savedCards = [];
  bool _isLoading = false;
  String? _error;
  SavedCard? _defaultCard;

  List<SavedCard> get savedCards => List.unmodifiable(_savedCards);
  bool get isLoading => _isLoading;
  String? get error => _error;
  SavedCard? get defaultCard => _defaultCard;

  /// Fetch all saved cards for the current user
  Future<void> fetchSavedCards() async {
    if (_auth.currentUser == null) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final doc = await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .get();
      final data = doc.data() ?? {};
      final cardsData = (data['paymentMethods'] as List? ?? [])
          .cast<Map<String, dynamic>>();

      _savedCards = cardsData
          .map((card) => SavedCard.fromJson(card))
          .toList();

      // Find default card
      if (_savedCards.isNotEmpty) {
        try {
          _defaultCard = _savedCards.firstWhere((card) => card.isDefault);
        } catch (e) {
          _defaultCard = _savedCards.first;
        }
      } else {
        _defaultCard = null;
      }
    } catch (e) {
      _error = 'Failed to fetch saved cards';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Save a new card
  Future<bool> saveCard({
    required String cardNumber,
    required String cardholderName,
    required String expiryDate,
    required String cvv,
    bool isDefault = false,
  }) async {
    if (_auth.currentUser == null) return false;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Validate card inputs
      if (cardNumber.replaceAll(' ', '').length != 16) {
        _error = 'Invalid card number';
        return false;
      }
      if (cardholderName.trim().isEmpty) {
        _error = 'Cardholder name is required';
        return false;
      }
      if (expiryDate.length != 5) {
        _error = 'Invalid expiry date';
        return false;
      }
      if (cvv.length != 3) {
        _error = 'Invalid CVV';
        return false;
      }

      // Create new card object
      final cardId = const Uuid().v4();
      final newCard = SavedCard(
        cardId: cardId,
        cardNumber: cardNumber.replaceAll(' ', '').substring(
          cardNumber.replaceAll(' ', '').length - 4,
        ), // Store only last 4 digits
        cardholderName: cardholderName,
        expiryDate: expiryDate,
        cvv: cvv,
        isDefault: isDefault && _savedCards.isEmpty, // First card is always default
        createdAt: DateTime.now(),
      );

      // If this card is default, unset others
      if (newCard.isDefault) {
        _savedCards = _savedCards
            .map((card) => card.copyWith(isDefault: false))
            .toList();
      }

      _savedCards.add(newCard);

      // Persist to Firestore. Use set(merge: true) instead of update() so
      // this succeeds even if the user's document doesn't exist yet or has
      // never had a paymentMethods field (update() throws NOT_FOUND in that
      // case, which is why cards previously appeared to silently fail to save).
      final userRef = _firestore.collection('users').doc(_auth.currentUser!.uid);
      await userRef.set({
        'paymentMethods': _savedCards.map((card) => card.toJson()).toList(),
      }, SetOptions(merge: true));

      if (newCard.isDefault) {
        _defaultCard = newCard;
      }

      return true;
    } catch (e) {
      _error = 'Failed to save card: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Delete a saved card
  Future<bool> deleteCard(String cardId) async {
    if (_auth.currentUser == null) return false;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _savedCards.removeWhere((card) => card.cardId == cardId);

      // Persist to Firestore
      final userRef = _firestore.collection('users').doc(_auth.currentUser!.uid);
      await userRef.set({
        'paymentMethods': _savedCards.map((card) => card.toJson()).toList(),
      }, SetOptions(merge: true));

      // If deleted card was default, set first as default
      if (_defaultCard?.cardId == cardId && _savedCards.isNotEmpty) {
        _defaultCard = _savedCards.first;
        _savedCards[0] = _savedCards[0].copyWith(isDefault: true);
        await userRef.set({
          'paymentMethods': _savedCards.map((card) => card.toJson()).toList(),
        }, SetOptions(merge: true));
      } else if (_savedCards.isEmpty) {
        _defaultCard = null;
      }

      return true;
    } catch (e) {
      _error = 'Failed to delete card';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Set a card as default
  Future<bool> setDefaultCard(String cardId) async {
    if (_auth.currentUser == null) return false;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _savedCards = _savedCards.map((card) {
        if (card.cardId == cardId) {
          _defaultCard = card.copyWith(isDefault: true);
          return _defaultCard as SavedCard;
        }
        return card.copyWith(isDefault: false);
      }).toList();

      // Persist to Firestore
      final userRef = _firestore.collection('users').doc(_auth.currentUser!.uid);
      await userRef.set({
        'paymentMethods': _savedCards.map((card) => card.toJson()).toList(),
      }, SetOptions(merge: true));

      return true;
    } catch (e) {
      _error = 'Failed to set default card';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}