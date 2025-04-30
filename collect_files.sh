#!/bin/bash

if [ "$#" -ne 2 ]; then
    echo "Нужно 2 аргумента: входная и выходная папки"
    exit 1
fi

input_dir="$1"
output_dir="$2"

echo "Входная папка: $input_dir"
echo "Выходная папка: $output_dir"

if [ ! -d "$input_dir" ]; then
    echo "Ошибка: входная папка не существует!"
    exit 1
fi

mkdir -p "$output_dir"
echo "Создана папка: $output_dir"

generate_unique_name() {
    local base_path="$1"
    local name="$2"
    local ext="$3"
    local counter=1
    
    if [ -z "$ext" ]; then
        while [ -e "${base_path}/${name}_${counter}" ]; do
            ((counter++))
        done
        echo "${name}_${counter}"
    else
        while [ -e "${base_path}/${name}_${counter}.${ext}" ]; do
            ((counter++))
        done
        echo "${name}_${counter}.${ext}"
    fi
}

process_file() {
    local file="$1"
    local output_dir="$2"
    
    local filename=$(basename "$file")
    local name="${filename%.*}"
    local ext="${filename##*.}"
    
    if [ "$name" = "$filename" ]; then
        ext=""
    fi

    if [ -f "$output_dir/$filename" ]; then
        if cmp -s "$file" "$output_dir/$filename"; then
            echo "Файл '$filename' уже существует и идентичен - пропускаем"
            return
        else
            new_name=$(generate_unique_name "$output_dir" "$name" "$ext")
            cp "$file" "$output_dir/$new_name"
            echo "Скопирован (дубликат): $new_name"
        fi
    else
        cp "$file" "$output_dir/"
        echo "Скопирован: $filename"
    fi
}

find "$input_dir" -type f | while read -r file; do
    process_file "$file" "$output_dir"
done

echo "Готово, всего файлов: $(ls "$output_dir" | wc -l)"
