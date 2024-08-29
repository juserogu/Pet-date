import 'package:flutter/material.dart';
import 'package:pet_date/presentation/viewmodels/auth_viewmodel.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.pinkAccent,
        title: Text("PetLove"),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await authViewModel.signOut();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final users = snapshot.data!.docs;

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];

              // No mostrar el perfil del usuario autenticado
              if (user.id == authViewModel.user?.uid) {
                return SizedBox.shrink();
              }

              return ListTile(
                title: Text(user['name']),
                subtitle: Text(user['email']),
                leading: CircleAvatar(
                  child: Text(user['name'][0]),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.thumb_up, color: Colors.green),
                      onPressed: () async {
                        await likeUser(authViewModel.user!.uid, user.id);
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.thumb_down, color: Colors.red),
                      onPressed: () async {
                        await dislikeUser(authViewModel.user!.uid, user.id);
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> likeUser(String currentUserId, String likedUserId) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .collection('likes')
        .doc(likedUserId)
        .set({});
  }

  Future<void> dislikeUser(String currentUserId, String dislikedUserId) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .collection('dislikes')
        .doc(dislikedUserId)
        .set({});
  }
}
