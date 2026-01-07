import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'calculator_provider.dart';
import '../auth/login_screen.dart';
import '../screens/main_navigation.dart';

class CalculatorScreen extends StatelessWidget {
  const CalculatorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                alignment: Alignment.bottomRight,
                child: Consumer<CalculatorProvider>(
                  builder: (context, provider, child) {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          provider.input,
                          style: const TextStyle(color: Colors.white70, fontSize: 32),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          provider.result,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 64,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (provider.isFirstSetup)
                          const Padding(
                            padding: EdgeInsets.only(top: 8.0),
                            child: Text(
                              "Setup: Enter 4+ digits & press '=' to set PIN",
                              style: TextStyle(color: Colors.amber, fontSize: 14),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                ),
                child: Column(
                  children: [
                    _buildRow(context, ["AC", "DEL", "%", "÷"], isSpecial: true),
                    _buildRow(context, ["7", "8", "9", "x"]),
                    _buildRow(context, ["4", "5", "6", "-"]),
                    _buildRow(context, ["1", "2", "3", "+"]),
                    _buildRow(context, ["0", ".", "00", "="], isLast: true),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(BuildContext context, List<String> labels, {bool isSpecial = false, bool isLast = false}) {
    return Expanded(
      child: Row(
        children: labels.map((label) {
          return _buildButton(context, label, isSpecial: isSpecial && label != "÷", isOperator: ["÷", "x", "-", "+", "="].contains(label));
        }).toList(),
      ),
    );
  }

  Widget _buildButton(BuildContext context, String label, {bool isSpecial = false, bool isOperator = false}) {
    final provider = Provider.of<CalculatorProvider>(context, listen: false);
    
    Color bgColor = Colors.transparent;
    Color textColor = Colors.white;
    
    if (isOperator) {
      bgColor = Colors.deepPurpleAccent;
      textColor = Colors.white;
    } else if (isSpecial) {
      textColor = Colors.deepPurpleAccent;
    }

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: InkWell(
          onTap: () async {
            if (label == "AC") {
              provider.clear();
            } else if (label == "DEL") {
              provider.delete();
            } else if (label == "=") {
              bool unlocked = await provider.evaluate(context);
              if (unlocked) {
                if (FirebaseAuth.instance.currentUser != null) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const MainNavigation()),
                  );
                } else {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                }
              }
            } else if (["+", "-", "x", "÷", "%"].contains(label)) {
              provider.onOperatorPress(label);
            } else {
              provider.onNumberPress(label);
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: bgColor != Colors.transparent ? [
                BoxShadow(
                  color: bgColor.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                )
              ] : null,
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
