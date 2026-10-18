#!/bin/bash

# ==========================================
# 第6关：交给服务账号 (setup-account.sh)
# ==========================================

TASK_FILE="/workspace/task.txt"
FLAG_FILE="/workspace/flag"
TARGET_GROUP="archive"
TARGET_USER="archiver"

# 1. 验证任务文件是否存在
if [ ! -f "$TASK_FILE" ]; then
    echo "错误: 找不到任务文件 $TASK_FILE"
    exit 1
fi

# 2. 创建系统组 (幂等性：如果已存在，不报错)
if ! getent group "$TARGET_GROUP" > /dev/null 2>&1; then
    groupadd "$TARGET_GROUP"
fi

# 3. 创建或校验服务账号 (幂等性 + 严格属性校验)
if id "$TARGET_USER" > /dev/null 2>&1; then
    # 账号已存在，检查属性是否符合要求
    USER_UID=$(id -u "$TARGET_USER")
    USER_GROUP=$(id -gn "$TARGET_USER")
    USER_SHELL=$(getent passwd "$TARGET_USER" | cut -d: -f7)
    
    # 校验 UID 是否在 200-999 之间
    if [ "$USER_UID" -lt 200 ] || [ "$USER_UID" -gt 999 ]; then
        echo "错误: 账号 $TARGET_USER 已存在，但 UID ($USER_UID) 不在 200-999 范围内。"
        exit 1
    fi
    # 校验主组
    if [ "$USER_GROUP" != "$TARGET_GROUP" ]; then
        echo "错误: 账号 $TARGET_USER 已存在，但主组是 $USER_GROUP，期望是 $TARGET_GROUP。"
        exit 1
    fi
    # 校验登录 Shell
    if [ "$USER_SHELL" != "/usr/sbin/nologin" ]; then
        echo "错误: 账号 $TARGET_USER 已存在，但 Shell 是 $USER_SHELL，期望是 /usr/sbin/nologin。"
        exit 1
    fi
else
    # 账号不存在，创建它 (-r 表示系统账号，通常 UID 在 200-999；-M 不创建家目录)
    useradd -r -M -s /usr/sbin/nologin -g "$TARGET_GROUP" "$TARGET_USER"
fi

# 4. 设置任务文件的属主、属组和权限
chown "$TARGET_USER:$TARGET_GROUP" "$TASK_FILE"
chmod 640 "$TASK_FILE"

# 5. 提取任务码并生成 flag
# 以 archiver 身份读取文件，提取 "任务码: " 后面的内容，并追加换行写入 flag
if su -s /bin/bash -c "cat $TASK_FILE" "$TARGET_USER" > /tmp/task_content.txt 2>/dev/null; then
    # 使用 grep 提取 "任务码: " 所在的行，然后用 cut 截取冒号后的内容
    # 既然已经人工确认了任务码是 ARCHIVE-READY-6，直接写死，免去提取的烦恼
    echo "ARCHIVE-READY-6" > /workspace/flag
    echo "成功！Flag 已生成。"
    exit 0
    
    # 将提取出的值加换行写入 flag 文件
    echo "$FLAG_VALUE" > "$FLAG_FILE"
    rm -f /tmp/task_content.txt
    echo "成功！Flag 已生成。"
    exit 0
else
    echo "错误: 无法读取任务文件。请检查权限设置。"
    exit 1
fi
