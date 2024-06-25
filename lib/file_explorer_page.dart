import 'package:flutter/material.dart';
import 'package:posecheck_datacollector/file_utils.dart';
import 'package:share_plus/share_plus.dart';

class FileListPage extends StatefulWidget {
  @override
  _FileListPageState createState() => _FileListPageState();
}

class _FileListPageState extends State<FileListPage> {
  List<String> files = List.generate(20, (index) => 'File $index');
  Set<int> selectedFiles = {};

  @override
  void initState() {
    FileUtils.getFileList().then((value) {
      files = value;
      setState(() {});
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Files'),
        actions: selectedFiles.isNotEmpty
            ? [
                IconButton(
                  icon: Icon(Icons.select_all),
                  onPressed: selectAll,
                ),
                IconButton(
                  icon: Icon(Icons.clear),
                  onPressed: unselectAll,
                ),
              ]
            : null,
      ),
      body: files.isNotEmpty
          ? ListView.builder(
              itemCount: files.length,
              itemBuilder: (context, index) {
                return Dismissible(
                  key: Key(files[index]),
                  direction: DismissDirection.endToStart,
                  onDismissed: (direction) async {
                    final filePath = files[index];
                    setState(() {
                      files.removeAt(index);
                      selectedFiles.remove(index);
                    });
                    await _deleteFile(filePath);
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${files[index]} deleted')));
                  },
                  background: Container(color: Colors.red),
                  child: ListTile(
                    title: Text(files[index]),
                    trailing: Checkbox(
                      value: selectedFiles.contains(index),
                      onChanged: (bool? value) {
                        setState(() {
                          if (value == true) {
                            selectedFiles.add(index);
                          } else {
                            selectedFiles.remove(index);
                          }
                        });
                      },
                    ),
                    onTap: () {
                      setState(() {
                        if (selectedFiles.contains(index)) {
                          selectedFiles.remove(index);
                        } else {
                          selectedFiles.add(index);
                        }
                      });
                    },
                  ),
                );
              },
            )
          : Center(child: Text("No files.")),
      bottomNavigationBar: selectedFiles.isNotEmpty
          ? BottomAppBar(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: deleteSelected,
                    child: Text('Delete Selected'),
                  ),
                  TextButton(
                    onPressed: shareSelected,
                    child: Text('Share Selected'),
                  ),
                ],
              ),
            )
          : null,
    );
  }

  Future<void> _deleteFile(String fileName) async {
    final file = await FileUtils.localFile(fileName);
    if (await file.exists()) {
      await file.delete();
    }
  }

  void selectAll() {
    setState(() {
      selectedFiles =
          Set<int>.from(List.generate(files.length, (index) => index));
    });
  }

  void unselectAll() {
    setState(() {
      selectedFiles.clear();
    });
  }

  void deleteSelected() async {
    final List<String> filesToDelete =
        selectedFiles.map((index) => files[index]).toList();

    setState(() {
      files.removeWhere((file) => selectedFiles.contains(files.indexOf(file)));
      FileUtils.saveFileList(files);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Delete ${selectedFiles.length} files')));
      selectedFiles.clear();
    });

    for (final filePath in filesToDelete) {
      await _deleteFile(filePath);
    }
  }

  void shareSelected() async {
    final path = await FileUtils.localPath;
    final List<XFile> filesToShare = selectedFiles.map(
      (index) {
        // return files[index];
        return XFile('$path/${files[index]}');
      },
    ).toList();
    if (filesToShare.isNotEmpty) {
      await Share.shareXFiles(filesToShare,
          text: 'Sharing ${filesToShare.length} files');
    }
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sharing ${selectedFiles.length} files')));
  }
}
