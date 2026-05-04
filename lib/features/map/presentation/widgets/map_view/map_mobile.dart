import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../../../design_system/theme/app_colors.dart';
import '../../../domain/university.dart';
import '../university_map_html.dart';

Widget buildMap({
  required BuildContext context,
  required List<University> universities,
  required void Function(University u) onMarkerClick,
}) {
  return _MobileMapWidget(
    universities: universities,
    onMarkerClick: onMarkerClick,
  );
}

class _MobileMapWidget extends StatefulWidget {
  final List<University> universities;
  final void Function(University u) onMarkerClick;

  const _MobileMapWidget({
    Key? key,
    required this.universities,
    required this.onMarkerClick,
  }) : super(key: key);

  @override
  State<_MobileMapWidget> createState() => _MobileMapWidgetState();
}

class _MobileMapWidgetState extends State<_MobileMapWidget> {
  late final WebViewController _controller;
  late final Map<String, University> _uniById;

  @override
  void initState() {
    super.initState();
    _uniById = {for (final u in widget.universities) u.id: u};

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(AppColors.backgroundNavy)
      ..addJavaScriptChannel(
        'HangukMapChannel',
        onMessageReceived: (JavaScriptMessage message) {
          final u = _uniById[message.message];
          if (u != null && mounted) {
            widget.onMarkerClick(u);
          }
        },
      )
      ..loadHtmlString(generateMapHtml(widget.universities), baseUrl: 'https://hanguk.uz');
  }

  @override
  Widget build(BuildContext context) {
    return WebViewWidget(controller: _controller);
  }
}
