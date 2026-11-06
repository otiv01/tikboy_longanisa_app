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
      'text': 'Hello! I am TikBot AI 🤖. How can I help you with our delicious longganisa today?',
      'isUser': false,
    },
  ];

  Future<void> _callGeminiAI(String userMessage) async {
    const apiKey = 'YOUR_API_KEY';
    
    final url = apiKey.startsWith('AQ')
        ? 'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent'
        : 'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey';

    final headers = {
      'Content-Type': 'application/json',
      if (apiKey.startsWith('AQ'))
        'Authorization': 'Bearer $apiKey'
    };

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: json.encode({
          'system_instruction': {
            'parts': [
              {
                'text': 'You are TikBot AI, a friendly AI customer support assistant for Tikboy Longanisa store in Tayabas, Quezon. '
                        'Our menu & prices: Pork Longanisa (Regular: ₱85/₱170, Spicy: ₱90/₱180, Sweet: ₱200/kilo), '
                        'Chicken Longanisa (₱75/₱150), Embutido (₱50/₱100), Crispy Chili Garlic Oil (₱150). '
                        'Delivery is ₱40, but FREE for orders over ₱300. Customers can request refunds in My Orders.'
              }
            ]
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
        debugPrint('Gemini API Error: ${response.statusCode} - ${response.body}');
        _fallbackResponse(userMessage);
      }
    } catch (e) {
      debugPrint('Gemini API Exception: $e');
      _fallbackResponse(userMessage);
    }
  }

  void _fallbackResponse(String userMessage) {
    String response = "I'm here to help! Try asking about 'prices', 'delivery', or 'refunds'.";
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
      response = "You can request a refund by going to 'My Orders' and tapping the 'Refund' button on active orders. 🔄";
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
    } else if (userMessageLower.contains('origin') || userMessageLower.contains('originate') || userMessageLower.contains('history') || userMessageLower.contains('where')) {
      response = "Longanisa traces its roots to Spanish 'longaniza' introduced during the Spanish colonial period, famously localized in Lucban, Quezon! 🇵🇭";
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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.red.shade800, Colors.deepOrange.shade600],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: const Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.white,
              radius: 16,
              child: Icon(Icons.smart_toy, color: Colors.red, size: 18),
            ),
            SizedBox(width: 10),
            Text('TikBot AI', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        elevation: 0,
        foregroundColor: Colors.white,
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMessageBubble(msg['text'], isUser),
                    if (!isUser && index == 0) ...[
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.only(left: 36.0),
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: ['Prices', 'Delivery', 'Origin'].map((chipText) {
                            return ActionChip(
                              label: Text(chipText, style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold)),
                              backgroundColor: Colors.red.withValues(alpha: 0.1),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              side: BorderSide.none,
                              onPressed: () => _handleSend(chipText),
                            );
                          }).toList(),
                        ),
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

  Widget _buildMessageBubble(String text, bool isUser) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            const CircleAvatar(
              radius: 14,
              backgroundColor: Colors.red,
              child: Icon(Icons.smart_toy, size: 14, color: Colors.white),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
              decoration: BoxDecoration(
                color: isUser ? Colors.red.shade700 : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isUser ? 20 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 20),
                ),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4, offset: const Offset(0, 2)),
                ],
              ),
              child: Text(
                text,
                style: TextStyle(
                  color: isUser ? Colors.white : Colors.black87,
                  fontSize: 13.5,
                  height: 1.3,
                ),
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            const CircleAvatar(
              radius: 14,
              backgroundColor: Colors.grey,
              child: Icon(Icons.person, size: 14, color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.grey.withValues(alpha: 0.08), spreadRadius: 1, blurRadius: 6),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Ask anything about our longanisa...',
                hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              onSubmitted: (_) => _handleSend(),
            ),
          ),
          const SizedBox(width: 10),
          CircleAvatar(
            backgroundColor: Colors.red.shade700,
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white, size: 18),
              onPressed: () => _handleSend(),
            ),
          ),
        ],
      ),
    );
  }
}
