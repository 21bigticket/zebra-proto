#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# 默认 proto 根目录
API_DIR="./api"

# 处理命令行参数
if [ $# -eq 0 ]; then
    # 没有参数时，处理 api/ 下的所有子目录
    SERVICE_DIRS=$(find "$API_DIR" -maxdepth 1 -type d ! -path "$API_DIR")
    echo "📝 未指定服务，将处理 api/ 下的所有服务目录"
else
    # 有参数时，处理指定的服务目录
    SERVICE_DIRS=""
    for service in "$@"; do
        service_dir="$API_DIR/$service"
        if [ -d "$service_dir" ]; then
            SERVICE_DIRS="$SERVICE_DIRS $service_dir"
        else
            echo "⚠️ 服务目录不存在: $service_dir"
        fi
    done
fi

# 检查是否有有效的服务目录
if [ -z "$SERVICE_DIRS" ]; then
    echo "❌ 没有找到有效的服务目录"
    exit 1
fi

# 统计变量
TOTAL_FILES=0
SUCCESS_COUNT=0
FAILED_COUNT=0

# 处理 proto 文件的函数
process_proto_files() {
    local dir="$1"
    local prefix="$2"

    # 递归查找该目录下所有 .proto 文件
    local proto_files=$(find "$dir" -type f -name "*.proto")

    # 检查是否找到 proto 文件
    if [ -z "$proto_files" ]; then
        return
    fi

    # 逐个执行 protoc 生成命令
    for proto_file in $proto_files; do
        echo "${prefix}🔨 正在生成: $proto_file"
        TOTAL_FILES=$((TOTAL_FILES + 1))

        protoc --go_out=. --go_opt=paths=source_relative \
               --go-triple_out=. --go-triple_opt=paths=source_relative \
               "$proto_file"

        # 检查命令执行结果
        if [ $? -eq 0 ]; then
            echo "${prefix}✅ 生成成功"
            SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
        else
            echo "${prefix}❌ 生成失败: $proto_file"
            FAILED_COUNT=$((FAILED_COUNT + 1))
        fi
    done
}

# 首先处理 api/ 目录下直接的 .proto 文件
echo -e "\n📁 正在处理目录: $API_DIR"
process_proto_files "$API_DIR" "  "

# 然后遍历每个服务子目录
for service_dir in $SERVICE_DIRS; do
    echo -e "\n📁 正在处理服务目录: $service_dir"
    process_proto_files "$service_dir" "  "
done

# 输出总结
echo -e "\n========================================"
echo "🎉 处理完成！"
echo "📊 总计: $TOTAL_FILES 个文件"
echo "✅ 成功: $SUCCESS_COUNT 个"
echo "❌ 失败: $FAILED_COUNT 个"
echo "========================================"
