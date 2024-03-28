# Checkpoint Management Shell Script

## Summary

This Linux shell script provides functionality for creating checkpoints, managing backup checkpoints, and rolling back to previous states. It is designed to help users maintain backups of important data and easily restore them as needed.

## Features

- **Create Checkpoint:** Allows users to create a backup checkpoint of a predefined folder. The script automatically generates a timestamped archive file (ZIP or TAR.GZ) containing the contents of the predefined folder.

- **Manage Backup Checkpoints:** Users can view available backup checkpoints and select one for rollback. The script lists available checkpoints, allowing users to choose which checkpoint to rollback to.

- **Rollback Functionality:** Provides the ability to rollback to a selected checkpoint. The selected checkpoint is unpacked, and its contents are restored to the predefined folder, effectively reverting the folder to the state captured in the checkpoint.

## Usage

1. **Setup:**
   - When running the script for the first time, it prompts users to specify the paths for the checkpoint folder and the predefined folder. These paths are used for storing checkpoints and specifying the folder to be backed up, respectively.

2. **Creating Checkpoints:**
   - Choose option 1 from the menu to create a backup checkpoint. The script automatically generates a timestamped archive file (ZIP or TAR.GZ)
