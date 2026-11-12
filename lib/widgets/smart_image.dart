import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';

/// Displays an image from either a network URL or a base64 data URI,
/// with graceful fallback on error.
class SmartImage extends StatelessWidget {
  final String? source;
  final Uint8List? memoryBytes;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget? fallback;

  const SmartImage({
    super.key,
    this.source,
    this.memoryBytes,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.fallback,
  });

  static ImageProvider? resolveProvider(String? src) {
    if (src == null || src.trim().isEmpty) return null;
    if (src.startsWith('data:image')) {
      final commaIdx = src.indexOf(',');
      if (commaIdx != -1) {
        try {
          final bytes = base64Decode(src.substring(commaIdx + 1));
          return MemoryImage(bytes);
        } catch (_) {
          return null;
        }
      }
    }
    if (src.startsWith('http://') || src.startsWith('https://')) {
      return NetworkImage(src);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final fallbackWidget = fallback ??
        Container(
          width: width,
          height: height,
          color: Colors.grey.withValues(alpha: 0.15),
          child: const Icon(Icons.eco, color: Colors.grey),
        );

    if (memoryBytes != null) {
      return Image.memory(
        memoryBytes!,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, _, _) => fallbackWidget,
      );
    }

    final src = source?.trim();
    if (src == null || src.isEmpty) {
      return fallbackWidget;
    }

    if (src.startsWith('data:image')) {
      final commaIdx = src.indexOf(',');
      if (commaIdx == -1) return fallbackWidget;
      try {
        final bytes = base64Decode(src.substring(commaIdx + 1));
        return Image.memory(
          bytes,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (_, _, _) => fallbackWidget,
        );
      } catch (_) {
        return fallbackWidget;
      }
    }

    if (!src.startsWith('http://') && !src.startsWith('https://')) {
      return fallbackWidget;
    }

    return Image.network(
      src,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (_, _, _) => fallbackWidget,
    );
  }
}

