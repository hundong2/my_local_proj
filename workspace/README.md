# Workspace Directory

This directory is mounted into the Code Server container and can be used for development work.

## Getting Started

1. Access VSCode Server at: https://your-domain/vscode
2. This directory will be available at `/home/coder/workspace`
3. You can create and edit files here

## Example Files

Create some example files to test the environment:

```bash
echo 'print("Hello from Python!")' > hello.py
echo 'console.log("Hello from JavaScript!");' > hello.js
echo '# Hello World\n\nThis is a markdown file.' > hello.md
```

## Features

- Full VSCode editor with extensions support
- Terminal access
- Git integration
- File explorer
- Collaborative editing (when properly configured)
