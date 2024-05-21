#!/bin/bash

checksum() {
    local filePath="$1"
    md5sum "$filePath" | awk '{ print $1 }'
}

# Function to synchronize directories (One-way)
syncDirectories() {
    local srcDir="$1"
    local destDir="$2"

    # Create missing directories
    for srcSubDir in "$srcDir"/*; do
        if [[ -d "$srcSubDir" ]]; then
            local subDirName=$(basename "$srcSubDir")
            local destSubDir="$destDir/$subDirName"
            if [[ ! -d "$destSubDir" ]]; then
                mkdir -p "$destSubDir"
                echo "Created directory $destSubDir"
            fi
            # Recursively sync subdirectories
            syncDirectories "$srcSubDir" "$destSubDir"
        fi
    done

    # Sync files
    for srcFile in "$srcDir"/*; do
        if [[ -f "$srcFile" ]]; then
            local fileName=$(basename "$srcFile")
            local destFile="$destDir/$fileName"

            if [[ -f "$destFile" ]]; then
                local srcChecksum=$(checksum "$srcFile")
                local destChecksum=$(checksum "$destFile")

                if [[ "$srcChecksum" != "$destChecksum" ]]; then
                    cp "$srcFile" "$destFile"
                    echo "Updated $destFile"
                fi
            else
                cp "$srcFile" "$destFile"
                echo "Copied $srcFile to $destFile"
            fi
        fi
    done
}

# Function to monitor changes in the source directory
monitorChanges() {
    local srcDir="$1"
    echo "Monitoring changes in $srcDir"
    inotifywait -m -r -e modify,create,delete --format '%w %f %e' "$srcDir" | while read dir file event; do
        path="$dir$file"
        echo "Change detected: $path with event: $event"
        case "$event" in
            MODIFY|CREATE)
                echo "Copying file $file to remote."
                rclone copy "$path" uno:test/
                ;;
            DELETE)
                echo "Removing file $file from remote."
                rclone deletefile "uno:test/$file"
                ;;
            *)
                echo "Unhandled event: $event"
                ;;
        esac
    done
}

# Validate directories
validateDirectories() {
    if [[ ! -d "$1" ]]; then
        echo "Error: Source directory $1 does not exist or is not a directory."
        exit 1
    fi
    if [[ ! -d "$2" ]]; then
        echo "Error: Destination directory $2 does not exist or is not a directory."
        exit 1
    fi
}

# Main function
sankar() {
    local intervalSec="$1"
    local src="$2"
    local dest="$3"
    local twoWay="$4"

    while true; do
        syncDirectories "$src" "$dest"
        if [[ "$twoWay" == "true" ]]; then
            syncDirectories "$dest" "$src"
        fi
        sleep $intervalSec
    done
}

# Default values
intervalSec=0
intervalSet=false
twoWay=true
watcherMode=false

# Option parsing
while [[ "$#" -gt 0 ]]; do
    case "$1" in
        -h|--hour)
            if [[ -n "$2" && "$2" =~ ^[0-9]+$ ]]; then
                intervalSec=$(( $2 * 3600 ))
                intervalSet=true
                shift 2
            else
                echo "Error: --hour requires a numerical argument."
                exit 1
            fi
            ;;
        --daily)
            intervalSec=86400
            intervalSet=true
            shift 1
            ;;
        -ow|--one-way)
            twoWay=false
            shift 1
            ;;
        -w|--watcher-mode)
            if [[ "$intervalSet" == "true" ]]; then
                echo "Error: --watcher-mode cannot be used with interval arguments."
                exit 1
            fi
            watcherMode=true
            ;;
        *)
            if [[ -z "$src" ]]; then
                src="$1"
            elif [[ -z "$dest" ]]; then
                dest="$1"
            elif [[ -z "$intervalMS" ]]; then
                intervalSec=$(echo "scale=3; $1 / 1000" | bc)
                intervalSet=true
            else
                echo "Error: Unknown argument: $1"
                exit 1
            fi
            shift 1
            ;;
    esac
done

# monitorChanges "$src"

# Validate inputs
if [[ -z "$src" || -z "$dest" && (! "$intervalSet" == "true" && "$watcherMode" == "false") || (! "$intervalSet" == "false" && "$watcherMode" == "true")]]; then
    echo "Usage: $0 [options] <sourceDir> <targetDir>"
    echo "Options:"
    echo "  -h, --hour <n>         Run the script every n hours"
    echo "  --daily                Run the script once daily"
    echo "  -ow, --one-way         Sync from source to target directory only"
    echo "  -w, --watcher-mode    Monitor source directory and upload to remote on change"
    exit 1
fi

if [[ "$watcherMode" == true ]]; then
    monitorChanges "$src"
else
    validateDirectories "$src" "$dest"
    sankar "$intervalSec" "$src" "$dest" "$twoWay"
fi
