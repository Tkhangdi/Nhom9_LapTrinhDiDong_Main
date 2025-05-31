import 'package:flutter/material.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Notification"),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Your Activity",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView(
                children: [
                  buildNotificationItem(
                    icon: Icons.local_shipping,
                    title: "Order Arrived",
                    message: "Order 24089794727000824 has been completed & arrived at the destination address (Please rate your order).",
                  ),
                  buildNotificationItem(
                    icon: Icons.check_circle_outline,
                    title: "Order Success",
                    message: "Order 24089794727000824 has been Success. Please wait for the product to be sent.",
                  ),
                  buildNotificationItem(
                    icon: Icons.payment,
                    title: "Payment Confirmed",
                    message: "Payment order 24089794727000824 has been confirmed. Please wait for the product to be sent.",
                  ),
                  buildNotificationItem(
                    icon: Icons.cancel,
                    title: "Order Canceled",
                    message: "Refunds order 24089794727000824 have been processed. A fund of \$120 will be returned in 15 minutes.",
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildNotificationItem({required IconData icon, required String title, required String message}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.orange, size: 30),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: const TextStyle(fontSize: 14, color: Colors.black54),
                ),
                const SizedBox(height: 4),
                const Text("July 20, 2020 (08:00 pm)", style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
