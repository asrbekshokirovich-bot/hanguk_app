import 'package:flutter/material.dart';
import '../../domain/document_type.dart';
import '../../domain/document.dart';
import '../../../../design_system/theme/hanguk_ink.dart';
import '../../../../l10n/app_localizations.dart';

class DocumentSlot extends StatelessWidget {
  final int index;
  final DocumentType type;
  final AppDocument? uploadedDoc;
  final bool isUploading;
  final VoidCallback onUploadTap;
  final VoidCallback? onPreviewTap;
  final VoidCallback? onDeleteTap;

  const DocumentSlot({
    super.key,
    required this.index,
    required this.type,
    this.uploadedDoc,
    required this.isUploading,
    required this.onUploadTap,
    this.onPreviewTap,
    this.onDeleteTap,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final bool isApproved = uploadedDoc?.status == 'approved';
    final bool isUploaded = uploadedDoc != null;

    final Color bgColor = isApproved
        ? HangukInk.jade.withValues(alpha: 0.10)
        : isUploaded
        ? HangukInk.plum.withValues(alpha: 0.08)
        : HangukInk.paper.withValues(alpha: 0.70);

    final Color borderColor = isApproved
        ? HangukInk.jade.withValues(alpha: 0.32)
        : isUploaded
        ? HangukInk.plum.withValues(alpha: 0.32)
        : HangukInk.ink.withValues(alpha: 0.10);

    return Container(
      margin: const EdgeInsets.only(bottom: 11),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: HangukInk.ink.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          // Index or Checkmark
          SizedBox(
            width: 32,
            child: isApproved
                ? const Icon(Icons.check_circle, color: HangukInk.jadeDeep)
                : isUploaded
                ? const Icon(
                    Icons.check_circle_outline,
                    color: HangukInk.plumDeep,
                  )
                : Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: HangukInk.ink.withValues(alpha: 0.2),
                        width: 2,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: HangukInk.ink3,
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: 8),

          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  type.nameEn,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    height: 1.25,
                    color: isApproved ? HangukInk.jadeDeep : HangukInk.ink,
                  ),
                ),
                if (isUploaded && !isApproved)
                  const Text(
                    'Pending Review',
                    style: TextStyle(fontSize: 12, color: HangukInk.plumDeep),
                  ),
                if (isApproved)
                  const Text(
                    'Approved',
                    style: TextStyle(fontSize: 12, color: HangukInk.jadeDeep),
                  ),
              ],
            ),
          ),

          // Actions
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isUploaded || isApproved) ...[
                IconButton(
                  icon: const Icon(Icons.visibility_outlined, size: 20),
                  color: HangukInk.jadeDeep,
                  tooltip: l.a11yTooltipPreviewDocument,
                  onPressed: onPreviewTap,
                ),
                if (!isApproved)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    color: Colors.redAccent,
                    tooltip: l.a11yTooltipDeleteDocument,
                    onPressed: isUploading ? null : onDeleteTap,
                  ),
              ] else
                ElevatedButton.icon(
                  onPressed: isUploading ? null : onUploadTap,
                  icon: isUploading
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.cloud_upload_outlined, size: 14),
                  label: const Text('Upload'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: HangukInk.plum,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    textStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(11),
                    ),
                    // WCAG 2.2 target-size minimum is 48dp on the height
                    // axis; previous 36dp height failed AA.
                    minimumSize: const Size(80, 48),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
