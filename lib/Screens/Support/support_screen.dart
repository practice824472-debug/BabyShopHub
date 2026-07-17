import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../Controllers/auth_controller.dart';
import '../../Controllers/chat_controller.dart';
import '../../Utils/app_theme.dart';
import '../../Widgets/chat_view.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  @override
  void dispose() {
    context.read<ChatController>().closeThread();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Help & Support'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'FAQ'),
              Tab(text: 'Contact Us'),
              Tab(text: 'Chat'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _FAQTab(),
            const _ContactUsTab(),
            const _LiveChatTab(),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Live Chat Tab — real-time conversation with admin
// ──────────────────────────────────────────────
class _LiveChatTab extends StatefulWidget {
  const _LiveChatTab();

  @override
  State<_LiveChatTab> createState() => _LiveChatTabState();
}

class _LiveChatTabState extends State<_LiveChatTab> {
  final _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<ChatController>().openMyChat());
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _textController.text;
    if (text.trim().isEmpty) return;
    final auth = context.read<AuthController>();
    final uid = auth.user?.uid;
    if (uid == null) return;

    final chat = context.read<ChatController>();
    _textController.clear();
    await chat.sendMessage(
      userId: uid,
      isAdmin: false,
      text: text,
      userName: auth.userName.isNotEmpty ? auth.userName : 'User',
      userEmail: auth.user?.email ?? '',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatController>(
      builder: (context, chat, _) {
        return ChatView(
          messages: chat.messages,
          isLoading: chat.messagesLoading,
          isSending: chat.isSending,
          error: chat.error,
          viewerIsAdmin: false,
          textController: _textController,
          onSend: _send,
          emptyTitle: 'Chat with our support team',
          emptyMessage:
              'Send a message and we\'ll reply here as soon as we can.',
        );
      },
    );
  }
}

// ──────────────────────────────────────────────
// FAQ Tab
// ──────────────────────────────────────────────
class _FAQTab extends StatefulWidget {
  @override
  State<_FAQTab> createState() => _FAQTabState();
}

class _FAQTabState extends State<_FAQTab> {
  int? _expandedIndex;

  static const List<Map<String, String>> _faqs = [
    {
      'question': 'How do I create an account?',
      'answer':
          'To create an account, tap the "Sign Up" button on the login screen. Enter your name, email, and password. You\'ll receive a confirmation email to verify your account.',
    },
    {
      'question': 'How do I place an order?',
      'answer':
          'Browse products, add items to your cart, proceed to checkout, enter your delivery address, select payment method, and confirm your order. You\'ll receive an order confirmation email.',
    },
    {
      'question': 'What payment methods do you accept?',
      'answer':
          'We accept all major credit cards, debit cards, and digital wallets. Our payment system is secure and encrypted for your protection.',
    },
    {
      'question': 'How can I track my order?',
      'answer':
          'Go to the "Orders" section in your profile to view all your orders. Tap on any order to see real-time tracking information including: Pending, Confirmed, Packed, Shipped, Out for Delivery, and Delivered.',
    },
    {
      'question': 'What is your return/refund policy?',
      'answer':
          'You can return items within 30 days of delivery if they are unused and in original packaging. Please contact our support team to initiate a return.',
    },
    {
      'question': 'How do I write a review?',
      'answer':
          'Go to a product you\'ve purchased, open the product details, tap "Reviews", then switch to "Write Review" tab. Rate the product and share your experience.',
    },
    {
      'question': 'How long does delivery take?',
      'answer':
          'Standard delivery takes 3-5 business days. Express delivery (2-3 days) is available in selected areas. Delivery times are calculated from order confirmation.',
    },
    {
      'question': 'Is my personal information secure?',
      'answer':
          'Yes, we use industry-standard encryption and security protocols. Your data is protected by Firebase security and we never share your information with third parties.',
    },
    {
      'question': 'Can I cancel my order?',
      'answer':
          'You can cancel your order only if it hasn\'t been shipped yet. Go to your Orders section and tap "Cancel" if the option is available.',
    },
    {
      'question': 'How do I change my password?',
      'answer':
          'Go to Profile → Change Password. Enter your current password and new password. Your password will be updated immediately.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _faqs.length,
      itemBuilder: (context, index) {
        final faq = _faqs[index];
        final isExpanded = _expandedIndex == index;

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: ExpansionTile(
            key: ValueKey(index),
            initiallyExpanded: isExpanded,
            title: Text(
              faq['question']!,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            onExpansionChanged: (expanded) {
              setState(() => _expandedIndex = expanded ? index : null);
            },
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  faq['answer']!,
                  style: TextStyle(color: Colors.grey.shade700, height: 1.5),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ──────────────────────────────────────────────
// Contact Us Tab
// ──────────────────────────────────────────────
class _ContactUsTab extends StatelessWidget {
  const _ContactUsTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Header section
          Container(
            padding: const EdgeInsets.all(16),
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Get in Touch',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Have a question? We\'d love to hear from you.',
                  style: TextStyle(color: Colors.grey.shade700, height: 1.5),
                ),
              ],
            ),
          ),

          // Contact info cards
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _ContactInfoCard(
                  icon: Icons.email_outlined,
                  title: 'Email',
                  subtitle: 'support@babyshophub.com',
                  onTap: () {},
                ),
                const SizedBox(height: 12),
                _ContactInfoCard(
                  icon: Icons.phone_outlined,
                  title: 'Phone',
                  subtitle: '+1 (555) 123-4567',
                  onTap: () {},
                ),
                const SizedBox(height: 12),
                _ContactInfoCard(
                  icon: Icons.location_on_outlined,
                  title: 'Address',
                  subtitle: '123 Baby Street, Shopping City, SC 12345',
                  onTap: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Contact Info Card Widget
// ──────────────────────────────────────────────
class _ContactInfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ContactInfoCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: AppTheme.primaryColor),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: Icon(Icons.arrow_forward_ios,
            size: 16, color: Colors.grey.shade400),
        onTap: onTap,
      ),
    );
  }
}
