#!/bin/bash
# Author: casey
# date: 2024-12-12
# 分析指定目录中可执行文件（动态库）的依赖关系，输出svg关系图表

#########################################################################
######################## config that
OBJDUMP=objdump
######################## config end
#########################################################################

# 获取要遍历的目录路径
dir_path=$1

# 确保目录路径已输入
if [ -z "$dir_path" ]; then
  echo "请指定要遍历的目录路径，例如：$0 /usr/local/bin"
  exit 1
fi

# 确保目录存在
if [ ! -d "$dir_path" ]; then
  echo "找不到目录：$dir_path"
  exit 1
fi

# Define_dot_file_name
current_date=`date +%Y-%m-%d`
DOT_FILE="dependencies_${current_date}.gv"
# 导出依赖库路径到 CSV 文件
output_file="dependencies_${current_date}.csv"
echo -e "程序名称,依赖库路径" > $output_file

# 开始生成DOT文件
echo "digraph dependencies {" > "$DOT_FILE"

# 遍历目录中的所有程序
# for program_path in `find $dir_path -type f -executable`; do
for program_path in `find $dir_path -executable`; do
    # 获取程序名
    program_name=$(basename $program_path)

        # 跳过链接文件的分析
        # program_real_path=`readlink $program_path`
        # if [ $? -eq 0 ]; then
        #         # program_real=$(basename $program_real_path)
        #         # 跳过busybox的链接文件
        #         # if [ $program_real = "busybox" ]; then
        #         # continue
        #         # fi

        #         # echo '  "'${program_real}'" -> "'${program_name}'"' >> "$DOT_FILE"
        #         # 链接文件直接显示源文件
        #         # program_name=$program_real
        #         continue
        # fi

    # 跳过对文件夹的分析
    # if [ -d "$program_path" ]; then
    #   continue
    # fi

    # 只分析elf文件
    if [[ ! $(file -b "$program_path" | grep "ELF" ) ]]; then
      continue
    fi

    # 获取程序的所有依赖库路径
    dependencies=$($OBJDUMP -p $program_path | awk '/NEEDED/ {print $2}')

    # 遍历所有依赖
    for dependency in $dependencies; do
        file_get=`find $dir_path -name $dependency`
        if [ -z "$file_get" ]; then
          # 如果依赖文件不存在
          echo '  "not_exist" -> "'${dependency}'"[color="red"]' >> "$DOT_FILE"
          echo -e "${dependency},not_exist" >> $output_file
        else
          # 在目录中找到依赖文件
          dependency_real_path=`readlink $file_get`
          # 如果依赖文件是链接文件，则直接显示源文件名称
          if [ -z "$dependency_real_path" ]; then
            dependency_real=
          else
            dependency_real=$(basename $dependency_real_path)
            dependency=$dependency_real
          fi
        fi
        # 输出依赖关系到Dot文件中
        echo '  "'${dependency}'" -> "'${program_name}'"' >> "$DOT_FILE"
        echo -e "${program_name},${dependency}" >> $output_file
    done

done

# 结束Dot文件
echo "}" >> "$DOT_FILE"

echo "程序依赖库路径已导出到文件 $output_file $DOT_FILE"

dot -Tsvg $DOT_FILE -o $DOT_FILE.svg
