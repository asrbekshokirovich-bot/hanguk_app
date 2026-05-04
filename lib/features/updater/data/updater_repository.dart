import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final updaterRepositoryProvider = Provider<UpdaterRepository>((ref) {
  return UpdaterRepository(Supabase.instance.client);
});

class AppVersionInfo {
  final String latestVersion;
  final String downloadUrl;
  final bool forceUpdate;

  AppVersionInfo({
    required this.latestVersion,
    required this.downloadUrl,
    required this.forceUpdate,
  });

  factory AppVersionInfo.fromMap(Map<String, dynamic> map) {
    return AppVersionInfo(
      latestVersion: map['latest_version'] as String? ?? '',
      downloadUrl: map['download_url'] as String? ?? '',
      forceUpdate: map['force_update'] == true,
    );
  }
}

class UpdaterRepository {
  final SupabaseClient _client;
  
  UpdaterRepository(this._client);

  Future<AppVersionInfo?> checkForUpdate() async {
    try {
      if (kIsWeb || !Platform.isAndroid) return null;

      final packageInfo = await PackageInfo.fromPlatform();
      final localVersion = packageInfo.version;
      final localBuildStr = packageInfo.buildNumber;
      final localBuildInt = int.tryParse(localBuildStr) ?? 0;
      
      final response = await _client
          .from('app_versions')
          .select()
          .eq('id', 'android')
          .maybeSingle();

      if (response == null) return null;

      final remoteVersionInfo = AppVersionInfo.fromMap(response);
      final remoteVersionStr = remoteVersionInfo.latestVersion;
      
      final remoteBaseStr = remoteVersionStr.split('+').first;
      final localBaseStr = localVersion.split('+').first;
      
      final remoteBuildMatch = RegExp(r'\+(\d+)').firstMatch(remoteVersionStr);
      final remoteBuildInt = remoteBuildMatch != null ? int.parse(remoteBuildMatch.group(1)!) : 0;

      bool triggerUpdate = false;

      if (remoteBaseStr != localBaseStr) {
        List<int> remoteParts = remoteBaseStr.split('.').map((s) => int.tryParse(s) ?? 0).toList();
        List<int> localParts = localBaseStr.split('.').map((s) => int.tryParse(s) ?? 0).toList();
        
        for (int i = 0; i < 3; i++) {
          int r = i < remoteParts.length ? remoteParts[i] : 0;
          int l = i < localParts.length ? localParts[i] : 0;
          if (r > l) {
             triggerUpdate = true;
             break;
          } else if (r < l) {
             break;
          }
        }
      } else {
        if (remoteBuildInt > localBuildInt) {
          triggerUpdate = true;
        }
      }

      if (triggerUpdate) {
        debugPrint('[Updater] Update Available: Local($localBaseStr+$localBuildInt) vs Remote($remoteBaseStr+$remoteBuildInt)');
        return remoteVersionInfo;
      }
      
      debugPrint('[Updater] App is up to date.');
      return null;
    } catch (e) {
      debugPrint('Error checking for update: $e');
      return null;
    }
  }

  Future<bool> triggerUpdate(AppVersionInfo versionInfo) async {
    try {
      final uri = Uri.parse(versionInfo.downloadUrl);
      if (await canLaunchUrl(uri)) {
        // Delegate APK download and install to Android's native browser logic
        // This natively bypasses any PackageInstaller read locks and Storage scopes
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      return false;
    } catch (e) {
      debugPrint('Error launching APK link: $e');
      return false;
    }
  }
}
