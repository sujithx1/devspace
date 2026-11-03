import 'package:flutter/cupertino.dart';

import '../../core/widgets/widgets.dart';

class NotesScreen extends StatelessWidget {
  const NotesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const DSPage(
      title: 'Notes',
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: DSEmptyState(
            icon: CupertinoIcons.doc_text,
            title: 'Notes are on the way',
            message: 'A rich-text editor with checklists, code blocks, folders and autosave is coming in a later build.',
          ),
        ),
      ],
    );
  }
}
