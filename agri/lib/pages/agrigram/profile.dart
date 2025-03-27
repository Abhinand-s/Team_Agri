import 'package:agri/pages/agrigram/editpost.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileScreen extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return Center(child: Text("Please log in to view your profile"));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("My Profile"),
        backgroundColor: Colors.green,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestore.collection('users').doc(userId).snapshots(),
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (userSnapshot.hasError || !userSnapshot.hasData || !userSnapshot.data!.exists) {
            return Center(child: Text("User data not found"));
          }

          var userData = userSnapshot.data!.data() as Map<String, dynamic>;

          return Column(
            children: [
              // User Details
              Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Username: ${userData['username']}",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      "Email: ${userData['email']}",
                      style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(height: 8),
                    Text(
                      "Date of Birth: ${userData['dob']}",
                      style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(height: 8),
                    Text(
                      "Occupation: ${userData['occupation']}",
                      style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(height: 8),
                    Text(
                      "Bio: ${userData['bio']}",
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
              Divider(),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _firestore
                      .collection('posts')
                      .where('userId', isEqualTo: userId)
                      .orderBy('timestamp', descending: true)
                      .snapshots(),
                  builder: (context, postSnapshot) {
                    if (postSnapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }

                    if (postSnapshot.hasError) {
                      print("Error fetching posts: ${postSnapshot.error}");
                      return Center(child: Text("Error loading posts"));
                    }

                    if (!postSnapshot.hasData || postSnapshot.data!.docs.isEmpty) {
                      print("No posts found for user: $userId");
                      return Center(child: Text("No posts available"));
                    }

                    // Debug: Print the fetched posts
                    postSnapshot.data!.docs.forEach((doc) {
                      print("Post: ${doc.data()}");
                    });

                    return ListView.builder(
                      itemCount: postSnapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        var post = postSnapshot.data!.docs[index].data() as Map<String, dynamic>;
                        String postId = postSnapshot.data!.docs[index].id;
                        return _buildPostCard(context, post, postId);
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPostCard(BuildContext context, Map<String, dynamic> post, String postId) {
    return Card(
      margin: EdgeInsets.all(8),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Username
            Text(
              "Posted by: ${post['username']}",
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            SizedBox(height: 8),

            // Title
            Text(
              post['title'] ?? '',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),

            // Description
            Text(
              post['description'] ?? '',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 8),

            // Image (if available)
            if (post['imageUrl'] != null)
              Image.network(
                post['imageUrl'],
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
              ),
            SizedBox(height: 16),

            // Edit and Delete Buttons
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditPostScreen(postId: postId, post: post),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () => _deletePost(postId),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deletePost(String postId) async {
    await _firestore.collection('posts').doc(postId).delete();
  }
}