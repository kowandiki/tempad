

import 'package:bloknot/globals.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class WorkspaceRow extends StatefulWidget {

  final int index;
  final Function(int) clearWorkspaceText;
  final bool isWorkspaceActive;

  const WorkspaceRow({
    required this.index,
    required this.clearWorkspaceText,
    required this.isWorkspaceActive,
    super.key,
  });

  @override
  State<WorkspaceRow> createState() => _WorkspaceRowState();

}

class _WorkspaceRowState extends State<WorkspaceRow> {

  bool _isWorkspaceActive = false;

  @override
  void initState() {
    super.initState();

    _isWorkspaceActive = widget.isWorkspaceActive;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
          children: [
            SimpleDialogOption(
              onPressed: () { Navigator.pop(context, widget.index); },
              child: RichText(
                text: TextSpan(
                  text: "Workspace ${widget.index}",
                  style: TextStyle(
                    color: Globals.appButtonColor,
                    fontSize: 16,
                  )
                )
              ),
            ),
            Expanded(child: Container(),),
            IconButton(
              onPressed: () { 
                widget.clearWorkspaceText(widget.index); 
                _isWorkspaceActive = false;
                setState((){});
                HapticFeedback.lightImpact();
              },
              icon: const Icon(Icons.delete_forever), 
              // color: activeWorkspaces[widget.index] ? Globals.appButtonColor : Globals.disabledButtonColor
              color: _isWorkspaceActive ? Globals.appButtonColor : Globals.disabledButtonColor,
            ),
          ]
        );
  }


}