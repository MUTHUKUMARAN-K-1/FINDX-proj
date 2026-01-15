import 'package:flutter/material.dart';

class FilterChips extends StatefulWidget {
  const FilterChips({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final String selected;
  final void Function(String) onSelected;

  static const List<Map<String, dynamic>> _filters = [
    {'label': 'All', 'icon': Icons.grid_view},
    {'label': 'Lost', 'icon': Icons.search},
    {'label': 'Found', 'icon': Icons.check_circle_outline},
    {'label': 'Pets', 'icon': Icons.pets},
    {'label': 'Electronics', 'icon': Icons.devices},
    {'label': 'Documents', 'icon': Icons.description},
  ];

  @override
  State<FilterChips> createState() => _FilterChipsState();
}

class _FilterChipsState extends State<FilterChips> {
  final ScrollController _scrollController = ScrollController();
  bool _canScrollBackward = false;
  bool _canScrollForward = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_updateScrollButtons);
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateScrollButtons());
  }

  @override
  void dispose() {
    _scrollController.removeListener(_updateScrollButtons);
    _scrollController.dispose();
    super.dispose();
  }

  void _updateScrollButtons() {
    if (!mounted || !_scrollController.hasClients) return;
    final pos = _scrollController.position;
    final canBack = pos.pixels > 0.5;
    final canForward = pos.pixels < pos.maxScrollExtent - 0.5;
    if (canBack != _canScrollBackward || canForward != _canScrollForward) {
      setState(() {
        _canScrollBackward = canBack;
        _canScrollForward = canForward;
      });
    }
  }

  void _scrollBy(double offset) {
    if (!_scrollController.hasClients) return;
    final target = (_scrollController.offset + offset).clamp(
      _scrollController.position.minScrollExtent,
      _scrollController.position.maxScrollExtent,
    );
    _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    const scrollStep = 140.0;

    return SizedBox(
      height: 56,
      child: Row(
        children: [
          // Left chevron
          SizedBox(
            width: 36,
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: Icon(
                Icons.chevron_left,
                color: _canScrollBackward
                    ? colorScheme.onSurface
                    : Colors.grey.shade300,
              ),
              onPressed: _canScrollBackward
                  ? () => _scrollBy(-scrollStep)
                  : null,
              tooltip: 'Scroll left',
            ),
          ),
          // Scrollable chips
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              child: Row(
                children: [
                  for (final filter in FilterChips._filters) ...[
                    Builder(
                      builder: (context) {
                        final isSelected = widget.selected == filter['label'];
                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(22),
                            onTap: () =>
                                widget.onSelected(filter['label'] as String),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? colorScheme.primary
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(
                                  color: isSelected
                                      ? colorScheme.primary
                                      : Colors.grey.shade300,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: colorScheme.primary
                                              .withOpacity(0.12),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    filter['icon'],
                                    size: 16,
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.grey.shade600,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    filter['label'],
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.grey.shade700,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.w500,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
          // Right chevron
          SizedBox(
            width: 36,
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: Icon(
                Icons.chevron_right,
                color: _canScrollForward
                    ? colorScheme.onSurface
                    : Colors.grey.shade300,
              ),
              onPressed: _canScrollForward ? () => _scrollBy(scrollStep) : null,
              tooltip: 'Scroll right',
            ),
          ),
        ],
      ),
    );
  }
}
