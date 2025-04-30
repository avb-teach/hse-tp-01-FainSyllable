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
        echo "Ошибка: Исходная папка '$input_dir' не существует" >&2
        exit 1
    }
    
    [[ -r "$input_dir" ]] || {
        echo "Ошибка: Нет доступа для чтения папки '$input_dir'" >&2
        exit 1
    }
    
    mkdir -p "$output_dir" || {
        echo "Ошибка: Не удалось создать папку '$output_dir'" >&2
        exit 1
    }
    
    [[ -w "$output_dir" ]] || {
        echo "Ошибка: Нет доступа для записи в папку '$output_dir'" >&2
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
                echo "[✓] Пропущен дубликат: $filename"
            else
                new_name=$(get_unique_name "$output_dir" "$name" "$ext")
                cp -- "$file" "$output_dir/$new_name" && ((count++))
                echo "[→] Скопирован как: $new_name"
            fi
        else
            cp -- "$file" "$output_dir/" && ((count++))
            echo "[+] Скопирован: $filename"
        fi
    done < <(find "$input_dir" -maxdepth "$max_depth" -type f -name "*.txt" -print0)
    
    echo "Всего скопировано файлов: $count"
}

if [[ $# -lt 2 || $# -gt 4 ]]; then
    echo "Использование: $0 [-d ГЛУБИНА] исходная_папка выходная_папка" >&2
    exit 1
fi

if [[ "$1" == "-d" ]]; then
    [[ "$2" =~ ^[0-9]+$ ]] || {
        echo "Ошибка: Глубина должна быть положительным числом" >&2
        exit 1
    }
    max_depth="$2"
    input_dir="$3"
    output_dir="$4"
else
    input_dir="$1"
    output_dir="$2"
fi

echo "Начало обработки файлов"
check_dirs
copy_files
echo "Обработка завершена успешно"
