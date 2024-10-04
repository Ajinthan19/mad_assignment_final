import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:battery_plus/battery_plus.dart';

class ProfilePage extends StatefulWidget {
  final String userName;

  ProfilePage({required this.userName});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String email = '';
  String phoneNumber = '';
  String fullName = '';
  String address = '';
  String profilePictureUrl = '';
  bool isLoading = true;
  int? batteryLevel;

  @override
  void initState() {
    super.initState();
    fetchUserDetails();
    _getBatteryLevel();
  }

  Future<void> fetchUserDetails() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    final response = await http.get(
      Uri.parse('http://192.168.1.2:8000/api/customer/details'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        fullName = data['full_name'] ?? 'N/A';
        email = data['email'] ?? 'N/A';
        phoneNumber = data['phone_number'] ?? 'N/A';
        address = data['address'] ?? 'N/A';
        profilePictureUrl = data['profile_picture'] ?? '';
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
      print('Failed to load user details: ${response.body}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load user details')),
      );
    }
  }

  Future<void> _getBatteryLevel() async {
    Battery battery = Battery();
    try {
      int level = await battery.batteryLevel;
      setState(() {
        batteryLevel = level;
      });
    } catch (e) {
      setState(() {
        batteryLevel = null;
      });
      print('Error getting battery level: $e');
    }
  }

  Future<void> _editProfilePicture() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        profilePictureUrl = image.path;
      });
    }
  }

  void _shareApp() {
    Share.share('Check out this amazing app!');
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      appBar: AppBar(
        title: Text('Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.indigo,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'User Profile',
              style: TextStyle(fontSize: isLandscape ? 24 : 28, fontWeight: FontWeight.bold, color: Colors.indigo),
            ),
            SizedBox(height: screenHeight * 0.03),
            Center(
              child: GestureDetector(
                onTap: _editProfilePicture,
                child: CircleAvatar(
                  radius: isLandscape ? screenHeight * 0.1 : screenHeight * 0.12,
                  backgroundImage: profilePictureUrl.isNotEmpty
                      ? NetworkImage(profilePictureUrl)
                      : AssetImage('assets/images/review.png') as ImageProvider,
                  child: profilePictureUrl.isEmpty
                      ? Icon(Icons.camera_alt, size: isLandscape ? 50 : 60, color: Colors.white)
                      : null,
                ),
              ),
            ),
            SizedBox(height: screenHeight * 0.03),
            _buildProfileDetail('Username:', widget.userName, screenWidth),
            _buildProfileDetail('Full Name:', fullName, screenWidth),
            _buildProfileDetail('Email:', email, screenWidth),
            _buildProfileDetail('Phone Number:', phoneNumber, screenWidth),
            _buildProfileDetail('Address:', address, screenWidth),
            SizedBox(height: screenHeight * 0.02),
            Text(
              'Battery Level: ${batteryLevel != null ? batteryLevel.toString() + '%' : 'N/A'}',
              style: TextStyle(fontSize: screenWidth * 0.04, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: screenHeight * 0.04),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    '/updateProfile',
                    arguments: widget.userName,
                  );
                },
                child: Text('Edit Profile'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.indigo,
                  padding: EdgeInsets.symmetric(
                    vertical: isLandscape ? 14.0 : 16.0,
                    horizontal: isLandscape ? 24.0 : 32.0,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: _shareApp,
                child: Text('Share App'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.indigo,
                  padding: EdgeInsets.symmetric(
                    vertical: isLandscape ? 14.0 : 16.0,
                    horizontal: isLandscape ? 24.0 : 32.0,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileDetail(String title, String detail, double screenWidth) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: screenWidth * 0.04, fontWeight: FontWeight.bold, color: Colors.black54),
          ),
          Flexible(
            child: Text(
              detail,
              style: TextStyle(fontSize: screenWidth * 0.04, fontWeight: FontWeight.normal),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
