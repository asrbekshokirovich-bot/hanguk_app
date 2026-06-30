import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/documents_repository.dart';
import '../domain/document_type.dart';
import '../domain/document.dart';
import '../../../../design_system/adaptive/ink_ambient_background.dart';
import '../../../../design_system/theme/hanguk_ink.dart';
import '../../../../l10n/app_localizations.dart';
import 'widgets/document_slot.dart';

class DocumentsTab extends ConsumerStatefulWidget {
  const DocumentsTab({super.key});

  @override
  ConsumerState<DocumentsTab> createState() => _DocumentsTabState();
}

class _DocumentsTabState extends ConsumerState<DocumentsTab> {
  final Map<String, bool> _uploadingDocs = {};

  Future<void> _handleUpload(DocumentType type) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() => _uploadingDocs[type.id] = true);

        File file = File(result.files.single.path!);
        final repo = ref.read(documentsRepositoryProvider);

        await repo.uploadDocument(file, type);

        // Refresh provider
        ref.invalidate(documentsProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _uploadingDocs[type.id] = false);
      }
    }
  }

  Future<void> _handlePreview(AppDocument doc) async {
    try {
      final signedUrl = await Supabase.instance.client.storage
          .from('student-documents')
          .createSignedUrl(doc.filePath, 300); // 5-minute expiry

      final uri = Uri.parse(signedUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open document preview.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Preview error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final docsAsync = ref.watch(documentsProvider);
    final l = AppLocalizations.of(context)!;

    return Stack(
      children: [
        const InkAmbientBackground(tabIndex: 2),
        RefreshIndicator(
      color: HangukInk.plumDeep,
      backgroundColor: HangukInk.paper,
      // Pull-to-refresh so newly uploaded/approved documents appear without
      // restarting the app.
      onRefresh: () async {
        ref.invalidate(documentsProvider);
        await ref.read(documentsProvider.future);
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverAppBar(
            title: Text(
              l.documentsTabTitle,
              style: HangukInk.display.copyWith(fontSize: 24),
            ),
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            foregroundColor: HangukInk.ink,
            elevation: 0,
            floating: true,
            snap: true,
          ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: HangukInk.jade.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: HangukInk.jade.withValues(alpha: 0.28),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: HangukInk.jadeDeep),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Upload valid PDF or JPEG scans of your original documents. Max 10MB per file.',
                          style: TextStyle(fontSize: 13, color: HangukInk.ink2),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 26),
                const Padding(
                  padding: EdgeInsets.only(left: 2),
                  child: Text('REQUIRED DOCUMENTS', style: HangukInk.overline),
                ),
                const SizedBox(height: 14),
              ],
            ),
          ),
        ),

        docsAsync.when(
          data: (uploadedDocs) {
            return SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final type = DocumentConstants.requiredDocuments[index];

                  // Match uploaded doc safely
                  AppDocument? uploadedMatch;
                  for (final doc in uploadedDocs) {
                    if (doc.name.contains('[${type.id}]') ||
                        doc.filePath.contains('${type.id}-')) {
                      uploadedMatch = doc;
                      break;
                    }
                  }

                  return DocumentSlot(
                    index: index,
                    type: type,
                    uploadedDoc: uploadedMatch,
                    isUploading: _uploadingDocs[type.id] ?? false,
                    onUploadTap: () => _handleUpload(type),
                    onPreviewTap: uploadedMatch != null
                        ? () => _handlePreview(uploadedMatch!)
                        : null,
                    onDeleteTap: () async {
                      if (uploadedMatch != null) {
                        setState(() => _uploadingDocs[type.id] = true);
                        await ref
                            .read(documentsRepositoryProvider)
                            .deleteDocument(uploadedMatch);
                        ref.invalidate(documentsProvider);
                        setState(() => _uploadingDocs[type.id] = false);
                      }
                    },
                  );
                }, childCount: DocumentConstants.requiredDocuments.length),
              ),
            );
          },
          loading: () => const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator.adaptive()),
          ),
          error: (err, stack) => SliverFillRemaining(
            child: Center(
              child: Text(
                'Error: $err',
                style: const TextStyle(color: HangukInk.ink2),
              ),
            ),
          ),
        ),

          const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
        ],
      ),
    ),
      ],
    );
  }
}
