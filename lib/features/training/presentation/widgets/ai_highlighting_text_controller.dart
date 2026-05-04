import 'package:flutter/material.dart';

class GrammarIssue {
  final int start;
  final int end;
  final String originalText;
  final String suggestion;

  GrammarIssue({required this.start, required this.end, required this.originalText, required this.suggestion});
}

class AiHighlightingTextController extends TextEditingController {
  String? ghostText;
  List<GrammarIssue> issues = [];

  AiHighlightingTextController({String? text}) : super(text: text);

  void setGhostText(String? text) {
    if (ghostText != text) {
      ghostText = text;
      notifyListeners();
    }
  }

  void setIssues(List<GrammarIssue> newIssues) {
    issues = newIssues;
    notifyListeners();
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    List<InlineSpan> children = [];
    String sourceText = text;

    if (issues.isEmpty) {
      children.add(TextSpan(style: style, text: sourceText));
    } else {
      // Sort issues by start index
      List<GrammarIssue> sortedIssues = List.from(issues)..sort((a, b) => a.start.compareTo(b.start));
      int currentPos = 0;

      for (final issue in sortedIssues) {
        if (issue.start > currentPos) {
          children.add(TextSpan(
            style: style,
            text: sourceText.substring(currentPos, issue.start),
          ));
        }

        // Add the squiggly underlined issue
        int endPos = issue.end > sourceText.length ? sourceText.length : issue.end;
        if (issue.start < endPos) {
          children.add(TextSpan(
            style: style?.copyWith(
              decoration: TextDecoration.underline,
              decorationStyle: TextDecorationStyle.wavy,
              decorationColor: Colors.redAccent,
            ),
            text: sourceText.substring(issue.start, endPos),
          ));
          currentPos = endPos;
        }
      }

      if (currentPos < sourceText.length) {
        children.add(TextSpan(
          style: style,
          text: sourceText.substring(currentPos),
        ));
      }
    }

    // Append ghost text if available
    if (ghostText != null && ghostText!.isNotEmpty) {
      children.add(TextSpan(
        style: style?.copyWith(
          color: Colors.white24, // Muted color for ghost text
          fontStyle: FontStyle.italic,
        ),
        text: ghostText,
      ));
    }

    return TextSpan(style: style, children: children);
  }
}
