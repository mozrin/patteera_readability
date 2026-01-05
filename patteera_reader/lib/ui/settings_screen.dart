import 'package:flutter/material.dart';
import 'package:patteera_reader/services/config_service.dart';
import 'package:patteera_reader/services/readability_service.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final configService = Provider.of<ConfigService>(context);
    final bands = configService.bands;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.restore),
            tooltip: 'Reset to Defaults',
            onPressed: () async {
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              final readabilityService = Provider.of<ReadabilityService>(
                context,
                listen: false,
              );

              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Reset Settings?'),
                  content: const Text(
                    'This will revert all weights and lists to the original configuration.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Reset'),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                await configService.resetToDefaults();
                if (mounted) {
                  readabilityService.invalidateCache();
                  setState(() {});
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(content: Text('Settings reset')),
                  );
                }
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text(
            'Frequency Bands & Weights',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Adjust the weight of each word list. Higher weight means words in that list contribute more to the "Easy" score.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          ...bands.asMap().entries.map((entry) {
            final index = entry.key;
            final band = entry.value;
            return _BandListItem(
              index: index,
              band: band,
              configService: configService,
              onEdit: () =>
                  _showEditBandDialog(context, configService, index, band),
              onDelete: () async {
                final readabilityService = Provider.of<ReadabilityService>(
                  context,
                  listen: false,
                );
                await configService.removeBand(index);
                if (mounted) {
                  readabilityService.invalidateCache();
                }
              },
            );
          }),
          ElevatedButton.icon(
            onPressed: () => _showAddBandDialog(context, configService),
            icon: const Icon(Icons.add),
            label: const Text('Add Frequency Band'),
          ),
          const Divider(height: 48, thickness: 1),
          const Text(
            'Classification Thresholds',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Define difficulty levels based on score (0-100). The system checks thresholds from highest score to lowest.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          ...configService.thresholds.asMap().entries.map((entry) {
            final index = entry.key;
            final t = entry.value;
            final colorVal =
                int.tryParse(t['color'] ?? '0xFF9E9E9E') ?? 0xFF9E9E9E;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Color(colorVal),
                  radius: 12,
                ),
                title: Text(t['label'] ?? 'Unknown'),
                subtitle: Text('Score ≥ ${t['score']}'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () async {
                    final readabilityService = Provider.of<ReadabilityService>(
                      context,
                      listen: false,
                    );
                    await configService.removeThreshold(index);
                    if (mounted) {
                      readabilityService.invalidateCache();
                    }
                  },
                ),
                onTap: () =>
                    _showEditThresholdDialog(context, configService, index, t),
              ),
            );
          }),
          ElevatedButton.icon(
            onPressed: () => _showAddThresholdDialog(context, configService),
            icon: const Icon(Icons.add),
            label: const Text('Add Threshold'),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditBandDialog(
    BuildContext context,
    ConfigService service,
    int index,
    Map<String, dynamic> band,
  ) async {
    final nameController = TextEditingController(text: band['name']);
    final pathController = TextEditingController(text: band['path']);

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Band'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: pathController,
                decoration: const InputDecoration(labelText: 'Asset Path'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final navigator = Navigator.of(ctx);
              final readabilityService = Provider.of<ReadabilityService>(
                context,
                listen: false,
              );

              final updatedBand = Map<String, dynamic>.from(band);
              updatedBand['name'] = nameController.text;
              updatedBand['path'] = pathController.text;

              await service.updateBand(index, updatedBand);

              if (mounted) {
                readabilityService.invalidateCache();
                navigator.pop();
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddBandDialog(
    BuildContext context,
    ConfigService service,
  ) async {
    final nameController = TextEditingController();
    final pathController = TextEditingController(text: 'assets/words/');
    double weight = 1.0;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add New Band'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                TextField(
                  controller: pathController,
                  decoration: const InputDecoration(labelText: 'Asset Path'),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('Weight: '),
                    Expanded(
                      child: Slider(
                        value: weight,
                        min: 0.0,
                        max: 10.0,
                        divisions: 20,
                        label: weight.toString(),
                        onChanged: (val) => setState(() => weight = val),
                      ),
                    ),
                    Text(weight.toStringAsFixed(1)),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final navigator = Navigator.of(ctx);
                final readabilityService = Provider.of<ReadabilityService>(
                  context,
                  listen: false,
                );

                if (nameController.text.isNotEmpty &&
                    pathController.text.isNotEmpty) {
                  await service.addBand({
                    'name': nameController.text,
                    'path': pathController.text,
                    'weight': weight,
                  });
                  if (mounted) {
                    readabilityService.invalidateCache();
                    navigator.pop();
                  }
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditThresholdDialog(
    BuildContext context,
    ConfigService service,
    int index,
    Map<String, dynamic> threshold,
  ) async {
    final labelController = TextEditingController(text: threshold['label']);
    final scoreController = TextEditingController(
      text: threshold['score'].toString(),
    );
    String selectedColor = threshold['color'] ?? "0xFF4CAF50";

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Threshold'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: labelController,
                  decoration: const InputDecoration(labelText: 'Label'),
                ),
                TextField(
                  controller: scoreController,
                  decoration: const InputDecoration(labelText: 'Minimum Score'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                InputDecorator(
                  decoration: const InputDecoration(labelText: 'Color'),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedColor,
                      isDense: true,
                      onChanged: (val) => setState(() => selectedColor = val!),
                      items: _colorOptions.entries.map((e) {
                        return DropdownMenuItem(
                          value: e.value,
                          child: Row(
                            children: [
                              Container(
                                width: 16,
                                height: 16,
                                color: Color(int.parse(e.value)),
                              ),
                              const SizedBox(width: 8),
                              Text(e.key),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final navigator = Navigator.of(ctx);
                final readabilityService = Provider.of<ReadabilityService>(
                  context,
                  listen: false,
                );

                final updated = Map<String, dynamic>.from(threshold);
                updated['label'] = labelController.text;
                updated['score'] = num.tryParse(scoreController.text) ?? 0;
                updated['color'] = selectedColor;

                await service.updateThreshold(index, updated);

                if (mounted) {
                  readabilityService.invalidateCache();
                  navigator.pop();
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddThresholdDialog(
    BuildContext context,
    ConfigService service,
  ) async {
    final labelController = TextEditingController();
    final scoreController = TextEditingController();
    String selectedColor = "0xFF4CAF50"; // Default Green

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add New Threshold'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: labelController,
                  decoration: const InputDecoration(labelText: 'Label'),
                ),
                TextField(
                  controller: scoreController,
                  decoration: const InputDecoration(labelText: 'Minimum Score'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                InputDecorator(
                  decoration: const InputDecoration(labelText: 'Color'),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedColor,
                      isDense: true,
                      onChanged: (val) => setState(() => selectedColor = val!),
                      items: _colorOptions.entries.map((e) {
                        return DropdownMenuItem(
                          value: e.value,
                          child: Row(
                            children: [
                              Container(
                                width: 16,
                                height: 16,
                                color: Color(int.parse(e.value)),
                              ),
                              const SizedBox(width: 8),
                              Text(e.key),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final navigator = Navigator.of(ctx);
                final readabilityService = Provider.of<ReadabilityService>(
                  context,
                  listen: false,
                );

                if (labelController.text.isNotEmpty &&
                    scoreController.text.isNotEmpty) {
                  await service.addThreshold({
                    'label': labelController.text,
                    'score': num.tryParse(scoreController.text) ?? 0,
                    'color': selectedColor,
                  });
                  if (mounted) {
                    readabilityService.invalidateCache();
                    navigator.pop();
                  }
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  static const Map<String, String> _colorOptions = {
    'Green': '0xFF4CAF50',
    'Light Green': '0xFF8BC34A',
    'Amber': '0xFFFFC107',
    'Orange': '0xFFFF9800',
    'Red': '0xFFF44336',
    'Blue': '0xFF2196F3',
    'Grey': '0xFF9E9E9E',
  };
}

class _BandListItem extends StatefulWidget {
  final int index;
  final Map<String, dynamic> band;
  final ConfigService configService;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _BandListItem({
    required this.index,
    required this.band,
    required this.configService,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_BandListItem> createState() => _BandListItemState();
}

class _BandListItemState extends State<_BandListItem> {
  late double _weight;

  @override
  void initState() {
    super.initState();
    _weight = (widget.band['weight'] as num).toDouble();
  }

  @override
  void didUpdateWidget(covariant _BandListItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.band['weight'] != widget.band['weight']) {
      // Only update from external source if not currently dragging?
      // Actually, for simplicity, we sync if parental state changes.
      _weight = (widget.band['weight'] as num).toDouble();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(widget.band['name'] ?? 'Unnamed config'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Path: ${widget.band['path']}'),
            Row(
              children: [
                const Text('Weight: '),
                Expanded(
                  child: Slider(
                    value: _weight,
                    min: 0.0,
                    max: 10.0,
                    divisions: 20,
                    label: _weight.toString(),
                    onChanged: (val) {
                      setState(() {
                        _weight = val;
                      });
                    },
                    onChangeEnd: (val) async {
                      // Capture service before async gap
                      final readabilityService =
                          Provider.of<ReadabilityService>(
                            context,
                            listen: false,
                          );

                      final updatedBand = Map<String, dynamic>.from(
                        widget.band,
                      );
                      updatedBand['weight'] = val;

                      await widget.configService.updateBand(
                        widget.index,
                        updatedBand,
                      );

                      // Safe to call on instance without context
                      readabilityService.invalidateCache();
                    },
                  ),
                ),
                Text(_weight.toStringAsFixed(1)),
              ],
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete),
          onPressed: widget.onDelete,
        ),
        onTap: widget.onEdit,
      ),
    );
  }
}
