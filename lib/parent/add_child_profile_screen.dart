import 'package:flutter/material.dart';

class AddChildProfileScreen extends StatefulWidget {
  const AddChildProfileScreen({super.key});

  @override
  State<AddChildProfileScreen> createState() => _AddChildProfileScreenState();
}

class _AddChildProfileScreenState extends State<AddChildProfileScreen> {
  final formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final birthController = TextEditingController();
  final ageController = TextEditingController();
  final specificProblemController = TextEditingController();

  String? gender;
  String? medicalProblem;
  String? therapyGoal;

  @override
  void dispose() {
    nameController.dispose();
    birthController.dispose();
    ageController.dispose();
    specificProblemController.dispose();
    super.dispose();
  }

  Widget inputBox(String label, TextEditingController controller) {
    return Row(
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: TextFormField(
            controller: controller,
            decoration: const InputDecoration(
              filled: true,
              fillColor: Color(0xFFE0E0E0),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8,
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return "Required";
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget disabledInputBox(String label) {
    return Row(
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: TextFormField(
            enabled: false,
            decoration: const InputDecoration(
              filled: true,
              fillColor: Color(0xFFE0E0E0),
              border: InputBorder.none,
              hintText: "Only if choose Other",
              contentPadding: EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget dropdownBox({
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: DropdownButtonFormField<String>(
            value: value,
            decoration: const InputDecoration(
              filled: true,
              fillColor: Color(0xFFE0E0E0),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 10),
            ),
            hint: const Text("Select"),
            items: items.map((item) {
              return DropdownMenuItem(
                value: item,
                child: Text(item),
              );
            }).toList(),
            onChanged: onChanged,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return "Required";
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  // CHANGED: Now returns the child name and pops with result
  void saveChild() {
    if (medicalProblem != "Other") {
      specificProblemController.clear();
    }

    if (formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Child profile saved"),
        ),
      );

      // Return the child name back to previous screen
      Navigator.pop(context, nameController.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF4),

      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 15),

                      Row(
                        children: [
                          IconButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            icon: const Icon(Icons.arrow_back),
                          ),
                          const Text(
                            "Create Child Profile",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 15),

                      Center(
                        child: Container(
                          width: 120,
                          height: 120,
                          color: const Color(0xFFE0E0E0),
                          child: const Center(
                            child: Text("+ photo"),
                          ),
                        ),
                      ),

                      const SizedBox(height: 25),

                      const Text(
                        "Personal Information",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),

                      const SizedBox(height: 8),

                      inputBox("Name", nameController),
                      const SizedBox(height: 8),

                      inputBox("Birth Date", birthController),
                      const SizedBox(height: 8),

                      inputBox("Age", ageController),
                      const SizedBox(height: 8),

                      dropdownBox(
                        label: "Gender",
                        value: gender,
                        items: const ["Male", "Female"],
                        onChanged: (value) {
                          setState(() {
                            gender = value;
                          });
                        },
                      ),

                      const SizedBox(height: 25),

                      const Text(
                        "Speech Information",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),

                      const SizedBox(height: 8),

                      dropdownBox(
                        label: "Medical Problem",
                        value: medicalProblem,
                        items: const [
                          "Speech Delay",
                          "Articulation Disorder",
                          "Autism",
                          "Other",
                        ],
                        onChanged: (value) {
                          setState(() {
                            medicalProblem = value;

                            if (medicalProblem != "Other") {
                              specificProblemController.clear();
                            }
                          });
                        },
                      ),

                      const SizedBox(height: 8),

                      if (medicalProblem == "Other")
                        inputBox(
                          "Specific Problem",
                          specificProblemController,
                        )
                      else
                        disabledInputBox("Specific Problem"),

                      const SizedBox(height: 8),

                      dropdownBox(
                        label: "Therapy Goal",
                        value: therapyGoal,
                        items: const [
                          "Improve Pronunciation",
                          "Improve Vocabulary",
                          "Improve Communication",
                          "Practice R/S/L Sounds",
                          "Build Confidence",
                        ],
                        onChanged: (value) {
                          setState(() {
                            therapyGoal = value;
                          });
                        },
                      ),

                      const SizedBox(height: 35),

                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD6D600),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 45,
                              vertical: 14,
                            ),
                          ),
                          onPressed: saveChild,
                          child: const Text(
                            "Save",
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),

            Container(
              height: 65,
              color: Colors.white,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  BottomNavItem(icon: Icons.home, label: "Home"),
                  BottomNavItem(icon: Icons.bar_chart, label: "Progress"),
                  BottomNavItem(
                    icon: Icons.medical_services,
                    label: "Therapist",
                  ),
                  BottomNavItem(icon: Icons.person, label: "Profile"),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BottomNavItem extends StatelessWidget {
  const BottomNavItem({
    super.key,
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 28, color: Colors.black),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}