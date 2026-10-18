#!/bin/bash

WORK_DIR="${WORK_DIR:-/opt/recruitment}"
PID_FILE="$WORK_DIR/worker.pid"
WORKER="/opt/recruitment/bin/slow-worker"

is_running() {
    if [ -f "$PID_FILE" ]; then
        local pid
        pid=$(cat "$PID_FILE" 2>/dev/null)
        if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
            local cmd
            cmd=$(ps -p "$pid" -o args= 2>/dev/null)
            if echo "$cmd" | grep -q "slow-worker"; then
                return 0
            fi
        fi
    fi
    return 1
}

do_start() {
    if is_running; then
        return 0
    fi
    mkdir -p "$WORK_DIR"
    nohup "$WORKER" > /dev/null 2>&1 &
    echo "$!" > "$PID_FILE"
    return 0
}

do_status() {
    if is_running; then
        echo "running"
        return 0
    else
        echo "stopped"
        return 1
    fi
}

do_report() {
    if ! is_running; then
        return 1
    fi
    local pid
    pid=$(cat "$PID_FILE")
    local report_file="$WORK_DIR/resource.txt"
    echo "PID=$pid" > "$report_file"
    ps -p "$pid" -o pid,stat,args >> "$report_file" 2>/dev/null
    top -b -n 1 -p "$pid" >> "$report_file" 2>/dev/null
    return 0
}

do_stop() {
    if ! is_running; then
        return 0
    fi
    local pid
    pid=$(cat "$PID_FILE")
    kill -TERM "$pid" 2>/dev/null
    # 只短等一次，避免超时
    sleep 1
    # 如果还在，再补一次 TERM
    if kill -0 "$pid" 2>/dev/null; then
        kill -TERM "$pid" 2>/dev/null
        sleep 1
    fi
    rm -f "$PID_FILE"
    return 0
}

case "${1}" in
    start)
        do_start
        ;;
    status)
        do_status
        ;;
    report)
        do_report
        ;;
    stop)
        do_stop
        ;;
    *)
        echo "usage"
        exit 64
        ;;
esac