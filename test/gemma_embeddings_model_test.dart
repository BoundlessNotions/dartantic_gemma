import 'package:dartantic_gemma/src/embeddings/gemma_embeddings_model.dart';
import 'package:dartantic_gemma/src/embeddings/gemma_embeddings_model_options.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GemmaEmbeddingsModel', () {
    test('creates with required parameters', () {
      final model = GemmaEmbeddingsModel(
        name: 'test-embedding-model',
        defaultOptions: const GemmaEmbeddingsModelOptions(),
      );
      expect(model.name, 'test-embedding-model');
    });

    test('creates with default options', () {
      final model = GemmaEmbeddingsModel(name: 'test-embedding-model');
      expect(model.defaultOptions, isA<GemmaEmbeddingsModelOptions>());
    });

    test('creates with custom dimensions', () {
      final model = GemmaEmbeddingsModel(
        name: 'test-embedding-model',
        dimensions: 768,
        defaultOptions: const GemmaEmbeddingsModelOptions(),
      );
      expect(model.dimensions, 768);
    });

    test('creates with custom batch size', () {
      final model = GemmaEmbeddingsModel(
        name: 'test-embedding-model',
        batchSize: 32,
        defaultOptions: const GemmaEmbeddingsModelOptions(),
      );
      expect(model.batchSize, 32);
    });

    test('creates with GemmaEmbeddingsModelOptions', () {
      const options = GemmaEmbeddingsModelOptions(
        dimensions: 512,
        batchSize: 16,
        preferredBackend: PreferredBackend.cpu,
      );
      final model = GemmaEmbeddingsModel(
        name: 'test-embedding-model',
        defaultOptions: options,
      );
      expect(model.defaultOptions.dimensions, 512);
      expect(model.defaultOptions.batchSize, 16);
      expect(model.defaultOptions.preferredBackend, PreferredBackend.cpu);
    });

    test('dispose cleans up resources', () async {
      final model = GemmaEmbeddingsModel(
        name: 'test-embedding-model',
        defaultOptions: const GemmaEmbeddingsModelOptions(),
      );
      await model.dispose();
    });
  });
}
