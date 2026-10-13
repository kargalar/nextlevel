---
applyTo: '*
---
Provide project context and coding guidelines that AI should follow when generating code, answering questions, or reviewing changes.
- Always write code according to clean code principles:
- No file should exceed 600 lines.
- Each file should have a single responsibility (SRP).
- Keep components small; separate UI and business logic.
- Apply a feature-based folder structure.
- Separate UI components according to atomic design logic (atoms, molecules, organisms, pages).
- Move repetitive code into custom hooks or utils.
- Errors occur in the application, but most of the time they are not visible. From now on, add code for messages in the debug panel for the code I write, in case of errors or success. 
If you need to use Color, call it from the AppColors class. 

Never build or start the application. 

Do not create md files unless absolutely necessary (for summaries, etc.).
*'
---
