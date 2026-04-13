import 'package:dartantic_gemma/src/embeddings/gemma_embeddings_model_options.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GemmaEmbeddingsModelOptions', () {
    test('creates with default values', () {
      const options = GemmaEmbeddingsModelOptions();
      expect(options.dimensions, isNull);
      expect(options.batchSize, isNull);
      expect(options.preferredBackend, isNull);
    });

    test('creates with custom values', () {
      const options = GemmaEmbeddingsModelOptions(
        dimensions: 768,
        batchSize: 32,
        preferredBackend: PreferredBackend.gpu,
      );
      expect(options.dimensions, 768);
      expect(options.batchSize, 32);
      expect(options.preferredBackend, PreferredBackend.gpu);
    });
  });
}
