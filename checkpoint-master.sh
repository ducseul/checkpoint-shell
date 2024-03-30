#!/bin/bash

# Default checkpoint and predefined folder paths
checkpoint_storage_folder=""
predefined_folder=""

# Function to prompt user for folder paths if they are not set
set_folders() {
    if [ -z "$checkpoint_storage_folder" ] || [ -z "$predefined_folder" ]; then
        echo "It's look like the first time you ran script."
		echo "Please set following parameter!"
		echo "The folder path should be absolute path"
        read -rp "Enter the path to storage checkpoint folder: " checkpoint_folder_input
        read -rp "Enter the path to the target folder: " predefined_folder_input
        checkpoint_storage_folder="$checkpoint_folder_input"
        predefined_folder="$predefined_folder_input"
        echo "Checkpoint's storage folder set to: $checkpoint_storage_folder"
        echo "Target folder set to: $predefined_folder"
		echo Script is ready to use, please start script again
		echo
        # Update the script itself with new folder paths
        sed -i "s|^checkpoint_storage_folder=.*|checkpoint_storage_folder=\"$checkpoint_storage_folder\"|g" "$0"
        sed -i "s|^predefined_folder=.*|predefined_folder=\"$predefined_folder\"|g" "$0"
        exit
    fi
}

# Precheck function to verify if necessary commands and folders exist
precheck() {
	echo "QXV0aG9yOiBkdWNzZXVsICAgVmVyc2lvbjogMy4xLjUNCkNoZWNrIGZvciB1cGRhdGU6IGdpdGh1Yi5jb20vZHVjc2V1bC9jaGVja3BvaW50LXNoZWxsDQo=" | base64 -d
    if ! command -v zip &>/dev/null; then
        echo "Warning: 'zip' command not found. Using 'tar' instead."
        use_tar=true
    else
        use_tar=false
    fi

    if [ ! -d "$checkpoint_storage_folder" ]; then
        mkdir -p "$checkpoint_storage_folder"
        echo "Create checkpoint folder done!"
    fi
}

create_checkpoint() {
    datetime=$(date '+%Y-%m-%d_%H-%M-%S')
    echo "Creating checkpoint..."
    if [ "$use_tar" = true ]; then
        tar -czf "$checkpoint_storage_folder/backup_$datetime.tar.gz" -C "$predefined_folder" .
    else
        zip -rq "$checkpoint_storage_folder/backup_$datetime.zip" "$predefined_folder"
    fi
    echo "Checkpoint created: backup_$datetime"
}

rollback_checkpoint() {
    echo "Available Checkpoints:"
    echo "0) Exit"
    cd "$checkpoint_storage_folder" || exit
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
    cd "$checkpoint_storage_folder" || exit
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

add_cron_job() {
    local current_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
    local script_name=$(basename "$0")

    # Command to be executed by the cron job
    local COMMAND="$current_dir/$script_name backup_now >> $current_dir/$backup-cron.log"
    # DEBUG command echo $COMMAND

    # Function to prompt and add cron job
    prompt_and_add_cron_job() {
        local choice
        echo "Select cron schedule option:"
        echo "1. Daily"
        echo "2. Weekly"
        echo "3. Custom"
        echo "4. Exit"

        read -p "Enter your choice: " choice

        case $choice in
            1)
                schedule="0 0 * * *"
                ;;
            2)
                schedule="0 0 * * 0"
                ;;
            3)
                read -p "Enter custom cron schedule: " custom_schedule
                schedule="$custom_schedule"
                ;;
            4)
                echo "Exiting..."
                exit 0
                ;;
            *)
                echo "Invalid option."
                exit 1
                ;;
        esac

        # Check if the cron job already exists
        if ! crontab -l | grep -q "$COMMAND"; then
            # Add the cron job
            (crontab -l 2>/dev/null; echo "$schedule $COMMAND") | crontab -
            echo "Cron job added successfully."
        else
            echo "Cron job already exists."
        fi
    }

    # Call the function to prompt and add cron job
    prompt_and_add_cron_job
}


menu() {
    echo "1. Create a backup checkpoint"
    echo "2. Rollback from a checkpoint"
    echo "3. Remove backup files"
	echo "4. Add auto create checkpoint to crontab"
    echo "5. Exit"
    read -rp "Enter your choice: " choice
    case $choice in
        1) create_checkpoint ;;
        2) rollback_checkpoint ;;
        3) remove_backup_files ;;
		4) add_cron_job ;;
        5) exit ;;
        *) echo "Invalid option. Please try again." ;;
    esac
}

# Set folders if not already set
set_folders
# Perform prechecks
precheck

# Main menu loop
if [[ $1 == "backup_now" ]]; then
    create_checkpoint
else
    while true; do
        echo
        menu
    done
fi