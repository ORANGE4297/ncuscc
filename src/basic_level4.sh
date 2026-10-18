#!/bin/bash

# 1. 初始化结果路径（完全尊重系统给的路径）
if [ -z "$ROUTE_RESULT" ]; then
    export ROUTE_RESULT="/workspace/flag"
else
    export ROUTE_RESULT
fi

# 2. 参数校验：必须恰好两个参数
if [ $# -ne 2 ]; then
    echo "usage"
    rm -f "$ROUTE_RESULT"
    exit 64
fi

MODE="$1"
ITEM="$2"

# 校验 MODE 和 ITEM 的合法性
if [[ ! "$MODE" =~ ^(ok|retry|fatal)$ ]] || [[ ! "$ITEM" =~ ^[a-zA-Z0-9]{1,32}$ ]]; then
    echo "usage"
    rm -f "$ROUTE_RESULT"
    exit 64
fi

# 3. 加载配置并导出环境变量
source /workspace/job.env
export ACCESS_TOKEN
export TASK_TOOL_DIR

# 4. 把工具目录加入 PATH
export PATH="$TASK_TOOL_DIR:$PATH"

# 5. 调用工具，捕获输出，并立刻保存退出码
OUTPUT=$(task-probe "$MODE" "$ITEM")
RC=$?

# 6. 根据退出码处理结果（严格使用 printf 控制格式和换行）
case $RC in
    0)
        # 假设工具的输出就是 "receipt:xxx"，我们原样保留，并补一个 \n
        printf "%s\n" "$OUTPUT" > "$ROUTE_RESULT"
        exit 0
        ;;
    11)
        printf "retry:%s\n" "$ITEM" > "$ROUTE_RESULT"
        exit 75
        ;;
    23)
        printf "rejected:%s\n" "$ITEM" > "$ROUTE_RESULT"
        exit 65
        ;;
    *)
        exit 1
        ;;
esac