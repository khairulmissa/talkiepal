import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'add_child_profile_screen.dart';
import '../main.dart';

/// Parent must be signed in. Child profiles belong to that parent's account.
class KidsProfileSelectionScreen extends StatelessWidget {
  const KidsProfileSelectionScreen({super.key});

  static const Color cream = Color(0xFFFFFBF4);
  static const Color yellow = Color(0xFFFFEFA8);
  static const Color purple = Color(0xFF8B5E9E);

  Uint8List? _photoBytes(dynamic raw) {
    if (raw is! String || raw.isEmpty) return null;
    try {
      // Accepts plain Base64 and data:image/jpeg;base64,...
      final payload = raw.contains(',') ? raw.split(',').last : raw;
      return base64Decode(payload);
    } catch (_) {
      return null;
    }
  }

  Future<void> _addChild(BuildContext context) async {
    final result = await Navigator.push<Object?>(
      context,
      MaterialPageRoute(builder: (_) => const AddChildProfileScreen()),
    );
    if (!context.mounted) return;
    if (result is Map && result['findTherapist'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Child saved. Therapist search is available from the parent area.')),
      );
    }
    // StreamBuilder refreshes automatically after Firestore saves.
  }

  void _openChild(BuildContext context, String childName) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => HomePage(
        selectedKidName: childName,
      ),
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    final parent = FirebaseAuth.instance.currentUser;
    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        title: const Text('Choose Kids Profile'),
        centerTitle: true,
        backgroundColor: cream,
      ),
      body: parent == null
          ? const Center(child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('Ask your parent to sign in first to access your profiles.', textAlign: TextAlign.center),
            ))
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(parent.uid)
                  .collection('children')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text('Unable to load profiles: ${snapshot.error}', textAlign: TextAlign.center),
                  ));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final children = snapshot.data!.docs.toList()
                  ..sort((a, b) => (a.data()['name'] ?? '').toString()
                      .compareTo((b.data()['name'] ?? '').toString()));
                return LayoutBuilder(builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 620 ? 4 : 2;
                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
                    child: Column(
                      children: [
                        const Icon(Icons.star_rounded, size: 65, color: yellow),
                        const Text('CHOOSE KIDS\nPROFILE',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 29, fontWeight: FontWeight.w600,
                                color: Color(0xFFD6BB00), height: 1.1)),
                        const SizedBox(height: 28),
                        if (children.isEmpty)
                          const Padding(
                            padding: EdgeInsets.only(bottom: 24),
                            child: Text('No child profiles yet. Tap + to create one.', textAlign: TextAlign.center),
                          ),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: columns,
                            mainAxisSpacing: 18,
                            crossAxisSpacing: 16,
                            childAspectRatio: 0.82,
                          ),
                          itemCount: children.length + (children.length < 5 ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == children.length) {
                              return InkWell(
                                onTap: () => _addChild(context),
                                borderRadius: BorderRadius.circular(16),
                                child: Column(children: [
                                  Expanded(child: Container(
                                    width: double.infinity,
                                    decoration: BoxDecoration(color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)]),
                                    child: const Icon(Icons.add, size: 54),
                                  )),
                                  const SizedBox(height: 8),
                                  const Text('Add Child', style: TextStyle(fontWeight: FontWeight.w600)),
                                ]),
                              );
                            }
                            final child = children[index];
                            final data = child.data();
                            final name = (data['name'] ?? 'Child').toString();
                            final bytes = _photoBytes(data['photoBase64']);
                            return InkWell(
                              onTap: () => _openChild(context, name),
                              borderRadius: BorderRadius.circular(16),
                              child: Column(children: [
                                Expanded(child: Container(
                                  width: double.infinity,
                                  clipBehavior: Clip.antiAlias,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE0F1C0),
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                                  ),
                                  child: bytes == null
                                      ? const Icon(Icons.child_care, size: 64, color: purple)
                                      : Image.memory(bytes, fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => const Icon(Icons.child_care, size: 64)),
                                )),
                                const SizedBox(height: 8),
                                Text(name, textAlign: TextAlign.center, maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontWeight: FontWeight.w700)),
                              ]),
                            );
                          },
                        ),
                      ],
                    ),
                  );
                });
              },
            ),
    );
  }
}
