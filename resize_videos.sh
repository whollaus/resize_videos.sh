#!/bin/bash

#================================================================
# resize_videos.sh
#
# Resizes all videos in the specified directory incl. subdirectories
#
## Features
#
# - Progress bar
# - Processing summary
# - JSON output
# - Quiet mode
# - Supported file formats: .mp4, .mov, .mkvm .avi
#
## Options:
#
#  		-h, --help           Display this help message.
#  		-s, --src            Source directory containing the original videos.
#  		-d, --dest           Destination directory for the resized videos.
#  		-q, --quiet          Run in quiet mode (suppress all output).
#  		-m, --max-dimension  Set maximum dimension for the longer side of the video.
#  		-c, --compression    Set quality for the resized videos. 0 = no compression (large file, good quality); 50 = strong compression (small file, poor quality); default value = 23
#  		-j, --json        	 Display the summary in json format.
#
## Dependencies:
#
# --- Attention: Developed and tested only under MacOS ---
#
# - ffmpeg
# ```bash
# brew install ffmpeg
# ```
# - bc
# - du
# - touch
#
## Installation:
#
# - Download the resize_videos.sh Script
# - Make the script executable:
# ```bash
#   chmod +x resize_videos.sh
# ```
#
## Usage
#
# ```bash
# resize_videos.sh -s ./originals -d ./resized -m 800 -c 23
# ```
#
## License:
#
# [MIT](https://choosealicense.com/licenses/mit/)
#
## Authors
#
# - [@whollaus](https://github.com/whollaus) form [HOLLAUS-IT](https://hollaus-it.at/)
#
## Versions:
#
# - 2024/10/02 : whollaus : First release
#================================================================

# Default values
SRC_DIR=""
DEST_DIR=""
MAX_DIMENSION="800"
FORMAT="mp4"
COMPRESSION="23"
START_TIME=$(date +%s)
QUIET=false
JSON_OUTPUT=0

# Display the help text
show_help() {
    print_msg "Usage: $(basename $0) [OPTIONS]"
    print_msg
    print_msg "Resizes all videos in the specified directory incl. subdirectories"
    print_msg
    print_msg "Supported file formats: .mp4, .mov, .mkvm .avi"
    print_msg
    print_msg "Options:"
    print_msg "  -h, --help           Display this help message."
    print_msg "  -s, --src            Source directory containing the original videos."
    print_msg "  -d, --dest           Destination directory for the resized videos."
    print_msg "  -q, --quiet          Run in quiet mode (suppress all output)."
    print_msg "  -m, --max-dimension  Set maximum dimension for the longer side of the video."
    print_msg "  -c, --compression    Set quality for the resized videos. 0 = no compression (large file, good quality); 50 = strong compression (small file, poor quality); default value = 23"
    print_msg "  -j, --json           Display the summary in json format"
    print_msg
    print_msg "Dependencies:"
    print_msg "  - ffmpeg"
    print_msg "  - bc"
    print_msg "  - du"
    print_msg "  - touch"
    print_msg
    print_msg "Example:"
    print_msg "  $(basename $0) -s ./originals -d ./resized -m 800 -c 23"
    print_msg
    print_msg "Copyright © MIT License - https://hollaus-it.at/"
}

# Function to output messages when the quiet mode is not active
print_msg() {
    if [ "$JSON_OUTPUT" -eq 0 ] && ! $QUIET; then
        # Checks if there are arguments after the first one (implies that it is a format string)
        if [ "$#" -gt 1 ]; then
            printf "$@"
        else
            echo "$1"
        fi
    fi
}

# Process arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -s|--source) SRC_DIR="$2"; shift ;;
        -d|--dest) DEST_DIR="$2"; shift ;;
        -m|--max-dimension) MAX_DIMENSION="$2"; shift ;;
        -f|--format) FORMAT="$2"; shift ;;
        -c|--compression) COMPRESSION="$2"; shift ;;
        -j|--json) JSON_OUTPUT=1; shift ;;
        -h|--help) show_help; exit 0 ;;
        --quiet) QUIET="$2"; shift ;;
        *) echo "Unknown parameter passed: $1"; show_help; exit 1 ;;
    esac
    shift
done

# check if the necessary arguments are set
if [[ -z "$SRC_DIR" || -z "$DEST_DIR" || -z "$MAX_DIMENSION" || -z "$COMPRESSION" ]]; then
    show_help
    exit 1
fi

# Check if all tools are installed
if ! command -v ffmpeg &> /dev/null; then
    echo "Error: ffmpeg is not installed." >&2
    exit 1
fi
if ! command -v bc &> /dev/null; then
    echo "Error: 'bc' is not installed." >&2
    exit 1
fi

if ! command -v du &> /dev/null; then
    echo "Error: 'du' is not installed." >&2
    exit 1
fi

if ! command -v touch &> /dev/null; then
    echo "Error: 'touch' is not installed." >&2
    exit 1
fi


# Checking the directories
if [ ! -d "$SRC_DIR" ]; then
    echo "Error: Source directory '$SRC_DIR' does not exist." >&2
    exit 1
fi

if [ ! -r "$SRC_DIR" ]; then
    echo "Error: Source directory '$SRC_DIR' is not readable." >&2
    exit 1
fi

if [ ! -d "$DEST_DIR" ]; then
    echo "Error: Destination directory '$DEST_DIR' does not exist." >&2
    exit 1
fi

if [ ! -w "$DEST_DIR" ]; then
    echo "Error: Destination directory '$DEST_DIR' is not writable." >&2
    exit 1
fi

total_videos=$(find "$SRC_DIR" -type f | wc -l)
processed_videos=0

print_progress_bar() {
    local total=$1
    local current=$2
    local width=50
    local perc=$((100*current/total))
    local bars=$((width*current/total))

    print_msg "|%-*s| %3d%% (%d/%d)\r" "$width" "$(printf "%0.s=" $(seq 1 $bars))" "$perc" "$current" "$total"
}


# Start processing
print_msg "====== PROCESS =========================================================================================="
print_msg "%-50s %-31s %-30s\n" "File" "Source" "Minimized"

processed_count=0
minimized_count=0
total_orig_size_kb=0

IFS=$'\n'
for src in $(find "$SRC_DIR" -type f \( -iname \*.mp4 -o -iname \*.mov -o -iname \*.mkv -o -iname \*.avi \)); do
    
    processed_count=$((processed_count + 1))
    
    file_size_kb=$(du -sk "$src" | awk '{print $1}')
	total_orig_size_kb=$((total_orig_size_kb + file_size_kb))
    
    src_rel_path="${src#$SRC_DIR/}"
    dest="$DEST_DIR/$src_rel_path"
    dest="${dest%.*}.$FORMAT"
    
 	# Create the destination directory
	src_folder=$(dirname "$SRC_DIR/$src_rel_path")
	dest_folder=$(dirname "$dest")

	if [[ ! -d "$dest_folder" ]]; then
    	mkdir -p "$dest_folder"
    fi
    
    # Minimize video
    if [[ ! -f "$dest" ]] || [[ "$src" -nt "$dest" ]]; then
            
        ffmpeg -loglevel quiet -i "$src" -vf "scale='if(gt(iw,ih),${MAX_DIMENSION},-2):if(gt(iw,ih),-2,${MAX_DIMENSION})',hqdn3d=1:1:1:1" -c:v libx264 -crf ${COMPRESSION} -preset slower -movflags +faststart -c:a aac -b:a 128k "$dest"
        
        touch -r "$src" "$dest" # Copy original file creation and modification date
        minimized_count=$((minimized_count + 1))
        
        orig_size=$(bc <<< "scale=2; $(stat -f%z "$src") / 1048576")
        orig_size=$(awk 'BEGIN{printf "%.2f", '$orig_size'}')
        
        minimized_size=$(bc <<< "scale=2; $(stat -f%z "$dest") / 1048576")
        minimized_size=$(awk 'BEGIN{printf "%.2f", '$minimized_size'}')

        print_msg "%-50s %-31s %-30s\n" "$src_rel_path" "${orig_size} MB" "${minimized_size} MB"
        		
    fi
    
    touch -r "${src_folder}" "${dest_folder}" # Copy original folder creation and modification date
    
    ((processed_videos++))
    print_progress_bar $total_videos $processed_videos
    
done

total_minimized_size_kb=$(du -sk "$DEST_DIR" | awk '{print $1}')

if [[ $total_orig_size_kb && $total_minimized_size_kb ]]; then
    total_orig_size=$(echo "scale=2; $total_orig_size_kb/1024" | bc -l)
    total_minimized_size=$(echo "scale=2; $total_minimized_size_kb/1024" | bc -l)
else
    total_orig_size="0.00"
    total_minimized_size="0.00"
fi

# Show summary
print_msg "====== SUMMARY =========================================================================================="
print_msg "Processed files:       $processed_count"
print_msg "Minimized files:       $minimized_count"

END_TIME=$(date +%s)
ELAPSED_TIME=$((END_TIME - START_TIME))

if [ "$JSON_OUTPUT" -eq 1 ]; then

    echo "{\"processed_files\": $processed_count, \"minimized_files\": $minimized_count, \"elapsed_time\": $ELAPSED_TIME, \"total_source_size\": $total_orig_size, \"total_minimized_size\": $total_minimized_size}"
    
else

	if (( ELAPSED_TIME < 60 )); then
	    print_msg "Total execution time:  $ELAPSED_TIME seconds"
	else
	    ELAPSED_MINUTES=$((ELAPSED_TIME / 60))
	    ELAPSED_SECONDS=$((ELAPSED_TIME % 60))
	    if (( ELAPSED_SECONDS > 0 )); then
	        print_msg "Total execution time:  $ELAPSED_MINUTES minutes and $ELAPSED_SECONDS seconds"
	    else
	        print_msg "Total execution time:  $ELAPSED_MINUTES minutes"
	    fi
	fi
	
	print_msg "Total Source Size:     $total_orig_size MB"
	print_msg "Total Minimized Size:  $total_minimized_size MB"


fi

