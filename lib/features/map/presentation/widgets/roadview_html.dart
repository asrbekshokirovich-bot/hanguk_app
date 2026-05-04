String generateRoadviewHtml(double lat, double lng, String name) {
  final safeName = name.replaceAll("'", "\\'").replaceAll('"', '\\"');
  
  return '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
    <style>
        html, body { width: 100%; height: 100%; margin: 0; padding: 0; background-color: #0f1626; }
        #roadview { width: 100%; height: 100%; }
        .loading-container {
            position: absolute;
            top: 50%;
            left: 50%;
            transform: translate(-50%, -50%);
            color: white;
            font-family: sans-serif;
            text-align: center;
        }
        * { -webkit-tap-highlight-color: transparent; }
    </style>
</head>
<body>
    <div id="roadview">
        <div class="loading-container" id="loadingText">
            <h3>Booting $safeName Campus Walkaround...</h3>
        </div>
    </div>
    <script>
        function triggerError(msg) {
            document.getElementById('roadview').innerHTML = "<div class='loading-container'>Error initializing Roadview: " + msg + "</div>";
        }

        // Try Loading Kakao JS dynamically
        var script = document.createElement('script');
        script.src = "https://dapi.kakao.com/v2/maps/sdk.js?appkey=c695b428933e192ca1d8582e3aab14a4&autoload=false";
        
        script.onload = function() {
            try {
                if (typeof kakao === 'undefined' || !kakao.maps) {
                    triggerError("Kakao SDK Blocked");
                    return;
                }
                
                kakao.maps.load(function() {
                    try {
                        var rvContainer = document.getElementById('roadview');
                        var rv = new kakao.maps.Roadview(rvContainer); 
                        var rvClient = new kakao.maps.RoadviewClient(); 
                        
                        var targetPosition = new kakao.maps.LatLng($lat, $lng);

                        // Increased radius to 2000 meters to guarantee a valid panoId nearby
                        rvClient.getNearestPanoId(targetPosition, 2000, function(panoId) {
                            if (panoId === null) {
                                triggerError("Walkaround data completely isolated.");
                            } else {
                                rv.setPanoId(panoId, targetPosition);
                            }
                        });

                    } catch(e) {
                         triggerError(e.message);
                    }
                });

            } catch (e) {
                 triggerError(e.message);
            }
        };
        script.onerror = function() { triggerError("Network connection denied."); };
        document.head.appendChild(script);
    </script>
</body>
</html>
''';
}
