import 'package:flutter/material.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState
    extends State<ForgotPasswordScreen> {

  final formKey = GlobalKey<FormState>();

  final emailController =
      TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  void resetPassword() {
    if (formKey.currentState!.validate()) {

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            "Password reset link sent to email",
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
          "Forgot Password",

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
        padding:
            const EdgeInsets.all(25),

        child: Form(
          key: formKey,

          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [

              const SizedBox(height: 40),

              const Text(
                "Enter your email address",

                style: TextStyle(
                  fontSize: 20,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                "Please enter your valid email account",

                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),

              const SizedBox(height: 35),

              TextFormField(
                controller:
                    emailController,

                keyboardType:
                    TextInputType
                        .emailAddress,

                decoration:
                    InputDecoration(
                  hintText: "Email",

                  prefixIcon:
                      const Icon(
                    Icons.email_outlined,
                  ),

                  filled: true,
                  fillColor:
                      Colors.white,

                  border:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius
                            .circular(
                      30,
                    ),
                  ),
                ),

                validator: (value) {
                  if (value == null ||
                      value.isEmpty) {
                    return "Email is required";
                  }

                  if (!value
                      .contains('@')) {
                    return "Enter valid email";
                  }

                  return null;
                },
              ),

              const SizedBox(height: 35),

              SizedBox(
                width: double.infinity,

                height: 50,

                child: ElevatedButton(
                  style:
                      ElevatedButton
                          .styleFrom(
                    backgroundColor:
                        const Color(
                      0xFFD6D600,
                    ),

                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius
                              .circular(
                        30,
                      ),
                    ),
                  ),

                  onPressed:
                      resetPassword,

                  child: const Text(
                    "Confirm",

                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight:
                          FontWeight
                              .bold,
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