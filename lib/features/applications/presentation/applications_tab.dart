import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/data/auth_repository.dart';
import '../../uni_db/presentation/widgets/home_recent_changes_banner.dart';
import '../../uni_db/presentation/widgets/verified_deadlines_overlay.dart';
import 'widgets/application_card.dart';
import 'widgets/selection_bar.dart';
import 'widgets/university_selection_view.dart';
import 'widgets/university_room_modal.dart';
import 'applications_view_model.dart';

class ApplicationsTab extends ConsumerWidget {
  const ApplicationsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabStateAsync = ref.watch(applicationsTabProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  title: const Text('My Applications'),
                  floating: true,
                  snap: true,
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.logout),
                      tooltip: 'Sign Out',
                      onPressed: () {
                        ref.read(authRepositoryProvider).signOut();
                      },
                    ),
                  ],
                ),

                // University DB overlay (gated by --dart-define=UNI_DB_ENABLED=true).
                // Renders nothing when the flag is off or the user has no
                // tracked institutions, so production builds are unaffected.
                const HomeRecentChangesBannerSliver(),
                const VerifiedDeadlinesOverlaySliver(),

                tabStateAsync.when(
                  data: (state) {
                    if (state.isEmpty) {
                      return const SliverFillRemaining(
                        child: _EmptyApplicationsState(),
                      );
                    }

                    return SliverMainAxisGroup(
                      slivers: [
                        // Suggestions Section
                        if (state.shouldShowSuggestions)
                          SliverToBoxAdapter(
                            child: UniversitySelectionView(
                              suggestions: state.suggestions,
                              onSubmitted: () {
                                // The selection bar handles refresh/invalidation
                              },
                            ),
                          )
                        else
                          const SliverToBoxAdapter(child: SizedBox.shrink()),

                        // Applications Section
                        if (state.pendingApps.isNotEmpty)
                          ..._buildPendingSection(state.pendingApps),

                        if (state.activeApps.isNotEmpty)
                          ..._buildActiveSection(state.activeApps),

                        if (state.hasActiveApplications)
                          const SliverToBoxAdapter(child: SizedBox(height: 120)),
                      ],
                    );
                  },
                  loading: () => const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator.adaptive()),
                  ),
                  error: (err, stack) => SliverFillRemaining(
                    child: Center(child: Text('Error loading applications: $err')),
                  ),
                ),
              ],
            ),
          ),
          // Phase 1: persistent selection bar — shared with the Map tab so
          // picks made anywhere are reflected here, and a single Submit
          // button finalises the batch.
          const SelectionBar(),
        ],
      ),
    );
  }

  List<Widget> _buildPendingSection(List<dynamic> pendingApps) {
    return [
      const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(
            'Pending Applications',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
      ),
      SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final app = pendingApps[index];
            return ApplicationCard(
              application: app,
              onDiscussionTap: () {
                UniversityRoomModal.show(context, app, initialTabIndex: 1);
              },
            );
          },
          childCount: pendingApps.length,
        ),
      ),
    ];
  }

  List<Widget> _buildActiveSection(List<dynamic> activeApps) {
    return [
      const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(
            'Active Applications',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
      ),
      SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final app = activeApps[index];
            return ApplicationCard(
              application: app,
              onDiscussionTap: () {
                UniversityRoomModal.show(context, app, initialTabIndex: 1);
              },
            );
          },
          childCount: activeApps.length,
        ),
      ),
    ];
  }
}

class _EmptyApplicationsState extends StatelessWidget {
  const _EmptyApplicationsState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.school_outlined, size: 64, color: Colors.white24),
            const SizedBox(height: 16),
            const Text(
              'No applications yet',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              'Open the Map tab to browse universities and add them to your list.',
              style: TextStyle(color: Colors.white54, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
