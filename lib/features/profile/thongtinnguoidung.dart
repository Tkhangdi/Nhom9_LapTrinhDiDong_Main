import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
import 'package:shop_ban_dong_ho/core/utils/app_colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class MyAccountScreen extends StatefulWidget {
  const MyAccountScreen({super.key});

  @override
  _MyAccountScreenState createState() => _MyAccountScreenState();
}

class _MyAccountScreenState extends State<MyAccountScreen> {
  // Thông tin người dùng
  String userName = "";
  String userEmail = "";
  String userPhone = "";
  String userAddress = "";
  String userGender = "Nam";
  String userPassword = "";
  String userId = "";
  String avatarUrl = "assets/images/default.png"; // Đường dẫn avatar mặc định
  bool isLoading = true;
  
  File? _profileImage;
  bool isPasswordHidden = true;
  final ImagePicker _picker = ImagePicker();
  
  // Tab controller cho các loại thông tin
  int _selectedTabIndex = 0;
  final List<String> _tabs = ["Thông tin", "Bảo mật", "Tùy chọn"];

  // Controllers cho phép chỉnh sửa trực tiếp
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _emailController;
  
  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _addressController = TextEditingController();
    _emailController = TextEditingController();
    
    // Load thông tin người dùng từ Firebase
    _loadUserData();
  }
  
  // Phương thức lấy thông tin người dùng từ Firebase
  Future<void> _loadUserData() async {
    try {
      // Lấy người dùng hiện tại từ Firebase Auth
      User? currentUser = FirebaseAuth.instance.currentUser;
      
      if (currentUser != null) {
        // Truy vấn thông tin chi tiết từ Firestore bằng UID của người dùng hiện tại
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('khachhang')
            .doc(currentUser.uid)
            .get();
            
        if (userDoc.exists) {
          Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
            setState(() {
            userName = userData['hotenkh'] ?? "";
            userEmail = userData['email'] ?? "";
            userPhone = userData['sdt'] ?? "";
            userAddress = userData['diachi'] ?? "";
            userGender = userData['gioitinh'] ?? "Nam";
            userPassword = userData['matkhau'] ?? "";
            userId = userData['id'] ?? "";
            avatarUrl = userData['avatarUrl'] ?? "assets/images/default.png";
            
            // Cập nhật controllers
            _nameController.text = userName;
            _phoneController.text = userPhone;
            _addressController.text = userAddress;
            _emailController.text = userEmail;
            
            isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Lỗi khi tải thông tin người dùng: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _emailController.dispose();
    super.dispose();
  }
  Future<void> _getImage() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: Icon(Icons.photo_library, color: AppColors.primary),
                title: const Text('Chọn từ thư viện'),
                onTap: () async {
                  Navigator.of(context).pop();
                  final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
                  if (image != null) {
                    setState(() {
                      _profileImage = File(image.path);
                    });
                    // Upload ảnh lên Firebase Storage và cập nhật avatarUrl
                    await _uploadImageToFirebase(File(image.path));
                  }
                },
              ),
              ListTile(
                leading: Icon(Icons.camera_alt, color: AppColors.primary),
                title: const Text('Chụp ảnh mới'),
                onTap: () async {
                  Navigator.of(context).pop();
                  final XFile? image = await _picker.pickImage(source: ImageSource.camera);
                  if (image != null) {
                    setState(() {
                      _profileImage = File(image.path);
                    });
                    // Upload ảnh lên Firebase Storage và cập nhật avatarUrl
                    await _uploadImageToFirebase(File(image.path));
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }
  
  // Phương thức upload ảnh lên Firebase Storage
  Future<void> _uploadImageToFirebase(File imageFile) async {
    try {
      // Hiển thị loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: Center(
              child: CircularProgressIndicator(),
            ),
          );
        },
      );
      
      User? currentUser = FirebaseAuth.instance.currentUser;
      
      if (currentUser != null) {
        // Tạo reference đến Firebase Storage
        final storageRef = FirebaseStorage.instance.ref();
        
        // Tạo tên file duy nhất cho avatar
        String fileName = 'avatars/${currentUser.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        
        // Upload file lên Firebase Storage
        final uploadTask = await storageRef.child(fileName).putFile(
          imageFile,
          SettableMetadata(contentType: 'image/jpeg'),
        );
        
        // Lấy URL download của file
        final downloadUrl = await uploadTask.ref.getDownloadURL();
        
        // Cập nhật URL avatar vào Firestore
        await FirebaseFirestore.instance
            .collection('khachhang')
            .doc(currentUser.uid)
            .update({
              'avatarUrl': downloadUrl,
            });
            
        // Cập nhật state
        setState(() {
          avatarUrl = downloadUrl;
        });
        
        // Đóng dialog loading
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
        
        // Hiển thị thông báo thành công
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cập nhật ảnh đại diện thành công')),
        );
      }
    } catch (e) {
      // Đóng dialog loading nếu có lỗi
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      
      print('Lỗi khi upload ảnh: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi cập nhật ảnh đại diện: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Hồ Sơ Cá Nhân"),
          backgroundColor: AppColors.primary,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    return Scaffold(
      backgroundColor: Colors.grey[100],
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "Hồ Sơ Cá Nhân",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Gradient header with profile image
            Container(
              padding: EdgeInsets.only(
                bottom: 30.0, 
                top: MediaQuery.of(context).padding.top + 60
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary,
                    AppColors.primary.withOpacity(0.8),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    spreadRadius: 2,
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
              ),
              child: Column(
                children: [
                  Hero(
                    tag: 'profile_image',
                    child: GestureDetector(
                      onTap: _getImage,
                      child: Stack(
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 4,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  spreadRadius: 2,
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),                            child: ClipOval(
                              child: _profileImage != null
                                  ? Image.file(_profileImage!, fit: BoxFit.cover)
                                  : (avatarUrl.startsWith('http') || avatarUrl.startsWith('https')
                                      ? Image.network(
                                          avatarUrl,
                                          fit: BoxFit.cover,
                                          loadingBuilder: (context, child, loadingProgress) {
                                            if (loadingProgress == null) return child;
                                            return Center(
                                              child: CircularProgressIndicator(
                                                value: loadingProgress.expectedTotalBytes != null
                                                    ? loadingProgress.cumulativeBytesLoaded / 
                                                      (loadingProgress.expectedTotalBytes ?? 1)
                                                    : null,
                                              ),
                                            );
                                          },
                                          errorBuilder: (context, error, stackTrace) {
                                            return Image.asset(
                                              "assets/images/default.png",
                                              fit: BoxFit.cover,
                                            );
                                          },
                                        )
                                      : Image.asset(
                                          avatarUrl,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Image.asset(
                                              "assets/images/default.png",
                                              fit: BoxFit.cover,
                                            );
                                          },
                                        )),
                            ),
                          ),
                          Positioned(
                            right: 5,
                            bottom: 5,
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    spreadRadius: 1,
                                    blurRadius: 5,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.camera_alt,
                                color: AppColors.primary,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    userName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          offset: Offset(0, 1),
                          blurRadius: 2,
                          color: Color.fromRGBO(0, 0, 0, 0.3),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white30,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      userEmail,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Custom Tab Bar
            Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                child: Row(
                  children: List.generate(
                    _tabs.length,
                    (index) => Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedTabIndex = index;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _selectedTabIndex == index
                                ? AppColors.primary
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Center(
                            child: Text(
                              _tabs[index],
                              style: TextStyle(
                                color: _selectedTabIndex == index
                                    ? Colors.white
                                    : Colors.grey[600],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            
            // Tab Content
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _buildTabContent(),
            ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, -1),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _saveUserInfo,
                  icon: const Icon(Icons.save_outlined),
                  label: const Text("Lưu thông tin"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildTabContent() {
    switch (_selectedTabIndex) {
      case 0:
        return _buildPersonalInfoTab();
      case 1:
        return _buildSecurityTab();
      case 2:
        return _buildPreferencesTab();
      default:
        return _buildPersonalInfoTab();
    }
  }

  Widget _buildPersonalInfoTab() {
    return Container(
      key: const ValueKey('personal_info'),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _buildInfoCard(
            "Họ và tên",
            _buildTextField(
              _nameController, 
              (value) => setState(() => userName = value),
              prefixIcon: Icons.person_outline,
            ),
          ),
          _buildInfoCard(
            "Số điện thoại",
            _buildTextField(
              _phoneController, 
              (value) => setState(() => userPhone = value),
              prefixIcon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
            ),
          ),
          _buildInfoCard(
            "Địa chỉ",
            _buildTextField(
              _addressController, 
              (value) => setState(() => userAddress = value),
              prefixIcon: Icons.location_on_outlined,
              maxLines: 2,
            ),
          ),
          _buildInfoCard(
            "Email",
            _buildTextField(
              _emailController, 
              (value) => setState(() => userEmail = value),
              prefixIcon: Icons.email_outlined,
              enabled: false,
              keyboardType: TextInputType.emailAddress,
            ),
          ),
          _buildInfoCard(
            "Giới tính",
            _buildSelectionField(
              userGender,
              _showGenderSelection,
              prefixIcon: Icons.people_outline,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityTab() {
    return Container(
      key: const ValueKey('security'),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _buildInfoCard(
            "Đổi mật khẩu",
            _buildActionField(
              "Cập nhật mật khẩu của bạn",
              _showChangePasswordDialog,
              prefixIcon: Icons.lock_outline,
              actionIcon: Icons.chevron_right,
            ),
          ),
          _buildInfoCard(
            "Xác thực hai yếu tố",
            _buildSwitchField(
              "Bảo vệ tài khoản bằng xác thực hai yếu tố",
              false,
              (value) {
                // Xử lý khi người dùng bật/tắt xác thực 2 yếu tố
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      value 
                          ? 'Đã bật xác thực hai yếu tố' 
                          : 'Đã tắt xác thực hai yếu tố'
                    ),
                  ),
                );
              },
              prefixIcon: Icons.security_outlined,
            ),
          ),
          _buildInfoCard(
            "Đăng xuất trên tất cả thiết bị",
            _buildActionField(
              "Đăng xuất khỏi tất cả các thiết bị khác",
              () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text("Xác nhận"),
                    content: const Text(
                      "Bạn có chắc chắn muốn đăng xuất khỏi tất cả các thiết bị khác không?",
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text("Hủy"),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Đã đăng xuất khỏi tất cả các thiết bị khác'),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                        ),
                        child: const Text("Xác nhận"),
                      ),
                    ],
                  ),
                );
              },
              prefixIcon: Icons.logout_outlined,
              actionIcon: Icons.chevron_right,
            ),
          ),
          _buildInfoCard(
            "Xóa tài khoản",
            _buildActionField(
              "Xóa vĩnh viễn tài khoản của bạn",
              () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text("Cảnh báo"),
                    content: const Text(
                      "Hành động này sẽ xóa vĩnh viễn tài khoản của bạn và tất cả dữ liệu liên quan. Bạn có chắc chắn muốn tiếp tục?",
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text("Hủy"),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          // Logic xóa tài khoản
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        child: const Text("Xác nhận"),
                      ),
                    ],
                  ),
                );
              },
              prefixIcon: Icons.delete_outline,
              actionIcon: Icons.chevron_right,
              textColor: Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferencesTab() {
    return Container(
      key: const ValueKey('preferences'),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _buildInfoCard(
            "Thông báo",
            _buildSwitchField(
              "Nhận thông báo về sản phẩm và ưu đãi",
              true,
              (value) {
                // Xử lý khi người dùng bật/tắt thông báo
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      value 
                          ? 'Đã bật thông báo' 
                          : 'Đã tắt thông báo'
                    ),
                  ),
                );
              },
              prefixIcon: Icons.notifications_outlined,
            ),
          ),
          _buildInfoCard(
            "Chế độ tối",
            _buildSwitchField(
              "Sử dụng giao diện tối",
              false,
              (value) {
                // Xử lý khi người dùng bật/tắt chế độ tối
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      value 
                          ? 'Đã bật chế độ tối' 
                          : 'Đã tắt chế độ tối'
                    ),
                  ),
                );
              },
              prefixIcon: Icons.dark_mode_outlined,
            ),
          ),
          _buildInfoCard(
            "Ngôn ngữ",
            _buildActionField(
              "Tiếng Việt",
              () {
                // Hiển thị bottom sheet để chọn ngôn ngữ
                showModalBottomSheet(
                  context: context,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  builder: (context) => Container(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(bottom: 20),
                          child: Text(
                            "Chọn ngôn ngữ",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                        ListTile(
                          leading: const Icon(Icons.check, color: Colors.green),
                          title: const Text("Tiếng Việt"),
                          onTap: () => Navigator.pop(context),
                        ),
                        ListTile(
                          title: const Text("English"),
                          onTap: () {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Đã chuyển sang tiếng Anh')),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
              prefixIcon: Icons.language_outlined,
              actionIcon: Icons.chevron_right,
            ),
          ),
          _buildInfoCard(
            "Đăng xuất",
            _buildActionField(
              "Đăng xuất khỏi tài khoản",
              () async {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text("Đăng xuất"),
                    content: const Text("Bạn có chắc chắn muốn đăng xuất?"),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text("Hủy"),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          Navigator.of(context).pop();
                          // Xử lý đăng xuất
                          await FirebaseAuth.instance.signOut();
                          
                          // Quay về màn hình đăng nhập
                          Navigator.of(context).popUntil((route) => route.isFirst);
                          
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Đăng xuất thành công')),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        child: const Text("Đăng xuất"),
                      ),
                    ],
                  ),
                );
              },
              prefixIcon: Icons.exit_to_app,
              actionIcon: Icons.chevron_right,
              textColor: Colors.red,
            ),
          ),
          _buildInfoCard(
            "Phiên bản",
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.grey[600],
                    size: 22,
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    "Phiên bản ứng dụng: 1.0.0",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, Widget content) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
          Divider(color: Colors.grey[100]),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: content,
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    Function(String) onChanged, {
    bool enabled = true,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    IconData? prefixIcon,
  }) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      enabled: enabled,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: TextStyle(
        fontSize: 16,
        color: enabled ? Colors.black87 : Colors.grey,
      ),
      decoration: InputDecoration(
        prefixIcon: prefixIcon != null 
            ? Icon(prefixIcon, color: enabled ? AppColors.primary : Colors.grey) 
            : null,
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        isDense: true,
        border: InputBorder.none,
        hintStyle: TextStyle(color: Colors.grey[400]),
      ),
    );
  }

  Widget _buildSelectionField(
    String value, 
    VoidCallback onTap, {
    IconData? prefixIcon,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            if (prefixIcon != null) ...[
              Icon(prefixIcon, color: AppColors.primary),
              const SizedBox(width: 16),
            ],
            Expanded(
              child: Text(
                value,
                style: const TextStyle(fontSize: 16),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey[400],
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionField(
    String description, 
    VoidCallback onTap, {
    IconData? prefixIcon,
    IconData? actionIcon,
    Color? textColor,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            if (prefixIcon != null) ...[
              Icon(
                prefixIcon, 
                color: textColor ?? AppColors.primary,
                size: 22,
              ),
              const SizedBox(width: 16),
            ],
            Expanded(
              child: Text(
                description,
                style: TextStyle(
                  fontSize: 16,
                  color: textColor,
                ),
              ),
            ),
            if (actionIcon != null)
              Icon(
                actionIcon,
                color: textColor ?? Colors.grey[400],
                size: 18,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchField(
    String description, 
    bool value, 
    Function(bool) onChanged, {
    IconData? prefixIcon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          if (prefixIcon != null) ...[
            Icon(prefixIcon, color: AppColors.primary, size: 22),
            const SizedBox(width: 16),
          ],
          Expanded(
            child: Text(
              description,
              style: const TextStyle(fontSize: 16),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.white,
            activeTrackColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  void _showGenderSelection() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Chọn giới tính",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    splashRadius: 20,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(),
              _buildGenderOption("Nam", "Nam"),
              _buildGenderOption("Nữ", "Nữ"),
              _buildGenderOption("Khác", "Khác"),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGenderOption(String label, String value) {
    final bool isSelected = userGender == value;
    
    return InkWell(
      onTap: () {
        setState(() => userGender = value);
        Navigator.pop(context);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.primary : Colors.grey,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                color: isSelected ? AppColors.primary : Colors.black87,
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showChangePasswordDialog() {
    final TextEditingController currentPasswordController = TextEditingController();
    final TextEditingController newPasswordController = TextEditingController();
    final TextEditingController confirmPasswordController = TextEditingController();
    
    bool _currentPasswordVisible = false;
    bool _newPasswordVisible = false;
    bool _confirmPasswordVisible = false;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Đổi mật khẩu",
                    style: TextStyle(fontSize: 20),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Mật khẩu hiện tại",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: currentPasswordController,
                      obscureText: !_currentPasswordVisible,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.primary),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        hintText: "Nhập mật khẩu hiện tại",
                        suffixIcon: IconButton(
                          icon: Icon(
                            _currentPasswordVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: Colors.grey,
                            size: 20,
                          ),
                          onPressed: () {
                            setDialogState(() {
                              _currentPasswordVisible = !_currentPasswordVisible;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "Mật khẩu mới",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: newPasswordController,
                      obscureText: !_newPasswordVisible,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.primary),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        hintText: "Nhập mật khẩu mới",
                        suffixIcon: IconButton(
                          icon: Icon(
                            _newPasswordVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: Colors.grey,
                            size: 20,
                          ),
                          onPressed: () {
                            setDialogState(() {
                              _newPasswordVisible = !_newPasswordVisible;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "Xác nhận mật khẩu mới",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: confirmPasswordController,
                      obscureText: !_confirmPasswordVisible,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.primary),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        hintText: "Xác nhận mật khẩu mới",
                        suffixIcon: IconButton(
                          icon: Icon(
                            _confirmPasswordVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: Colors.grey,
                            size: 20,
                          ),
                          onPressed: () {
                            setDialogState(() {
                              _confirmPasswordVisible = !_confirmPasswordVisible;
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          // Kiểm tra thông tin mật khẩu và xử lý đổi mật khẩu
                          if (newPasswordController.text.isEmpty || 
                              newPasswordController.text.length < 6) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Mật khẩu mới phải có ít nhất 6 ký tự!'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                            return;
                          }
                          
                          if (newPasswordController.text != confirmPasswordController.text) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Mật khẩu mới không khớp!'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                            return;
                          }
                          
                          // Hiển thị loading
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (context) => const Dialog(
                              backgroundColor: Colors.transparent,
                              elevation: 0,
                              child: Center(child: CircularProgressIndicator()),
                            ),
                          );
                          
                          try {
                            // Lấy người dùng hiện tại
                            User? currentUser = FirebaseAuth.instance.currentUser;
                            
                            if (currentUser != null) {
                              // Xác thực lại người dùng với mật khẩu hiện tại
                              AuthCredential credential = EmailAuthProvider.credential(
                                email: userEmail, 
                                password: currentPasswordController.text
                              );
                              
                              // Xác thực lại người dùng trước khi đổi mật khẩu
                              await currentUser.reauthenticateWithCredential(credential);
                              
                              // Cập nhật mật khẩu trong Firebase Authentication
                              await currentUser.updatePassword(newPasswordController.text);
                              
                              // Cập nhật mật khẩu trong Firestore
                              await FirebaseFirestore.instance
                                  .collection('khachhang')
                                  .doc(currentUser.uid)
                                  .update({'matkhau': newPasswordController.text});
                              
                              // Cập nhật state
                              setState(() {
                                userPassword = newPasswordController.text;
                              });
                              
                              // Đóng dialog loading
                              Navigator.pop(context);
                              
                              // Đóng dialog đổi mật khẩu
                              Navigator.pop(context);
                              
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Đổi mật khẩu thành công!'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          } catch (e) {
                            // Đóng dialog loading
                            Navigator.pop(context);
                            
                            String errorMessage = 'Đã xảy ra lỗi khi đổi mật khẩu';
                            if (e is FirebaseAuthException) {
                              if (e.code == 'wrong-password') {
                                errorMessage = 'Mật khẩu hiện tại không đúng!';
                              } else {
                                errorMessage = 'Lỗi: ${e.message}';
                              }
                            }
                            
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(errorMessage),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text(
                          "Cập nhật mật khẩu",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            );
          },
        );
      },
    );
  }

  Future<void> _saveUserInfo() async {
    // Hiển thị loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
    );
    
    try {
      // Lấy người dùng hiện tại từ Firebase Auth
      User? currentUser = FirebaseAuth.instance.currentUser;
      
      if (currentUser != null) {
        // Cập nhật thông tin người dùng trong Firestore
        await FirebaseFirestore.instance
            .collection('khachhang')
            .doc(currentUser.uid)
            .update({
              'hotenkh': _nameController.text,
              'sdt': _phoneController.text,
              'diachi': _addressController.text,
              'gioitinh': userGender,
            });
            
        // Cập nhật trạng thái nội bộ
        setState(() {
          userName = _nameController.text;
          userPhone = _phoneController.text;
          userAddress = _addressController.text;
        });
        
        // Đóng dialog loading
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
        
        // Hiển thị thông báo thành công
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.green,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "Cập nhật thành công",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Thông tin cá nhân của bạn đã được cập nhật",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text(
                          "Đồng ý",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }
    } catch (e) {
      // Đóng dialog loading
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      
      // Hiển thị thông báo lỗi
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi cập nhật thông tin: $e')),
      );
    }
  }
}
