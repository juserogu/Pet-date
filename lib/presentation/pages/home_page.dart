import 'package:flutter/material.dart';
import 'package:pet_date/presentation/viewmodels/auth_viewmodel.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:card_swiper/card_swiper.dart';
import 'package:pet_date/presentation/widgets/user_card.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late SwiperController _swiperController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _swiperController = SwiperController();
  }

  @override
  void dispose() {
    _swiperController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.pinkAccent,
        elevation: 0,
        title: Text(
          "PetLove",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: Colors.white),
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
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Colors.pinkAccent),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Loading profiles...',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          final users = snapshot.data!.docs
              .where((user) => user.id != authViewModel.user?.uid)
              .toList();

          if (users.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.pets,
                    size: 100,
                    color: Colors.grey[400],
                  ),
                  SizedBox(height: 20),
                  Text(
                    'No more profiles',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Come back later to see new profiles',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[500],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return Stack(
            children: [
              // Swiper de cards
              Swiper(
                controller: _swiperController,
                itemBuilder: (BuildContext context, int index) {
                  final user = users[index];
                  return UserCard(
                    user: user,
                    onLike: () => _handleLike(
                        authViewModel.user!.uid, user.id, users[index]),
                    onDislike: () => _handleDislike(
                        authViewModel.user!.uid, user.id, users[index]),
                  );
                },
                itemCount: users.length,
                itemWidth: MediaQuery.of(context).size.width,
                itemHeight: MediaQuery.of(context).size.height * 0.7,
                layout: SwiperLayout.STACK,
                onIndexChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                onTap: (index) {
                  // Opcional: manejar tap en la card
                },
              ),

              // Botones de acción en la parte inferior
              Positioned(
                bottom: 50,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Botón de dislike
                    GestureDetector(
                      onTap: () {
                        // Lógica para dislike
                        if (users.isNotEmpty && _currentIndex < users.length) {
                          _handleDislike(authViewModel.user!.uid,
                              users[_currentIndex].id, users[_currentIndex]);
                        }
                      },
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 10,
                              offset: Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.close,
                          color: Colors.red,
                          size: 30,
                        ),
                      ),
                    ),

                    // Botón de super like
                    GestureDetector(
                      onTap: () {
                        // Lógica para super like
                        if (users.isNotEmpty && _currentIndex < users.length) {
                          _handleSuperLike(authViewModel.user!.uid,
                              users[_currentIndex].id, users[_currentIndex]);
                        }
                      },
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 10,
                              offset: Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.star,
                          color: Colors.blue,
                          size: 25,
                        ),
                      ),
                    ),

                    // Botón de like
                    GestureDetector(
                      onTap: () {
                        // Lógica para like
                        if (users.isNotEmpty && _currentIndex < users.length) {
                          _handleLike(authViewModel.user!.uid,
                              users[_currentIndex].id, users[_currentIndex]);
                        }
                      },
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 10,
                              offset: Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.favorite,
                          color: Colors.green,
                          size: 30,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _handleLike(
      String currentUserId, String likedUserId, DocumentSnapshot user) async {
    final userName = (user.data() as Map<String, dynamic>)['name'] ?? 'Usuario';

    // Show confirmation message
    _showConfirmationDialog(
      'You like $userName! ❤️',
      'You have liked this profile',
      Colors.green,
      Icons.favorite,
      () async {
        await _likeUser(currentUserId, likedUserId);
        _nextCard();
      },
    );
  }

  Future<void> _handleDislike(String currentUserId, String dislikedUserId,
      DocumentSnapshot user) async {
    final userName = (user.data() as Map<String, dynamic>)['name'] ?? 'Usuario';

    // Show confirmation message
    _showConfirmationDialog(
      'You don\'t like $userName',
      'You have rejected this profile',
      Colors.red,
      Icons.close,
      () async {
        await _dislikeUser(currentUserId, dislikedUserId);
        _nextCard();
      },
    );
  }

  Future<void> _handleSuperLike(String currentUserId, String superLikedUserId,
      DocumentSnapshot user) async {
    final userName = (user.data() as Map<String, dynamic>)['name'] ?? 'Usuario';

    // Show confirmation message
    _showConfirmationDialog(
      'Super Like for $userName! ⭐',
      'You have super liked this profile',
      Colors.blue,
      Icons.star,
      () async {
        await _superLikeUser(currentUserId, superLikedUserId);
        _nextCard();
      },
    );
  }

  void _showConfirmationDialog(
    String title,
    String message,
    Color color,
    IconData icon,
    VoidCallback onConfirm,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withOpacity(0.1),
                  color.withOpacity(0.05),
                ],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withOpacity(0.2),
                  ),
                  child: Icon(
                    icon,
                    size: 40,
                    color: color,
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 12),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[300],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          onConfirm();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: color,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          'Confirm',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _nextCard() {
    // Avanzar a la siguiente card después de un breve delay
    Future.delayed(Duration(milliseconds: 300), () {
      try {
        _swiperController.next();
      } catch (e) {
        // Si hay error, simplemente no hacer nada
      }
    });
  }

  Future<void> _likeUser(String currentUserId, String likedUserId) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .collection('likes')
        .doc(likedUserId)
        .set({
      'timestamp': FieldValue.serverTimestamp(),
      'type': 'like',
    });
  }

  Future<void> _dislikeUser(String currentUserId, String dislikedUserId) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .collection('dislikes')
        .doc(dislikedUserId)
        .set({
      'timestamp': FieldValue.serverTimestamp(),
      'type': 'dislike',
    });
  }

  Future<void> _superLikeUser(
      String currentUserId, String superLikedUserId) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .collection('superLikes')
        .doc(superLikedUserId)
        .set({
      'timestamp': FieldValue.serverTimestamp(),
      'type': 'superLike',
    });
  }
}
