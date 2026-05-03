#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

API_DIR="./api"

declare -a SERVICE_DIRS=()
declare -a ROOT_PROTO_FILES=()

if [ $# -eq 0 ]; then
    echo "📝 未指定服务，将处理 api/ 下的所有服务目录"
    while IFS= read -r dir; do
        SERVICE_DIRS+=("$dir")
    done < <(find "$API_DIR" -mindepth 1 -maxdepth 1 -type d | sort)
else
    for service in "$@"; do
        service_dir="$API_DIR/$service"
        if [ -d "$service_dir" ]; then
            SERVICE_DIRS+=("$service_dir")
        else
            echo "⚠️ 服务目录不存在: $service_dir"
        fi
    done
fi

while IFS= read -r file; do
    ROOT_PROTO_FILES+=("$file")
done < <(find "$API_DIR" -mindepth 1 -maxdepth 1 -type f -name "*.proto" | sort)

if [ ${#SERVICE_DIRS[@]} -eq 0 ] && [ ${#ROOT_PROTO_FILES[@]} -eq 0 ]; then
    echo "❌ 没有找到有效的 proto 文件"
    exit 1
fi

TOTAL_FILES=0
SUCCESS_COUNT=0
FAILED_COUNT=0

generate_proto() {
    local proto_file="$1"
    local prefix="$2"

    echo "${prefix}🔨 正在生成: $proto_file"
    TOTAL_FILES=$((TOTAL_FILES + 1))

    if protoc --go_out=. --go_opt=paths=source_relative \
        --go-triple_out=. --go-triple_opt=paths=source_relative \
        "$proto_file"; then
        echo "${prefix}✅ 生成成功"
        SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
    else
        echo "${prefix}❌ 生成失败: $proto_file"
        FAILED_COUNT=$((FAILED_COUNT + 1))
    fi
}

process_proto_files() {
    local dir="$1"
    local prefix="$2"
    local found=0

    while IFS= read -r proto_file; do
        found=1
        generate_proto "$proto_file" "$prefix"
    done < <(find "$dir" -type f -name "*.proto" | sort)

    if [ $found -eq 0 ]; then
        echo "${prefix}ℹ️ 未找到 proto 文件"
    fi
}

if [ ${#ROOT_PROTO_FILES[@]} -gt 0 ]; then
    echo -e "\n📁 正在处理根目录 proto: $API_DIR"
    for proto_file in "${ROOT_PROTO_FILES[@]}"; do
        generate_proto "$proto_file" "  "
    done
fi

for service_dir in "${SERVICE_DIRS[@]}"; do
    echo -e "\n📁 正在处理服务目录: $service_dir"
    process_proto_files "$service_dir" "  "
done

echo -e "\n========================================"
echo "🎉 处理完成！"
echo "📊 总计: $TOTAL_FILES 个文件"
echo "✅ 成功: $SUCCESS_COUNT 个"
echo "❌ 失败: $FAILED_COUNT 个"
echo "========================================"
