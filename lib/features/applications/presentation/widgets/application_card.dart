import 'package:flutter/material.dart';
import '../../domain/application.dart';
import '../../../../design_system/theme/hanguk_ink.dart';
import 'process_tracker.dart';
import 'university_room_modal.dart';

class ApplicationCard extends StatefulWidget {
  final StudentApplication application;
  final VoidCallback? onDiscussionTap;

  const ApplicationCard({
    super.key,
    required this.application,
    this.onDiscussionTap,
  });

  @override
  State<ApplicationCard> createState() => _ApplicationCardState();
}

class _ApplicationCardState extends State<ApplicationCard> {
  bool _isExpanded = false;

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    final application = widget.application;
    final university = application.university;

    final isPending = application.status == 'pending_approval';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      decoration: BoxDecoration(
        color: HangukInk.paper.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isPending
              ? HangukInk.gold.withValues(alpha: 0.32)
              : HangukInk.ink.withValues(alpha: 0.10),
        ),
        boxShadow: [
          BoxShadow(
            color: HangukInk.ink.withValues(alpha: 0.07),
            blurRadius: 26,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: _toggleExpanded,
          child: Padding(
            padding: const EdgeInsets.all(
              16.0,
            ), // Standard padding for the card contents
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Logo + Title + Expand Icon
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (university?.logoUrl != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        // University name appears beside the logo, so the
                        // logo image is decorative for screen readers.
                        child: Image.network(
                          university!.logoUrl!,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          excludeFromSemantics: true,
                          errorBuilder: (context, error, stackTrace) =>
                              _fallbackLogo(),
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return _loadingLogo();
                          },
                        ),
                      )
                    else
                      _fallbackLogo(),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            university?.name ?? 'Unknown University',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: HangukInk.ink,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Text(
                                university?.location ?? '',
                                style: const TextStyle(
                                  color: HangukInk.ink2,
                                  fontSize: 13,
                                ),
                              ),
                              if (university?.isPartner ?? false) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: HangukInk.jade.withValues(
                                      alpha: 0.12,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'Partner',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: HangukInk.jadeDeep,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      _isExpanded ? Icons.expand_less : Icons.expand_more,
                      color: HangukInk.ink3,
                    ),
                  ],
                ),

                // Expandable Body
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  alignment: Alignment.topCenter,
                  child: _isExpanded
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 16),

                            // Status Tracker or Pending Banner
                            if (isPending)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: HangukInk.gold.withValues(
                                    alpha: 0.10,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  border: const Border(
                                    left: BorderSide(
                                      color: HangukInk.gold,
                                      width: 3,
                                    ),
                                  ),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(
                                      Icons.hourglass_empty_rounded,
                                      color: HangukInk.goldDeep,
                                      size: 20,
                                    ),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Awaiting Counselor Approval.\nWe will notify you once reviewed.',
                                        style: TextStyle(
                                          color: HangukInk.goldDeep,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else
                              ProcessTracker(status: application.status),

                            const SizedBox(height: 16),
                            Divider(
                              color: HangukInk.ink.withValues(alpha: 0.10),
                            ),

                            // Actions
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => UniversityRoomModal.show(
                                      context,
                                      application,
                                      initialTabIndex: 1,
                                    ),
                                    style: _actionButtonStyle,
                                    icon: const Icon(
                                      Icons.forum_outlined,
                                      size: 16,
                                      color: HangukInk.jadeDeep,
                                    ),
                                    label: const Text('Discussion'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => UniversityRoomModal.show(
                                      context,
                                      application,
                                      initialTabIndex: 3,
                                    ),
                                    style: _actionButtonStyle,
                                    icon: const Icon(
                                      Icons.event_note_outlined,
                                      size: 16,
                                      color: HangukInk.jadeDeep,
                                    ),
                                    label: const Text('Calendar'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static final ButtonStyle _actionButtonStyle = OutlinedButton.styleFrom(
    foregroundColor: HangukInk.ink,
    side: BorderSide(color: HangukInk.ink.withValues(alpha: 0.16)),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
  );

  Widget _fallbackLogo() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: HangukInk.gold.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.school_outlined, color: HangukInk.goldDeep),
    );
  }

  // Low-contrast placeholder shown while the logo is still loading so users
  // see something on slow networks (audit P1).
  Widget _loadingLogo() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: HangukInk.ink.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: HangukInk.ink.withValues(alpha: 0.25),
          ),
        ),
      ),
    );
  }
}
