# resize_videos.sh

Resizes all videos in the specified directory incl. subdirectories

# Features

- Progress bar
- Processing summary
- JSON output
- Quiet mode
- Supported file formats: .mp4, .mov, .mkvm .avi

# Options:

  		-h, --help           Display this help message.
  		-s, --src            Source directory containing the original videos.
  		-d, --dest           Destination directory for the resized videos.
  		-q, --quiet          Run in quiet mode (suppress all output).
  		-m, --max-dimension  Set maximum dimension for the longer side of the video.
  		-c, --compression    Set quality for the resized videos. 0 = no compression (large file, good quality); 50 = strong compression (small file, poor quality); default value = 23
  		-j, --json        	 Display the summary in json format.

# Dependencies:

--- Attention: Developed and tested only under MacOS ---

- ffmpeg
```bash
brew install ffmpeg
```
- bc
- du
- touch

# Installation:

- Download the resize_videos.sh Script
- Make the script executable:
```bash
  chmod +x resize_videos.sh
```

# Usage

```bash
resize_videos.sh -s ./originals -d ./resized -m 800 -c 23
```

# License:

[MIT](https://choosealicense.com/licenses/mit/)

# Authors

- [@whollaus](https://github.com/whollaus) form [HOLLAUS-IT](https://hollaus-it.at/)

# Versions:

- 2024/10/02 : whollaus : First release
