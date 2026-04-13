import 'package:dartantic_gemma/src/chat/gemma_chat_model.dart';
import 'package:dartantic_gemma/src/chat/gemma_chat_model_options.dart';
import 'package:dartantic_interface/dartantic_interface.dart';
import 'package:flutter_gemma/core/model.dart' as fg;
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GemmaChatModel', () {
    test('creates with required parameters', () {
      final model = GemmaChatModel(
        name: 'test-model',
        defaultOptions: const GemmaChatModelOptions(),
      );
      expect(model.name, 'test-model');
    });

    test('creates with enableThinking flag', () {
      final modelWithThinking = GemmaChatModel(
        name: 'test-model',
        enableThinking: true,
        defaultOptions: const GemmaChatModelOptions(),
      );
      expect(modelWithThinking, isA<GemmaChatModel>());

      final modelWithoutThinking = GemmaChatModel(
        name: 'test-model',
        enableThinking: false,
        defaultOptions: const GemmaChatModelOptions(),
      );
      expect(modelWithoutThinking, isA<GemmaChatModel>());
    });

    test('creates with custom temperature', () {
      final model = GemmaChatModel(
        name: 'test-model',
        temperature: 0.7,
        defaultOptions: const GemmaChatModelOptions(),
      );
      expect(model.temperature, 0.7);
    });

    test('creates with tools', () {
      final tool = Tool<String>(
        name: 'test_tool',
        description: 'A test tool',
        onCall: (input) async => 'result',
      );
      final model = GemmaChatModel(
        name: 'test-model',
        tools: [tool],
        defaultOptions: const GemmaChatModelOptions(),
      );
      expect(model.tools, isNotNull);
      expect(model.tools!.length, 1);
      expect(model.tools!.first.name, 'test_tool');
    });

    test('creates with ModelType', () {
      final model = GemmaChatModel(
        name: 'test-model',
        modelType: fg.ModelType.gemmaIt,
        defaultOptions: const GemmaChatModelOptions(),
      );
      expect(model, isA<GemmaChatModel>());
    });

    test('creates with different ModelTypes', () {
      final modelDeepSeek = GemmaChatModel(
        name: 'test-model',
        modelType: fg.ModelType.deepSeek,
        defaultOptions: const GemmaChatModelOptions(),
      );
      expect(modelDeepSeek, isA<GemmaChatModel>());

      final modelQwen = GemmaChatModel(
        name: 'test-model',
        modelType: fg.ModelType.qwen,
        defaultOptions: const GemmaChatModelOptions(),
      );
      expect(modelQwen, isA<GemmaChatModel>());
    });

    test('creates with GemmaChatModelOptions', () {
      const options = GemmaChatModelOptions(
        maxTokens: 2048,
        topK: 40,
        topP: 0.9,
        systemInstruction: 'You are a helpful assistant.',
      );
      final model = GemmaChatModel(name: 'test-model', defaultOptions: options);
      expect(model.defaultOptions.maxTokens, 2048);
      expect(model.defaultOptions.topK, 40);
      expect(model.defaultOptions.topP, 0.9);
      expect(
        model.defaultOptions.systemInstruction,
        'You are a helpful assistant.',
      );
    });

    test('dispose cleans up resources', () {
      final model = GemmaChatModel(
        name: 'test-model',
        defaultOptions: const GemmaChatModelOptions(),
      );
      model.dispose();
    });
  });
}
