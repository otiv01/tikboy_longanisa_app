import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = false;
  final List<Map<String, dynamic>> _messages = [
    {
      'text': 'Hello! I am Tikboy Bot 🤖. How can I help you with our delicious longganisa today?',
      'isUser': false,
    },
  ];

  Future<void> _callGeminiAI(String userMessage) async {
    const apiKey = String.fromEnvironment('GEMINI_API_KEY', defaultValue: 'YOUR_GEMINI_API_KEY');
    final url = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'system_instruction': {
            'parts': {
              'text': 'You are Tikboy Bot, a friendly AI customer support assistant for Tikboy Longanisa store in Tayabas, Quezon. '
                      'Our menu & prices: Pork Longanisa (Regular: ₱85/₱170, Spicy: ₱90/₱180, Sweet: ₱200/kilo), '
                      'Chicken Longanisa (₱75/₱150), Embutido (₱50/₱100), Crispy Chili Garlic Oil (₱150). '
                      'Delivery is ₱40, but FREE for orders over ₱300. Customers can request refunds in My Orders.'
            }
          },
          'contents': [
            {
              'parts': [
                {'text': userMessage}
              ]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final aiReply = data['candidates'][0]['content']['parts'][0]['text'].trim();

        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _messages.add({
            'text': aiReply,
            'isUser': false,
          });
        });
      } else {
        _fallbackResponse(userMessage);
      }
    } catch (e) {
      _fallbackResponse(userMessage);
    }
  }

  void _fallbackResponse(String userMessage) {
    String response = "I'm not quite sure about that. Try asking about 'prices', 'delivery', 'refunds', 'payment', or 'bestsellers'! 💡";
    final userMessageLower = userMessage.toLowerCase();

    if (userMessageLower.contains('delivery') || userMessageLower.contains('ship') || userMessageLower.contains('fee')) {
      response = "We deliver within Lucban and neighboring areas! Delivery fee is ₱40, but completely FREE for orders over ₱300. 🚚";
    } else if (userMessageLower.contains('price') || userMessageLower.contains('cost') || userMessageLower.contains('menu') || userMessageLower.contains('product') || userMessageLower.contains('longanisa') || userMessageLower.contains('embutido')) {
      response = "Here is our product menu & pricing:\n\n"
                 "• **Pork Longanisa**:\n  - Regular: ₱85 (Small) | ₱170 (Big)\n  - Spicy: ₱90 (Small) | ₱180 (Big)\n  - Sweet: ₱200 (Per Kilo)\n"
                 "• **Chicken Longanisa**: ₱75 (Small) | ₱150 (Big)\n"
                 "• **Embutido**: ₱50 (Small) | ₱100 (Big)\n"
                 "• **Crispy Chili Garlic Oil**: ₱150 💰";
    } else if (userMessageLower.contains('refund') || userMessageLower.contains('cancel')) {
      response = "You can request a refund on any active order by going to 'My Orders' and tapping the 'Refund' button. 🔄";
    } else if (userMessageLower.contains('payment') || userMessageLower.contains('pay') || userMessageLower.contains('gcash')) {
      response = "We accept Cash on Delivery (COD) and GCash payments during checkout! 💳";
    } else if (userMessageLower.contains('hour') || userMessageLower.contains('open') || userMessageLower.contains('time')) {
      response = "We are open daily from 8:00 AM to 8:00 PM to serve your freshly made longganisa cravings! ⏰";
    } else if (userMessageLower.contains('bestseller') || userMessageLower.contains('popular') || userMessageLower.contains('favorite')) {
      response = "Our Tikboy Classic Pork Longanisa and Crispy Chili Garlic Oil are absolute crowd favorites! 🔥";
    } else if (userMessageLower.contains('order')) {
      response = "You can place an order by choosing your favorite product, selecting your preferred flavor/size, adding it to your Cart, and checking out!";
    } else if (userMessageLower.contains('hi') || userMessageLower.contains('hello') || userMessageLower.contains('hey')) {
      response = "Hi there! Welcome to Tikboy Longanisa 😋. How can I assist you today?";
    }

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _messages.add({
        'text': response,
        'isUser': false,
      });
    });
  }

  void _handleSend([String? textToSend]) {
    final text = textToSend ?? _controller.text;
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add({
        'text': text,
        'isUser': true,
      });
      _isLoading = true;
    });

    if (textToSend == null) {
      _controller.clear();
    }

    _callGeminiAI(text);
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
                final isUser = msg['isUser'] as bool;
                return Column(
                  crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    _buildChatBubble(msg['text'], isUser),
                    if (!isUser && index == 0) ...[
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: ['Prices', 'Delivery', 'Refunds'].map((chipText) {
                          return ActionChip(
                            label: Text(chipText, style: const TextStyle(color: Colors.red, fontSize: 12)),
                            backgroundColor: Colors.red.withValues(alpha: 0.1),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            side: BorderSide.none,
                            onPressed: () => _handleSend(chipText),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ],
                );
              },
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: LinearProgressIndicator(color: Colors.red),
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
          BoxShadow(color: Colors.grey.withValues(alpha: 0.1), spreadRadius: 1, blurRadius: 5),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Ask anything about our longanisa...',
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
              onPressed: () => _handleSend(),
            ),
          ),
        ],
      ),
    );
  }
}
