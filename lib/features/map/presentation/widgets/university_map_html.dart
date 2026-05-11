import '../../../../core/config/app_config.dart';
import '../../domain/university.dart';

String generateMapHtml(List<University> universities) {
  // Audit K2 (2026-05-11): Kakao JS key sourced from AppConfig
  // (overridable via `--dart-define=KAKAO_JS_KEY=...`). The HTML
  // string is templated by Dart before being loaded into the WebView;
  // no external input touches the interpolation site.
  final kakaoJsKey = AppConfig.kakaoJsKey;
  final validUnis =
      universities.where((u) => u.latitude != null && u.longitude != null);

  final kakaoMarkersJs = validUnis.map((u) {
    final safeName = u.name.replaceAll("'", "\\'").replaceAll('"', '\\"');
    return "addKakaoMarker('${u.id}', ${u.latitude}, ${u.longitude}, '$safeName');";
  }).join('\n');

  final leafletMarkersJs = validUnis.map((u) {
    final safeName = u.name.replaceAll("'", "\\'").replaceAll('"', '\\"');
    return "addLeafletMarker('${u.id}', ${u.latitude}, ${u.longitude}, '$safeName');";
  }).join('\n');

  return '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
    <!-- Leaflet CSS loaded statically for OSM fallback -->
    <link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css" integrity="sha256-p4NxAoJBhIIN+hmNHrzRCf9tD/miZyoHS5obTRR9BMY=" crossorigin=""/>
    <script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js" integrity="sha256-20nQCchB9co0qIjJZRGuk2/Z9VM+kNiyxNV1lvTlZBo=" crossorigin=""></script>
    <style>
        html, body { width: 100%; height: 100%; margin: 0; padding: 0; background-color: #0f1626; }
        #map { width: 100%; height: 100%; }
        * { -webkit-tap-highlight-color: transparent; }
        .leaflet-custom-marker {
            background-color: #1e40af;
            border: 2px solid #ffffff;
            border-radius: 50%;
            box-shadow: 0 1px 3px rgba(0,0,0,0.4);
        }
    </style>
</head>
<body>
    <div id="map"></div>
    <script>
        function triggerAppEvent(id) {
            if (window.HangukMapChannel) window.HangukMapChannel.postMessage(id);
            if (window.parent) window.parent.postMessage({ type: 'HangukMapClick', id: id }, '*');
        }

        function initLeafletMap() {
            if (!window.L) {
                document.getElementById('map').innerHTML = "<div style='color:white;text-align:center;padding-top:40%;'>Error: Leaflet SDK could not be loaded. Please check your network connection.</div>";
                return;
            }
            try {
                var map = L.map('map').setView([36.5, 127.8], 7);
                
                L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
                    attribution: '© OpenStreetMap',
                    maxZoom: 19
                }).addTo(map);

                function addLeafletMarker(id, lat, lng, title) {
                    var icon = L.divIcon({
                        className: 'leaflet-custom-marker',
                        iconSize: [16, 16]
                    });
                    var marker = L.marker([lat, lng], {icon: icon}).addTo(map);
                    marker.bindTooltip(title, {direction: 'top', offset: [0, -8]});
                    marker.on('click', function() {
                        triggerAppEvent(id);
                    });
                }

                // Inject Leaflet Markers
                $leafletMarkersJs
                
                setTimeout(function() { map.invalidateSize(); }, 600);
            } catch (e) {
                console.error(e);
                document.getElementById('map').innerHTML = "<div style='color:white;text-align:center;padding-top:40%;'>Error initializing Leaflet map: " + e.message + "</div>";
            }
        }

        function initKakaoMap() {
            var mapContainer = document.getElementById('map');
            var mapOption = { center: new kakao.maps.LatLng(36.5, 127.8), level: 13 };
            var map = new kakao.maps.Map(mapContainer, mapOption);

            function addKakaoMarker(id, lat, lng, title) {
                var markerPosition = new kakao.maps.LatLng(lat, lng);
                var marker = new kakao.maps.Marker({ position: markerPosition, title: title });
                marker.setMap(map);
                kakao.maps.event.addListener(marker, 'click', function() {
                    triggerAppEvent(id);
                });
            }

            // Inject Kakao Markers
            $kakaoMarkersJs
        }

        let mapInitialized = false;
        function fallbackToOsm() {
            if (mapInitialized) return;
            mapInitialized = true;
            console.log('Kakao Map blocked or timed out. Falling back to OpenStreetMap (Leaflet).');
            initLeafletMap();
        }

        // Try Loading Kakao JS dynamically
        var script = document.createElement('script');
        script.src = "https://dapi.kakao.com/v2/maps/sdk.js?appkey=$kakaoJsKey&autoload=false";
        script.onload = function() {
            try {
                if (typeof kakao === 'undefined' || !kakao.maps) {
                    fallbackToOsm();
                    return;
                }
                
                kakao.maps.load(function() {
                    try {
                        initKakaoMap();
                        mapInitialized = true;
                    } catch(e) {
                        fallbackToOsm();
                    }
                });

                // Failsafe timeout
                setTimeout(function() {
                    if (!mapInitialized) {
                        fallbackToOsm();
                    }
                }, 1500);

            } catch (e) {
                fallbackToOsm();
            }
        };
        script.onerror = fallbackToOsm;
        document.head.appendChild(script);
    </script>
</body>
</html>
''';
}
