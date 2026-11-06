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
  bool _isLoading = false;
  final List<Map<String, dynamic>> _messages = [
    {
      'text': 'Hello! Welcome to Tikboy Longanisa. 🤖 How can I help you today?',
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
    } else if (msg.contains('origin') || msg.contains('originate') || msg.contains('history') || msg.contains('where')) {
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
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        width: double.infinity,
        height: 540,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          children: [
            // Header: TikBot AI (subtitle removed)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.red.shade800, Colors.deepOrange.shade600],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: Colors.white,
                    radius: 20,
                    child: Icon(Icons.smart_toy, color: Colors.red, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'TikBot AI',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
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
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 4),
                child: LinearProgressIndicator(color: Colors.red, minHeight: 2),
              ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey[200]!)),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: 'Ask anything about our longanisa...',
                        hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      ),
                      onSubmitted: (_) => _handleSend(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: Colors.red.shade700,
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white, size: 18),
                      onPressed: () => _handleSend(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
                color: isUser ? Colors.red.shade700 : Colors.grey[100],
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
}
