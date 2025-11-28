#!/bin/zsh

if [ "`uname -a | grep -i android`" = "" ]; then
    # PC环境
    . ~/env.sh
    adb_wait_for_boot_ok

    alias acall=ashell
else
    # 手机环境
    acall() {
        $@
    }
fi

black_list="qti|qualcom|system|server|xiaomi|oppo|opluse|huawei|vivo|meizu|flyme|xjmz|debug|android"

# 保存当前系统中安装的所有app包名到变量
echo "正在获取已安装应用列表..."
# 使用变量保存应用列表，移除package:前缀
APPS=$(acall pm list packages | sed 's/package://g')
# 过滤掉黑名单中的应用
APPS=$(echo "$APPS" | grep -v -E "$black_list")
# 输出应用列表
echo "已安装应用列表:"
echo "$APPS"

# 计算应用数量
APP_COUNT=$(echo "$APPS" | wc -l)
echo "总共发现 $APP_COUNT 个应用"

sleep 1  # 等待1秒
echo "开始处理每个应用..."

app_ok_count=0
app_fail_list=""
# 遍历应用列表
for package in `echo $APPS`; do
    echo "----------------------------------------"
    echo "正在处理应用: $package"

    # 回到home
    echo "回到主页..."
    acall input keyevent 3  # KEYCODE_HOME

    # 等待1秒，确保回到主页
    sleep 1

    # 启动app
    echo "启动应用 $package..."
    if acall monkey -p "$package" -c android.intent.category.LAUNCHER 1 > /dev/null 2>&1; then
        app_ok_count=$((app_ok_count + 1))
        echo "应用 $package 启动成功"

        # 等待1秒，确保应用启动完成
        sleep 1

        # 滑动屏幕 (从(500,1500)滑动到(500,500)，持续500ms)
        echo "滑动屏幕..."
        acall input swipe 500 1500 500 500 500
        sleep 0.5

        echo "滑动屏幕..."
        acall input swipe 500 1500 500 500 500

        # 等待1秒，展示滑动效果
        sleep 1
    else
        app_fail_list="$app_fail_list $package"
        echo "警告: 无法启动应用 $package"
    fi

    # 每个应用操作后等待1秒
    sleep 1
done

echo "----------------------------------------"
echo "应用启动成功: $app_ok_count/$APP_COUNT"
echo "失败的应用列表:"
echo "$app_fail_list"
