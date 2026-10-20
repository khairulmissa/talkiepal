import 'package:flutter/material.dart';

/// Colours of the screens before signing in (from the TalkiePal logo).
class EntryColors {
  static const Color cream = Color(0xFFFDF7E7);
  static const Color yellow = Color(0xFFF6C445);
  static const Color orange = Color(0xFFE8793A);
  static const Color orangeDark = Color(0xFFC75E22);
  static const Color teal = Color(0xFF5FAFA6);
  static const Color ink = Color(0xFF26272B);
  static const Color soft = Color(0xFF7A7468);
  static const Color muted = Color(0xFFB4AC9C);
  static const Color line = Color(0xFFEFE6D2);
  static const Color field = Color(0xFFFAF6EC);
}

/// The logo pictures.
class EntryLogo {
  /// Speech bubble with the two kids, the name and the slogan.
  static const String full = 'lib/assets/images/talkiepal_logo.png';

  /// Only the speech bubble with the two kids.
  static const String icon = 'lib/assets/images/talkiepal_logo_icon.png';
}

/// Sign-in style page: the logo, a title on cream and a white sheet below
/// with the form.
class EntryPage extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget> children;

  /// Shows a back arrow (e.g. Forgot password).
  final bool back;

  const EntryPage({super.key, required this.title, required this.subtitle, required this.children, this.back = false});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EntryColors.cream,
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    SizedBox(
                      height: 56,
                      child: back
                          ? Align(
                              alignment: Alignment.centerLeft,
                              child: IconButton(
                                icon: const Icon(Icons.arrow_back_rounded, color: EntryColors.ink),
                                onPressed: () => Navigator.pop(context),
                              ),
                            )
                          : null,
                    ),
                    Image.asset(EntryLogo.icon, height: 128),
                    const SizedBox(height: 10),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: EntryColors.ink),
                    ),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        subtitle,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: EntryColors.soft),
                      ),
                    ),
                    const SizedBox(height: 22),
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.fromLTRB(22, 26, 22, 16 + MediaQuery.of(context).padding.bottom),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                          boxShadow: [BoxShadow(color: Color(0x14000000), blurRadius: 20, offset: Offset(0, -4))],
                        ),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Text field with an icon; password fields get a show/hide button.
class EntryField extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool password;
  final bool enabled;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final AutovalidateMode? autovalidateMode;

  const EntryField({
    super.key,
    required this.controller,
    required this.hint,
    required this.icon,
    this.password = false,
    this.enabled = true,
    this.keyboardType,
    this.validator,
    this.autovalidateMode,
  });

  @override
  State<EntryField> createState() => _EntryFieldState();
}

class _EntryFieldState extends State<EntryField> {
  bool _shown = false;

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder border(Color color, [double width = 1.2]) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: color, width: width),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: widget.controller,
        enabled: widget.enabled,
        keyboardType: widget.keyboardType,
        obscureText: widget.password && !_shown,
        autovalidateMode: widget.autovalidateMode,
        validator: widget.validator,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: EntryColors.ink),
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle: const TextStyle(color: EntryColors.muted, fontWeight: FontWeight.w600),
          prefixIcon: Icon(widget.icon, color: EntryColors.soft, size: 20),
          suffixIcon: widget.password
              ? IconButton(
                  icon: Icon(
                    _shown ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                    color: EntryColors.muted,
                  ),
                  onPressed: () => setState(() => _shown = !_shown),
                )
              : null,
          filled: true,
          fillColor: EntryColors.field,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          border: border(EntryColors.line),
          enabledBorder: border(EntryColors.line),
          disabledBorder: border(EntryColors.line),
          focusedBorder: border(EntryColors.orange, 1.6),
          errorBorder: border(Colors.red),
          focusedErrorBorder: border(Colors.red, 1.6),
        ),
      ),
    );
  }
}

/// Big orange button with a darker bottom edge.
class EntryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool busy;

  const EntryButton({super.key, required this.label, required this.onPressed, this.busy = false});

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !busy;
    return GestureDetector(
      onTap: enabled ? onPressed : null,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          color: enabled || busy ? EntryColors.orange : EntryColors.muted,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(color: enabled || busy ? EntryColors.orangeDark : EntryColors.soft, offset: const Offset(0, 4)),
          ],
        ),
        child: Center(
          child: busy
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                )
              : Text(
                  label,
                  style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800, color: Colors.white),
                ),
        ),
      ),
    );
  }
}

/// "or continue with" and the Google and Facebook buttons.
class EntrySocialButtons extends StatelessWidget {
  final String text;
  final VoidCallback? onGoogle;
  final VoidCallback? onFacebook;

  const EntrySocialButtons({super.key, this.text = 'or continue with', this.onGoogle, this.onFacebook});

  @override
  Widget build(BuildContext context) {
    Widget button(Widget icon, String label, VoidCallback? onTap) => Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Opacity(
          opacity: onTap == null ? 0.5 : 1,
          child: Container(
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: EntryColors.line, width: 1.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                icon,
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: EntryColors.ink),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return Column(
      children: [
        Row(
          children: [
            const Expanded(child: Divider(color: EntryColors.line, thickness: 1.5)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                text,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: EntryColors.soft),
              ),
            ),
            const Expanded(child: Divider(color: EntryColors.line, thickness: 1.5)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            button(
              Image.asset(
                'lib/assets/images/google.png',
                width: 22,
                height: 22,
                errorBuilder: (_, _, _) => const Icon(Icons.g_mobiledata_rounded, size: 26),
              ),
              'Google',
              onGoogle,
            ),
            const SizedBox(width: 12),
            button(const Icon(Icons.facebook_rounded, color: Color(0xFF1877F2), size: 24), 'Facebook', onFacebook),
          ],
        ),
      ],
    );
  }
}

/// "New to TalkiePal? Create account" style line with a tappable link.
class EntryLink extends StatelessWidget {
  final String text;
  final String link;
  final VoidCallback? onTap;

  const EntryLink({super.key, required this.text, required this.link, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          text,
          style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: EntryColors.soft),
        ),
        GestureDetector(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              link,
              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: EntryColors.orange),
            ),
          ),
        ),
      ],
    );
  }
}

/// A short message floating near the bottom; red for problems.
void showEntryMessage(BuildContext context, String text, {bool error = true, Duration? duration}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: error ? const Color(0xFFD32F2F) : const Color(0xFF2E7D32),
        behavior: SnackBarBehavior.floating,
        duration: duration ?? const Duration(seconds: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
}
