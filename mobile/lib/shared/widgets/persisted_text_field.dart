import 'package:flutter/material.dart';

/// Keeps the cursor stable while accepting external updates (GPS or transcription).
class PersistedTextField extends StatefulWidget {
  const PersistedTextField({
    super.key,
    required this.value,
    required this.label,
    required this.onChanged,
    this.hint,
    this.numeric = false,
    this.maxLength,
    this.minLines = 1,
    this.maxLines = 1,
  });
  final String value, label;
  final String? hint;
  final ValueChanged<String> onChanged;
  final bool numeric;
  final int? maxLength;
  final int minLines, maxLines;
  @override
  State<PersistedTextField> createState() => _PersistedTextFieldState();
}

class _PersistedTextFieldState extends State<PersistedTextField> {
  late final controller = TextEditingController(text: widget.value);
  @override
  void didUpdateWidget(PersistedTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value == oldWidget.value || controller.text == widget.value) {
      return;
    }
    if (widget.numeric &&
        (widget.value.isEmpty ||
            double.tryParse(controller.text.replaceAll(',', '.')) ==
                double.tryParse(widget.value))) {
      return;
    }
    controller.value = TextEditingValue(
      text: widget.value,
      selection: TextSelection.collapsed(offset: widget.value.length),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    decoration: InputDecoration(labelText: widget.label, hintText: widget.hint),
    keyboardType: widget.numeric
        ? const TextInputType.numberWithOptions(decimal: true, signed: true)
        : null,
    minLines: widget.minLines,
    maxLines: widget.maxLines,
    maxLength: widget.maxLength,
    onChanged: widget.onChanged,
  );
}
