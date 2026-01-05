import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:patteera_reader/models/analysis_result.dart';
import 'package:patteera_reader/services/ocr_service.dart';
import 'package:patteera_reader/services/readability_service.dart';
import 'package:patteera_reader/ui/settings_screen.dart';
import 'package:provider/provider.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _textController = TextEditingController();

  AnalysisResult? _result;
  bool _isAnalyzing = false;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _analyze(String text) async {
    if (text.isEmpty) return;

    setState(() {
      _isAnalyzing = true;
      _statusMessage = "Analyzing text...";
    });

    try {
      final service = context.read<ReadabilityService>();
      final map = await service.analyze(text);
      if (mounted) {
        setState(() {
          _result = AnalysisResult.fromMap(map);
          _isAnalyzing = false;
          _statusMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
          _statusMessage = "Error: $e";
        });
      }
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['txt', 'md'],
    );

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final text = await file.readAsString();
      _textController.text = text; // Populate text tab
      _tabController.animateTo(0); // Switch to text tab
      _analyze(text);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final ocrService = context.read<OcrService>(); // Moved before async gap
    final image = await picker.pickImage(source: source);

    if (image != null) {
      setState(() {
        _isAnalyzing = true;
        _statusMessage = "Extracting text from image (OCR)...";
      });

      try {
        final text = await ocrService.extractText(image.path);

        if (mounted) {
          _textController.text = text;
          _tabController.animateTo(0);
          _analyze(text);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
          setState(() {
            _isAnalyzing = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Mobile / Narrow Layout
                  if (constraints.maxWidth < 900) {
                    return Column(
                      children: [
                        // Result Panel (Top)
                        if (_result != null || _isAnalyzing)
                          SizedBox(
                            height:
                                constraints.maxHeight *
                                0.45, // Take 45% of height
                            child: _buildResultPanel(),
                          ),

                        // Input/Tabs (Bottom, takes remaining space)
                        Expanded(
                          child: Column(
                            children: [
                              Expanded(
                                child: TabBarView(
                                  controller: _tabController,
                                  children: [
                                    _buildTextInput(),
                                    _buildFileUpload(),
                                    _buildImageInput(),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }

                  // Desktop / Wide Layout
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: Column(
                          children: [
                            Expanded(
                              child: TabBarView(
                                controller: _tabController,
                                children: [
                                  _buildTextInput(),
                                  _buildFileUpload(),
                                  _buildImageInput(),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_result != null || _isAnalyzing)
                        Expanded(flex: 2, child: _buildResultPanel()),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.auto_stories_rounded,
            size: 32,
            color: Theme.of(context).colorScheme.primary,
          ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Patteera Reader',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Text Readability Analyzer',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTextInput() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              decoration: InputDecoration(
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                hintText: "Enter or paste your text here...",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(24),
              ),
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton(
              onPressed: () => _analyze(_textController.text),
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text("Analyze Readability"),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileUpload() {
    return Center(
      child: InkWell(
        onTap: _pickFile,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.5),
              width: 2,
              style: BorderStyle.solid, // Fallback to solid for now
            ),
          ),
          padding: const EdgeInsets.all(6),
          child: Container(
            width: 300,
            height: 200,
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.surface.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.cloud_upload_outlined,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  "Click to Upload Text File",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "Supports .txt, .md",
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageInput() {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildImageOption(
            icon: Icons.camera_alt_outlined,
            label: "Take Photo",
            onTap: () => _pickImage(ImageSource.camera),
          ),
          const SizedBox(width: 32),
          _buildImageOption(
            icon: Icons.add_photo_alternate_outlined,
            label: "Upload Image",
            onTap: () => _pickImage(ImageSource.gallery),
          ),
        ],
      ),
    );
  }

  Widget _buildImageOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: 160,
        height: 160,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 48,
              color: Theme.of(context).colorScheme.secondary,
            ),
            const SizedBox(height: 16),
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildResultPanel() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: _isAnalyzing
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(_statusMessage ?? "Processing..."),
                ],
              ),
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Analysis Result",
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 32),
                          Center(
                            child: FittedBox(
                              // Use FittedBox locally for the big circle if it helps, but mostly just standard layout
                              fit: BoxFit.scaleDown,
                              child: Container(
                                width: 200,
                                height: 200,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.primaryContainer,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary
                                          .withValues(alpha: 0.4),
                                      blurRadius: 20,
                                      spreadRadius: 5,
                                    ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      _result!.score.toStringAsFixed(1),
                                      style: Theme.of(context)
                                          .textTheme
                                          .displayLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                          ),
                                    ).animate().fadeIn().scale(),
                                    Text(
                                      "Score",
                                      style: Theme.of(
                                        context,
                                      ).textTheme.labelLarge,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                          Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).colorScheme.secondaryContainer,
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child:
                                  Text(
                                    _result!.label,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSecondaryContainer,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ).animate().slideY(
                                    begin: 0.5,
                                    end: 0,
                                    duration: 400.ms,
                                  ),
                            ),
                          ),
                          const Spacer(), // Spacer works inside IntrinsicHeight + ConstrainedBox (minHeight) column usually, or use Expanded if parent is Flex
                          // Actually Spacer in IntrinsicHeight is tricky. Better to use MainAxisAlignment.spaceBetween or Expanded.
                          // But we are in a SingleChildScrollView -> ConstrainedBox -> Column.
                          // If we want "push to bottom", we should use `Expanded` but `Expanded` needs bounded height.
                          // `ConstrainedBox` gives minHeight, but `Column` doesn't strictly force height to match minHeight unless we use `mainAxisSize: MainAxisSize.max`.
                          // Let's use `Expanded` for the gap.
                          const SizedBox(height: 24),
                          _buildStatRow(
                            "Total Words",
                            _result!.details['totalWords'].toString(),
                          ),
                          _buildStatRow(
                            "Off-List",
                            "${(_result!.details['offList'] as num).toStringAsFixed(1)}%",
                          ),
                          ...(_result!.details.entries
                              .where(
                                (e) =>
                                    e.key != 'totalWords' &&
                                    e.key != 'score' &&
                                    e.key != 'offList' &&
                                    e.key != 'weights',
                              )
                              .map((e) {
                                final weight =
                                    _result!.details['weights']?[e.key];
                                final label = weight != null
                                    ? "${e.key} (x$weight)"
                                    : e.key;
                                return _buildStatRow(
                                  label,
                                  "${(e.value as num).toStringAsFixed(1)}%",
                                );
                              })),
                        ].animate(interval: 100.ms).fadeIn(duration: 400.ms).slideX(begin: 0.1, end: 0),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyLarge),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
