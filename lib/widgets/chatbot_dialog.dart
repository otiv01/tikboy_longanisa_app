import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ChatbotDialog extends StatefulWidget {
  const ChatbotDialog({super.key});

  @override
  State<ChatbotDialog> createState() => _ChatbotDialogState();
}

class _ChatbotDialogState extends State<ChatbotDialog> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, dynamic>> _messages = [
    {
      'text': 'Hello! Welcome to Tikboy Longanisa. 🤖 How can I help you today?',
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
          _messages.add({
            'text': aiReply,
            'isUser': false,
          });
        });
      } else {
        // Fallback if API fails due to billing/quota limits
        _fallbackResponse(userMessage);
      }
    } catch (e) {
      // Fallback on network error
      _fallbackResponse(userMessage);
    }
  }

  void _fallbackResponse(String userMessage) {
    String response = "I'm here to help! Try asking about 'prices', 'delivery', or 'refunds'.";
    final msg = userMessage.toLowerCase();
    if (msg.contains('delivery') || msg.contains('ship') || msg.contains('fee')) {
      response = "We deliver within Lucban! Delivery is ₱40, but FREE for orders over ₱300. 🚚";
    } else if (msg.contains('price') || msg.contains('cost') || msg.contains('menu') || msg.contains('longanisa') || msg.contains('sales') || msg.contains('marketing')) {
      response = "Our menu:\n• Pork Longanisa: Reg ₱85/₱170, Spicy ₱90/₱180, Sweet ₱200/kilo\n• Chicken Longanisa: ₱75/₱150\n• Embutido: ₱50/₱100\n• Crispy Chili Garlic Oil: ₱150 💰";
    } else if (msg.contains('refund') || msg.contains('cancel')) {
      response = "You can request a refund by going to 'My Orders' and tapping the 'Refund' button on active orders. 🔄";
    } else if (msg.contains('payment') || msg.contains('pay') || msg.contains('gcash')) {
      response = "We accept Cash on Delivery (COD) and GCash payments! 💳";
    } else if (msg.contains('hi') || msg.contains('hello')) {
      response = "Hi there! Ready for some fresh longganisa? 😋";
    } else if (msg.contains('support') || msg.contains('help')) {
      response = "Our support team is always ready. What do you need assistance with?";
    }

    if (!mounted) return;
    setState(() {
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
    });
    if (textToSend == null) {
      _controller.clear();
    }

    // Call Google Gemini API (with smart offline fallback)
    _callGeminiAI(text);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.all(15),
      child: Container(
        width: double.infinity,
        height: 520,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            // Top Bar (matching screenshot style)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: const BoxDecoration(
                color: Color(0xFF7B2CBF), // Rich purple header matching screenshot
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Stack(
                    children: [
                      const CircleAvatar(
                        backgroundColor: Colors.white,
                        radius: 18,
                        child: Icon(Icons.smart_toy, color: Color(0xFF7B2CBF), size: 20),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            border: Border.fromBorderSide(BorderSide(color: Colors.white, width: 1.5)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tikboy Bot',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        '🟢 Online Now',
                        style: TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Chat Messages Area
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  final isUser = msg['isUser'] as bool;
                  return Column(
                    crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                    children: [
                      if (!isUser)
                        const Padding(
                          padding: EdgeInsets.only(left: 4, bottom: 4),
                          child: Text('Tikboy Bot', style: TextStyle(color: Colors.grey, fontSize: 10)),
                        ),
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                        decoration: BoxDecoration(
                          color: isUser ? const Color(0xFF7B2CBF) : Colors.grey[100],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          msg['text'],
                          style: TextStyle(
                            color: isUser ? Colors.white : Colors.black87,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      // Quick suggestion chips after first message
                      if (!isUser && index == 0) ...[
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: ['Prices', 'Delivery', 'Refunds'].map((chipText) {
                            return ActionChip(
                              label: Text(chipText, style: const TextStyle(color: Color(0xFF7B2CBF), fontSize: 12)),
                              backgroundColor: const Color(0xFF7B2CBF).withValues(alpha: 0.1),
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

            // Bottom Input Area
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey[200]!)),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        hintText: 'Reply to Tikboy Bot...',
                        hintStyle: TextStyle(color: Colors.grey, fontSize: 13),
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => _handleSend(),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send, color: Color(0xFF7B2CBF)),
                    onPressed: () => _handleSend(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
