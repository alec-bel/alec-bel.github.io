#!/bin/bash

# Script to resize images based on aspect ratio
# Usage: ./resize_images.sh <input_image>

if [ $# -eq 0 ]; then
    echo "Usage: $0 <input_image>"
    echo "Example: $0 photo.jpg"
    exit 1
fi

input_image="$1"

# Check if input file exists
if [ ! -f "$input_image" ]; then
    echo "Error: File '$input_image' not found"
    exit 1
fi

# Get image dimensions using sips
dimensions=$(sips -g pixelWidth -g pixelHeight "$input_image" | grep -E "(pixelWidth|pixelHeight)" | awk '{print $2}')
width=$(echo "$dimensions" | head -1)
height=$(echo "$dimensions" | tail -1)

echo "Original image dimensions: ${width}x${height}"

# Calculate aspect ratio
aspect_ratio=$(echo "scale=2; $width / $height" | bc -l)

# Determine aspect ratio category
if (( $(echo "$aspect_ratio >= 0.8 && $aspect_ratio <= 1.2" | bc -l) )); then
    # Square-ish (1x1)
    aspect_category="1x1"
    thumbnail_max=200
    smaller_max=1200
elif (( $(echo "$aspect_ratio > 1.2 && $aspect_ratio <= 2.5" | bc -l) )); then
    # Wide (2x1, 3x1)
    if (( $(echo "$aspect_ratio >= 2.0" | bc -l) )); then
        aspect_category="3x1"
        thumbnail_max=600
        smaller_max=1600
    else
        aspect_category="2x1"
        thumbnail_max=400
        smaller_max=1200
    fi
elif (( $(echo "$aspect_ratio >= 0.4 && $aspect_ratio < 0.8" | bc -l) )); then
    # Tall (2x2, 3x2)
    if (( $(echo "$aspect_ratio >= 0.5" | bc -l) )); then
        aspect_category="2x2"
        thumbnail_max=400
        smaller_max=1200
    else
        aspect_category="3x2"
        thumbnail_max=600
        smaller_max=1800
    fi
else
    # Default to 1x1 for very extreme ratios
    aspect_category="1x1"
    thumbnail_max=200
    smaller_max=1200
fi

echo "Aspect ratio: $aspect_ratio (classified as $aspect_category)"
echo "Thumbnail max dimension: ${thumbnail_max}px"
echo "Smaller version max dimension: ${smaller_max}px"

# Generate output filenames
filename=$(basename "$input_image")
name_without_ext="${filename%.*}"
extension="${filename##*.}"

thumbnail_name="${name_without_ext}-thumbnail.${extension}"
smaller_name="${name_without_ext}.${extension}"

# Create thumbnail
echo "Creating thumbnail: $thumbnail_name"
sips -Z "$thumbnail_max" "$input_image" --out "$thumbnail_name"

# Create smaller version
echo "Creating smaller version: $smaller_name"
sips -Z "$smaller_max" "$input_image" --out "$smaller_name"

echo "Done! Created:"
echo "  - $thumbnail_name (${thumbnail_max}px max)"
echo "  - $smaller_name (${smaller_max}px max)" 