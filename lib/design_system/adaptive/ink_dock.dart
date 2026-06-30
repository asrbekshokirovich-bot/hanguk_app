import 'package:flutter/material.dart';
import '../theme/hanguk_ink.dart';

/// Floating "ink-seal dock" bottom navigation from the `Hanguk App.dc.html`
/// prototype: a frosted hanji bar holding two seal-stamp tabs on each side of
/// a central violet **Ask AI** pill. The active tab fills with sumi ink, its
/// icon flips to ivory, and a dancheong accent dot appears above it.
///
/// Drop-in for [HomeScreen]: it owns both navigation (via [onTap]) and the AI
/// entry point (via [onAskAi]), replacing the old bottom bar + floating button.
class InkDock extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onAskAi;
  final List<InkDockItem> items;
  final String askAiLabel;

  const InkDock({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.onAskAi,
    required this.items,
    this.askAiLabel = 'Ask AI',
  });

  @override
  Widget build(BuildContext context) {
    assert(items.length == 4, 'InkDock expects exactly 4 tabs.');
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        child: Container(
          height: 70,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFFDFBF6).withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: HangukInk.ink.withValues(alpha: 0.08)),
            boxShadow: [
              BoxShadow(
                color: HangukInk.ink.withValues(alpha: 0.16),
                blurRadius: 38,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Row(
            children: [
              _SealTab(item: items[0], accent: HangukInk.tabAccents[0],
                  selected: currentIndex == 0, onTap: () => onTap(0)),
              _SealTab(item: items[1], accent: HangukInk.tabAccents[1],
                  selected: currentIndex == 1, onTap: () => onTap(1)),
              Expanded(child: _AskAiPill(label: askAiLabel, onTap: onAskAi)),
              _SealTab(item: items[2], accent: HangukInk.tabAccents[2],
                  selected: currentIndex == 2, onTap: () => onTap(2)),
              _SealTab(item: items[3], accent: HangukInk.tabAccents[3],
                  selected: currentIndex == 3, onTap: () => onTap(3)),
            ],
          ),
        ),
      ),
    );
  }
}

class InkDockItem {
  final String label;
  final IconData icon;
  const InkDockItem({required this.label, required this.icon});
}

class _SealTab extends StatelessWidget {
  final InkDockItem item;
  final Color accent;
  final bool selected;
  final VoidCallback onTap;

  const _SealTab({
    required this.item,
    required this.accent,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Stack(
            alignment: Alignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOut,
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: selected ? HangukInk.ink : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: HangukInk.ink.withValues(alpha: 0.28),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ]
                      : null,
                ),
                child: Icon(
                  item.icon,
                  size: 22,
                  color: selected ? HangukInk.hanji : HangukInk.ink2,
                ),
              ),
              if (selected)
                Positioned(
                  top: 0,
                  right: 2,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AskAiPill extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _AskAiPill({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Semantics(
        button: true,
        label: label,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Container(
            height: 50,
            padding: const EdgeInsets.fromLTRB(14, 0, 7, 0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF9B7CE0), Color(0xFF7857C8), Color(0xFF523A92)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF523A92).withValues(alpha: 0.42),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.smart_toy_outlined,
                    size: 20, color: Color(0xFFEFE7FB)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.92),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFF0E9FC), Color(0xFFCDB9F2)],
                    ),
                  ),
                  child: const Icon(Icons.send_rounded,
                      size: 17, color: Color(0xFF4A2F86)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
