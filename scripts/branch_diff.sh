# !/bin/bash

# this script is used to compare two branches in multiple git repositories

if [ "$#" -lt 3 ];then
    echo "Usage: $0 <branch_left> <branch_right> <date_since> [-u <true|false>]"
    echo "Example: $0 branch1 branch2 2024-06-10 -u true"
    exit
fi

this_remote="null"
branch_left=$1
branch_right=$2
date_since=$3

if [ "$4" == "-u" ];then
    git_update=$5
else
    git_update="false"
fi

function echo_red()
{
	text=$1
	echo -e "\033[31m$text\033[0m"
}

function echo_green()
{
	text=$1
	echo -e "\033[32m$text\033[0m"
}

function search_one_repo()
{
	repo=$1
	if [ -z "$repo" ];then
		return
	fi

    this_remote="`git remote`"

	if [ "$git_update" != "false" ];then
		echo fetch $this_remote $branch_left $branch_right
		git fetch $this_remote $branch_left
        git fetch $this_remote $branch_right
	fi

	git branch -a|grep $branch_left > /dev/null
	if [ $? -ne 0 ];then
		echo $repo no branch: $branch_left
		return
	fi
	git branch -a|grep $branch_right > /dev/null
	if [ $? -ne 0 ];then
		echo $repo no branch: $branch_left
		return
	fi
	git log --pretty=format:"%h ! %s ! %cd" --date=format:"%Y-%m-%d %H:%M:%S" --since="$date_since 00:00:00" remotes/$this_remote/$branch_left > $branch_left.patch_list;
	git log --pretty=format:"%h ! %s ! %cd" --date=format:"%Y-%m-%d %H:%M:%S" --since="$date_since 00:00:00" remotes/$this_remote/$branch_right > $branch_right.patch_list
	left_size=$(wc -c $branch_left.patch_list|awk '{print $1}')
	right_size=$(wc -c $branch_right.patch_list|awk '{print $1}')
	if [ $left_size -lt 2 ] && [ $right_size -lt 2 ]; then
	   echo $repo no change
	   return
	fi
	echo "" >> $branch_left.patch_list
    echo "" >> $branch_right.patch_list
	echo $repo
	cat $branch_left.patch_list|while read patch
	do
		if [ -z "$patch" ];then
            continue;
        fi

		commit=$(echo $patch|awk -F'!' '{print $1}')
		title=$(echo $patch|awk -F'!' '{print $2}')
		ret=$(grep -F "!$title" $branch_right.patch_list)
		cnt=$(grep -F "!$title" $branch_right.patch_list|wc -l)
		if [ -z "$ret" ];then
			echo_red "    $patch in $branch_left but not in $branch_right"
			Author="$(git log $commit |head -3 |grep Author|sed 's/</ /'|sed 's/>/ /'|awk '{print $3}')"
			# Author=$(echo $commit|xargs git show |grep Author|sed 's/</ /'|sed 's/>/ /'|awk '{print $3}') # 该方法可能获得多个Author
			echo $repo ! n ! $patch ! $Author >> $out_file
		else
			if [ $cnt -gt 1 ];then
				# 相同title数量大于1
				# ret=$(grep -F "$commit" $branch_right.patch_list)	# 该方法会找不到对应提交
				ret_commit=$(grep -F "!$title" $branch_right.patch_list |awk '{printf $1 " "}')
				ret=$ret_commit$(grep -F "!$title" $branch_right.patch_list | head -1 |awk '{$1=""; printf $0}') # 该方法将显示所有对应的commit
			fi
			echo "    same patch: $patch"
			Author="$(git log $commit |head -3 |grep Author|sed 's/</ /'|sed 's/>/ /'|awk '{print $3}')"
			# Author=$(echo $commit|xargs git show |grep Author|sed 's/</ /'|sed 's/>/ /'|awk '{print $3}') # 该方法可能获得多个Author
			echo $repo ! y ! $patch ! $Author ! $ret >> $out_file
		fi
	done < "$branch_left.patch_list"

	cat $branch_right.patch_list|while read patch
	do
		commit=$(echo $patch|awk -F'!' '{print $1}')
		ret=$(grep -F "$commit" $branch_left.patch_list)
		if [ ! -z "$ret" ];then
			continue
		fi

		commit=$(echo $patch|awk -F'!' '{print $1}')
		title=$(echo $patch|awk -F'!' '{print $2}')
		ret=$(grep -F "!$title" $branch_left.patch_list)
		all_cnt=$(grep -F "!$title" $branch_left.patch_list $branch_right.patch_list|wc -l)
		if [ -z "$patch" ];then
			continue;
		fi
		if [ -z "$ret" ];then
				echo_red "    $patch in $branch_right but not in $branch_left"
			    Author="$(git log $commit |head -3 |grep Author|sed 's/</ /'|sed 's/>/ /'|awk '{print $3}')"
				# Author=$(echo $commit|xargs git show |grep Author|sed 's/</ /'|sed 's/>/ /'|awk '{print $3}') # 该方法可能获得多个Author
				echo $repo ! n !  !  !  ! $Author ! $patch >> $out_file
		else
			if [ $all_cnt -gt 2 ];then
				ret=$(grep -F "$commit" $branch_left.patch_list)
				if [ -z "$ret" ];then
					echo_red "    $patch in $branch_right but not in $branch_left"
			        Author="$(git log $commit |head -3 |grep Author|sed 's/</ /'|sed 's/>/ /'|awk '{print $3}')"
					# Author=$(echo $commit|xargs git show |grep Author|sed 's/</ /'|sed 's/>/ /'|awk '{print $3}') # 该方法可能获得多个Author
					echo $repo ! n !  !  !  ! $Author ! $patch >> $out_file
					continue
				fi
			fi
			echo "    same patch: $patch"
		fi
	done < "$branch_right.patch_list"

	rm $branch_left.patch_list $branch_right.patch_list
	echo ""
}


check_idle()
{
	while :
	do
	lim=`ls $LIMIT_DIR -l | grep "^-" | wc -l`
	# echo lim=$lim
	if [ $lim -lt 32 ];then
		return
	fi
	done
}

wait_done()
{
	while :
	do
	lim=`ls $LIMIT_DIR -l | grep "^-" | wc -l`
	if [ $lim -eq 0 ];then
		return
	fi
	done
}

# this is children
# echo NEW $*
if [ $6 == "self" ];then
	WORK_DIR=$7
	repo=$8
	LIMIT_DIR=${WORK_DIR}/limit
	ID=`echo $repo | sha1sum | awk '{print $1}'`
	out_file=${WORK_DIR}/${ID}.out

	echo start $repo $out_file

	touch $LIMIT_DIR/$ID
	touch $out_file
	cd $repo
	# sleep 1;
	search_one_repo $repo
	# cd - > /dev/null
	rm $LIMIT_DIR/$ID
	exit
fi

WORK_DIR=/tmp/branch_diff.`date +"%Y-%m-%d.%H_%m_%S"`
LIMIT_DIR=${WORK_DIR}/limit
# echo $WORK_DIR

croot=$(pwd)
repo_file=".repo/project.list"
out_file=$croot"/${branch_left}_${branch_right}_since_${date_since}.diff"
echo "仓库：$repo，提交时间：$date_since 00:00:00 ~ $(date '+%Y-%m-%d %H:%M:%S')" > $out_file
echo "" >> $out_file
echo "  仓库 ! sync ! $branch_left.patch_list ! ! !owner! $branch_right.patch_list ! !" >> $out_file

# this case for git dir
OLDIFS=$IFS
IFS=`echo -e "\n"`
if [ ! -e "$repo_file" ];then
	search_one_repo $(pwd)
	IFS=$OLDIFS
	echo ""
	echo_green "result is collected in $out_file"
	exit
fi

clean_out()
{
	cat ${WORK_DIR}/*.out >> $out_file
	rm -rf $WORK_DIR

	echo ""
	echo_green "result is collected in $out_file"

}

# trap "echo ctrl+c!!!; clean_out" SIGINT
trap "echo goodbye!!!; clean_out" EXIT

# this case for repo dir
mkdir $WORK_DIR
mkdir $LIMIT_DIR
cat $repo_file|while read repo
do
	check_idle
	$0 $branch_left $branch_right $date_since -u $git_update self $WORK_DIR $repo &
done < "$repo_file"
IFS=$OLDIFS

sleep 1
wait_done

exit
