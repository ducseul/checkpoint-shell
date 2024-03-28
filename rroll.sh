#!/bin/bash

# Default checkpoint and predefined folder paths
checkpoint_folder=""
predefined_folder=""

# Function to prompt user for folder paths if they are not set
set_folders() {
    if [ -z "$checkpoint_folder" ] || [ -z "$predefined_folder" ]; then
        echo "It's look like the first time you ran script."
		echo "Please set following parameter!"
        read -rp "Enter the path to the checkpoint folder: " checkpoint_folder_input
        read -rp "Enter the path to the predefined folder: " predefined_folder_input
        checkpoint_folder="$checkpoint_folder_input"
        predefined_folder="$predefined_folder_input"
        echo "Checkpoint folder set to: $checkpoint_folder"
        echo "Predefined folder set to: $predefined_folder"
		echo Script is ready to use, please start script again
		echo
        # Update the script itself with new folder paths
        sed -i "s|^checkpoint_folder=.*|checkpoint_folder=\"$checkpoint_folder\"|g" "$0"
        sed -i "s|^predefined_folder=.*|predefined_folder=\"$predefined_folder\"|g" "$0"
        exit
    fi
}

# Precheck function to verify if necessary commands and folders exist
precheck() {
	echo "QXV0aG9yOiBkdWNzZXVsIFZlcnNpb246IDIuMS40Cg==" | base64 -d
    if ! command -v zip &>/dev/null; then
        echo "Warning: 'zip' command not found. Using 'tar' instead."
        use_tar=true
    else
        use_tar=false
    fi

    if [ ! -d "$checkpoint_folder" ]; then
        mkdir -p "$checkpoint_folder"
        echo "Create checkpoint folder done!"
    fi
}

create_checkpoint() {
    datetime=$(date '+%Y-%m-%d_%H-%M-%S')
    echo "Creating checkpoint..."
    if [ "$use_tar" = true ]; then
        tar -czf "$checkpoint_folder/backup_$datetime.tar.gz" -C "$predefined_folder" .
    else
        zip -rq "$checkpoint_folder/backup_$datetime.zip" "$predefined_folder"
    fi
    echo "Checkpoint created: backup_$datetime"
}

rollback_checkpoint() {
    echo "Available Checkpoints:"
    echo "0) Exit"
    cd "$checkpoint_folder" || exit
    # zip might not be available yet, check for not showing unecessary messages
    if ls -1 *.zip &>/dev/null; then
        zip_checkpoints=($(ls -1t *.zip))
    else
        zip_checkpoints=()
    fi

    if ls -1 *.tar.gz &>/dev/null; then
        tar_checkpoints=($(ls -1t *.tar.gz))
    else
        tar_checkpoints=()
    fi

    # Combine output of 2 checks
    all_checkpoints=( "${tar_checkpoints[@]}" "${zip_checkpoints[@]}" )

    if [ ${#all_checkpoints[@]} -eq 0 ]; then
        echo "No checkpoints found."
        return
    fi

    # Insert "Exit" option at the beginning
    options=("${all_checkpoints[@]}")
    
    select checkpoint in "${options[@]}"; do
        if [ -z "$checkpoint" ]; then
            echo "Exiting..."
            return
        elif [ "$checkpoint" = "Exit" ]; then
            echo "Exiting..."
            return
        elif [ -n "$checkpoint" ]; then
            echo "Rolling back from $checkpoint..."
            
            # Prompt for confirmation
            read -rp "Confirm to rollback from $checkpoint? (yes/no): " confirm
            if [[ $confirm == "yes" ]]; then
                rm -rf "$predefined_folder"/*
                if [[ "$checkpoint" == *.tar.gz ]]; then
                    tar -xzf "$checkpoint" -C "$predefined_folder"
                elif [[ "$checkpoint" == *.zip ]]; then
                    unzip -q "$checkpoint" -d "$predefined_folder"
                fi
                echo "Rollback from $checkpoint completed."
            else
                echo "Rollback canceled."
            fi
            break
        else
            echo "Invalid selection. Please choose again."
        fi
    done

}

remove_backup_files() {
    echo "Remove backup files:"
    cd "$checkpoint_folder" || exit
    echo "Checkin directory: $(pwd)"
    
    # Debug: List all files in the current directory
    #echo "Listing all files in the directory:"
    #ls -1
    
    # Check for backup files
    backup_files=$(find . -maxdepth 1 -type f \( -name "*.zip" -o -name "*.tar.gz" \))
    
    if [ -z "$backup_files" ]; then
        echo "No backup files found."
        return
    fi

    # Display options
    echo "Select an option:"
    echo "1. Remove specific file"
    echo "2. Remove files older than a specified number of days"
    echo "3. Remove all backup files"

    # Read user choice
    read -rp "Enter your choice: " remove_option

    case $remove_option in
        1)
            echo "Available backup files:"
            echo "$backup_files"
            read -rp "Enter the name of the file you want to remove: " file_to_remove
            if [ -e "$file_to_remove" ]; then
                read -rp "Are you sure you want to remove $file_to_remove? (yes/no): " confirm
                if [[ $confirm == "yes" ]]; then
                    rm -i "$file_to_remove"
                    echo "File $file_to_remove removed."
                else
                    echo "Operation canceled."
                fi
            else
                echo "File does not exist."
            fi
            ;;
        2)
            read -rp "Enter the number of days: " days
            read -rp "Are you sure you want to remove files older than $days days? (yes/no): " confirm
            if [[ $confirm == "yes" ]]; then
                find . -maxdepth 1 -type f -name "*.zip" -mtime +$days -exec rm -i {} \;
                find . -maxdepth 1 -type f -name "*.tar.gz" -mtime +$days -exec rm -i {} \;
                echo "Backup files older than $days days removed."
            else
                echo "Operation canceled."
            fi
            ;;
        3)
            echo "Do you want to remove all backup files? (yes/no)"
            read -r confirm
            if [[ $confirm == "yes" ]]; then
                rm -f *.zip *.tar.gz
				echo "All backup files removed."
            else
                echo "Operation canceled."
            fi
            ;;
        *)
            echo "Invalid option. Please try again."
            ;;
    esac
}


menu() {
    echo "1. Create a backup checkpoint"
    echo "2. Rollback from a checkpoint"
    echo "3. Remove backup files"
    echo "4. Exit"
    read -rp "Enter your choice: " choice
    case $choice in
        1) create_checkpoint ;;
        2) rollback_checkpoint ;;
        3) remove_backup_files ;;
        4) exit ;;
        *) echo "Invalid option. Please try again." ;;
    esac
}

# Set folders if not already set
set_folders
# Perform prechecks
precheck

# Main menu loop
while true; do
    echo
    menu
done
