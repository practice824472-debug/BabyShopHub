import 'package:flutter/material.dart';

class PasswordController extends ChangeNotifier {
bool isVisible = true;

void ChangeVisiblility(){
  isVisible = !isVisible;
  notifyListeners();
}

}