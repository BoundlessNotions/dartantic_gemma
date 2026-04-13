import 'package:dartantic_interface/dartantic_interface.dart';
import 'package:flutter_gemma/flutter_gemma.dart' show PreferredBackend;

class GemmaChatModelOptions extends ChatModelOptions {
  const GemmaChatModelOptions({
    this.maxTokens,
    this.tokenBuffer,
    this.topK,
    this.topP,
    this.systemInstruction,
    this.preferredBackend,
  });

  final int? maxTokens;
  final int? tokenBuffer;
  final int? topK;
  final double? topP;
  final String? systemInstruction;
  final PreferredBackend? preferredBackend;
}
