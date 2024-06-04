# Itay Zahor 208127480

#!/bin/bash

# Function to print usage information
usage() {
    echo "Usage: $0 <source_pgn_file> <destination_directory>"
    exit 1
}

# Validate the number of arguments
if [ $# -ne 2 ]; then
    usage
fi

input_file=$1
dest_dir=$2

# Check if the source file exists
if [ ! -f "$input_file" ]; then
    echo "Error: File '$input_file' does not exist."
    exit 1
fi

# Create the destination directory if it does not exist
if [ ! -d "$dest_dir" ]; then
    mkdir -p "$dest_dir"
    echo "Created directory '$dest_dir'."
fi

# Initializing game counter and output file
game_number=0
output_file=""

# Split the PGN file into individual game files
while IFS= read -r line || [ -n "$line" ]; do
    if [[ $line =~ ^\[Event[[:space:]]\".*\" ]]; then
        # Start a new game
        ((game_number++))
        output_file="$dest_dir/$(basename "$input_file" .pgn)_$game_number.pgn"
        echo "Saved game to '$output_file'."
    fi
    echo "$line" >> "$output_file"
done < "$input_file"

echo "All games have been split and saved to '$dest_dir'."
