import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';

/// Skeleton loading con shimmer
class LoadingShimmer extends StatelessWidget {
  final int itemCount;
  final double height;
  final bool isList;

  const LoadingShimmer({
    super.key,
    this.itemCount = 5,
    this.height = 80,
    this.isList = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Shimmer.fromColors(
      baseColor: isDark ? AppColors.cardDark : AppColors.grey200,
      highlightColor: isDark ? AppColors.surfaceDark : AppColors.grey100,
      child: isList
          ? ListView.separated(
              padding: const EdgeInsets.all(AppDimens.paddingScreen),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: itemCount,
              separatorBuilder: (_, _) => const SizedBox(height: AppDimens.md),
              itemBuilder: (_, _) => _shimmerItem(),
            )
          : GridView.count(
              padding: const EdgeInsets.all(AppDimens.paddingScreen),
              crossAxisCount: 2,
              crossAxisSpacing: AppDimens.md,
              mainAxisSpacing: AppDimens.md,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: List.generate(itemCount, (_) => _shimmerGrid()),
            ),
    );
  }

  Widget _shimmerItem() {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
      ),
    );
  }

  Widget _shimmerGrid() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
      ),
    );
  }
}

/// Loading overlay
class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;

  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: Colors.black.withAlpha(77),
            child: const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
          ),
      ],
    );
  }
}
