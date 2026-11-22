import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Future<bool> showParentalGate(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const _ParentalGateDialog(),
  );
  return result ?? false;
}

class _ParentalGateDialog extends StatefulWidget {
  const _ParentalGateDialog();

  @override
  State<_ParentalGateDialog> createState() => _ParentalGateDialogState();
}

class _ParentalGateDialogState extends State<_ParentalGateDialog> {
  static const Color _purple = Color(0xFF6B4C7A);
  static const Color _softPurple = Color(0xFF9A7FA8);

  final TextEditingController _answerController = TextEditingController();
  late final int _a;
  late final int _b;

  @override
  void initState() {
    super.initState();
    final random = Random();
    _a = random.nextInt(7) + 3;
    _b = random.nextInt(7) + 3;
  }

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  void _submit() {
    final answer = int.tryParse(_answerController.text.trim());
    final correct = answer == _a * _b;
    if (!correct) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Wrong answer. Please ask a parent for help.')),
      );
    }
    Navigator.of(context).pop(correct);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Row(
        children: [
          Icon(Icons.lock_rounded, color: _purple),
          SizedBox(width: 8),
          Text(
            'Parents Only',
            style: TextStyle(fontWeight: FontWeight.w900, color: _purple),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Please answer this question to continue.',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _softPurple),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              '$_a × $_b = ?',
              style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: _purple),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _answerController,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            maxLength: 3,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            decoration: InputDecoration(
              counterText: '',
              hintText: 'Answer',
              filled: true,
              fillColor: const Color(0xFFF5EEF8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel', style: TextStyle(color: _softPurple)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: _purple,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          onPressed: _submit,
          child: const Text('Continue'),
        ),
      ],
    );
  }
}