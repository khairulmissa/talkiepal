import 'dart:math';

import 'package:flutter/material.dart';

import 'kid_page_ui.dart';

/// Asks a sum that a young child is unlikely to answer, before opening a
/// grown-ups-only page from the kids area. Returns true when it is answered.
Future<bool> askGrownUp(BuildContext context) async {
  final random = Random();
  final a = 6 + random.nextInt(4);
  final b = 6 + random.nextInt(4);
  final answer = await showDialog<bool>(
    context: context,
    builder: (_) => _ParentGateDialog(a: a, b: b),
  );
  return answer ?? false;
}

class _ParentGateDialog extends StatefulWidget {
  final int a;
  final int b;

  const _ParentGateDialog({required this.a, required this.b});

  @override
  State<_ParentGateDialog> createState() => _ParentGateDialogState();
}

class _ParentGateDialogState extends State<_ParentGateDialog> {
  final _controller = TextEditingController();
  bool _wrong = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _check() {
    if (int.tryParse(_controller.text.trim()) == widget.a * widget.b) {
      Navigator.pop(context, true);
    } else {
      setState(() => _wrong = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text(
        '👪 Ask a grown-up',
        style: TextStyle(color: KidColors.plumDark, fontWeight: FontWeight.w900),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'This part is for grown-ups. Please answer:',
            style: TextStyle(color: KidColors.soft, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Text(
            '${widget.a} × ${widget.b} = ?',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: KidColors.ink),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            onSubmitted: (_) => _check(),
            decoration: InputDecoration(
              hintText: 'Answer',
              errorText: _wrong ? 'Not quite. Try again.' : null,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel', style: TextStyle(color: Color(0xFFC9B3E0))),
        ),
        TextButton(
          onPressed: _check,
          child: const Text('OK', style: TextStyle(color: KidColors.plum, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
