import 'dart:convert';

import 'package:flutter_gemma/core/model_response.dart';
import 'package:logging/logging.dart';

class Gemma4ToolParser {
  static final Logger _logger = Logger('dartantic.gemma4.tool_parser');

  static const String _toolCallStart = '<|tool_call>';
  static const String _toolCallEnd = '<tool_call|>';
  static const String _escapeToken = '<|"|>';

  static final RegExp _standardPattern = RegExp(
    r'<\|tool_call>call:(\w+)\{([\s\S]*?)\}<tool_call\|>',
  );

  static final RegExp _fallbackPattern = RegExp(
    r'(?:<call>|(?:^|\s)call:)(\w+)\{([\s\S]*?)\}',
  );

  static List<FunctionCallResponse> parseAll(
    String text, {
    bool strict = false,
  }) {
    if (text.isEmpty) return [];

    final results = <FunctionCallResponse>[];

    for (final match in _standardPattern.allMatches(text)) {
      final name = match.group(1);
      final argsStr = match.group(2);

      if (name != null && argsStr != null) {
        final args = _parseArguments(argsStr);
        results.add(FunctionCallResponse(name: name, args: args));
      }
    }

    if (results.isNotEmpty || strict) return results;

    for (final match in _fallbackPattern.allMatches(text)) {
      final name = match.group(1);
      final argsStr = match.group(2);

      if (name != null && argsStr != null) {
        final args = _parseArguments(argsStr);
        results.add(FunctionCallResponse(name: name, args: args));
      }
    }

    return results;
  }

  static bool hasToolCall(String buffer) {
    if (!buffer.contains(_toolCallStart)) return false;
    return true;
  }

  static bool isToolCallComplete(String buffer) {
    final startCount = buffer.split(_toolCallStart).length - 1;
    final endCount = buffer.split(_toolCallEnd).length - 1;
    return startCount > 0 && startCount == endCount;
  }

  static FunctionCallResponse? parse(String text) {
    final calls = parseAll(text);
    return calls.isNotEmpty ? calls.first : null;
  }

  static Map<String, dynamic> _parseArguments(String argsStr) {
    if (argsStr.isEmpty) return {};

    final cleaned = argsStr.replaceAll(_escapeToken, '"');

    try {
      final parsed = jsonDecode('{$cleaned}');
      if (parsed is Map) {
        return parsed.map(
          (k, v) => MapEntry(k as String, v is String ? v : v.toString()),
        );
      }
    } catch (e) {
      _logger.fine('Gemma4: JSON parse failed, trying regex: $e');
    }

    final arguments = <String, dynamic>{};

    final keyValueRegex = RegExp(r'(\w+):\s*"([^"]*)"');
    for (final match in keyValueRegex.allMatches(cleaned)) {
      final key = match.group(1);
      final value = match.group(2);
      if (key != null && value != null) {
        arguments[key] = value;
      }
    }

    if (arguments.isEmpty) {
      final bareRegex = RegExp(r'(\w+):\s*([^,}]+)');
      for (final match in bareRegex.allMatches(argsStr)) {
        final key = match.group(1);
        var value = match.group(2)?.trim() ?? '';
        value = value.replaceAll(_escapeToken, '').replaceAll('"', '').trim();
        if (key != null && value.isNotEmpty) {
          arguments[key] = value;
        }
      }
    }

    return arguments;
  }
}
