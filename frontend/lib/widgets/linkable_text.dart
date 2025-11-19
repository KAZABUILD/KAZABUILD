/// This widget displays text with clickable links that open in a new browser tab.
///
/// It automatically detects URLs in the text and makes them clickable.
/// When a user clicks on a link, it opens in a new browser tab/window.
library;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/gestures.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';

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

  /// Map of username to user ID for @mention resolution
  final Map<String, String>? usernameToUserIdMap;

  const LinkableText({
    super.key,
    required this.text,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.height,
    this.usernameToUserIdMap,
  });

  /// Regular expression to match URLs.
  /// Matches http://, https://, www., and email addresses.
  static final RegExp _urlRegex = RegExp(
    r'(?:(?:https?|ftp):\/\/)?(?:www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b(?:[-a-zA-Z0-9()@:%_\+.~#?&\/=]*)|[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}',
  );
  
  /// Regular expression to match @mentions (e.g., @username)
  static final RegExp _mentionRegex = RegExp(
    r'@([a-zA-Z0-9_]+)',
  );

  /// Splits the text into segments (regular text, URLs, and mentions).
  List<_TextSegment> _parseText(String text) {
    final List<_TextSegment> segments = [];
    
    // Find all URLs and mentions
    final urlMatches = _urlRegex.allMatches(text);
    final mentionMatches = _mentionRegex.allMatches(text);
    
    // Combine all matches with their positions
    final List<_MatchInfo> allMatches = [];
    
    for (final match in urlMatches) {
      allMatches.add(_MatchInfo(
        start: match.start,
        end: match.end,
        text: match.group(0)!,
        isUrl: true,
        isMention: false,
      ));
    }
    
    for (final match in mentionMatches) {
      // Check if this mention is already part of a URL (email)
      bool isPartOfUrl = false;
      for (final urlMatch in urlMatches) {
        if (match.start >= urlMatch.start && match.end <= urlMatch.end) {
          isPartOfUrl = true;
          break;
        }
      }
      
      if (!isPartOfUrl) {
        allMatches.add(_MatchInfo(
          start: match.start,
          end: match.end,
          text: match.group(0)!,
          username: match.group(1),
          isUrl: false,
          isMention: true,
        ));
      }
    }
    
    // Sort matches by position
    allMatches.sort((a, b) => a.start.compareTo(b.start));
    
    if (allMatches.isEmpty) {
      // No URLs or mentions found, return the entire text as a single segment
      segments.add(_TextSegment(text: text, isUrl: false));
      return segments;
    }

    int lastEnd = 0;
    for (final match in allMatches) {
      // Add text before the match
      if (match.start > lastEnd) {
        segments.add(
          _TextSegment(
            text: text.substring(lastEnd, match.start),
            isUrl: false,
          ),
        );
      }

      if (match.isUrl) {
        // Add the URL
        String urlText = match.text;
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
      } else if (match.isMention) {
        // Add the mention
        segments.add(
          _TextSegment(
            text: match.text,
            isUrl: false,
            isMention: true,
            mentionUsername: match.username,
          ),
        );
      }

      lastEnd = match.end;
    }

    // Add remaining text after the last match
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
          } else if (segment.isMention && segment.mentionUsername != null) {
            return TextSpan(
              text: segment.text,
              style: (style ?? DefaultTextStyle.of(context).style).copyWith(
                color: theme.colorScheme.primary,
                decoration: TextDecoration.underline,
                decorationColor: theme.colorScheme.primary,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  // Navigate to user profile using user ID if available, otherwise use username
                  final router = GoRouter.of(context);
                  final userId = usernameToUserIdMap?[segment.mentionUsername];
                  if (userId != null && userId.isNotEmpty) {
                    router.push('/profile/$userId');
                  } else {
                    // Fallback to username if user ID not found
                    router.push('/profile/${segment.mentionUsername}');
                  }
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

/// Helper class to store match information
class _MatchInfo {
  final int start;
  final int end;
  final String text;
  final String? username;
  final bool isUrl;
  final bool isMention;
  
  _MatchInfo({
    required this.start,
    required this.end,
    required this.text,
    this.username,
    required this.isUrl,
    required this.isMention,
  });
}

/// Helper class to represent a segment of text (either regular text, a URL, or a mention).
class _TextSegment {
  final String text;
  final bool isUrl;
  final String? url;
  final bool isMention;
  final String? mentionUsername;

  _TextSegment({
    required this.text,
    required this.isUrl,
    this.url,
    this.isMention = false,
    this.mentionUsername,
  });
}
