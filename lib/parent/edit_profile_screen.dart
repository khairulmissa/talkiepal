import 'package:flutter/material.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({
    super.key,
    this.username = "Adam Shah",
  });

  final String username;

  @override
  State<EditProfileScreen> createState() =>
      _EditProfileScreenState();
}

class _EditProfileScreenState
    extends State<EditProfileScreen> {

  final formKey = GlobalKey<FormState>();

  final nameController =
      TextEditingController();

  final emailController =
      TextEditingController(
    text: "adamparent@gmail.com",
  );

  final phoneController =
      TextEditingController();

  final dobController =
      TextEditingController();

  late TextEditingController
      nicknameController;

  @override
  void initState() {
    super.initState();

    nicknameController =
        TextEditingController(
      text: widget.username,
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    nicknameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    dobController.dispose();
    super.dispose();
  }

  void saveProfile() {
    if (formKey.currentState!
        .validate()) {

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            "Profile updated successfully",
          ),
        ),
      );

      Navigator.pop(context);
    }
  }

  Widget inputBox({
    required String label,
    required TextEditingController
        controller,
    bool readOnly = false,
  }) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 12,
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [

          Text(
            "$label:",

            style: const TextStyle(
              fontWeight:
                  FontWeight.bold,
              fontSize: 14,
            ),
          ),

          const SizedBox(height: 5),

          TextFormField(
            controller: controller,
            readOnly: readOnly,

            decoration:
                InputDecoration(
              filled: true,

              fillColor: readOnly
                  ? Colors
                      .grey
                      .shade200
                  : Colors.white,

              contentPadding:
                  const EdgeInsets
                      .symmetric(
                horizontal: 15,
                vertical: 12,
              ),

              border:
                  OutlineInputBorder(
                borderRadius:
                    BorderRadius
                        .circular(
                  25,
                ),

                borderSide:
                    BorderSide.none,
              ),
            ),

            validator: (value) {
              if (readOnly) {
                return null;
              }

              if (value == null ||
                  value.isEmpty) {
                return "$label is required";
              }

              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget navItem(
    IconData icon,
    String label,
  ) {
    return Column(
      mainAxisAlignment:
          MainAxisAlignment.center,

      children: [

        Icon(
          icon,
          size: 28,
          color: Colors.black,
        ),

        Text(
          label,

          style: const TextStyle(
            fontSize: 11,
            fontWeight:
                FontWeight.bold,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFFFFBF4),

      resizeToAvoidBottomInset:
          true,

      body: SafeArea(
        child: Column(
          children: [

            Expanded(
              child: Form(
                key: formKey,

                child:
                    SingleChildScrollView(
                  padding:
                      const EdgeInsets
                          .symmetric(
                    horizontal: 20,
                  ),

                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,

                    children: [

                      const SizedBox(
                        height: 15,
                      ),

                      Row(
                        children: [

                          IconButton(
                            onPressed: () {
                              Navigator.pop(
                                  context);
                            },

                            icon: const Icon(
                              Icons.arrow_back,
                            ),
                          ),

                          const Text(
                            "Edit Profile",

                            style: TextStyle(
                              fontWeight:
                                  FontWeight
                                      .bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(
                        height: 15,
                      ),

                      Center(
                        child: Stack(
                          children: [

                            const CircleAvatar(
                              radius: 60,

                              backgroundImage:
                                  AssetImage(
                                'lib/assets/images/profile.png',
                              ),
                            ),

                            Positioned(
                              bottom: 5,
                              right: 5,

                              child:
                                  GestureDetector(
                                onTap: () {
                                  ScaffoldMessenger.of(
                                          context)
                                      .showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        "Edit picture clicked",
                                      ),
                                    ),
                                  );
                                },

                                child: Container(
                                  padding:
                                      const EdgeInsets
                                          .all(7),

                                  decoration:
                                      const BoxDecoration(
                                    color:
                                        Colors
                                            .black,

                                    shape:
                                        BoxShape
                                            .circle,
                                  ),

                                  child:
                                      const Icon(
                                    Icons
                                        .camera_alt,

                                    color:
                                        Colors
                                            .white,

                                    size: 18,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(
                        height: 25,
                      ),

                      inputBox(
                        label: "Name",
                        controller:
                            nameController,
                      ),

                      inputBox(
                        label: "Username",
                        controller:
                            nicknameController,
                        readOnly: true,
                      ),

                      inputBox(
                        label: "Email",
                        controller:
                            emailController,
                        readOnly: true,
                      ),

                      inputBox(
                        label:
                            "Phone Number",
                        controller:
                            phoneController,
                      ),

                      inputBox(
                        label:
                            "Date of Birth",
                        controller:
                            dobController,
                      ),

                      const SizedBox(
                        height: 15,
                      ),

                      SizedBox(
                        width:
                            double.infinity,
                        height: 48,

                        child:
                            ElevatedButton(
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
                              saveProfile,

                          child:
                              const Text(
                            "Save Changes",

                            style:
                                TextStyle(
                              color: Colors
                                  .white,

                              fontWeight:
                                  FontWeight
                                      .bold,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(
                        height: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            Container(
              height: 65,
              color: Colors.white,

              child: Row(
                mainAxisAlignment:
                    MainAxisAlignment
                        .spaceAround,

                children: [

                  navItem(
                    Icons.home,
                    "Home",
                  ),

                  navItem(
                    Icons.bar_chart,
                    "Progress",
                  ),

                  navItem(
                    Icons
                        .medical_services,
                    "Therapist",
                  ),

                  navItem(
                    Icons.person,
                    "Profile",
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}