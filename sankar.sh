 #!/bin/bash

# QuickXorHash (Prototype)
quickXorHash() {
    local filePath="$1"
    local hash=0
    local offset=0
    local byte
    while IFS= read -r -n1 byte; do
        local byteVal=$(printf "%d" "'$byte")
        hash=$((hash ^ (byteVal << (offset % 15))))
        offset=$((offset + 1))
    done < "$filePath"
    echo $hash
}

# Function to synchronize dirs (One-way - Prototype)
syncDirectories() {
    local srcDir="$1"
    local destDir="$2"

    for srcFile in "$srcDir"/*; do
        if [[ -f "$srcFile" ]]; then
            local fileName=$(basename "$srcFile")
            local destFile="$destDir/$fileName"

            if [[ -f "$destFile" ]]; then
                local srcHash=$(quickXorHash "$srcFile")
                local destHash=$(quickXorHash "$destFile")

                if [[ "$srcHash" != "$destHash" ]]; then
                    cp "$srcFile" "$destFile"
                    echo "Updated $destFile"
                fi
            else
                cp "$srcFile" "$destFile"
                echo "Copied $srcFile to $dest"
            fi
        fi
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

# Main Function
sankar() {
    local intervalMS="$1"
    local src="$2"
    local dest="$3"
    local sleepSec=$(echo "scale=3; $intervalMS / 1000" | bc)
    while true; do
        syncDirectories "$src" "$dest"
        sleep $sleepSec
    done
}

# Check args
if [[ $# -ne 3 ]]; then
    echo "Usage: $0 <sourceDir> <targetDir> <intervalMs>"
    exit 1
fi

validateDirectories "$1" "$2"
sankar "$3" "$1" "$2"
