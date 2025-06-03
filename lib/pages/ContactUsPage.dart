import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../ui/ui_colors.dart';

class ContactUsPage extends StatefulWidget {
  final bool darkMode;

  const ContactUsPage({super.key, required this.darkMode});

  @override
  State<ContactUsPage> createState() => _ContactUsPageState();
}

class _ContactUsPageState extends State<ContactUsPage> {
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    _emailController.dispose();
    _nameController.dispose();
    _subjectController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage(BuildContext context) async {
    if (_messageController.text.isEmpty || _emailController.text.isEmpty) {
      _showDialog(
          context, "Error", "Please fill in all fields before sending.");
      return;
    }

    _showLoadingDialog(context);

    final url =
        "https://silent-rain-272c.karm88998.workers.dev?url=https://api.emailjs.com/api/v1.0/email/send";

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'origin': '*',
          'x-requested-with': 'XMLHttpRequest',
        },
        body: jsonEncode({
          "service_id": "service_bvkrmyx",
          "template_id": "template_253391p",
          "user_id": "Qqbc0BuZmUDa_Fh6s",
          "accessToken": "fSTAuFHc-FoHoQsaPn7Cz",
          "template_params": {
            "message": _messageController.text,
            "email": _emailController.text,
          }
        }),
      );

      Navigator.pop(context); // Close loading dialog

      if (response.statusCode == 200) {
        _showDialog(
            context, "Success", "Your message has been sent successfully!");
        _messageController.clear();
        _emailController.clear();
      } else {
        _showDialog(
            context, "Error", "Failed to send message. Please try again.");
      }
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      _showDialog(
          context, "Error", "An error occurred. Please check your connection.");
    }
  }

  void _showDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("OK", style: TextStyle(color: UIColors.primaryColor)),
          ),
        ],
      ),
    );
  }

  void _showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(color: UIColors.primaryColor),
            SizedBox(width: 20),
            Text("Sending message..."),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Row(
      children: [
        Container(
          width: MediaQuery.of(context).size.width * 0.45,
          color: widget.darkMode ? UIColors.backgroundColor : Colors.white,
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'We would love to hear from you!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: widget.darkMode
                      ? Colors.white
                      : const Color.fromARGB(255, 0, 0, 0),
                ),
              ),
              SizedBox(height: 15),
              _inputField("Your Name", "Enter your name...", _nameController,
                  widget.darkMode),
              SizedBox(height: 20),
              _inputField("Your Email", "Type your email here...",
                  _emailController, widget.darkMode),
              SizedBox(height: 20),
              _inputField("Subject", "Enter subject...", _subjectController,
                  widget.darkMode),
              SizedBox(height: 20),
              _inputField("Your Message", "Type your message here...",
                  _messageController, widget.darkMode,
                  maxLines: 4),
              SizedBox(height: 25),
              Center(
                child: ElevatedButton(
                  onPressed: () => _sendMessage(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: UIColors.primaryColor,
                    padding: EdgeInsets.symmetric(vertical: 15, horizontal: 40),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    textStyle: TextStyle(fontSize: 18),
                  ),
                  child: Text(
                    'Send Message',
                    style: TextStyle(
                      color: widget.darkMode
                          ? const Color.fromARGB(221, 0, 0, 0)
                          : const Color.fromARGB(255, 0, 0, 0),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Container(
            color: widget.darkMode ? Colors.black87 : UIColors.primaryColor,
            padding: EdgeInsets.all(30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Contact Information',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: widget.darkMode
                        ? Colors.white
                        : const Color.fromARGB(255, 0, 0, 0),
                  ),
                ),
                SizedBox(height: 30),
                _contactDetailItem(Icons.email, 'Email', 'karm88998@gmail.com'),
                SizedBox(height: 20),
                _contactDetailItem(Icons.phone, 'Phone', '+1 (234) 567-890'),
                SizedBox(height: 20),
                _contactDetailItem(Icons.location_on, 'Address',
                    '123 Business Street, Tech City, TC 12345'),
                SizedBox(height: 20),
                _contactDetailItem(Icons.access_time, 'Business Hours',
                    'Monday - Friday: 9AM to 5PM'),
                SizedBox(height: 40),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      color: Colors.grey[200],
                    ),
                    // Add a map or image here
                    child: Center(
                      child: Text('Map placeholder'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ));
  }

  Widget _contactDetailItem(IconData icon, String title, String detail) {
    return Row(
      children: [
        Icon(icon,
            color: widget.darkMode ? Colors.white70 : Colors.black, size: 24),
        SizedBox(width: 15),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: widget.darkMode ? Colors.white70 : Colors.black,
              ),
            ),
            SizedBox(height: 5),
            Text(
              detail,
              style: TextStyle(
                fontSize: 14,
                color: widget.darkMode ? Colors.white60 : Colors.black,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _inputField(String label, String hint,
      TextEditingController controller, bool darkMode,
      {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: widget.darkMode ? Colors.white : Colors.black,
          ),
        ),
        SizedBox(height: 10),
        Container(
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            style: TextStyle(
              color: widget.darkMode ? Colors.white : Colors.black,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: widget.darkMode ? Colors.black26 : Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              hintText: hint,
              hintStyle: TextStyle(
                  color: widget.darkMode ? Colors.white54 : Colors.black45),
              contentPadding:
                  EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            ),
          ),
        )
      ],
    );
  }
}
