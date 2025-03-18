import 'package:demo/dummy_data/development.dart';
import 'package:flutter/material.dart';
import 'package:trina_grid/trina_grid.dart';

import '../../widget/trina_example_button.dart';
import '../../widget/trina_example_screen.dart';

class ScrollbarsScreen extends StatefulWidget {
  static const routeName = 'feature/scrollbars';

  const ScrollbarsScreen({super.key});

  @override
  State<ScrollbarsScreen> createState() => _ScrollbarsScreenState();
}

class _ScrollbarsScreenState extends State<ScrollbarsScreen> {
  final List<TrinaColumn> columns = [];
  final List<TrinaRow> rows = [];
  late final TrinaGridStateManager stateManager;

  // Scrollbar configuration
  bool isAlwaysShown = true;
  bool thumbVisible = true;
  bool showTrack = true;
  bool showHorizontal = true;
  bool showVertical = true;
  double thickness = 8.0;
  double minThumbLength = 40.0;
  Color? thumbColor;
  Color? trackColor;

  @override
  void initState() {
    super.initState();

    final dummyData = DummyData(20, 500);
    columns.addAll(dummyData.columns);
    rows.addAll(dummyData.rows);
  }

  void _updateScrollbarConfig() {
    final config = TrinaGridConfiguration(
      columnSize: const TrinaGridColumnSizeConfig(
        autoSizeMode: TrinaAutoSizeMode.none,
      ),
      scrollbar: TrinaGridScrollbarConfig(
        isAlwaysShown: isAlwaysShown,
        thumbVisible: thumbVisible,
        showTrack: showTrack,
        showHorizontal: showHorizontal,
        showVertical: showVertical,
        thickness: thickness,
        minThumbLength: minThumbLength,
        thumbColor: thumbColor,
        trackColor: trackColor,
      ),
    );

    stateManager.setConfiguration(config);
    stateManager.notifyListeners();
  }

  @override
  Widget build(BuildContext context) {
    return TrinaExampleScreen(
      title: 'Scrollbar Customization',
      topTitle: 'Scrollbar Customization',
      topContents: const [
        Text(
          'TrinaGrid provides extensive customization options for scrollbars. Control visibility, appearance, and behavior of scrollbars.',
        ),
      ],
      topButtons: [
        TrinaExampleButton(
          url:
              'https://github.com/doonfrs/trina_grid/blob/master/demo/lib/screen/feature/scrollbars.dart',
        ),
      ],
      body: Column(
        children: [
          _buildControls(),
          Expanded(
            child: TrinaGrid(
              columns: columns,
              rows: rows,
              onLoaded: (TrinaGridOnLoadedEvent event) {
                stateManager = event.stateManager;
                _updateScrollbarConfig();
              },
              configuration: TrinaGridConfiguration(
                columnSize: const TrinaGridColumnSizeConfig(
                  autoSizeMode: TrinaAutoSizeMode.none,
                ),
                scrollbar: TrinaGridScrollbarConfig(
                  isAlwaysShown: isAlwaysShown,
                  thumbVisible: thumbVisible,
                  showTrack: showTrack,
                  showHorizontal: showHorizontal,
                  showVertical: showVertical,
                  thickness: thickness,
                  minThumbLength: minThumbLength,
                  thumbColor: thumbColor,
                  trackColor: trackColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Scrollbar Settings',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 12),

                // Visibility controls
                Row(
                  children: [
                    _buildSwitchControl('Always Show', isAlwaysShown, (value) {
                      setState(() {
                        isAlwaysShown = value;
                        _updateScrollbarConfig();
                      });
                    }),
                    const SizedBox(width: 16),
                    _buildSwitchControl('Thumb Visible', thumbVisible, (value) {
                      setState(() {
                        thumbVisible = value;
                        _updateScrollbarConfig();
                      });
                    }),
                    const SizedBox(width: 16),
                    _buildSwitchControl('Show Track', showTrack, (value) {
                      setState(() {
                        showTrack = value;
                        _updateScrollbarConfig();
                      });
                    }),
                  ],
                ),
                const SizedBox(height: 8),

                // Scrollbar direction controls
                Row(
                  children: [
                    _buildSwitchControl('Show Horizontal', showHorizontal,
                        (value) {
                      setState(() {
                        showHorizontal = value;
                        _updateScrollbarConfig();
                      });
                    }),
                    const SizedBox(width: 16),
                    _buildSwitchControl('Show Vertical', showVertical, (value) {
                      setState(() {
                        showVertical = value;
                        _updateScrollbarConfig();
                      });
                    }),
                  ],
                ),
                const SizedBox(height: 12),

                // Size controls
                Row(
                  children: [
                    const Text('Thickness:'),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 200,
                      child: Slider(
                        value: thickness,
                        min: 1,
                        max: 20,
                        divisions: 19,
                        label: thickness.round().toString(),
                        onChanged: (value) {
                          setState(() {
                            thickness = value;
                            _updateScrollbarConfig();
                          });
                        },
                      ),
                    ),
                    Text('${thickness.round()} px'),
                  ],
                ),
                Row(
                  children: [
                    const Text('Min Thumb Length:'),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 200,
                      child: Slider(
                        value: minThumbLength,
                        min: 20,
                        max: 100,
                        divisions: 16,
                        label: minThumbLength.round().toString(),
                        onChanged: (value) {
                          setState(() {
                            minThumbLength = value;
                            _updateScrollbarConfig();
                          });
                        },
                      ),
                    ),
                    Text('${minThumbLength.round()} px'),
                  ],
                ),
                const SizedBox(height: 12),

                // Color controls
                Row(
                  children: [
                    // Thumb color
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Thumb Color:'),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _buildColorButton(
                              null,
                              'Default',
                              thumbColor == null,
                              () => _setThumbColor(null),
                            ),
                            const SizedBox(width: 8),
                            _buildColorButton(
                              Colors.blue.withAlpha((0.6 * 255).toInt()),
                              'Blue',
                              thumbColor ==
                                  Colors.blue.withAlpha((0.6 * 255).toInt()),
                              () => _setThumbColor(
                                  Colors.blue.withAlpha((0.6 * 255).toInt())),
                            ),
                            const SizedBox(width: 8),
                            _buildColorButton(
                              Colors.purple.withAlpha((0.6 * 255).toInt()),
                              'Purple',
                              thumbColor ==
                                  Colors.purple.withAlpha((0.6 * 255).toInt()),
                              () => _setThumbColor(
                                  Colors.purple.withAlpha((0.6 * 255).toInt())),
                            ),
                            const SizedBox(width: 8),
                            _buildColorButton(
                              Colors.orange.withAlpha((0.6 * 255).toInt()),
                              'Orange',
                              thumbColor ==
                                  Colors.orange.withAlpha((0.6 * 255).toInt()),
                              () => _setThumbColor(
                                  Colors.orange.withAlpha((0.6 * 255).toInt())),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(width: 24),

                    // Track color
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Track Color:'),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _buildColorButton(
                              null,
                              'Default',
                              trackColor == null,
                              () => _setTrackColor(null),
                            ),
                            const SizedBox(width: 8),
                            _buildColorButton(
                              Colors.grey.withAlpha((0.2 * 255).toInt()),
                              'Grey',
                              trackColor ==
                                  Colors.grey.withAlpha((0.2 * 255).toInt()),
                              () => _setTrackColor(
                                  Colors.grey.withAlpha((0.2 * 255).toInt())),
                            ),
                            const SizedBox(width: 8),
                            _buildColorButton(
                              Colors.teal.withAlpha((0.2 * 255).toInt()),
                              'Teal',
                              trackColor ==
                                  Colors.teal.withAlpha((0.2 * 255).toInt()),
                              () => _setTrackColor(
                                  Colors.teal.withAlpha((0.2 * 255).toInt())),
                            ),
                            const SizedBox(width: 8),
                            _buildColorButton(
                              Colors.amber.withAlpha((0.2 * 255).toInt()),
                              'Amber',
                              trackColor ==
                                  Colors.amber.withAlpha((0.2 * 255).toInt()),
                              () => _setTrackColor(
                                  Colors.amber.withAlpha((0.2 * 255).toInt())),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchControl(
      String label, bool value, Function(bool) onChanged) {
    return Row(
      children: [
        Text(label),
        const SizedBox(width: 8),
        Switch(
          value: value,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildColorButton(
      Color? color, String label, bool isSelected, VoidCallback onPressed) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color ?? Colors.grey.shade300,
        elevation: isSelected ? 4 : 1,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      onPressed: onPressed,
      child: Text(
        label,
        style: TextStyle(
          color: color != null && color.a > 125 ? Colors.white : Colors.black,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  void _setThumbColor(Color? color) {
    setState(() {
      thumbColor = color;
      _updateScrollbarConfig();
    });
  }

  void _setTrackColor(Color? color) {
    setState(() {
      trackColor = color;
      _updateScrollbarConfig();
    });
  }
}
