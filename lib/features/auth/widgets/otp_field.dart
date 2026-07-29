import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/design/tokens.dart';

/// Single hidden input rendered as six digit boxes — keeps OS keyboard
/// auto-fill (one-time-code) working while looking like discrete cells.
class OtpField extends StatefulWidget {
  const OtpField({
    super.key,
    required this.onCompleted,
    this.length = 6,
    this.enabled = true,
  });

  final int length;
  final bool enabled;
  final ValueChanged<String> onCompleted;

  @override
  State<OtpField> createState() => _OtpFieldState();
}

class _OtpFieldState extends State<OtpField> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() {});
      if (_controller.text.length == widget.length) {
        widget.onCompleted(_controller.text);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = _controller.text;
    return Semantics(
      label: 'One-time code, ${widget.length} digits',
      child: GestureDetector(
        onTap: () => _focusNode.requestFocus(),
        child: Stack(
          children: [
            // Invisible real input (receives autofill + keyboard).
            Opacity(
              opacity: 0,
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                enabled: widget.enabled,
                keyboardType: TextInputType.number,
                autofillHints: const [AutofillHints.oneTimeCode],
                maxLength: widget.length,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.length, (i) {
                final filled = i < text.length;
                final isActive = i == text.length && _focusNode.hasFocus;
                return Container(
                  width: 46,
                  height: 56,
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(Corners.md),
                    border: Border.all(
                      color: isActive
                          ? scheme.primary
                          : filled
                              ? scheme.primary.withValues(alpha: 0.4)
                              : scheme.outlineVariant,
                      width: isActive ? 2 : 1,
                    ),
                  ),
                  child: Text(
                    filled ? text[i] : '',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
