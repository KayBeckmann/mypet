import 'package:flutter/material.dart';

enum PasswordStrength { empty, weak, fair, good, strong }

PasswordStrength evaluatePassword(String password) {
  if (password.isEmpty) return PasswordStrength.empty;
  int score = 0;
  if (password.length >= 8) score++;
  if (password.length >= 12) score++;
  if (RegExp(r'[A-Z]').hasMatch(password)) score++;
  if (RegExp(r'[0-9]').hasMatch(password)) score++;
  if (RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-]').hasMatch(password)) score++;

  if (score <= 1) return PasswordStrength.weak;
  if (score == 2) return PasswordStrength.fair;
  if (score == 3) return PasswordStrength.good;
  return PasswordStrength.strong;
}

class PasswordStrengthIndicator extends StatelessWidget {
  final String password;
  const PasswordStrengthIndicator({super.key, required this.password});

  @override
  Widget build(BuildContext context) {
    final strength = evaluatePassword(password);
    if (strength == PasswordStrength.empty) return const SizedBox.shrink();

    final (label, color, filledBars) = switch (strength) {
      PasswordStrength.weak => ('Schwach', const Color(0xFFD32F2F), 1),
      PasswordStrength.fair => ('Mittel', const Color(0xFFF57C00), 2),
      PasswordStrength.good => ('Gut', const Color(0xFF388E3C), 3),
      PasswordStrength.strong => ('Stark', const Color(0xFF1B5E20), 4),
      PasswordStrength.empty => ('', Colors.grey, 0),
    };

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: List.generate(4, (i) {
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.only(right: 4),
                  height: 4,
                  decoration: BoxDecoration(
                    color: i < filledBars ? color : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 4),
          Text(
            'Passwortstärke: $label',
            style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
