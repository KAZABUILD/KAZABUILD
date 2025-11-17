/// This widget displays text with clickable links that open in a new browser tab.
///
/// It automatically detects URLs in the text and makes them clickable.
/// When a user clicks on a link, it opens in a new browser tab/window.
library;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/gestures.dart';
import 'package:url_launcher/url_launcher.dart';

/// A widget that displays text with clickable links.
///
/// Automatically detects URLs in the text and makes them clickable.
/// Links open in a new browser tab when clicked.
class LinkableText extends StatelessWidget {
  /// The text content that may contain URLs.
  final String text;

  /// The text style to apply to non-link text.
  final TextStyle? style;

  /// Text alignment.
  final TextAlign? textAlign;

  /// Maximum number of lines.
  final int? maxLines;

  /// Text overflow behavior.
  final TextOverflow? overflow;

  /// Line height multiplier.
  final double? height;

  const LinkableText({
    super.key,
    required this.text,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.height,
  });

  /// Regular expression to match URLs.
  /// Matches http://, https://, www., and email addresses.
  static final RegExp _urlRegex = RegExp(
    r'(?:(?:https?|ftp):\/\/)?(?:www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b(?:[-a-zA-Z0-9()@:%_\+.~#?&\/=]*)|[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}',
  );

  /// Splits the text into segments (regular text and URLs).
  List<_TextSegment> _parseText(String text) {
    final List<_TextSegment> segments = [];
    final matches = _urlRegex.allMatches(text);

    if (matches.isEmpty) {
      // No URLs found, return the entire text as a single segment
      segments.add(_TextSegment(text: text, isUrl: false));
      return segments;
    }

    int lastEnd = 0;
    for (final match in matches) {
      // Add text before the URL
      if (match.start > lastEnd) {
        segments.add(
          _TextSegment(
            text: text.substring(lastEnd, match.start),
            isUrl: false,
          ),
        );
      }

      // Add the URL
      String urlText = match.group(0)!;
      // Ensure URL has a protocol
      String fullUrl = urlText;
      if (!urlText.startsWith('http://') && !urlText.startsWith('https://') && !urlText.startsWith('ftp://')) {
        if (urlText.contains('@')) {
          // Email address
          fullUrl = 'mailto:$urlText';
        } else {
          // Web URL
          fullUrl = 'https://$urlText';
        }
      }

      segments.add(
        _TextSegment(
          text: urlText,
          isUrl: true,
          url: fullUrl,
        ),
      );

      lastEnd = match.end;
    }

    // Add remaining text after the last URL
    if (lastEnd < text.length) {
      segments.add(
        _TextSegment(
          text: text.substring(lastEnd),
          isUrl: false,
        ),
      );
    }

    return segments;
  }

  /// Opens a URL in a new browser tab.
  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    
    // For web platform, use LaunchMode.externalApplication to open in new tab
    // For other platforms, use the default behavior
    if (kIsWeb) {
      // Web platform - open in new tab
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      }
    } else {
      // Mobile/Desktop platforms
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final segments = _parseText(text);
    final theme = Theme.of(context);

    return RichText(
      textAlign: textAlign ?? TextAlign.start,
      maxLines: maxLines,
      overflow: overflow ?? TextOverflow.clip,
      text: TextSpan(
        style: style ?? DefaultTextStyle.of(context).style,
        children: segments.map((segment) {
          if (segment.isUrl && segment.url != null) {
            return TextSpan(
              text: segment.text,
              style: (style ?? DefaultTextStyle.of(context).style).copyWith(
                color: theme.colorScheme.primary,
                decoration: TextDecoration.underline,
                decorationColor: theme.colorScheme.primary,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  _launchUrl(segment.url!);
                },
            );
          } else {
            return TextSpan(
              text: segment.text,
              style: style ?? DefaultTextStyle.of(context).style,
            );
          }
        }).toList(),
      ),
    );
  }
}

/// Helper class to represent a segment of text (either regular text or a URL).
class _TextSegment {
  final String text;
  final bool isUrl;
  final String? url;

  _TextSegment({
    required this.text,
    required this.isUrl,
    this.url,
  });
}


