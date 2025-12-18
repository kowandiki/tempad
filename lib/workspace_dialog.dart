import 'package:bloknot/globals.dart';
import 'package:bloknot/workspace_row.dart';
import 'package:flutter/material.dart';

class WorkspaceDialog extends StatelessWidget {

  final Function(int) clearWorkspaceText;
  final List<bool> activeWorkspaces;
  const WorkspaceDialog({
    super.key, 
    required this.clearWorkspaceText, 
    required this.activeWorkspaces, 
    });


  List<Widget> _generateWorkspaceList(BuildContext context, int numOfRows) {

    List<Widget> rows = [];

    for (int i = 0; i < numOfRows; i++) {
      rows.add(
        WorkspaceRow(
          index: i, 
          clearWorkspaceText: clearWorkspaceText, 
          isWorkspaceActive: activeWorkspaces[i])
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