#!/bin/zsh

. ~/.local/env.sh

close_thermal_engine() {
    ashell stop thermal-engine
    ashell setprop ctl.stop thermal-engine
}

cpu_performance() {
    ashell '\
        # 获取 CPU 核心的数量
        n=$(nproc)
        # 对每个 CPU 核心进行设置
        for i in $(seq 0 $((n-1))); do
            echo performance | tee /sys/devices/system/cpu/cpu$i/cpufreq/scaling_governor
        done \
        '
}

adb_wait_for_boot_ok

close_thermal_engine
cpu_performance

ashell monkey \
--throttle 1500 \
--ignore-crashes \
--ignore-timeouts \
--pct-touch 35 \
--pct-motion 30 \
--pct-trackball 5 \
--pct-nav 2 \
--pct-majornav 5 \
--pct-syskeys 0 \
--pct-appswitch 10 \
--pct-flip 3 \
--pct-pinchzoom 2 \
--pct-anyevent 8 \
-s 20240405 \
-v -v -v 1728000 &

# ashell monkey \
# --throttle 400 \
# --ignore-crashes \
# --ignore-timeouts \
# --pct-touch 40 \
# --pct-motion 30 \
# --pct-trackball 2 \
# --pct-nav 2 \
# --pct-majornav 5 \
# --pct-syskeys 3 \
# --pct-appswitch 5 \
# --pct-flip 3 \
# --pct-pinchzoom 2 \
# --pct-anyevent 8 \
# -s 20240405 \
# -v -v -v 172800 &

monkey_pid=$!

exit_hook()
{
    echo "monkey process $monkey_pid is exiting..."
    kill -9 $monkey_pid > /dev/null 2>&1
    ashell kill -9 `ashell ps -ef | grep 'monkey' | grep -v grep | awk '{print $2}'` > /dev/null 2>&1
    exit 0
}

trap "echo ctrl+c!!!; exit_hook" SIGINT
# trap "exit_hook" EXIT

echo "--------------------------------------------------"
echo "monkey process id: $monkey_pid"
echo "--------------------------------------------------"

while true; do
    sleep 1

    ashell settings put system screen_brightness 1024
    # ashell cmd media_session volume --stream 1 --set 0 > /dev/null
    # ashell cmd media_session volume --stream 2 --set 0 > /dev/null
    # ashell cmd media_session volume --stream 3 --set 0 > /dev/null
    ashell input keyevent 25
    ashell input keyevent 25
    # ashell input keyevent 25
    # ashell input keyevent 25
    # ashell input keyevent 25
    # ashell input keyevent 25
    # ashell 'settings put system volume_music 0; \
    # settings put system volume_ring 0; \
    # settings put system volume_alarm 0; \
    # settings put system volume_notification 0; \
    # settings put system volume_system 0'

    # if ! ps -p $monkey_pid > /dev/null; then
    #     echo "monkey process has exited"
    #     break
    # fi
    # echo "monkey is running..."
done
