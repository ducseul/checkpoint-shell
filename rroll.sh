#!/bin/bash

checkpoint_folder="/home/app/checkpoint"
predefined_folder="/home/app/TestScript"

# Precheck function to verify if necessary commands and folders exist
precheck() {
    echo Author: ducseul    Version: 1.6.2-beta
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
        tar -czf "$checkpoint_folder/originName_$datetime.tar.gz" -C "$predefined_folder" .
    else
        zip -rq "$checkpoint_folder/originName_$datetime.zip" "$predefined_folder"
    fi
    echo "Checkpoint created: originName_$datetime"
}

rollback_checkpoint() {
    echo "Available Checkpoints:"
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
	
	# combine output of 2 check
    all_checkpoints=( "${tar_checkpoints[@]}" "${zip_checkpoints[@]}" )


    if [ ${#all_checkpoints[@]} -eq 0 ]; then
        echo "No checkpoints found."
        return
    fi
    select checkpoint in "${all_checkpoints[@]}"; do
        if [ -n "$checkpoint" ]; then
            echo "Rolling back from $checkpoint..."
            rm -rf "$predefined_folder"/*
            if [[ "$checkpoint" == *.tar.gz ]]; then
                tar -xzf "$checkpoint" -C "$predefined_folder"
            elif [[ "$checkpoint" == *.zip ]]; then
                unzip -q "$checkpoint" -d "$predefined_folder"
            fi
            echo "Rollback from $checkpoint completed."
            break
        else
            echo "Invalid selection. Please choose again."
        fi
    done
}

menu() {
    echo "1. Create a backup checkpoint"
    echo "2. Rollback from a checkpoint"
    echo "3. Exit"
    read -rp "Enter your choice: " choice
    case $choice in
        1) create_checkpoint ;;
        2) rollback_checkpoint ;;
        3) exit ;;
        *) echo "Invalid option. Please try again." ;;
    esac
}

# Perform prechecks
precheck

# Main menu loop
while true; do
    echo
    menu
done
