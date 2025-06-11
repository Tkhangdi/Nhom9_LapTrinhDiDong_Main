import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shop_ban_dong_ho/features/statistics/chi_tiet_don_hang_screen.dart';

class ThongKeChiTieuScreen extends StatefulWidget {
  @override
  State<ThongKeChiTieuScreen> createState() => _ThongKeChiTieuScreenState();
}

class _ThongKeChiTieuScreenState extends State<ThongKeChiTieuScreen> with TickerProviderStateMixin {
  int selectedMonth = DateTime.now().month;
  int selectedYear = DateTime.now().year;

  int tongDon = 0;
  double tongTien = 0.0;
  List<Map<String, dynamic>> danhSachDon = [];
  bool isLoading = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    loadThongKe();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> loadThongKe() async {
     if (!mounted) return;
    setState(() {
      isLoading = true;
    });

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    DateTime start = DateTime(selectedYear, selectedMonth, 1);
    DateTime end = DateTime(selectedYear, selectedMonth + 1, 1);

    final querySnapshot = await FirebaseFirestore.instance
        .collection('orders')
        .doc(userId)
        .collection('user_orders')
        .where('trangThai', isEqualTo: 'completed')
        .where('ngayDat', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('ngayDat', isLessThan: Timestamp.fromDate(end))
        .get();

    double total = 0.0;
    List<Map<String, dynamic>> orders = [];

    for (var doc in querySnapshot.docs) {
      final data = doc.data();
      total += (data['tongCong'] ?? 0).toDouble();
      orders.add(data);
    }

    setState(() {
      tongDon = orders.length;
      tongTien = total;
      danhSachDon = orders;
      isLoading = false;
    });

    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8F9FA),
      body: CustomScrollView(
        slivers: [
          // Custom App Bar với gradient
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            flexibleSpace: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFFF8C42),
                    Color(0xFFFF6B35),
                  ],
                ),
              ),
              child: FlexibleSpaceBar(
                title: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.watch_later_outlined,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      "Thống Kê Chi Tiêu",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                centerTitle: true,
              ),
            ),
          ),

          // Nội dung chính
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Bộ lọc thời gian
                  _buildTimeFilter(),
                  SizedBox(height: 20),

                  // Thống kê tổng quan
                  if (isLoading)
                    _buildLoadingWidget()
                  else
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: _buildStatisticsCards(),
                    ),
                  
                  SizedBox(height: 20),

                  // Danh sách đơn hàng
                  if (!isLoading)
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: _buildOrdersList(),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeFilter() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Color(0xFFFF8C42).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.calendar_today,
                  color: Color(0xFFFF8C42),
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Text(
                "Chọn thời gian",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildCustomDropdown(
                  label: "Tháng",
                  value: selectedMonth,
                  items: List.generate(12, (index) {
                    return DropdownMenuItem(
                      value: index + 1,
                      child: Text("Tháng ${index + 1}"),
                    );
                  }),
                  onChanged: (value) {
                    setState(() {
                      selectedMonth = value!;
                    });
                    _animationController.reset();
                    loadThongKe();
                  },
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildCustomDropdown(
                  label: "Năm",
                  value: selectedYear,
                  items: List.generate(5, (index) {
                    int year = DateTime.now().year - 4 + index;
                    return DropdownMenuItem(
                      value: year,
                      child: Text("$year"),
                    );
                  }),
                  onChanged: (value) {
                    setState(() {
                      selectedYear = value!;
                    });
                    _animationController.reset();
                    loadThongKe();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCustomDropdown({
    required String label,
    required int value,
    required List<DropdownMenuItem<int>> items,
    required Function(int?) onChanged,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Color(0xFFE0E6ED)),
        borderRadius: BorderRadius.circular(12),
        color: Color(0xFFF8F9FA),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: value,
          items: items,
          onChanged: onChanged,
          icon: Icon(Icons.keyboard_arrow_down, color: Color(0xFFFF8C42)),
          style: TextStyle(
            color: Color(0xFF2C3E50),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          isExpanded: true,
        ),
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Container(
      height: 200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF8C42)),
              strokeWidth: 3,
            ),
            SizedBox(height: 16),
            Text(
              "Đang tải dữ liệu...",
              style: TextStyle(
                color: Color(0xFF7F8C8D),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsCards() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            title: "Tổng đơn hàng",
            value: tongDon.toString(),
            icon: Icons.shopping_bag_outlined,
            color: Color(0xFF3498DB),
            gradient: [Color(0xFF3498DB), Color(0xFF2980B9)],
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            title: "Tổng chi tiêu",
            value: NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(tongTien),
            icon: Icons.account_balance_wallet_outlined,
            color: Color(0xFFFF8C42),
            gradient: [Color(0xFFFF8C42), Color(0xFFFF6B35)],
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required List<Color> gradient,
  }) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 15,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
          ),
          SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersList() {
    if (danhSachDon.isEmpty) {
      return Container(
        padding: EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.watch_later_outlined,
                size: 48,
                color: Color(0xFFBDC3C7),
              ),
            ),
            SizedBox(height: 16),
            Text(
              "Chưa có đơn hàng nào",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
              ),
            ),
            SizedBox(height: 8),
            Text(
              "Không có đơn hàng nào trong tháng ${selectedMonth}/${selectedYear}",
              style: TextStyle(
                color: Color(0xFF7F8C8D),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Color(0xFFFF8C42).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.list_alt,
                    color: Color(0xFFFF8C42),
                    size: 20,
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  "Lịch sử đơn hàng",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                  ),
                ),
              ],
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(20, 0, 20, 20),
            itemCount: danhSachDon.length,
            separatorBuilder: (context, index) => SizedBox(height: 12),
            itemBuilder: (context, index) {
              final order = danhSachDon[index];
              return _buildOrderCard(order);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    return InkWell(
      onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChiTietDonHangScreen(donHang: order),
      ),
    );
  },
      child:  Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color(0xFFE0E6ED)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFF8C42), Color(0xFFFF6B35)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.watch,
              color: Colors.white,
              size: 20,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Đơn hàng #${order['orderId']}",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  DateFormat('dd/MM/yyyy - HH:mm').format(order['ngayDat'].toDate()),
                  style: TextStyle(
                    color: Color(0xFF7F8C8D),
                    fontSize: 12,
                  ),
                ),
                SizedBox(height: 8),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Color(0xFFFF8C42).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(order['tongCong']),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFFFF8C42),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            color: Color(0xFFBDC3C7),
          ),
        ],
      ),
    )
    );
  }
}