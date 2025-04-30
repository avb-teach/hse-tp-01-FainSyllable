#!/usr/bin/env bash

set -euo pipefail

max_depth=999
input_dir=""
output_dir=""

cleanup() {
    unset input_dir output_dir max_depth
}
trap cleanup EXIT

check_dirs() {
    [[ -d "$input_dir" ]] || {
        echo "Error: Input directory '$input_dir' does not exist" >&2
        exit 1
    }
    
    [[ -r "$input_dir" ]] || {
        echo "Error: Input directory '$input_dir' is not readable" >&2
        exit 1
    }
    
    mkdir -p "$output_dir" || {
        echo "Error: Cannot create output directory '$output_dir'" >&2
        exit 1
    }
    
    [[ -w "$output_dir" ]] || {
        echo "Error: Output directory '$output_dir' is not writable" >&2
        exit 1
    }
}

get_unique_name() {
    local path="$1" name="$2" ext="$3" counter=1
    while [[ -f "$path/${name}_$counter.$ext" ]]; do
        ((counter++))
    done
    echo "${name}_$counter.$ext"
}

copy_files() {
    local count=0
    while IFS= read -r -d '' file; do
        filename=$(basename -- "$file")
        name="${filename%.*}"
        ext="${filename##*.}"
        
        if [[ -f "$output_dir/$filename" ]]; then
            if cmp -s "$file" "$output_dir/$filename"; then
                echo "[✓] Skipped duplicate: $filename"
            else
                new_name=$(get_unique_name "$output_dir" "$name" "$ext")
                cp -- "$file" "$output_dir/$new_name" && ((count++))
                echo "[→] Copied as: $new_name"
            fi
        else
            cp -- "$file" "$output_dir/" && ((count++))
            echo "[+] Copied: $filename"
        fi
    done < <(find "$input_dir" -maxdepth "$max_depth" -type f -name "*.txt" -print0)
    
    echo "Total files copied: $count"
}

if [[ $# -lt 2 || $# -gt 4 ]]; then
    echo "Usage: $0 [-d DEPTH] input_dir output_dir" >&2
    exit 1
fi

if [[ "$1" == "-d" ]]; then
    [[ "$2" =~ ^[0-9]+$ ]] || {
        echo "Error: Depth must be a positive integer" >&2
        exit 1
    }
    max_depth="$2"
    input_dir="$3"
    output_dir="$4"
else
    input_dir="$1"
    output_dir="$2"
fi

echo "Starting file processing"
check_dirs
copy_files
echo "Processing completed successfully"