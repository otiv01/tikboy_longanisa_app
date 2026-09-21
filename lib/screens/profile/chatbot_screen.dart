import 'package:flutter/material.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, dynamic>> _messages = [
    {
      'text': 'Hello! I am Tikboy Bot. 🤖 How can I help you today?',
      'isUser': false,
    },
  ];

  void _handleSend() {
    if (_controller.text.trim().isEmpty) return;

    setState(() {
      _messages.add({
        'text': _controller.text,
        'isUser': true,
      });
    });

    final userMessage = _controller.text.toLowerCase();
    _controller.clear();

    // Simple Rule-based Chatbot Logic
    Future.delayed(const Duration(seconds: 1), () {
      String response = "I'm not sure about that. Can you try asking about 'delivery', 'price', or 'bestsellers'?";

      if (userMessage.contains('delivery')) {
        response = "We deliver within Lucban and neighboring towns! Delivery fee is ₱40, but free for orders over ₱300. 🚚";
      } else if (userMessage.contains('price') || userMessage.contains('cost')) {
        response = "Our prices start at ₱85 for a dozen of Regular Longganisa. Check the Home tab for the full menu! 💰";
      } else if (userMessage.contains('bestseller') || userMessage.contains('popular')) {
        response = "Our Tikboy Classic and Spicy Longganisa are the crowd favorites! 🔥";
      } else if (userMessage.contains('order')) {
        response = "You can place an order by adding items to your Cart and clicking 'Place Order'.";
      } else if (userMessage.contains('hi') || userMessage.contains('hello')) {
        response = "Hi there! Ready for some fresh longganisa? 😋";
      }

      setState(() {
        _messages.add({
          'text': response,
          'isUser': false,
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tikboy Support Bot', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 1,
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return _buildChatBubble(msg['text'], msg['isUser']);
              },
            ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildChatBubble(String text, bool isUser) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isUser ? Colors.red : Colors.grey[200],
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isUser ? 20 : 0),
            bottomRight: Radius.circular(isUser ? 0 : 20),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isUser ? Colors.white : Colors.black87,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.1), spreadRadius: 1, blurRadius: 5),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              ),
              onSubmitted: (_) => _handleSend(),
            ),
          ),
          const SizedBox(width: 10),
          CircleAvatar(
            backgroundColor: Colors.red,
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: _handleSend,
            ),
          ),
        ],
      ),
    );
  }
}
