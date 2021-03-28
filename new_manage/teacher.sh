#!/bin/bash
# UTF-8
# 程序名称: teacher.sh
# 作者: 鲍奕帆
# 学号: 3180103499
# 程序功能: 教师模块 提供相应的登陆界面以及各种支持函数

# 调用登陆与操作函数
teacher()
{
	t_login
	t_operate
	
}

t_login()
{
	read -p "please enter teacher ID: " teacher_ID  # 获取老师ID 后面均为这个
	# 注意我们的账号要**等长**
	# 否则回有匹配错误的问题--下同
	count=` cat account | awk '{print $1}' | grep -c "$teacher_ID" `
	if [ "$count" = "0" ]
    then
		echo "teacher ID doesn't exist, exit..." # 老师ID不存在
		exit 3
	fi
	echo -n "Please enter your password: " # 提示输入教师密码验证
	read -s passwd
	real_password=` cat account | grep ^"$teacher_ID" | awk '{print $3}' `
	if [ "$passwd" = "$real_password" ]
	then
		teacher_name=` cat account | grep ^"$teacher_ID" | awk '{print $2}' `
		echo 
        echo "welcome $teacher_name" # 欢迎
		return 0
	else
        echo 
		echo "wrong password, exit..." # 密码错误 退出
		exit 3
	fi
}

t_operate()
{
	# 此处直接获取course ID
	# 不完善 应该增加教师是否授课的内容-尽早的将可能出现的问题解决
	# 当然后面也会有类似提示 所以影响不大
	read -p "Please enter the course ID you are going to manage: " course_ID

	echo "Please enter your operation: "
	echo "1 manage course info"			# 1管理课程信息	
	echo "2 manage homework"			# 2管理作业
	echo "3 homework completion"		# 3查看作业完成情况
	echo "4 manage student"				# 管理学生
	echo "q exit the system"			# 退出系统

	read option							# 获取选项
	case $option in
		# 进入对应的界面
		1) manage_course_info	;;
		2) manage_homework		;;
		3) homework_completion	;;
		4) manage_student		;;
		q) exit 0				;;
	esac
	exit 1 

}
# 管理学生菜单
manage_student()
{
	echo "Please enter your option: "
	echo "1 --import student record"	# 1导入学生信息
	echo "2 --modify student record"	# 2修改学生信息
	echo "3 --delete student record"	# 3删除学生信息
	echo "4 --search student record"	# 4查找学生信息
	echo "q --exit the system"			# q退出系统
	echo "r --return to the previous menu" # r返回上一级菜单

	read option							# 读取选项
	case $option in						# 进入不同菜单
		"1") import_student ;;
		"2") modify_student ;;
		"3") delete_student ;;
		"4") search_student ;;
		"q") exit 0	 	    ;;
		"r") echo "return to the previous menu in 3 seconds"
			 sleep 3 
			 t_operate      ;;  
         *) echo "wrong command, try again" # 命令错误 重新进入当前菜单
			 manage_student
			 exit 1			;;
	esac
	
	exit 0
}

import_student()
{
	read -p "Please enter student ID: " student_ID # 读取对应学生ID
	
	# 判断学生信息是否存在
	count=` cat account | awk '{print $1}' | grep -c "$student_ID" `
	if [ "$count" != "0" ] #if 学生信息存在
	then
		count=` cat take/"$student_ID" | awk '{print $1}' | grep -c "$course_ID" `
		if [ "$count" != "0" ]
		then
			echo "the student is in the course" # 学生在课程中
			echo "return to the previous menu in 3 seconds"
			sleep 3
			manage_student
			exit 1
		fi
		
		# 学生信息存在且未选课--建立选课信息的目录
		echo "begin importing"
		echo "$course_ID" "$teacher_ID" >> take/"$student_ID" # 该学生增加一条选课信息
		# 对course_teacher/cid_tid/student_info记录相关信息
		echo "$student_ID" >> course_teacher/$course_ID"_"$teacher_ID/student_info
		echo "succeed" # 提示成功
		echo "reutrn to the previous menu in 2 seconds"
		sleep 2
        manage_student
		exit 1
	else #学生信息不存在
		echo "student doesn't exit"
		echo "return to the previous menu in 2 seconds"
        sleep 2
		manage_student
	fi
}

# 删除学生选课信息
delete_student()
{
	read -p "Please enter student ID: " student_ID # 读取学生ID
	#判断选课记录的目录是否存在
	
	count=` echo course_teacher/$course_ID"_"$teacher_ID/student_info | grep ^"$student_ID" `
	if [ "$count" != "0" ]
	then
        echo "begin processing" # 提示用户开始处理
		sed -i "/.*"${student_ID}"*./d" course_teacher/$course_ID"_"$teacher_ID/student_info
		sed -i "/"$course_ID" "$teacher_ID"/d"  take/"$student_ID"
	    echo "succeed"			# 提示成功
		echo "return to the previous menu in 3 seconds"
		manage_student
		exit 1
    else
		echo "student not registered"	# 学生未注册
		echo "reutrn to the previous menu in 3 seconds"
		manage_student
		exit 1
    fi
}

# 查找学生
# 考虑到基本信息的公开性,这里查找的不仅仅是学生
# 也可以是老师,学生也可以不是自己班级上的
search_student()
{
	read -p "Please enter student ID: " student_ID # 查找的学生ID
	
	count=` cat account | awk '{print $1}' | grep -c "$student_ID" `
	if [ $count = 0 ] #if 学生信息不存在
	then 
		echo "student does not exit" # 学生信息不存在
		echo "return to the previous menu in 3 seconds"
		sleep 3
		manage_student
		exit 1
	else 
		echo "student_ID student_name"	# 显示学生信息
		cat account | grep ^"$student_ID" | awk '{print $1,$2}'
		echo "return to the previous menu in 3 seconds"
		sleep 3
        manage_student
		exit 1 
	fi
}


# 修改学生信息
# 教师没有权力更改学生的信息
# 因此这里就是减少一个记录，再增加一个记录
modify_student()
{
	read -p "Please enter student ID to be modified: " student_ID
	#检查学生信息是否存在
	count=` cat account | awk '{print $1}' | grep -c "$student_ID" ` #账户信息
	count_new=` cat course_teacher/$course_ID"_"$teacher_ID/student_info | awk '{print $1}' | grep -c ^"$student_ID" `  #选课信息
	if [ "$count" != 0 ] && [ "$count_new" != "0"  ]  #if 学生信息存在并选选课
	then 
		echo "student_ID student_name"
		cat account | grep ^"$student_ID" | awk '{print $1,$2}'
		read -p "Please enter new student ID and name: " new_ID new_name
		# 检查新学生选课信息是否存在
		count_new=` cat course_teacher/$course_ID"_"$teacher_ID/student_info | awk '{print $1}' | grep -c ^"$new_ID" `
		count=` cat account | awk '{print $1}' | grep -c "$new_ID" ` 
		if [ "$count" != "0" ] && [ "$count_new" = "0" ]
		then
			# 用新的名字替换--注意对应学生选课信息要改
			sed -i "s/.*${student_ID}.*/"$new_ID" "$new_name"/ " course_teacher/$course_ID"_"$teacher_ID/student_info
			sed -i "/"$course_ID" "$teacher_ID"/d"  take/"$student_ID" # 删除原来学生的记录
			echo "$course_ID" "$teacher_ID: " >> take/"$student_ID" # 该学生增加一条选课信息
		    echo "succeed"
            echo "return to the previous menu in 2 seconds"
            sleep 2
            manage_student
        else
			echo "wrong student info" # 学生信息错误
			echo "reutrn to the previous menu in 3 seconds"
			sleep 3
			manage_student
		fi
	else 
		echo "wrong student info"	# 学生信息错误 返回上一级菜单
		echo "reutrn to the previous menu in 3 seconds"
		sleep 3
		manage_student
	fi
	exit 1
}





manage_homework()
{
	echo "Please enter your option: "	 # 提示用户输入选项
	echo "1 new homework"				 # 1增加作业
	echo "2 edit homework"				 # 2编辑作业描述
	echo "3 delete homework"			 # 3删除作业
	echo "4 list homework"				 # 4列出作业
	echo "q exit system"				 # q退出系统 
	echo "r return to the previous menu" # r返回上一菜单

	read option
	case $option in			# 根据选项进入不同的菜单
		1) new_homework		;;
		2) edit_homework	;;
		3) delete_homework	;;
		4) list_homework	;;
		q) exit 0			;;
		r) echo "return to the previous menu in 3 seconds"
           sleep 3
           t_operate 		;;
		*) echo "wrong option, return to the previous menu in 3 seconds"
		   sleep 3
           t_operate		;;	#其实也可以直接就这样-返回就ok了
	esac
	exit 1
}

#管理课程信息
manage_course_info()
{
	echo "Please enter your option: "		# 提示输入选项
	echo "1 new course info"				# 1增加课程信息
	echo "2 edit course info"				# 编辑课程信息
	echo "3 delete course info"				# 删除课程信息
	echo "4 list course info"				# 显示课程信息
	echo "q exit system"					# 退出系统
	echo "r return to the previous menu"	# 返回上一级菜单
	read option
	case $option in			# 根据选项选择
		1) new_course_info	  ;;
		2) edit_course_info	  ;;
		3) delete_course_info ;;
		4) list_course_info   ;;
		q) exit 0			  ;;
		r) echo "return to the previous menu in 3 seconds"
		   sleep 3
		   t_operate	      ;;
		# 其他键也是自动回到上一级菜单
		*) echo "return to the previous menu in 3 seconds"
		   sleep 3
		   t_operate 		  ;;

	esac
	exit 1
}

# 这个teacher_course文件
# 我也可以类似的把他改成目录
# 然后每一个course_info都是一个文件
# 每个文件名字就是他的发布日期
# 不过这种方式也可以 -- 最好把日期带上。
new_course_info()
{
	#输出时间方便交互
	#年 月 日 小时 分钟
	the_time=` date +%Y_%m_%d_%H_%M `
	echo "the time is:" $the_time
	read -p "Please enter file name: " file_name
    #直接创建对应文件
	info_file=course_teacher/$course_ID"_"$teacher_ID/course_info/$file_name
	touch $info_file
	echo "please enter new course info(enter "EOF" string to end)"
	while read line
	do
		if [ "$line" = EOF ]
		then
			break
		fi
		echo $line >> $info_file
	done
	echo "succeed"
	echo "return to the previous menu in 3 seconds"
	sleep 3
	manage_course_info
	exit 1
}

# 编辑课程信息
edit_course_info()
{

	echo "Please enter the info file name you are going to edit: "	# 提示输入指令
	echo "enter file to list all the course info files"
	read readin
	if [ "$readin" = "file" ]	# file 列出所有文件
	then
		ls course_teacher/$course_ID"_"$teacher_ID/course_info | more
        echo "re-enter this menu in 1 second"	# 1秒后重新进入编辑菜单
        sleep 1
        edit_course_info
	else
		info_file=course_teacher/$course_ID"_"$teacher_ID/course_info/$readin
		if [ -f "$info_file" ]
		then
			echo "edit file using vim, get into vim in 2 seconds"
			sleep 2
			# 编辑器是编辑文件的最好方式 但vim对用户不够友好
			vim $info_file
            echo "succeed"
            echo "return to the previous menu in 2 seconds"
            sleep 2
            manage_course_info
		else
			echo "no such course info file"		  # 提示不存在文件
			echo "reenter this menu in 2 seconds" # 重新进入编辑菜单
			sleep 2
			edit_course_info
		fi
	fi
    echo "return to the previous menu in 3 seconds"
    sleep 2
    manage_course_info
}


# 删除课程信息
delete_course_info()
{
	echo "Please enter the info file name you are going to delete: "
	echo "enter file to list all the course info files"
	read readin
	if [ "$readin" = "file" ]	# file显示当前的所有文件
	then
		ls course_teacher/$course_ID"_"$teacher_ID/course_info | more
		echo "re-enter this menu in 1 second"
		sleep 1
        delete_course_info
	else
		info_file=course_teacher/$course_ID"_"$teacher_ID/course_info/$readin
		if [ -f $info_file ]
		then
			echo "begin deleting..."
			rm $info_file	# 删除对应文件
            echo
            echo "succeed"	# 提示执行成功
            echo "return to the previous menu in 3 seconds"
            sleep 3
            manage_course_info
		else
			echo "no such course info file"	# 提示文件不存在
			echo "reenter this menu in 2 seconds"
			sleep 2
			delete_course_info
		fi
	fi
}
# 显示课程信息
list_course_info()
{
	echo "Please enter the info file name you are going to list: " # 提示用户输入要显示的课程信息文件
	echo "enter file to list all the course info files name, enter r to return to the previous menu" # file显示所有文件信息
	read readin

	if [ "$readin" = "file" ]
	then
		ls course_teacher/$course_ID"_"$teacher_ID/course_info | more
		echo "re-enter this menu in 1 second"
		sleep 1
        list_course_info
    elif [ "$readin" = "r" ]
        then
            manage_course_info
	else
		info_file=course_teacher/$course_ID"_"$teacher_ID/course_info/$readin
		if [ -f $info_file ]
		then
			cat $info_file | more	# 显示文件信息 more分屏
            echo "re-enter this menu in 1 second"
			sleep 1
			list_course_info
		else
			echo "no such course info file"	# 文件不存在
			echo "reenter this menu in 2 seconds"
			sleep 2
			list_course_info
		fi
	fi
}

# 增加作业
new_homework()
{
	read -p "Please enter homework(lab) name(q for quit): " homework_name # 读取作业名字
	if [ "$homework_name" = "q" ] 	# 输入q退出
	then	
		echo "return to the previous menu in 2 seconds"
		sleep 2
		manage_homework
	fi
	
	echo "begin creating"			# 提示正在创建
	homework_dir=course_teacher/$course_ID"_"$teacher_ID/homework/$homework_name
	mkdir $homework_dir				# 创建目录
	spec_file=$homework_dir/specification	# 作业描述文件路径
	touch $spec_file				# 创建作业描述文件
	echo "please enter homework specification(enter "EOF" string to end)"
	while read line
	do 
		if [ "$line" = "EOF" ]
		then
			break
		fi
		echo $line >> $spec_file
	done
	echo "succeed"
	echo "return to the previous menu in 2 seconds"
	sleep 2
	manage_homework
	exit 1	
}

# 删除作业
delete_homework()
{
	read -p "Please enter homework(lab) name(q for quit): " homework_name
	if [ "$homework_name" = "q" ]	# 输入q退出
	then
		echo "return to the previous menu in 2 seconds"
		sleep 2
		manage_homework
	fi

	homework_dir=course_teacher/$course_ID"_"$teacher_ID/homework/$homework_name
	if [ -d "$homework_dir" ]	# 判断是否是目录文件
	then
		echo "begin deleting homework..."
		rm -rf $homework_dir	# 递归的删除作业目录文件
		echo
		echo "succeed"			# 成功删除提示	
		echo "return to the previous menu in 2 seconds"
		sleep 2
		manage_homework
	else
		echo "no such homework directory"
		echo "return to the previous menu in 2 seconds"
		sleep 2
		manage_homework
	fi

}

# 这里显示的是所有的作业
# 也就是作业的目录--进一步可以显示作业的详细信息
list_homework()
{

	work_dir=course_teacher/$course_ID"_"$teacher_ID/homework
	echo "listing all the homework info"
	ls $work_dir	# 显示所有的作业目录
    read -p "enter the homework name to see more detail(q for quit)" readin
	if [ "$readin" = "q" ]	# 输入q返回上一级菜单
	then
		echo "return to the previous menu in 2 seconds"
		sleep 2
		manage_homework
	fi
	homework_dir=$work_dir/$readin  # 作业目录
	if [ -d $homework_dir ]  		# 检查是否是目录
	then
		echo "showing the homework specification..."	# 提示显示内容
        echo 
		cat $homework_dir/specification | more	# cat查看作业详细信息
	else
		echo "no such directory"	# 目录不存在
		echo "return to the previous menu in 2 seconds"
		sleep 2
		manage_homework
	fi
	sleep 1
	read -p "press any key to return to the previous menu" any	# 注意按键后要回车
	manage_homework
}

# 编辑作业
# 这里**编辑的作业 就是作业的详细信息** specification
edit_homework()
{
	# 输入作业名
	read -p "Please enter the info homeworkd you are going to edit(enter list to list all homework): " homework_name
	if [ "$homework_name" = "list" ]	# 显示所有作业目录
	then
		echo "showing the list of all homework..."
		ls course_teacher/$course_ID"_"$teacher_ID/homework
		echo "re-enter this menu in 2 seconds"	# 重新进入当前菜单
		sleep 2
		edit_homework
		
		
	else
		homework_dir=course_teacher/$course_ID"_"$teacher_ID/homework/$homework_name
		if [ -d "$homework_dir" ]
		then
			echo "edit file using vim, get into vim in 2 seconds"	# 使用vim编辑文件
			sleep 2
			vim $homework_dir/specification
		else 
			echo "no such homework directory"	# 目录不存在 重新进入当前目录
			echo "re-enter this menu in 2 seconds"
			sleep 2
			edit_homework
		fi
	fi
    echo "return to the previous menu in 2 seconds"
    sleep 2
    manage_homework
    exit 1
}

 #检查任务学生作业完成情况
homework_completion()
{
	read -p "Please enter the homework name(enter list to list all homework): " homework_name
	if [ "$homework_name" = "list" ]
	then
		echo "showing the list of all homework..."
		ls course_teacher/$course_ID"_"$teacher_ID/homework	# 显示作业目录列表
		echo "re-enter this menu in 2 seconds"
		sleep 2
		homework_completion		# 重新进入当前目录
	else
		homework_dir=course_teacher/$course_ID"_"$teacher_ID/homework/$homework_name
		if [ -d "$homework_dir" ]
		then
		stu_count=` cat course_teacher/$course_ID"_"$teacher_ID/student_info | wc -l ` # 提交作业人数
		submit=` ls $homework_dir | wc -l ` # 差值
		(( submit-- ))      # 这是由于有specification文件 要减掉
        difference=$[ $stu_count - $submit ]
		echo "total students enrolled: $stu_count"
		echo "$submit student(s) have submitted, $difference students haven't submitted"
		echo "return to the previous menu in 2 seconds"
        sleep 2
        manage_homework
        else
			echo "no such homework directory"
			echo "re-enter this menu in 2 seconds"
			sleep 2
			homework_completion	# 重新进入当前目录
			exit 1
		fi
	fi
	exit 1
}
