import 'package:dartantic_interface/dartantic_interface.dart';
import 'package:flutter_gemma/core/model.dart' as fg;
import 'package:flutter_gemma/core/message.dart' as fg;
import 'package:flutter_gemma/core/model_response.dart' as fg;
import 'package:flutter_gemma/flutter_gemma.dart' hide Tool;
import 'package:flutter_gemma/core/tool.dart' as fg;
import 'package:logging/logging.dart';

import '../parsing/gemma4_tool_parser.dart';
import 'gemma_chat_model_options.dart';

class GemmaChatModel extends ChatModel<GemmaChatModelOptions> {
  GemmaChatModel({
    required super.name,
    List<Tool>? tools,
    super.temperature,
    bool enableThinking = false,
    required GemmaChatModelOptions defaultOptions,
    fg.ModelType modelType = fg.ModelType.gemmaIt,
    PreferredBackend? preferredBackend,
  }) : _enableThinking = enableThinking,
       _modelType = modelType,
       _preferredBackend = preferredBackend,
       super(defaultOptions: defaultOptions, tools: tools);

  static final Logger _logger = Logger('dartantic.gemma');

  final bool _enableThinking;
  final fg.ModelType _modelType;
  final PreferredBackend? _preferredBackend;
  InferenceModel? _model;

  @override
  Stream<ChatResult<ChatMessage>> sendStream(
    List<ChatMessage> messages, {
    GemmaChatModelOptions? options,
    Schema? outputSchema,
  }) async* {
    _logger.warning('[SEND] ${messages.length} msgs');

    try {
      if (_model == null) {
        _model = await FlutterGemma.getActiveModel(
          maxTokens: options?.maxTokens ?? defaultOptions.maxTokens ?? 16384,
          preferredBackend: options?.preferredBackend ?? _preferredBackend,
        );
      }

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

      final chat = await _model!.createChat(
        tools: gemmaTools ?? [],
        supportsFunctionCalls: gemmaTools != null && gemmaTools.isNotEmpty,
        toolChoice: fg.ToolChoice.auto,
        isThinking: _enableThinking,
        modelType: _modelType,
        temperature: temperature ?? 0.8,
        topK: options?.topK ?? 40,
        topP: options?.topP,
        systemInstruction: options?.systemInstruction,
      );

      try {
        for (final message in messages) {
          final gemmaMessage = _convertToGemmaMessage(message);
          await chat.addQuery(gemmaMessage);
        }

        String accumulatedThinking = '';
        final textBuffer = StringBuffer();
        int toolCallIdCounter = 0;

        await for (final response in chat.generateChatResponseAsync()) {
          FinishReason finishReason = FinishReason.unspecified;

          if (response is fg.ThinkingResponse) {
            accumulatedThinking += response.content;
            yield ChatResult<ChatMessage>(
              output: ChatMessage(
                role: ChatMessageRole.model,
                parts: [ThinkingPart(accumulatedThinking)],
              ),
              thinking: accumulatedThinking,
              finishReason: finishReason,
            );
          } else if (response is fg.TextResponse) {
            textBuffer.write(response.token);

            final currentBuffer = textBuffer.toString();
            if (Gemma4ToolParser.hasToolCall(currentBuffer)) {
              final toolCalls = Gemma4ToolParser.parseAll(currentBuffer);
              if (toolCalls.isNotEmpty) {
                _logger.warning(
                  '[TOOL] ${toolCalls.map((t) => t.name).join(", ")}',
                );
                for (final tc in toolCalls) {
                  finishReason = FinishReason.toolCalls;
                  yield ChatResult<ChatMessage>(
                    output: ChatMessage(
                      role: ChatMessageRole.model,
                      parts: [
                        ToolPart.call(
                          callId: 'call_${toolCallIdCounter++}',
                          toolName: tc.name,
                          arguments: tc.args,
                        ),
                      ],
                    ),
                  );
                }
                continue;
              }
            }

            yield ChatResult<ChatMessage>(
              output: ChatMessage(
                role: ChatMessageRole.model,
                parts: [TextPart(response.token)],
              ),
              thinking: accumulatedThinking.isNotEmpty
                  ? accumulatedThinking
                  : null,
              finishReason: finishReason,
            );
          } else if (response is fg.FunctionCallResponse) {
            finishReason = FinishReason.toolCalls;
            _logger.warning('[TOOL] ${response.name}');
            yield ChatResult<ChatMessage>(
              output: ChatMessage(
                role: ChatMessageRole.model,
                parts: [
                  ToolPart.call(
                    callId: 'call_${toolCallIdCounter++}',
                    toolName: response.name,
                    arguments: response.args,
                  ),
                ],
              ),
              thinking: accumulatedThinking.isNotEmpty
                  ? accumulatedThinking
                  : null,
              finishReason: finishReason,
            );
          } else if (response is fg.ParallelFunctionCallResponse) {
            finishReason = FinishReason.toolCalls;
            _logger.warning('[TOOL] ${response.calls.length} parallel');
            final toolCallParts = response.calls
                .map(
                  (call) => ToolPart.call(
                    callId: 'call_${toolCallIdCounter++}',
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
              finishReason: finishReason,
            );
          }
        }
      } finally {
        await chat.close();
      }

      _logger.warning('[DONE]');
    } catch (e, stackTrace) {
      _logger.severe('[ERROR] $e', e, stackTrace);
      rethrow;
    }
  }

  Map<String, dynamic> _convertSchema(Schema? schema) {
    if (schema == null) return {};
    return Map<String, dynamic>.from(schema.value);
  }

  fg.Message _convertToGemmaMessage(ChatMessage message) {
    final buffer = StringBuffer();
    for (final part in message.parts) {
      if (part is TextPart) {
        buffer.write(part.text);
      } else if (part is ToolPart) {
        if (part.kind == ToolPartKind.result) {
          buffer.write(part.result.toString());
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
    _model = null;
    _logger.fine('disposed');
  }
}
