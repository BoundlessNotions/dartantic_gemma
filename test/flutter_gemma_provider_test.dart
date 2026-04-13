import 'package:dartantic_gemma/src/chat/gemma_chat_model.dart';
import 'package:dartantic_gemma/src/chat/gemma_chat_model_options.dart';
import 'package:dartantic_gemma/src/embeddings/gemma_embeddings_model_options.dart';
import 'package:dartantic_gemma/src/flutter_gemma_provider.dart';
import 'package:dartantic_interface/dartantic_interface.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FlutterGemmaProvider', () {
    test('creates with default values', () {
      final provider = FlutterGemmaProvider();
      expect(provider.name, 'flutter_gemma');
      expect(provider.displayName, 'Flutter Gemma');
      expect(provider.defaultModelNames[ModelKind.chat], 'gemma-2b-it');
      expect(
        provider.defaultModelNames[ModelKind.embeddings],
        'embedding-gemma',
      );
      expect(provider.aliases, contains('gemma'));
      expect(provider.aliases, contains('fluttergemma'));
    });

    test('creates with custom huggingface token', () {
      final provider = FlutterGemmaProvider(huggingFaceToken: 'test-token');
      expect(provider.apiKey, 'test-token');
      expect(provider.apiKeyName, 'HUGGINGFACE_TOKEN');
    });

    test('createChatModel returns GemmaChatModel with correct defaults', () {
      final provider = FlutterGemmaProvider();
      final chatModel = provider.createChatModel();

      expect(chatModel.name, 'gemma-2b-it');
      expect(chatModel.defaultOptions, isA<GemmaChatModelOptions>());
    });

    test('createChatModel respects enableThinking parameter', () {
      final provider = FlutterGemmaProvider();
      final chatModelWithThinking = provider.createChatModel(
        enableThinking: true,
      );
      expect(chatModelWithThinking, isA<GemmaChatModel>());

      final chatModelWithoutThinking = provider.createChatModel(
        enableThinking: false,
      );
      expect(chatModelWithoutThinking, isA<GemmaChatModel>());
    });

    test('createChatModel passes temperature parameter', () {
      final provider = FlutterGemmaProvider();
      final chatModel = provider.createChatModel(temperature: 0.5);
      expect(chatModel, isA<GemmaChatModel>());
    });

    test('createChatModel passes custom model name', () {
      final provider = FlutterGemmaProvider();
      final chatModel = provider.createChatModel(name: 'custom-model');
      expect(chatModel.name, 'custom-model');
    });

    test('createChatModel accepts tools', () {
      final provider = FlutterGemmaProvider();
      final tool = Tool<String>(
        name: 'test_tool',
        description: 'A test tool',
        onCall: (input) async => 'result',
      );
      final chatModel = provider.createChatModel(tools: [tool]);
      expect(chatModel.tools, isNotNull);
      expect(chatModel.tools!.length, 1);
    });

    test(
      'createEmbeddingsModel returns GemmaEmbeddingsModel with correct defaults',
      () {
        final provider = FlutterGemmaProvider();
        final embeddingsModel = provider.createEmbeddingsModel();

        expect(embeddingsModel.name, 'embedding-gemma');
        expect(
          embeddingsModel.defaultOptions,
          isA<GemmaEmbeddingsModelOptions>(),
        );
      },
    );

    test('createEmbeddingsModel accepts custom model name', () {
      final provider = FlutterGemmaProvider();
      final embeddingsModel = provider.createEmbeddingsModel(
        name: 'custom-embed',
      );
      expect(embeddingsModel.name, 'custom-embed');
    });

    test('createMediaModel throws UnimplementedError', () {
      final provider = FlutterGemmaProvider();
      expect(
        () => provider.createMediaModel(),
        throwsA(isA<UnimplementedError>()),
      );
    });

    test('activeModelId and modelType are initially null', () {
      final provider = FlutterGemmaProvider();
      expect(provider.activeModelId, isNull);
      expect(provider.modelType, isNull);
    });

    test('setActiveModel updates activeModelId', () {
      final provider = FlutterGemmaProvider();
      provider.setActiveModel('test-model-id');
      expect(provider.activeModelId, 'test-model-id');
    });
  });
}
