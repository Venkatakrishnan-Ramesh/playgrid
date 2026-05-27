import 'package:flutter/material.dart';

class PickableUser {
  const PickableUser({
    required this.id,
    required this.name,
    this.subtitle = '',
  });

  final String id;
  final String name;
  final String subtitle;
}

/// Shows a modal multi-select list of users and returns the chosen ids,
/// or null if the sheet is dismissed.
Future<List<String>?> showUserPicker({
  required BuildContext context,
  required String title,
  required String confirmLabel,
  required List<PickableUser> candidates,
}) {
  return showModalBottomSheet<List<String>>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (BuildContext context) => _UserPickerSheet(
        title: title, confirmLabel: confirmLabel, candidates: candidates),
  );
}

class _UserPickerSheet extends StatefulWidget {
  const _UserPickerSheet({
    required this.title,
    required this.confirmLabel,
    required this.candidates,
  });

  final String title;
  final String confirmLabel;
  final List<PickableUser> candidates;

  @override
  State<_UserPickerSheet> createState() => _UserPickerSheetState();
}

class _UserPickerSheetState extends State<_UserPickerSheet> {
  final Set<String> _selected = <String>{};

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(widget.title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            if (widget.candidates.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text('No one available to add right now.'),
              )
            else
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: widget.candidates.map((PickableUser user) {
                    final bool selected = _selected.contains(user.id);
                    return CheckboxListTile(
                      value: selected,
                      title: Text(user.name),
                      subtitle:
                          user.subtitle.isEmpty ? null : Text(user.subtitle),
                      secondary: CircleAvatar(
                        child: Text(user.name.isNotEmpty
                            ? user.name.characters.first
                            : '?'),
                      ),
                      onChanged: (_) => setState(() {
                        if (selected) {
                          _selected.remove(user.id);
                        } else {
                          _selected.add(user.id);
                        }
                      }),
                    );
                  }).toList(),
                ),
              ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _selected.isEmpty
                    ? null
                    : () => Navigator.of(context).pop(_selected.toList()),
                child: Text('${widget.confirmLabel} (${_selected.length})'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
