import 'package:bloknot/globals.dart';
import 'package:flutter/material.dart';

class WorkspaceDialog extends StatelessWidget {

  final Function(int) clearWorkspaceText;
  final List<bool> activeWorkspaces;
  const WorkspaceDialog({
    super.key, 
    required this.clearWorkspaceText, 
    required this.activeWorkspaces, 
    });


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
                    color: Globals.appButtonColor,
                    fontSize: 16,
                  )
                )
              ),
            ),
            Expanded(child: Container(),),
            IconButton(
              onPressed: () { clearWorkspaceText(i); },
              icon: const Icon(Icons.delete_forever), 
              color: activeWorkspaces[i] ? Globals.appButtonColor : Globals.disabledButtonColor
            ),
          ]
        )
      );
    }

    return rows;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Globals.appColor,
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
                  color: Globals.appButtonColor,
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