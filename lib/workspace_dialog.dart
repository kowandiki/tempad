import 'package:flutter/material.dart';

class WorkspaceDialog extends StatelessWidget {

  final Function(int) clearWorkspaceText;
  const WorkspaceDialog({super.key, required this.clearWorkspaceText});

  List<Row> _generateWorkspaceList(BuildContext context, int numOfRows) {

    List<Row> rows = [];

    for (int i = 0; i < numOfRows; i++) {
      rows.add(Row(
          children: [
            SimpleDialogOption(
              onPressed: () { Navigator.pop(context, i); },
              child: Text("Workspace $i")
            ),
            Expanded(child: Container(),),
            IconButton(onPressed: () { clearWorkspaceText(i); } , icon: const Icon(Icons.delete_forever)),
          ]
        )
      );
    }

    return rows;
  }

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      title: const Text("Select workspace"),
      children: _generateWorkspaceList(context, 5)
    );
  }

}