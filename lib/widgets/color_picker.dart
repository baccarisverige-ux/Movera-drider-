import 'package:flutter/material.dart';
import 'package:movera/widgets/owned_route_exit.dart';
import 'package:movera/widgets/single_route_entry.dart';

class ColorPickerDialog {
  static Future<void> show(
    BuildContext context,
    ValueChanged<String> onColorSelected,
  ) async {
    final selected = await pushSingle<String>(
      context,
      DialogRoute<String>(
        context: context,
        builder: (_) => const _ColorPicker(),
      ),
    );
    if (!context.mounted ||
        ModalRoute.of(context)?.isCurrent != true ||
        selected == null) {
      return;
    }
    onColorSelected(selected);
  }
}

class _ColorPicker extends StatelessWidget {
  const _ColorPicker();
  static const _colors = <(String, Color)>[
    ('Red', Colors.red),
    ('Blue', Colors.blue),
    ('Green', Colors.green),
    ('Black', Colors.black),
    ('White', Colors.white),
    ('Gray', Colors.grey),
    ('Silver', Colors.blueGrey),
    ('Yellow', Colors.yellow),
    ('Orange', Colors.orange),
    ('Brown', Colors.brown),
    ('Purple', Colors.purple),
    ('Pink', Colors.pink),
  ];
  @override
  Widget build(BuildContext context) {
    return Dialog(
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 420,
          maxHeight: MediaQuery.sizeOf(context).height * .8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Choose vehicle color',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close color picker',
                    onPressed: () => popOwned(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Flexible(
              child: LayoutBuilder(
                builder: (context, constraints) => GridView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                  itemCount: _colors.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: constraints.maxWidth >= 400 ? 3 : 2,
                    mainAxisExtent:
                        80 + MediaQuery.textScalerOf(context).scale(14) * 3,
                  ),
                  itemBuilder: (context, index) {
                    final (name, color) = _colors[index];
                    return TextButton(
                      key: ValueKey('vehicle-color-$name'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.all(8),
                      ),
                      onPressed: () => popOwned(context, name),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.black26),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            name,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 14,
                              height: 1.2,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
