import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/chatgpt_service.dart';

class ChatDesign extends StatefulWidget {
  final bool darkMode;
  const ChatDesign({super.key, required this.darkMode});

  @override
  State<ChatDesign> createState() => _ChatDesignState();
}

class _ChatDesignState extends State<ChatDesign> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _textFieldFocusNode = FocusNode();
  final List<String> _messages = [];
  List<List<String>> _chatHistories = [];
  int _currentChatIndex = 0;
  bool _darkMode = true;
  final ChatGPTService _chatGPTService = ChatGPTService();

  @override
  void initState() {
    super.initState();
    _loadChatHistories();
  }

  Future<void> _loadChatHistories() async {
    final prefs = await SharedPreferences.getInstance();
    final historiesCount = prefs.getInt('chat_histories_count') ?? 1;
    // Load the last active chat index
    _currentChatIndex = prefs.getInt('current_chat_index') ?? 0;

    setState(() {
      _chatHistories.clear();
      for (int i = 0; i < historiesCount; i++) {
        final chatHistory = prefs.getStringList('chat_history_$i') ?? [];
        _chatHistories.add(chatHistory);
      }
      _messages.clear();
      // Ensure the index is valid
      _currentChatIndex = _currentChatIndex.clamp(0, _chatHistories.length - 1);
      _messages.addAll(_chatHistories[_currentChatIndex]);
    });
  }

  Future<void> _saveChatHistories() async {
    final prefs = await SharedPreferences.getInstance();
    _chatHistories[_currentChatIndex] = List<String>.from(_messages);

    await prefs.setInt('chat_histories_count', _chatHistories.length);
    // Save the current chat index
    await prefs.setInt('current_chat_index', _currentChatIndex);
    for (int i = 0; i < _chatHistories.length; i++) {
      await prefs.setStringList('chat_history_$i', _chatHistories[i]);
    }
  }

  void _createNewChat() {
    setState(() {
      _chatHistories.add([]);
      _currentChatIndex = _chatHistories.length - 1;
      _messages.clear();
      _saveChatHistories();
    });
  }

  void _removeChat(int index) async {
    if (_chatHistories.length > 1) {
      // Prevent deleting if it's the last chat
      setState(() {
        _chatHistories.removeAt(index);
        if (_currentChatIndex >= _chatHistories.length) {
          _currentChatIndex = _chatHistories.length - 1;
        }
        _messages.clear();
        _messages.addAll(_chatHistories[_currentChatIndex]);
      });
      await _saveChatHistories();
    }
  }

  void _showHistoryDialog() {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(button.size.bottomRight(Offset.zero),
            ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );

    showMenu(
      context: context,
      position: position,
      color: widget.darkMode ? const Color(0xFF1E1E3F) : Colors.white,
      items: List.generate(
        _chatHistories.length,
        (index) => PopupMenuItem(
          value: index,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Chat ${index + 1} (${_chatHistories[index].length} messages)',
                style: TextStyle(
                  color: widget.darkMode ? Colors.white : Colors.black,
                  fontWeight: index == _currentChatIndex
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
              if (_chatHistories.length >
                  1) // Only show delete if more than one chat
                IconButton(
                  icon: Icon(
                    Icons.delete_outline,
                    color: widget.darkMode ? Colors.white70 : Colors.black54,
                    size: 20,
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    _removeChat(index);
                  },
                ),
            ],
          ),
        ),
      ),
    ).then((selectedIndex) {
      if (selectedIndex != null) {
        setState(() {
          _currentChatIndex = selectedIndex;
          _messages.clear();
          _messages.addAll(_chatHistories[selectedIndex]);
        });
      }
    });
  }

  void _sendMessage() async {
    String message = _controller.text.trim();
    if (message.isNotEmpty) {
      final now = DateTime.now();
      final timeStr =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

      setState(() {
        _messages.add('$timeStr - user - $message');
        _controller.clear();
      });

      // Get response from ChatGPT
      String response = await _chatGPTService.sendMessage(message);
      setState(() {
        _messages.add('$timeStr - assistant - $response');
        _saveChatHistories();
      });

      // Re-focus the text field after sending a message
      Future.delayed(Duration(milliseconds: 50), () {
        _textFieldFocusNode.requestFocus();
      });
    }
  }

  void _clearChat() {
    setState(() {
      _messages.clear();
      _saveChatHistories();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.darkMode ? const Color(0xFF1E1E3F) : Colors.white,
      appBar: AppBar(
        backgroundColor:
            widget.darkMode ? const Color(0xFF1E1E3F) : Colors.white,
        title: Text('Chat ${_currentChatIndex + 1}',
            style: TextStyle(
                color: widget.darkMode ? Colors.white : Colors.black)),
        actions: [
          IconButton(
            onPressed: _createNewChat,
            icon: const Icon(Icons.add, color: Colors.blue),
          ),
          IconButton(
            onPressed: _showHistoryDialog,
            icon: const Icon(Icons.history, color: Colors.blue),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final parts = _messages[index].split(' - ');
                final time = parts.length > 2 ? parts[0] : '';
                final role = parts.length > 2 ? parts[1] : 'user';
                final message = parts.length > 2 ? parts[2] : parts[0];

                return Row(
                  mainAxisAlignment: role == 'assistant'
                      ? MainAxisAlignment.end
                      : MainAxisAlignment.start,
                  children: [
                    Flexible(
                      child: Container(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.45,
                        ),
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: role == 'assistant'
                              ? Colors.blue[700]
                              : Colors.grey[700],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(message,
                                style: const TextStyle(color: Colors.white)),
                            if (time.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Align(
                                alignment: Alignment.bottomRight,
                                child: Text(time,
                                    style: TextStyle(
                                        color: Colors.grey[400], fontSize: 12)),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: RawKeyboardListener(
              focusNode: FocusNode(),
              autofocus: true,
              onKey: (RawKeyEvent event) {
                if (event is RawKeyDownEvent &&
                    event.logicalKey == LogicalKeyboardKey.enter) {
                  if (event.isShiftPressed || event.isControlPressed) {
                    setState(() {
                      _controller.text = "${_controller.text}\n";
                      _controller.selection = TextSelection.fromPosition(
                        TextPosition(offset: _controller.text.length),
                      );
                    });
                  } else {
                    _sendMessage();
                  }
                }
              },
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      focusNode: _textFieldFocusNode,
                      minLines: 1,
                      maxLines: 5,
                      keyboardType: TextInputType.multiline,
                      textInputAction: TextInputAction.newline,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: "Type a message...",
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        filled: true,
                        fillColor: Colors.grey[700],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.all(16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _sendMessage,
                    icon: const Icon(Icons.send, color: Colors.blue),
                  ),
                  IconButton(
                    onPressed: _clearChat,
                    icon: const Icon(Icons.delete_outline, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
