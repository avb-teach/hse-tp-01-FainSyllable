#!/bin/bash

if [ "$#" -ne 2 ]; then
    echo "Нужно 2 аргумента: входная и выходная папки" >&2
    exit 1
fi

input_dir=$(realpath "$1")
output_dir=$(realpath "$2")

echo "Входная папка: $input_dir" >&1
echo "Выходная папка: $output_dir" >&1

if [ ! -d "$input_dir" ]; then
    echo "Ошибка: входная папка не существует!" >&2
    exit 1
fi

mkdir -p "$output_dir" || {
    echo "Ошибка создания папки" >&2
    exit 1
}

generate_unique_name() {
    local base_path="$1" name="$2" ext="$3" counter=1
    while [ -f "${base_path}/${name}_${counter}.${ext}" ]; do
        ((counter++))
    done
    echo "${name}_${counter}.${ext}"
}

for file in "$input_dir"/*.txt; do
    [ -e "$file" ] || continue
    
    filename=$(basename "$file")
    name="${filename%.*}"
    ext="${filename##*.}"

    if [ -f "$output_dir/$filename" ]; then
        if cmp -s "$file" "$output_dir/$filename"; then
            continue
        else
            new_name=$(generate_unique_name "$output_dir" "$name" "$ext")
            cp "$file" "$output_dir/$new_name" || exit 1
        fi
    else
        cp "$file" "$output_dir/" || exit 1
    fi
done

exit 0
