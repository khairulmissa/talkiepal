import 'package:flutter/material.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState
    extends State<ChangePasswordScreen> {

  final formKey = GlobalKey<FormState>();

  final currentPasswordController =
      TextEditingController();

  final newPasswordController =
      TextEditingController();

  final confirmPasswordController =
      TextEditingController();

  @override
  void dispose() {
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Widget passwordField({
    required String label,
    required TextEditingController controller,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [

          Text(
            label,

            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),

          const SizedBox(height: 6),

          TextFormField(
            controller: controller,
            obscureText: true,

            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,

              contentPadding:
                  const EdgeInsets.symmetric(
                horizontal: 15,
                vertical: 14,
              ),

              border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(25),
                borderSide: BorderSide.none,
              ),
            ),

            validator: (value) {
              if (value == null ||
                  value.isEmpty) {
                return "$label is required";
              }

              if (value.length < 6) {
                return "Minimum 6 characters";
              }

              return null;
            },
          ),
        ],
      ),
    );
  }

  void changePassword() {
    if (formKey.currentState!.validate()) {

      if (newPasswordController.text !=
          confirmPasswordController.text) {

        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              "Password does not match",
            ),
          ),
        );

        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            "Password changed successfully",
          ),
        ),
      );

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFFFFBF4),

      appBar: AppBar(
        backgroundColor:
            const Color(0xFFFFEFA8),

        elevation: 0,

        centerTitle: true,

        title: const Text(
          "Change Password",

          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),

        iconTheme:
            const IconThemeData(
          color: Colors.black,
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Form(
          key: formKey,

          child: Column(
            children: [

              const SizedBox(height: 30),

              passwordField(
                label: "Current Password",
                controller:
                    currentPasswordController,
              ),

              passwordField(
                label: "New Password",
                controller:
                    newPasswordController,
              ),

              passwordField(
                label: "Confirm Password",
                controller:
                    confirmPasswordController,
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 50,

                child: ElevatedButton(
                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor:
                        const Color(
                      0xFFD6D600,
                    ),

                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                        30,
                      ),
                    ),
                  ),

                  onPressed:
                      changePassword,

                  child: const Text(
                    "Update Password",

                    style: TextStyle(
                      color: Colors.white,
                      fontWeight:
                          FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}