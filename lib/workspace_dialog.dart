import 'package:flutter/material.dart';

class WorkspaceDialog extends StatelessWidget {

  final Function(int) clearWorkspaceText;
  final List<bool> activeWorkspaces;
  const WorkspaceDialog({super.key, required this.clearWorkspaceText, required this.activeWorkspaces});

  final Color _enabledColor = Colors.white;
  final Color _disabledColor = const Color.fromARGB(255, 187, 187, 187);

  List<Row> _generateWorkspaceList(BuildContext context, int numOfRows) {

    List<Row> rows = [];

    for (int i = 0; i < numOfRows; i++) {
      rows.add(
        Row(
          children: [
            SimpleDialogOption(
              onPressed: () { Navigator.pop(context, i); },
              child: RichText(
                text: TextSpan(
                  text: "Workspace $i",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  )
                )
              ),
            ),
            Expanded(child: Container(),),
            IconButton(
              onPressed: () { clearWorkspaceText(i); },
              icon: const Icon(Icons.delete_forever), 
              color: activeWorkspaces[i] ? _enabledColor : _disabledColor
            ),
          ]
        )
      );
    }

    return rows;
  }

  // @override
  // Widget build(BuildContext context) {
  //   return SimpleDialog(
  //     title: const Text("Select workspace"),
  //     children: _generateWorkspaceList(context, 5)
  //   );
  // }
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.blue,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          
          children: <Widget>[
            RichText(
              text: TextSpan(
                text: "Select Workspace",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                )
              )
            ),
            SizedBox(height: 10,),
          ] + _generateWorkspaceList(context, activeWorkspaces.length)
        )
      )
    );
  }

}