import 'package:flutter/material.dart';

/// AccessibleText - Text widget that respects system text scaling
/// Automatically scales text based on MediaQuery.textScaleFactor
class AccessibleText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool softWrap;
  final double? maxScaleFactor;

  const AccessibleText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.softWrap = true,
    this.maxScaleFactor,
  });

  @override
  Widget build(BuildContext context) {
    // Get text scale factor from MediaQuery
    final textScaleFactor = MediaQuery.of(context).textScaleFactor;
    
    // Clamp to maximum if specified
    final effectiveScaleFactor = maxScaleFactor != null
        ? textScaleFactor.clamp(1.0, maxScaleFactor!)
        : textScaleFactor;

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(effectiveScaleFactor),
      ),
      child: Text(
        text,
        style: style,
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow,
        softWrap: softWrap,
      ),
    );
  }
}

/// AccessibleRichText - RichText widget that respects system text scaling
class AccessibleRichText extends StatelessWidget {
  final TextSpan textSpan;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool softWrap;
  final double? maxScaleFactor;

  const AccessibleRichText({
    super.key,
    required this.textSpan,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.softWrap = true,
    this.maxScaleFactor,
  });

  @override
  Widget build(BuildContext context) {
    // Get text scale factor from MediaQuery
    final textScaleFactor = MediaQuery.of(context).textScaleFactor;
    
    // Clamp to maximum if specified
    final effectiveScaleFactor = maxScaleFactor != null
        ? textScaleFactor.clamp(1.0, maxScaleFactor!)
        : textScaleFactor;

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(effectiveScaleFactor),
      ),
      child: RichText(
        text: textSpan,
        textAlign: textAlign ?? TextAlign.start,
        maxLines: maxLines,
        overflow: overflow ?? TextOverflow.clip,
        softWrap: softWrap,
      ),
    );
  }
}

/// ScalableContainer - Container that adjusts padding/margins based on text scale
class ScalableContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final Decoration? decoration;
  final double? width;
  final double? height;
  final AlignmentGeometry? alignment;
  final bool scaleSpacing;

  const ScalableContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.decoration,
    this.width,
    this.height,
    this.alignment,
    this.scaleSpacing = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!scaleSpacing) {
      return Container(
        padding: padding,
        margin: margin,
        decoration: decoration,
        width: width,
        height: height,
        alignment: alignment,
        child: child,
      );
    }

    final textScaleFactor = MediaQuery.of(context).textScaleFactor;
    final scaleFactor = textScaleFactor.clamp(1.0, 1.5); // Max 150% for spacing

    return Container(
      padding: padding != null
          ? EdgeInsets.only(
              left: padding!.left * scaleFactor,
              top: padding!.top * scaleFactor,
              right: padding!.right * scaleFactor,
              bottom: padding!.bottom * scaleFactor,
            )
          : null,
      margin: margin != null
          ? EdgeInsets.only(
              left: margin!.left * scaleFactor,
              top: margin!.top * scaleFactor,
              right: margin!.right * scaleFactor,
              bottom: margin!.bottom * scaleFactor,
            )
          : null,
      decoration: decoration,
      width: width,
      height: height,
      alignment: alignment,
      child: child,
    );
  }
}

/// TextScaleInfo - Widget to display current text scale factor (for debugging)
class TextScaleInfo extends StatelessWidget {
  const TextScaleInfo({super.key});

  @override
  Widget build(BuildContext context) {
    final textScaleFactor = MediaQuery.of(context).textScaleFactor;
    final percentage = (textScaleFactor * 100).round();

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'Text Scale: $percentage%',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
        ),
      ),
    );
  }
}
