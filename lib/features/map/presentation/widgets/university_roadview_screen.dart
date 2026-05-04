import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../domain/university.dart';
import 'roadview_html.dart';

class UniversityRoadviewScreen extends StatefulWidget {
  final University university;

  const UniversityRoadviewScreen({super.key, required this.university});

  @override
  State<UniversityRoadviewScreen> createState() => _UniversityRoadviewScreenState();
}

class _UniversityRoadviewScreenState extends State<UniversityRoadviewScreen> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();

    final htmlContent = generateRoadviewHtml(
      widget.university.latitude ?? 36.5,
      widget.university.longitude ?? 127.8,
      widget.university.name,
    );

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF0F1626)) // Match map base color
      ..loadHtmlString(htmlContent);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1626),
      body: Stack(
        children: [
          // The strict EagerGestureRecognizer prevents the WebView from 
          // passing gestures UP to Flutter. This completely solves the 
          // touch-dragging panning issue common to Kakao Roadview inside Flutter apps.
          WebViewWidget(
            controller: _controller,
            gestureRecognizers: {
              Factory<OneSequenceGestureRecognizer>(
                () => EagerGestureRecognizer(),
              ),
            },
          ),
          
          // Custom Back Button Overlay 
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            child: InkWell(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white24),
                ),
                child: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),

          // Label Overlay
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white24),
              ),
              child: Row(
                children: [
                   const Icon(Icons.directions_walk, color: Colors.white, size: 16),
                   const SizedBox(width: 8),
                   Text(
                    widget.university.name,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
