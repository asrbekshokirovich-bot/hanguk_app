import 'package:flutter/foundation.dart';

@immutable
class University {
  final String id;
  final String name; // name_en
  final String location; // city_en
  final double? latitude;
  final double? longitude;
  final String? logoUrl;
  final int? ranking;
  final int? localRank;
  final double? acceptanceRate;
  final int? tuitionMin;
  final int? tuitionMax;
  final bool isPartner;
  final bool isVisibleOnMap;
  final String? website;
  final String? descriptionEn;

  const University({
    required this.id,
    required this.name,
    required this.location,
    this.latitude,
    this.longitude,
    this.logoUrl,
    this.ranking,
    this.localRank,
    this.acceptanceRate,
    this.tuitionMin,
    this.tuitionMax,
    this.isPartner = false,
    this.isVisibleOnMap = true,
    this.website,
    this.descriptionEn,
  });
}
