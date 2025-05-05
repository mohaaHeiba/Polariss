import 'package:chat_gpt_sdk/chat_gpt_sdk.dart';

class ChatGPTService {
  final OpenAI openAI;

  ChatGPTService()
      : openAI = OpenAI.instance.build(
          token:
              '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', // Replace with your real API key
          baseOption: HttpSetup(
            receiveTimeout: const Duration(seconds: 60),
            connectTimeout: const Duration(seconds: 60),
          ),
        );

  Future<String> sendMessage(String message) async {
    try {
      final request = ChatCompleteText(
        messages: [
          {'role': 'system', 'content': 'You are a helpful assistant.'},
          {'role': 'user', 'content': message}
        ],
        maxToken: 2000,
        model: GptTurboChatModel(),
        temperature: 0.7,
      );

      final response = await openAI.onChatCompletion(request: request);
      if (response == null || response.choices.isEmpty) {
        print('Empty response from API');
        return 'Sorry, I could not generate a response.';
      }

      return response.choices.first.message?.content ?? 'No response content';
    } catch (e) {
      print('ChatGPT Error Details: $e');
      if (e.toString().contains('token')) {
        return 'Error: Please check your API key configuration.';
      } else if (e.toString().contains('429')) {
        return 'Error: You have exceeded your quota. Please check your OpenAI usage limits.';
      }
      return 'Error: Unable to process your request. Please try again.';
    }
  }
}
