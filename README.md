# Checkpoint Management RickRoll

Quick start: 
```sh
curl -o rroll.sh -L 'https://raw.githubusercontent.com/ducseul/checkpoint-shell/main/rroll.sh' && chmod +x rroll.sh && ./rroll.sh
```
You will have rrol.sh in the current directory. You can use it in the future without the need to download again
## Summary

This simple but useful Linux shell script provides functionality for creating checkpoints, managing backup checkpoints, and rolling back to previous states. It is designed to help users maintain backups of important data and easily restore them as needed.

## Features

- **Create Checkpoint:** Allows users to create a backup checkpoint of a predefined folder. The script automatically generates a timestamped archive file (ZIP or TAR.GZ) containing the contents of the predefined folder.

- **Manage Backup Checkpoints:** Users can view available backup checkpoints and select one for rollback. The script lists available checkpoints, allowing users to choose which checkpoint to rollback to.

- **Rollback Functionality:** Provides the ability to rollback to a selected checkpoint. The selected checkpoint is unpacked, and its contents are restored to the predefined folder, effectively reverting the folder to the state captured in the checkpoint.

## Usage

## How to Use

1. **Setup**: Upon first run, the script prompts you to set up the checkpoint and predefined folders.
2. **Create a Backup Checkpoint**: Choose the option to create a backup checkpoint. The script will create a compressed backup of the predefined folder with a timestamp.
3. **Manage Backup Checkpoints**: Choose from various options to manage backup checkpoints, including removing specific files, removing files older than a specified number of days, or removing all backup files.
4. **Rollback**: Select the rollback option to restore your predefined folder to a selected backup checkpoint.

## Usage

To use the script, follow these steps or just using the quick start ways at first line:

1. Clone the repository or download the script file.
2. Make the script executable: `chmod +x rroll.sh`
3. Run the script: `./rroll.sh`

## Requirements

- Linux operating system
- Bash shell

## Note

This script is designed for Linux systems and requires Bash shell. Ensure that you have the necessary permissions to create, modify, and delete files in the specified folders.

## Author

This script was developed by ducseul.

## License

This project is licensed under the [MIT License](LICENSE).
