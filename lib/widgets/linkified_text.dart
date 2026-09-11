import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// ويدجت يعرض نص عادي، وأي رابط (http/https) موجود جواه يصير
/// قابل للضغط ويفتح بالمتصفح الخارجي تلقائيًا.
///
/// الاستخدام بسيط: بدل ما تكتب
///   Text(myString, style: myStyle)
/// اكتب
///   LinkifiedText(myString, style: myStyle)
/// ونفس كل خصائص التنسيق (اللون، الحجم، المحاذاة...) بتضل شغالة
/// عالنص العادي، وبس الروابط بتتلوّن وتصير قابلة للضغط.
class LinkifiedText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final Color linkColor;
  final int? maxLines;
  final TextOverflow? overflow;

  const LinkifiedText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.linkColor = const Color(0xFF1A73E8),
    this.maxLines,
    this.overflow,
  });

  static final RegExp _urlRegExp = RegExp(
    r'((https?:\/\/)[^\s]+)',
    caseSensitive: false,
  );

  Future<void> _openLink(String rawUrl) async {
    // بعض الروابط بتيجي بآخرها علامات ترقيم عربي/إنجليزي ملتصقة
    // بالغلط (نقطة، فاصلة، قوس) — منشيلها قبل ما نحاول نفتح الرابط.
    final cleaned = rawUrl.replaceAll(RegExp(r'[)\]\},\.،؛]+$'), '');
    final uri = Uri.tryParse(cleaned);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final matches = _urlRegExp.allMatches(text);

    // ما في أي رابط بالنص — منعرضه عادي زي ما كان، بدون أي تغيير.
    if (matches.isEmpty) {
      return Text(
        text,
        style: style,
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow,
      );
    }

    final spans = <InlineSpan>[];
    int lastEnd = 0;

    for (final match in matches) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(text: text.substring(lastEnd, match.start)));
      }
      final url = match.group(0)!;
      spans.add(
        TextSpan(
          text: url,
          style: (style ?? const TextStyle()).copyWith(
            color: linkColor,
            decoration: TextDecoration.underline,
          ),
          recognizer: TapGestureRecognizer()..onTap = () => _openLink(url),
        ),
      );
      lastEnd = match.end;
    }

    if (lastEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastEnd)));
    }

    return RichText(
      textAlign: textAlign ?? TextAlign.start,
      maxLines: maxLines,
      overflow: overflow ?? TextOverflow.clip,
      text: TextSpan(style: style ?? DefaultTextStyle.of(context).style, children: spans),
    );
  }
}
