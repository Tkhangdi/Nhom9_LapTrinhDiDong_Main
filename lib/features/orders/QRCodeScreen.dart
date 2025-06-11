import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shop_ban_dong_ho/features/orders/quanlydonhang.dart';

class QRCodeScreen extends StatelessWidget {
  final String orderId;
  final double tongCong;

  const QRCodeScreen({
    super.key,
    required this.orderId,
    required this.tongCong,
  });

  @override
  Widget build(BuildContext context) {
    const accountNumber = "0123456789";
    const accountName = "NGUYEN VAN A";
    const bankCode = "vcb";

    final qrUrl =
        "https://img.vietqr.io/image/$bankCode-$accountNumber-compact2.png"
        "?amount=${tongCong.toInt()}&addInfo=ORDER$orderId&accountName=${Uri.encodeComponent(accountName)}";

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          "Thanh toán đơn hàng",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        backgroundColor: const Color(0xFFFF6B35),
        elevation: 0,
        centerTitle: true,
        // leading: IconButton(
        //   icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
        //   onPressed: () => Navigator.pop(context),
        // ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header gradient section
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFFF6B35), Color(0xFFFF8C42)],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
                child: Column(
                  children: [
                    const Icon(
                      Icons.watch_later_outlined,
                      size: 50,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "TimeZone Watch Store",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Đơn hàng #$orderId",
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            // QR Code Card
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    "Quét mã QR để thanh toán",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Sử dụng ứng dụng ngân hàng của bạn",
                    style: TextStyle(fontSize: 14, color: Color(0xFF7F8C8D)),
                  ),
                  const SizedBox(height: 24),

                  // QR Code with border
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFFF6B35).withOpacity(0.2),
                        width: 2,
                      ),
                    ),
                    child: Image.network(
                      qrUrl,
                      width: 220,
                      height: 220,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          width: 220,
                          height: 220,
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFFFF6B35),
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 220,
                          height: 220,
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 40,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 8),
                              Text(
                                "Không thể tải mã QR",
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Payment Details Card
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Thông tin thanh toán",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildPaymentInfo(
                    "Số tiền",
                    "${tongCong.toStringAsFixed(0)} ₫",
                    true,
                  ),
                  const SizedBox(height: 12),
                  _buildPaymentInfo("Nội dung CK", "ORDER$orderId", false),
                  const SizedBox(height: 12),
                  _buildPaymentInfo("Tài khoản", accountName, false),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Action Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  // Complete Payment Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        final docRef = FirebaseFirestore.instance
                            .collection('orders')
                            .doc(FirebaseAuth.instance.currentUser?.uid)
                            .collection('user_orders')
                            .doc(orderId);

                        await docRef.update({'trangThai': 'pending'});

                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => QuanLyDonHangScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF6B35),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_outline, size: 20),
                          SizedBox(width: 8),
                          Text(
                            "Hoàn tất thanh toán",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Back Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () async {
                        final docRef = FirebaseFirestore.instance
                            .collection('orders')
                            .doc(FirebaseAuth.instance.currentUser?.uid)
                            .collection('user_orders')
                            .doc(orderId);

                        final docSnap = await docRef.get();
                        if (docSnap.exists &&
                            docSnap.data()?['trangThai'] ==
                                'awaiting_payment') {
                          await docRef.delete();
                        }

                        Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFFF6B35),
                        side: const BorderSide(color: Color(0xFFFF6B35)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.arrow_back, size: 20),
                          SizedBox(width: 8),
                          Text(
                            "Quay lại",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentInfo(String label, String value, bool isAmount) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(fontSize: 14, color: Color(0xFF7F8C8D)),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: isAmount ? 18 : 14,
              fontWeight: isAmount ? FontWeight.bold : FontWeight.w500,
              color: isAmount
                  ? const Color(0xFFFF6B35)
                  : const Color(0xFF2C3E50),
            ),
          ),
        ),
      ],
    );
  }
}
