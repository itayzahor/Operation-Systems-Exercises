#!/bin/bash

# Function to reset the board to the initial position
reset_board() {
  board=(
    [a8]=r [b8]=n [c8]=b [d8]=q [e8]=k [f8]=b [g8]=n [h8]=r
    [a7]=p [b7]=p [c7]=p [d7]=p [e7]=p [f7]=p [g7]=p [h7]=p
    [a6]='.' [b6]='.' [c6]='.' [d6]='.' [e6]='.' [f6]='.' [g6]='.' [h6]='.'
    [a5]='.' [b5]='.' [c5]='.' [d5]='.' [e5]='.' [f5]='.' [g5]='.' [h5]='.'
    [a4]='.' [b4]='.' [c4]='.' [d4]='.' [e4]='.' [f4]='.' [g4]='.' [h4]='.'
    [a3]='.' [b3]='.' [c3]='.' [d3]='.' [e3]='.' [f3]='.' [g3]='.' [h3]='.'
    [a2]=P [b2]=P [c2]=P [d2]=P [e2]=P [f2]=P [g2]=P [h2]=P
    [a1]=R [b1]=N [c1]=B [d1]=Q [e1]=K [f1]=B [g1]=N [h1]=R
  )
}

# Function to display the board
display_board() {
  echo "  a b c d e f g h"
  for rank in {8..1}; do
    row="$rank "
    for file in {a..h}; do
      square="${file}${rank}"
      row+="${board[$square]} "
    done
    echo "$row"
  done
  echo "  a b c d e f g h"
}

# Function to apply a move
apply_move() {
  move=$1
  from=$(echo $move | cut -c1-2)
  to=$(echo $move | cut -c3-4)

  piece=${board[$from]}
  board[$from]="."
  board[$to]=$piece
}


# Check if the PGN file is provided
if [[ -z "$1" ]]; then
    echo "Usage: $0 <pgn-file>"
    exit 1
fi

PGN_FILE="$1"

# Check if the file exists
if [[ ! -f "$PGN_FILE" ]]; then
    echo "File does not exist: $PGN_FILE"
    exit 1
fi

# Read the metadata from the PGN file
metadata=$(grep -E "\[.*\]" "$PGN_FILE")

# Display metadata
echo "Metadata from PGN file:"
echo -e "$metadata\n"

# Read the moves from the PGN file (starting from the first move)
pgn_moves=$(grep -vE "\[.*\]" "$PGN_FILE"  | sed 's/[0-9]\+\.//g')

# Run parse_moves.py on the full PGN string and store the result
uci_moves_string=$(python3 parse_moves.py "$pgn_moves")

# Initialize an array to hold the UCI moves
uci_moves=()

# Split the UCI moves string into an array of moves
IFS=' ' read -ra uci_moves <<< "$uci_moves_string"

# Create the chess board
declare -A board
reset_board

# Initialize move counters
current_move=0
total_moves=${#uci_moves[@]}

# Main loop to handle user input
while true; do
  echo "Move $current_move/$total_moves"
  display_board
  echo "Press 'd' to move forward, 'a' to move back, 'w' to go to the start, 's' to go to the end, 'q' to quit:"
  read -n 1 key
  echo

  case $key in
    d)
      if (( current_move < total_moves )); then
        current_move=$((current_move + 1))
        # Apply the next move
        move=${uci_moves[$current_move-1]}
        apply_move $move
      else
        echo "No more moves available."
      fi
      ;;
    a)
      if (( current_move > 0 )); then
        current_move=$((current_move - 1))
        # Reset the board and reapply moves up to current_move
        reset_board
        for ((i=0; i<current_move; i++)); do
          move=${uci_moves[$i]}
          apply_move $move
        done
      fi
      ;;
    w)
      current_move=0
      # Reset to the initial position
      reset_board
      ;;
    s)
      current_move=$total_moves
      for ((i=0; i<current_move; i++)); do
        move=${uci_moves[$i]}
        apply_move $move
      done
      ;;
    q)
      echo "Exiting."
      exit 0
      ;;
    *)
      echo "Invalid key pressed: $key"
      ;;
  esac
done
echo "End of game."