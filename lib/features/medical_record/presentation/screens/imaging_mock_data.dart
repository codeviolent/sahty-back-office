import 'package:flutter/material.dart';

import '../../../../core/l10n/app_text_key.dart';

enum ImagingOutputType { image, report, waveform }

class ImagingStudy {
  const ImagingStudy({
    required this.titleKey,
    required this.metaKey,
    required this.icon,
    required this.outputType,
    this.previewAsset,
    this.reportLineKeys = const [],
    this.critical = false,
  });

  final AppTextKey titleKey;
  final AppTextKey metaKey;
  final IconData icon;
  final ImagingOutputType outputType;
  final String? previewAsset;
  final List<AppTextKey> reportLineKeys;
  final bool critical;
}

abstract final class ImagingMockData {
  static const studies = [
    ImagingStudy(
      titleKey: AppTextKey.imagingChestCtTitle,
      metaKey: AppTextKey.imagingChestCtMeta,
      icon: Icons.view_in_ar_outlined,
      outputType: ImagingOutputType.image,
      previewAsset: 'assets/data_images/scaner_2.jpeg',
      critical: true,
    ),
    ImagingStudy(
      titleKey: AppTextKey.imagingAbdomenUsTitle,
      metaKey: AppTextKey.imagingAbdomenUsMeta,
      icon: Icons.radar_outlined,
      outputType: ImagingOutputType.image,
      previewAsset: 'assets/data_images/scaner_1.jpeg',
    ),
    ImagingStudy(
      titleKey: AppTextKey.imagingKneeMriTitle,
      metaKey: AppTextKey.imagingKneeMriMeta,
      icon: Icons.image_outlined,
      outputType: ImagingOutputType.image,
    ),
    ImagingStudy(
      titleKey: AppTextKey.imagingBrainCtTitle,
      metaKey: AppTextKey.imagingBrainCtMeta,
      icon: Icons.psychology_outlined,
      outputType: ImagingOutputType.image,
    ),
    ImagingStudy(
      titleKey: AppTextKey.imagingSpineXrayTitle,
      metaKey: AppTextKey.imagingSpineXrayMeta,
      icon: Icons.accessibility_new_outlined,
      outputType: ImagingOutputType.image,
    ),
    ImagingStudy(
      titleKey: AppTextKey.imagingDentalPanoTitle,
      metaKey: AppTextKey.imagingDentalPanoMeta,
      icon: Icons.medical_services_outlined,
      outputType: ImagingOutputType.image,
    ),
    ImagingStudy(
      titleKey: AppTextKey.imagingMammographyTitle,
      metaKey: AppTextKey.imagingMammographyMeta,
      icon: Icons.health_and_safety_outlined,
      outputType: ImagingOutputType.image,
    ),
    ImagingStudy(
      titleKey: AppTextKey.imagingEndoscopyTitle,
      metaKey: AppTextKey.imagingEndoscopyMeta,
      icon: Icons.biotech_outlined,
      outputType: ImagingOutputType.image,
    ),
    ImagingStudy(
      titleKey: AppTextKey.imagingBloodTestTitle,
      metaKey: AppTextKey.imagingBloodTestMeta,
      icon: Icons.bloodtype_outlined,
      outputType: ImagingOutputType.report,
      reportLineKeys: [
        AppTextKey.imagingBloodReportHemoglobin,
        AppTextKey.imagingBloodReportWbc,
        AppTextKey.imagingBloodReportPlatelets,
      ],
    ),
    ImagingStudy(
      titleKey: AppTextKey.imagingEcgTitle,
      metaKey: AppTextKey.imagingEcgMeta,
      icon: Icons.monitor_heart_outlined,
      outputType: ImagingOutputType.waveform,
      reportLineKeys: [
        AppTextKey.imagingEcgReportRhythm,
        AppTextKey.imagingEcgReportRate,
        AppTextKey.imagingEcgReportConclusion,
      ],
    ),
    ImagingStudy(
      titleKey: AppTextKey.imagingUrineTestTitle,
      metaKey: AppTextKey.imagingUrineTestMeta,
      icon: Icons.science_outlined,
      outputType: ImagingOutputType.report,
      reportLineKeys: [
        AppTextKey.imagingUrineReportProtein,
        AppTextKey.imagingUrineReportGlucose,
        AppTextKey.imagingUrineReportCulture,
      ],
    ),
    ImagingStudy(
      titleKey: AppTextKey.imagingSpirometryTitle,
      metaKey: AppTextKey.imagingSpirometryMeta,
      icon: Icons.air_outlined,
      outputType: ImagingOutputType.waveform,
      reportLineKeys: [
        AppTextKey.imagingSpirometryReportFev1,
        AppTextKey.imagingSpirometryReportFvc,
        AppTextKey.imagingSpirometryReportConclusion,
      ],
    ),
    ImagingStudy(
      titleKey: AppTextKey.imagingEegTitle,
      metaKey: AppTextKey.imagingEegMeta,
      icon: Icons.graphic_eq_outlined,
      outputType: ImagingOutputType.waveform,
      reportLineKeys: [
        AppTextKey.imagingEegReportBackground,
        AppTextKey.imagingEegReportAbnormal,
        AppTextKey.imagingEegReportConclusion,
      ],
    ),
  ];
}
