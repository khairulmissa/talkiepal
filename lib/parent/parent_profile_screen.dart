import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'edit_profile_screen.dart';
import 'change_password_screen.dart';

class ParentProfileScreen extends StatefulWidget {
  const ParentProfileScreen({super.key});

  @override
  State<ParentProfileScreen> createState() => _ParentProfileScreenState();
}

class _ParentProfileScreenState extends State<ParentProfileScreen> {
  bool isNotificationOn = true;

  void showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            "Logout",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text(
            "Are you sure you want to logout?",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text(
                "Cancel",
                style: TextStyle(color: Colors.grey),
              ),
            ),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              onPressed: () {
                Navigator.pop(context);

                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LoginScreen(),
                  ),
                  (route) => false,
                );
              },
              child: const Text(
                "Logout",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget profileTile(
    IconData icon,
    String title, {
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon),
        title: Text(title),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 18,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF4),

      appBar: AppBar(
        backgroundColor: const Color(0xFFFFEFA8),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Parent Profile",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),

            CircleAvatar(
              radius: 55,
              backgroundColor: Colors.yellowAccent.shade100,
              child: const Icon(
                Icons.person,
                size: 60,
                color: Colors.black54,
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              "Adam Shah",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 5),

            const Text(
              "adamshah@gmail.com",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 35),

            profileTile(
              Icons.person,
              "Edit Profile",

              onTap: () {
                Navigator.push(
                  context,

                  MaterialPageRoute(
                    builder: (context) =>
                        const EditProfileScreen(),
                  ),
                );
              },
            ),

            profileTile(
              Icons.lock,
              "Change Password",

              onTap: () {
                Navigator.push(
                  context,

                  MaterialPageRoute(
                    builder: (context) =>
                        const ChangePasswordScreen(),
                  ),
                );
              },
            ),

            profileTile(
              Icons.child_care,
              "Manage Children",
            ),

            Container(
              margin: const EdgeInsets.only(bottom: 15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
              ),
              child: ListTile(
                leading: const Icon(Icons.notifications),
                title: const Text("Notifications"),
                trailing: Switch(
                  value: isNotificationOn,
                  activeThumbColor: Colors.green,
                  onChanged: (value) {
                    setState(() {
                      isNotificationOn = value;
                    });
                  },
                ),
              ),
            ),

            profileTile(
              Icons.logout,
              "Logout",
              onTap: showLogoutConfirmation,
            ),
          ],
        ),
      ),
    );
  }
}