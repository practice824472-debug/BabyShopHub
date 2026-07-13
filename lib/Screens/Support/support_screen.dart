import 'package:flutter/material.dart';
import '../../Utils/app_theme.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Help & Support'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'FAQ'),
              Tab(text: 'Contact Us'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _FAQTab(),
            _ContactUsTab(
              nameController: _nameController,
              emailController: _emailController,
              subjectController: _subjectController,
              messageController: _messageController,
            ),
          ],
        ),
      ),
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
class _ContactUsTab extends StatefulWidget {
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController subjectController;
  final TextEditingController messageController;

  const _ContactUsTab({
    required this.nameController,
    required this.emailController,
    required this.subjectController,
    required this.messageController,
  });

  @override
  State<_ContactUsTab> createState() => _ContactUsTabState();
}

class _ContactUsTabState extends State<_ContactUsTab> {
  bool _isSubmitting = false;
  final _formKey = GlobalKey<FormState>();

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      // Simulate sending contact form
      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Thank you! We\'ll get back to you soon.'),
          duration: Duration(seconds: 3),
        ),
      );

      // Clear form
      widget.nameController.clear();
      widget.emailController.clear();
      widget.subjectController.clear();
      widget.messageController.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to send message. Please try again.')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

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
                  'Have a question? We\'d love to hear from you. Send us a message and we\'ll respond as soon as possible.',
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

          const Divider(),

          // Contact form
          Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Send us a Message',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  // Name field
                  TextFormField(
                    controller: widget.nameController,
                    decoration: InputDecoration(
                      labelText: 'Full Name',
                      prefixIcon: const Icon(Icons.person_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  // Email field
                  TextFormField(
                    controller: widget.emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!value.contains('@')) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  // Subject field
                  TextFormField(
                    controller: widget.subjectController,
                    decoration: InputDecoration(
                      labelText: 'Subject',
                      prefixIcon: const Icon(Icons.subject_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a subject';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  // Message field
                  TextFormField(
                    controller: widget.messageController,
                    maxLines: 5,
                    minLines: 4,
                    decoration: InputDecoration(
                      labelText: 'Message',
                      prefixIcon: const Icon(Icons.message_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignLabelWithHint: true,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your message';
                      }
                      if (value.trim().length < 10) {
                        return 'Message must be at least 10 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Submit button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isSubmitting ? null : _submitForm,
                      icon: _isSubmitting
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                          : const Icon(Icons.send),
                      label: Text(_isSubmitting ? 'Sending...' : 'Send Message'),
                    ),
                  ),
                ],
              ),
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
        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
        onTap: onTap,
      ),
    );
  }
}
