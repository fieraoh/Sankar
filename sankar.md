# Sankar

This script provides a manual directory synchronization similar to rsync but uses a custom hash check (QuickXorHash) for determining when to copy files. It's designed to synchronize two directories on a specified millisecond interval, ensuring that changes in the source directory are reflected in the destination directory.

The script is currently a Prototype, it supports one-way sync as the only optiion.

## Features

- **File Comparison**: Uses a robust hashing algorithm (QuickXorHash) to compare files between the source and destination directories.
- **Customizable Frequency**: Synchronization frequency can be specified in milliseconds, allowing for fine-grained control over sync operations.

## Requirements

- Should run on any Unix-like system

## Usage

1. **Download the Script**: Download the script to your local machine where you intend to run it.
2. **Make It Executable**:
``bash``
``chmod +x sankar.sh``
3. **Run IT!**

## Repo on Github
[Sankar on Github](https://github.com/fieraoh/sankar-syncing)
