import 'package:dartantic_interface/dartantic_interface.dart';

class GemmaChatModelOptions extends ChatModelOptions {
  const GemmaChatModelOptions({
    this.maxTokens,
    this.tokenBuffer,
    this.topK,
    this.topP,
    this.systemInstruction,
  });

  final int? maxTokens;
  final int? tokenBuffer;
  final int? topK;
  final double? topP;
  final String? systemInstruction;
}
