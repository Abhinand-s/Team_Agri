import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ExpandPostScreen extends StatefulWidget {
  final Map<String, dynamic> post;
  final String postId;

  const ExpandPostScreen({required this.post, required this.postId});

  @override
  _ExpandPostScreenState createState() => _ExpandPostScreenState();
}

class _ExpandPostScreenState extends State<ExpandPostScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _commentController = TextEditingController();
  int? _userVote; // Tracks the user's current vote (1 for like, -1 for dislike, null for no vote)

  @override
  void initState() {
    super.initState();
    _fetchUserVote(); // Fetch the user's vote when the screen loads
  }

  // Fetch the user's vote from Firestore
  Future<void> _fetchUserVote() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    final voteDoc = await _firestore
        .collection('posts')
        .doc(widget.postId)
        .collection('votes')
        .doc(userId)
        .get();

    if (voteDoc.exists) {
      setState(() {
        _userVote = voteDoc.data()?['vote'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Post Details",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green[800],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Username
            Text(
              "Posted by: ${widget.post['username']}",
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
            SizedBox(height: 16),

            // Title
            Text(
              widget.post['description'] ?? '',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green[900]),
            ),
            SizedBox(height: 16),

            // Image (if available)
            if (widget.post['imageUrl'] != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: widget.post['imageUrl'],
                  placeholder: (context, url) => CircularProgressIndicator(),
                  errorWidget: (context, url, error) => Icon(Icons.error),
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              ),
            SizedBox(height: 16),

            // Description (Full Content)
            Text(
              widget.post['content'] ?? '',
              style: TextStyle(fontSize: 16, color: Colors.grey[800]),
            ),
            SizedBox(height: 16),

            // Like/Dislike Section
            Row(
              children: [
                IconButton(
                  icon: Icon(
                    Icons.thumb_up,
                    color: _userVote == 1 ? Colors.green[800] : Colors.grey,
                  ),
                  onPressed: () => _handleVote(1),
                ),
                Text(widget.post['upvotes']?.toString() ?? '0'),
                SizedBox(width: 16),
                IconButton(
                  icon: Icon(
                    Icons.thumb_down,
                    color: _userVote == -1 ? Colors.red : Colors.grey,
                  ),
                  onPressed: () => _handleVote(-1),
                ),
              ],
            ),
            SizedBox(height: 16),

            // Comment Input Field
            TextField(
              controller: _commentController,
              decoration: InputDecoration(
                hintText: "Add a comment...",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: IconButton(
                  icon: Icon(Icons.send, color: Colors.green[800]),
                  onPressed: _addComment,
                ),
              ),
            ),
            SizedBox(height: 16),

            // Comments List
            Text(
              "Comments",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green[800]),
            ),
            SizedBox(height: 8),
            StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('posts')
                  .doc(widget.postId)
                  .collection('comments')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError || !snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Text("No comments yet.");
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var comment = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                    return _buildCommentItem(comment);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentItem(Map<String, dynamic> comment) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              comment['username'] ?? 'Anonymous',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.green[800]),
            ),
            SizedBox(height: 4),
            Text(
              comment['text'] ?? '',
              style: TextStyle(fontSize: 14, color: Colors.grey[800]),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleVote(int vote) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    final postRef = _firestore.collection('posts').doc(widget.postId);
    final voteRef = postRef.collection('votes').doc(userId);

    // Check if the user has already voted
    final voteDoc = await voteRef.get();

    if (voteDoc.exists) {
      final previousVote = voteDoc.data()?['vote'] ?? 0;

      // If the user is trying to vote the same way again, remove their vote
      if (previousVote == vote) {
        await postRef.update({
          'upvotes': FieldValue.increment(-vote),
        });
        await voteRef.delete();
        setState(() {
          _userVote = null; // Reset the user's vote
        });
      } else {
        // If the user is changing their vote, update the vote count
        await postRef.update({
          'upvotes': FieldValue.increment(vote - previousVote),
        });
        await voteRef.update({
          'vote': vote,
        });
        setState(() {
          _userVote = vote; // Update the user's vote
        });
      }
    } else {
      // If the user hasn't voted before, record their vote
      await postRef.update({
        'upvotes': FieldValue.increment(vote),
      });
      await voteRef.set({
        'userId': userId,
        'vote': vote,
      });
      setState(() {
        _userVote = vote; // Set the user's vote
      });
    }
  }

  Future<void> _addComment() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null || _commentController.text.isEmpty) return;

    final commentRef = _firestore
        .collection('posts')
        .doc(widget.postId)
        .collection('comments')
        .doc();

    await commentRef.set({
      'userId': userId,
      'username': _auth.currentUser?.displayName ?? 'Anonymous',
      'text': _commentController.text,
      'timestamp': FieldValue.serverTimestamp(),
    });

    _commentController.clear(); // Clear the comment input field
  }
}