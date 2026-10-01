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
      'text': 'Hello! I am Tikboy Bot 🤖. How can I help you with our delicious longganisa today?',
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

    // Expanded Rule-based Chatbot Logic
    Future.delayed(const Duration(seconds: 1), () {
      String response = "I'm not quite sure about that. Try asking about 'prices', 'delivery', 'refunds', 'payment', or 'bestsellers'! 💡";

      if (userMessage.contains('delivery') || userMessage.contains('ship') || userMessage.contains('fee')) {
        response = "We deliver within Lucban and neighboring areas! Delivery fee is ₱40, but completely FREE for orders over ₱300. 🚚";
      } else if (userMessage.contains('price') || userMessage.contains('cost') || userMessage.contains('menu') || userMessage.contains('product') || userMessage.contains('longanisa') || userMessage.contains('embutido')) {
        response = "Here is our product menu & pricing:\n\n"
                   "• **Pork Longanisa**:\n  - Regular: ₱85 (Small) | ₱170 (Big)\n  - Spicy: ₱90 (Small) | ₱180 (Big)\n  - Sweet: ₱200 (Per Kilo)\n"
                   "• **Chicken Longanisa**: ₱75 (Small) | ₱150 (Big)\n"
                   "• **Embutido**: ₱50 (Small) | ₱100 (Big)\n"
                   "• **Crispy Chili Garlic Oil**: ₱150 💰";
      } else if (userMessage.contains('refund') || userMessage.contains('cancel')) {
        response = "You can request a refund on any active order by going to 'My Orders' and tapping the 'Refund' button. 🔄";
      } else if (userMessage.contains('payment') || userMessage.contains('pay') || userMessage.contains('gcash')) {
        response = "We accept Cash on Delivery (COD) and GCash payments during checkout! 💳";
      } else if (userMessage.contains('hour') || userMessage.contains('open') || userMessage.contains('time')) {
        response = "We are open daily from 8:00 AM to 8:00 PM to serve your freshly made longganisa cravings! ⏰";
      } else if (userMessage.contains('bestseller') || userMessage.contains('popular') || userMessage.contains('favorite')) {
        response = "Our Tikboy Classic Pork Longanisa and Crispy Chili Garlic Oil are absolute crowd favorites! 🔥";
      } else if (userMessage.contains('order')) {
        response = "You can place an order by choosing your favorite product, selecting your preferred flavor/size, adding it to your Cart, and checking out!";
      } else if (userMessage.contains('hi') || userMessage.contains('hello') || userMessage.contains('hey')) {
        response = "Hi there! Welcome to Tikboy Longanisa 😋. How can I assist you today?";
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
