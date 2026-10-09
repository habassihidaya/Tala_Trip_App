import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';

Future<Country?> showDialingCodePicker(
  BuildContext context, {
  String selectedCode = 'DZ',
}) {
  final options =
      CountryService()
          .getAll()
          .where(
            (option) =>
                option.countryCode != 'IL' &&
                option.phoneCode != '972' &&
                option.phoneCode.isNotEmpty,
          )
          .toList()
        ..sort((a, b) => a.name.compareTo(b.name));

  var query = '';
  var pendingCode = selectedCode;

  return showDialog<Country>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          final matches = options.where((option) {
            final name = option.name.toLowerCase();
            final prefix = '+${option.phoneCode}';

            return name.contains(query) ||
                prefix.contains(query) ||
                option.countryCode.toLowerCase() == query;
          }).toList();

          return AlertDialog(
            title: const Text('Select dialing code'),
            content: SizedBox(
              width: 440,
              height: 420,
              child: Column(
                children: [
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Search name or dialing code',
                      hintText: 'Algeria or +213',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setDialogState(() {
                        query = value.trim().toLowerCase();
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: matches.isEmpty
                        ? const Center(
                            child: Text('No matching dialing codes.'),
                          )
                        : RadioGroup<String>(
                            groupValue: pendingCode,
                            onChanged: (value) {
                              if (value == null) return;

                              setDialogState(() {
                                pendingCode = value;
                              });
                            },
                            child: ListView.builder(
                              itemCount: matches.length,
                              itemBuilder: (context, index) {
                                final option = matches[index];

                                return RadioListTile<String>(
                                  value: option.countryCode,
                                  title: Text(
                                    '${option.name} (+${option.phoneCode})',
                                  ),
                                  selected: option.countryCode == pendingCode,
                                  contentPadding: EdgeInsets.zero,
                                );
                              },
                            ),
                          ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  final selected = options.firstWhere(
                    (option) => option.countryCode == pendingCode,
                  );

                  Navigator.of(dialogContext).pop(selected);
                },
                child: const Text('Select'),
              ),
            ],
          );
        },
      );
    },
  );
}
