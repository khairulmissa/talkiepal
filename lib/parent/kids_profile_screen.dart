import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'add_child_profile_screen.dart';
import '../main.dart'; 

class KidsProfileScreen extends StatefulWidget {
  const KidsProfileScreen({super.key});

  @override
  State<KidsProfileScreen> createState() =>
      _KidsProfileScreenState();
}

class _KidsProfileScreenState
    extends State<KidsProfileScreen> {

  List<String> kids = [
    "Khairulmissa",
  ];

  void addKid() {
    if (kids.length >= 5) {

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            "Maximum 5 kids profile only",
          ),
        ),
      );

      return;
    }

    setState(() {
      kids.add(
        "New Kid ${kids.length + 1}",
      );
    });
  }

  Widget star(double size) {
    return Icon(
      Icons.star,
      color: const Color(0xFFFFEFA8),
      size: size,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFFFFBF4),

      body: SafeArea(
        child: Stack(
          children: [

            // STAR TOP RIGHT
            Positioned(
              top: -30,
              right: -25,
              child: star(120),
            ),

            // STAR LEFT
            Positioned(
              left: -45,
              top: 260,
              child: star(140),
            ),

            // STAR BOTTOM RIGHT
            Positioned(
              right: -45,
              bottom: 80,
              child: star(150),
            ),

            Padding(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 25,
              ),

              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [

                  const SizedBox(height: 45),

                  // TITLE
                  Center(
                    child: Text(
                      "CHOOSE KIDS\nPROFILE",

                      textAlign:
                          TextAlign.center,

                      style:
                          GoogleFonts.hennyPenny(
                        color:
                            const Color(
                          0xFFD6D600,
                        ),

                        fontSize: 28,
                      ),
                    ),
                  ),

                  const SizedBox(height: 55),

                  // KIDS LIST - CHANGED: Now each kid is clickable to go to HomePage
                  ...kids.map(
                    (kidName) =>
                        GestureDetector(  // ADD GestureDetector
                      onTap: () {
                        // Navigate to HomePage with the selected kid name
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => HomePage(selectedKidName: kidName),  // Pass kid name
                          ),
                        );
                      },
                      child: Padding(
                        padding:
                            const EdgeInsets.only(
                          bottom: 25,
                        ),

                        child: Row(
                          children: [

                            // KID PROFILE BOX
                            Container(
                              width: 100,
                              height: 100,

                              decoration:
                                  BoxDecoration(
                                color:
                                    Colors.white,

                                borderRadius:
                                    BorderRadius
                                        .circular(
                                  12,
                                ),

                                boxShadow: const [
                                  BoxShadow(
                                    color:
                                        Colors
                                            .black26,

                                    blurRadius:
                                        4,

                                    offset:
                                        Offset(
                                      1,
                                      2,
                                    ),
                                  ),
                                ],
                              ),

                              child:
                                  ClipRRect(
                                borderRadius:
                                    BorderRadius
                                        .circular(
                                  12,
                                ),

                                child:
                                    Image.asset(
                                  'lib/assets/images/kid_profile.png',

                                  fit: BoxFit
                                      .cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(Icons.person, size: 50);
                                  },
                                ),
                              ),
                            ),

                            const SizedBox(
                              width: 20,
                            ),

                            Text(
                              kidName,

                              style:
                                  const TextStyle(
                                fontSize: 20,
                                fontWeight:
                                    FontWeight
                                        .bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // ADD PROFILE BUTTON
                  GestureDetector(
                    onTap: () async {
                      if (kids.length >= 5) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Maximum 5 kids profile only"),
                          ),
                        );
                        return;
                      }

                      final newKidName = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddChildProfileScreen(),
                        ),
                      );

                      // If we got a name back from add screen, add it to the list
                      if (newKidName != null && newKidName.toString().isNotEmpty) {
                        setState(() {
                          kids.add(newKidName.toString());
                        });
                      }
                    },

                    child: Container(
                      width: 100,
                      height: 100,

                      decoration:
                          BoxDecoration(
                        color: Colors.white,

                        borderRadius:
                            BorderRadius
                                .circular(
                          12,
                        ),

                        boxShadow: const [
                          BoxShadow(
                            color:
                                Colors
                                    .black26,

                            blurRadius: 4,

                            offset:
                                Offset(
                              1,
                              2,
                            ),
                          ),
                        ],
                      ),

                      child: const Icon(
                        Icons.add,
                        size: 45,
                        color: Colors.black,
                      ),
                    ),
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