import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class EditPostScreen extends StatefulWidget {
  final String postId;
  final Map<String, dynamic> post;

  EditPostScreen({required this.postId, required this.post});

  @override
  _EditPostScreenState createState() => _EditPostScreenState();
}

class _EditPostScreenState extends State<EditPostScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  File? _image;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.post['title'];
    _descriptionController.text = widget.post['description'];
    _contentController.text = widget.post['content'];
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> _updatePost() async {
    if (_titleController.text.isEmpty || _descriptionController.text.isEmpty || _contentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String? imageUrl;
      if (_image != null) {
        // Upload new image to Firebase Storage
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('post_images/${DateTime.now().millisecondsSinceEpoch}.jpg');
        await storageRef.putFile(_image!);
        imageUrl = await storageRef.getDownloadURL();
      }

      // Update post in Firestore
      await FirebaseFirestore.instance.collection('posts').doc(widget.postId).update({
        'title': _titleController.text,
        'description': _descriptionController.text,
        'content': _contentController.text,
        'imageUrl': imageUrl ?? widget.post['imageUrl'],
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Post updated successfully!")),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to update post: ${e.toString()}")),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Edit Post"),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(labelText: "Title"),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(labelText: "Description"),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _contentController,
              decoration: InputDecoration(labelText: "Content"),
              maxLines: 5,
            ),
            SizedBox(height: 16),
            if (_image != null)
              Image.file(_image!, height: 100, width: 100, fit: BoxFit.cover),
            ElevatedButton(
              onPressed: _pickImage,
              child: Text("Pick Image"),
            ),
            SizedBox(height: 16),
            _isLoading
                ? CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _updatePost,
                    child: Text("Update Post"),
                  ),
          ],
        ),
      ),
    );
  }
}