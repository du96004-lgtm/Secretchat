import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:math_expressions/math_expressions.dart';

class CalculatorProvider with ChangeNotifier {
  String _input = "";
  String _result = "0";
  bool _isFirstSetup = true;
  String? _savedPinHash;

  String get input => _input;
  String get result => _result;
  bool get isFirstSetup => _isFirstSetup;

  CalculatorProvider() {
    _loadPin();
  }

  Future<void> _loadPin() async {
    final prefs = await SharedPreferences.getInstance();
    _savedPinHash = prefs.getString('secret_pin_hash');
    _isFirstSetup = _savedPinHash == null;
    notifyListeners();
  }

  void onNumberPress(String text) {
    _input += text;
    notifyListeners();
  }

  void onOperatorPress(String operator) {
    if (_input.isEmpty) return;
    _input += operator;
    notifyListeners();
  }

  void clear() {
    _input = "";
    _result = "0";
    notifyListeners();
  }

  void delete() {
    if (_input.isNotEmpty) {
      _input = _input.substring(0, _input.length - 1);
      notifyListeners();
    }
  }

  Future<bool> evaluate(BuildContext context) async {
    if (_input.isEmpty) return false;

    // Check for secret PIN
    if (_isFirstSetup) {
      if (_input.length >= 4) {
        await _savePin(_input);
        _input = "";
        _result = "PIN Set!";
        notifyListeners();
        return false;
      }
    } else {
      final inputHash = _hashPin(_input);
      if (inputHash == _savedPinHash) {
        _input = "";
        _result = "Unlocked";
        notifyListeners();
        return true; // Navigate to Chat
      }
    }

    // Normal calculation
    try {
      Parser p = Parser();
      Expression exp = p.parse(_input.replaceAll('x', '*').replaceAll('÷', '/'));
      ContextModel cm = ContextModel();
      double eval = exp.evaluate(EvaluationType.REAL, cm);
      
      if (eval == eval.toInt()) {
        _result = eval.toInt().toString();
      } else {
        _result = eval.toString();
      }
      _input = _result;
    } catch (e) {
      _result = "Error";
    }
    notifyListeners();
    return false;
  }

  String _hashPin(String pin) {
    return sha256.convert(utf8.encode(pin)).toString();
  }

  Future<void> _savePin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    final hash = _hashPin(pin);
    await prefs.setString('secret_pin_hash', hash);
    _savedPinHash = hash;
    _isFirstSetup = false;
  }
}
