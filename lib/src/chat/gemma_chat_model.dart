import 'package:dartantic_interface/dartantic_interface.dart';
import 'package:flutter_gemma/core/model.dart' as fg;
import 'package:flutter_gemma/core/message.dart' as fg;
import 'package:flutter_gemma/core/model_response.dart' as fg;
import 'package:flutter_gemma/flutter_gemma.dart' hide Tool;
import 'package:flutter_gemma/core/tool.dart' as fg;
import 'package:logging/logging.dart';

import 'gemma_chat_model_options.dart';

class GemmaChatModel extends ChatModel<GemmaChatModelOptions> {
  GemmaChatModel({
    required super.name,
    List<Tool>? tools,
    super.temperature,
    bool enableThinking = false,
    required GemmaChatModelOptions defaultOptions,
    fg.ModelType modelType = fg.ModelType.gemmaIt,
  }) : _enableThinking = enableThinking,
       _modelType = modelType,
       super(defaultOptions: defaultOptions, tools: tools);

  static final Logger _logger = Logger('dartantic.chat.models.gemma');

  final bool _enableThinking;
  final fg.ModelType _modelType;
  InferenceModel? _model;
  InferenceChat? _chat;

  @override
  Stream<ChatResult<ChatMessage>> sendStream(
    List<ChatMessage> messages, {
    GemmaChatModelOptions? options,
    Schema? outputSchema,
  }) async* {
    _logger.info(
      'Starting Flutter Gemma chat stream with ${messages.length} messages',
    );

    try {
      if (_model == null) {
        _model = await FlutterGemma.getActiveModel(
          maxTokens: options?.maxTokens ?? defaultOptions.maxTokens ?? 1024,
        );
      }

      if (_chat == null) {
        final dartanticTools = tools;
        List<fg.Tool>? gemmaTools;

        if (dartanticTools != null && dartanticTools.isNotEmpty) {
          gemmaTools = dartanticTools
              .map(
                (t) => fg.Tool(
                  name: t.name,
                  description: t.description,
                  parameters: _convertSchema(t.inputSchema),
                ),
              )
              .toList();
        }

        _chat = await _model!.createChat(
          tools: gemmaTools ?? [],
          supportsFunctionCalls: gemmaTools != null && gemmaTools.isNotEmpty,
          isThinking: _enableThinking,
          modelType: _modelType,
          temperature: temperature ?? 0.8,
          topK: options?.topK ?? 40,
          topP: options?.topP,
          systemInstruction: options?.systemInstruction,
        );
      }

      for (final message in messages) {
        final gemmaMessage = _convertToGemmaMessage(message);
        await _chat!.addQuery(gemmaMessage);
      }

      String accumulatedThinking = '';

      await for (final response in _chat!.generateChatResponseAsync()) {
        if (response is fg.ThinkingResponse) {
          accumulatedThinking += response.content;
          final parts = accumulatedThinking
              .split('\n')
              .map((line) => line.trim())
              .where((line) => line.isNotEmpty)
              .toList();

          if (parts.isNotEmpty) {
            yield ChatResult<ChatMessage>(
              output: ChatMessage(
                role: ChatMessageRole.model,
                parts: [ThinkingPart(accumulatedThinking)],
              ),
              thinking: accumulatedThinking,
              finishReason: FinishReason.unspecified,
            );
          }
        } else if (response is fg.TextResponse) {
          yield ChatResult<ChatMessage>(
            output: ChatMessage(
              role: ChatMessageRole.model,
              parts: [TextPart(response.token)],
            ),
            thinking: accumulatedThinking.isNotEmpty
                ? accumulatedThinking
                : null,
            finishReason: FinishReason.unspecified,
          );
        } else if (response is fg.FunctionCallResponse) {
          yield ChatResult<ChatMessage>(
            output: ChatMessage(
              role: ChatMessageRole.model,
              parts: [
                ToolPart.call(
                  callId: response.name,
                  toolName: response.name,
                  arguments: response.args,
                ),
              ],
            ),
            thinking: accumulatedThinking.isNotEmpty
                ? accumulatedThinking
                : null,
            finishReason: FinishReason.toolCalls,
          );
        } else if (response is fg.ParallelFunctionCallResponse) {
          final toolCallParts = response.calls
              .map(
                (call) => ToolPart.call(
                  callId: call.name,
                  toolName: call.name,
                  arguments: call.args,
                ),
              )
              .toList();
          yield ChatResult<ChatMessage>(
            output: ChatMessage(
              role: ChatMessageRole.model,
              parts: toolCallParts,
            ),
            thinking: accumulatedThinking.isNotEmpty
                ? accumulatedThinking
                : null,
            finishReason: FinishReason.toolCalls,
          );
        }
      }

      _logger.info('Flutter Gemma chat stream completed');
    } catch (e, stackTrace) {
      _logger.warning('Flutter Gemma chat stream error: $e', e, stackTrace);
      rethrow;
    }
  }

  Map<String, dynamic> _convertSchema(Schema? schema) {
    if (schema == null) return {};
    final map = schema as Map<String, Object?>;
    return Map<String, dynamic>.from(map);
  }

  fg.Message _convertToGemmaMessage(ChatMessage message) {
    final buffer = StringBuffer();

    for (final part in message.parts) {
      if (part is TextPart) {
        buffer.write(part.text);
      } else if (part is ToolPart) {
        if (part.kind == ToolPartKind.call) {
          buffer.write(
            '<start_function_call>call:${part.toolName}{${part.arguments}}<end_function_call>',
          );
        } else if (part.kind == ToolPartKind.result) {
          final content = part.result?.toString() ?? '';
          buffer.write('Tool result: $content\n');
        }
      } else if (part is ThinkingPart) {
        buffer.write(part.text);
      }
    }

    return fg.Message(
      text: buffer.toString(),
      isUser: message.role == ChatMessageRole.user,
    );
  }

  @override
  void dispose() {
    _chat?.close();
    _model?.close();
    _chat = null;
    _model = null;
    _logger.info('GemmaChatModel disposed');
  }
}
