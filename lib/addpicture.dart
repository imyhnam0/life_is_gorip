import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'user_provider.dart';
import 'package:provider/provider.dart';

class AddPicturePage extends StatefulWidget {
  const AddPicturePage({super.key});

  @override
  State<AddPicturePage> createState() => _AddPicturePageState();
}

class _AddPicturePageState extends State<AddPicturePage> {
  File? _image;
  String? _downloadURL;
  final ImagePicker _picker = ImagePicker();
  String? uid;
  String? currentFolder = '';
  List<String> folderList = [];
  List<String> imageList = [];
  bool _isDeleting = false;
  List<String> _selectedItems = [];

  @override
  void initState() {
    super.initState();
    uid = Provider.of<UserProvider>(context, listen: false).uid;
    _fetchFoldersAndImages();
  }

  Future<void> _deleteFolder(String folderPath) async {
  final ListResult result = await FirebaseStorage.instance.ref(folderPath).listAll();

  // Delete all files in the folder
  for (var fileRef in result.items) {
    await fileRef.delete();
  }

  // Recursively delete all subfolders
  for (var folderRef in result.prefixes) {
    await _deleteFolder(folderRef.fullPath);
  }
}

  

  Future<void> _fetchFoldersAndImages() async {
    await _fetchFolders();
    await _fetchImages();
  }

  Future<void> _fetchFolders() async {
    final ListResult result =
        await FirebaseStorage.instance.ref('$uid/$currentFolder').listAll();
    final List<String> folders =
        result.prefixes.map((ref) => ref.name).toList();
    setState(() {
      folderList = folders;
    });
  }

  Future<void> _fetchImages() async {
    final ListResult result =
        await FirebaseStorage.instance.ref('$uid/$currentFolder').listAll();
    final List<String> images = result.items
        .where((ref) => !ref.name.contains('.dummy'))
        .map((ref) => ref.fullPath)
        .toList();
    setState(() {
      imageList = images;
    });
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });

      await _uploadImage();
    }
  }

  Future<void> _uploadImage() async {
    if (_image == null || uid == null) return;

    final storageRef = FirebaseStorage.instance.ref().child(
        '$uid/$currentFolder/${DateTime.now().millisecondsSinceEpoch}.png');
    final uploadTask = storageRef.putFile(_image!);

    await uploadTask.whenComplete(() async {
      final url = await storageRef.getDownloadURL();
      setState(() {
        _downloadURL = url;
      });
      await _fetchImages();
    });
  }

  Future<void> _createFolder(String folderName) async {
    final folderRef = FirebaseStorage.instance
        .ref()
        .child('$uid/$currentFolder/$folderName/');
    await folderRef.child('.dummy').putString('');
    await _fetchFolders();
  }

  void _showCreateFolderDialog() {
    String folderName = '';
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('폴더 추가'),
          content: TextField(
            onChanged: (value) {
              folderName = value;
            },
            decoration: const InputDecoration(hintText: "폴더 이름 "),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                if (folderName.isNotEmpty) {
                  await _createFolder(folderName);
                }
              },
              child: const Text('확인'),
            ),
          ],
        );
      },
    );
  }

  void _enterFolder(String folderName) {
    setState(() {
      currentFolder = '$currentFolder/$folderName';
      _fetchFoldersAndImages();
    });
  }

  void _showImageDialog(String imagePath) async {
    String downloadURL =
        await FirebaseStorage.instance.ref(imagePath).getDownloadURL();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Image.network(downloadURL),
        );
      },
    );
  }
  
  Future<void> _deleteSelectedItems() async {
  for (String path in _selectedItems) {
    try {
      final ref = FirebaseStorage.instance.ref(path);
      final ListResult result = await ref.listAll();

      if (result.items.isEmpty && result.prefixes.isEmpty) {
        // It's a file, delete it
        await ref.delete();
      } else {
        // It's a folder, delete it recursively
        await _deleteFolder(path);
      }
    } catch (e) {
      print('Error deleting $path: $e');
    }
  }
  setState(() {
    _selectedItems.clear();
    _isDeleting = false;
  });
  await _fetchFoldersAndImages();
}


  void _confirmDelete() {
    showDialog(

      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.blueGrey.shade900,
          title: const Text('정말 삭제하시겠습니까?', style: TextStyle(color: Colors.white)),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('취소', style: TextStyle(color: Colors.white)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _deleteSelectedItems();
              },
              child: const Text('확인', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFolderItem(String folderName) {
  final isSelected = _selectedItems.contains('$uid/$currentFolder/$folderName');
  return GestureDetector(
    onTap: _isDeleting
        ? () {
            setState(() {
              if (isSelected) {
                _selectedItems.remove('$uid/$currentFolder/$folderName');
              } else {
                _selectedItems.add('$uid/$currentFolder/$folderName');
              }
            });
          }
        : () => _enterFolder(folderName),
    child: Stack(
      children: [
        Container(
          margin: EdgeInsets.all(8.0),
          padding: EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.blue),
            borderRadius: BorderRadius.circular(8.0),
            color: isSelected
                ? Colors.blueGrey.shade600
                : Colors.blueGrey.shade800,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.folder, color: Colors.white, size: 40.0),
              SizedBox(height: 8.0),
              Text(
                folderName,
                style: TextStyle(fontSize: 18.0, color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        if (isSelected)
          Positioned(
            top: 0,
            right: 0,
            child: Icon(Icons.check_circle, color: Colors.green),
          ),
      ],
    ),
  );
}


  Widget _buildImageItem(String imagePath) {
    final isSelected = _selectedItems.contains(imagePath);
    return FutureBuilder<String>(
      future: FirebaseStorage.instance.ref(imagePath).getDownloadURL(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error loading image'));
        }
        return GestureDetector(
          onTap: _isDeleting
              ? () {
                  setState(() {
                    if (isSelected) {
                      _selectedItems.remove(imagePath);
                    } else {
                      _selectedItems.add(imagePath);
                    }
                  });
                }
              : () => _showImageDialog(imagePath),
          child: Stack(
            children: [
              Container(
                margin: EdgeInsets.all(4.0),
                width: MediaQuery.of(context).size.width / 3 - 12,
                height: MediaQuery.of(context).size.width / 3 - 12,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8.0),
                  image: DecorationImage(
                    image: NetworkImage(snapshot.data!),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              if (isSelected)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Icon(Icons.check_circle, color: Colors.green),
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          currentFolder?.isEmpty ?? true ? 'My Pictures' : '$currentFolder',
          style: TextStyle(
              fontFamily: 'Pacifico', fontSize: 24.0, color: Colors.white),
        ),
        actions: <Widget>[
          IconButton(
            icon: Icon(_isDeleting ? Icons.check : Icons.create_new_folder, color: Colors.white),
            onPressed: _isDeleting ? _confirmDelete : _showCreateFolderDialog,
          ),
          IconButton(
            icon: Icon(_isDeleting ? Icons.cancel : Icons.delete, color: Colors.white),
            onPressed: () {
              setState(() {
                _isDeleting = !_isDeleting;
                if (!_isDeleting) _selectedItems.clear();
              });
            },
          ),
        ],
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (currentFolder?.isNotEmpty ?? false) {
              setState(() {
                currentFolder = currentFolder!
                    .substring(0, currentFolder!.lastIndexOf('/'));
                _fetchFoldersAndImages();
              });
            } else {
              Navigator.pop(context);
            }
          },
        ),
        backgroundColor: Colors.blueGrey.shade700,
      ),
      body: Container(
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: Colors.blueGrey.shade900,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: _pickImage,
              child: const Text('사진 추가'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyan.shade700,
                foregroundColor: Colors.white,
                textStyle: TextStyle(fontFamily: 'Oswald', fontSize: 18),
                padding: EdgeInsets.symmetric(horizontal: 30.0, vertical: 10.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
            Expanded(
              child: GridView.count(
                crossAxisCount: 3,
                children: <Widget>[
                  ...folderList
                      .map((folder) => _buildFolderItem(folder))
                      .toList(),
                  ...imageList.map((image) => _buildImageItem(image)).toList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
