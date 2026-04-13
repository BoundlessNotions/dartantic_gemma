import 'package:dartantic_gemma/src/chat/gemma_chat_model_options.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GemmaChatModelOptions', () {
    test('creates with default values', () {
      const options = GemmaChatModelOptions();
      expect(options.maxTokens, isNull);
      expect(options.tokenBuffer, isNull);
      expect(options.topK, isNull);
      expect(options.topP, isNull);
      expect(options.systemInstruction, isNull);
    });

    test('creates with custom values', () {
      const options = GemmaChatModelOptions(
        maxTokens: 2048,
        tokenBuffer: 512,
        topK: 40,
        topP: 0.9,
        systemInstruction: 'You are a helpful assistant.',
      );
      expect(options.maxTokens, 2048);
      expect(options.tokenBuffer, 512);
      expect(options.topK, 40);
      expect(options.topP, 0.9);
      expect(options.systemInstruction, 'You are a helpful assistant.');
    });
  });
}
