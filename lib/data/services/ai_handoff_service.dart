import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

enum AiHandoffTarget { chatgpt, claude, gemini, deepseek, systemShare }

extension AiHandoffTargetX on AiHandoffTarget {
  String get displayName {
    switch (this) {
      case AiHandoffTarget.chatgpt:
        return 'ChatGPT';
      case AiHandoffTarget.claude:
        return 'Claude';
      case AiHandoffTarget.gemini:
        return 'Gemini';
      case AiHandoffTarget.deepseek:
        return 'DeepSeek';
      case AiHandoffTarget.systemShare:
        return 'More apps';
    }
  }

  Uri? get destinationUri {
    switch (this) {
      case AiHandoffTarget.chatgpt:
        return Uri.parse('https://chatgpt.com/');
      case AiHandoffTarget.claude:
        return Uri.parse('https://claude.ai/');
      case AiHandoffTarget.gemini:
        return Uri.parse('https://gemini.google.com/');
      case AiHandoffTarget.deepseek:
        return Uri.parse('https://chat.deepseek.com/');
      case AiHandoffTarget.systemShare:
        return null;
    }
  }
}

class AiHandoffResult {
  const AiHandoffResult({
    required this.success,
    required this.message,
    this.copiedToClipboard = false,
  });

  final bool success;
  final String message;
  final bool copiedToClipboard;
}

class AiHandoffService {
  Future<AiHandoffResult> sendPrompt({
    required String prompt,
    required AiHandoffTarget target,
  }) async {
    if (target == AiHandoffTarget.systemShare) {
      await SharePlus.instance.share(ShareParams(text: prompt));
      return const AiHandoffResult(
        success: true,
        message: 'Choose an app to continue.',
      );
    }

    await Clipboard.setData(ClipboardData(text: prompt));

    final uri = target.destinationUri;
    if (uri == null) {
      return const AiHandoffResult(
        success: false,
        message: 'No destination is available for this handoff.',
        copiedToClipboard: true,
      );
    }

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (launched) {
        return AiHandoffResult(
          success: true,
          message: 'Prompt copied. Paste it into ${target.displayName}.',
          copiedToClipboard: true,
        );
      }
    } catch (_) {
      // Fall through to clipboard-preserved fallback below.
    }

    return AiHandoffResult(
      success: false,
      message:
          'Could not open ${target.displayName}. The prompt was copied to your clipboard.',
      copiedToClipboard: true,
    );
  }
}
