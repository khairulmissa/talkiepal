import 'package:flutter/material.dart';

import 'parent_ui.dart';

/// Text field in the parent style: soft filled box, purple when focused.
InputDecoration parentInputDecoration(String label, {String? hint, Widget? suffix, bool locked = false}) =>
    InputDecoration(
      labelText: label,
      hintText: hint,
      suffixIcon:
          suffix ?? (locked ? const Icon(Icons.lock_outline_rounded, size: 18, color: ParentColors.muted) : null),
      filled: true,
      fillColor: locked ? const Color(0xFFEEEAF2) : ParentColors.background,
      labelStyle: const TextStyle(color: ParentColors.soft, fontWeight: FontWeight.w600),
      floatingLabelStyle: const TextStyle(color: ParentColors.purple, fontWeight: FontWeight.w700),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: ParentColors.purple, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.red, width: 1.2),
      ),
    );

/// Big purple button fixed at the bottom of a parent form.
class ParentSaveButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool busy;

  const ParentSaveButton({super.key, required this.label, required this.onPressed, this.busy = false});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton(
            onPressed: busy ? null : onPressed,
            style: FilledButton.styleFrom(
              backgroundColor: ParentColors.purple,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: busy
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                  )
                : Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
          ),
        ),
      ),
    );
  }
}
