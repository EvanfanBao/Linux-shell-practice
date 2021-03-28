#!/bin/bash
# UTF-8
# 程序名称: student.sh
# 作者: 鲍奕帆
# 学号: 3180103499
# 程序功能: 学生模块 提供相应的登陆界面以及各种支持函数

# 调用登陆与操作函数
student()
{
    s_login
    s_operate

	exit 1 
}


s_login()
{
	read -p "Please enter student ID: " student_ID	# 读入学生ID
	# 利用account文件检查学生信息是否存在
	count=` cat account | awk '{print $1}' | grep -c "$student_ID" `
	if [ "$count" = "0" ]
    then
		echo "student doesn't exit"  # 学生不存在 退出
		exit 1 
	fi
	echo -n "Please enter your password: "	# 提示输入密码
    read -s passwd					 # 读入密码 不会显
    real_password=` cat account | grep ^"$student_ID" | awk '{print $3}' `
	if [ "$passwd" = "$real_password" ]	# 比较密码是否相同
	then
		student_name=` cat account | grep ^"$student_ID"| awk '{print $3}' ` # 获取学生名字
		echo "welcome $student_name"	# 欢迎对应学生
		return 0
	else 
		echo "wrong password, exit..."	# 密码错误
		exit 3
	fi
}



s_operate()
{
	
  	read -p "Please enter the course ID and teacher ID you are going to manage: " course_ID teacher_ID # 对应课程的ID和授课老师ID

	echo "Please enter your operation: "
	echo "1 submit homework(lab)"			 # 1提交作业
	echo "2 edit homework(lab)"				 # 2编辑作业
	echo "3 list homework(lab) finished"	 # 3列出已经完成作业
	echo "4 list homework(lab) not finished" # 4列出未完成作业
	echo "5 show course info"				 # 显示作业信息
	echo "q exit the system"				 # 退出系统
	echo "r re-enter this meue to choose another course" # 重新进入系统
	read option				# 读入对应数据
	case $option in			# 根据对应输入进入不同菜单
		1) submit_homework			;;
		2) edit_homework			;;
		3) list_homework_finished	;;
		4) list_homework_unfinished	;;
		5) show_course_info			;;
		q) exit 0					;;
        r) s_operate                ;;
   esac
}

# 提交学生作业
submit_homework()
{
	read -p "Please enter the homework name: " homework_name	# 读取作业名
	homework_direcotry="course_teacher/$course_ID"_"$teacher_ID/homework/$homework_name"	# 获取作业目录

	read -p "Please enter your submission path: " path  		# 读取提交路径
	submission_name=` basename $path `							# 获取提交本地文件名

	if [ "$submission_name" != "$student_ID" ] 					# 如果提交的本地作业名不等于用户ID
    then
        echo "Please rename your file name to $student_ID"		# 要求将文件命名为自己的ID
		echo "exit in 2 seconds"
		sleep 2
		exit 1;
	fi

	if [ -d "$homework_direcotry" ]		# 如果作业目录存在
	then	
		cp $path $homework_direcotry/	# 拷贝文件到作业目录
		echo "succeed"					# 提示操作成功
		echo "return to the previous menu in 2 seconds" 
		sleep 2
		s_operate
	else
		echo "no such homework directory" # 不存在对应目录
		echo "return to the previous menu in 2 seconds"
		sleep 2
		s_operate
	fi
}

#编辑作业
edit_homework()
{
	read -p "Please enter the homework name: " homework_name  	# 提示输入作业名
	homework_direcotry="course_teacher/$course_ID"_"$teacher_ID/homework/$homework_name" # 作业目录

	if [ -d "$homework_direcotry" ]		# 作业目录存在
	then

		if [ -f "$homework_direcotry/$student_ID" ]  # 检查学生作业文件是否存在(学生提交作业名为其ID)
		then
			echo "using vim to edit the homework file after 2 seconds"
			vim $homework_direcotry/$student_ID 	 # 使用vim编辑文件
            echo "return to the previous menu in 2 seconds"
            sleep 2
            s_operate
		else
			echo "no such homework file"			 # 文件不存在 2秒后返回上一级菜单
			echo "return to the previous menu in 2 seconds"
			sleep 2
			s_operate
		fi
	else
		echo "no such homework directory"			 # 文件目录不存在
		echo "return to the previous menu in 2 seconds"
		sleep 2
		s_operate
	fi
}

# 列出已经提交的作业
# 可以和后面的未提交合并
# 共同表示学生的作业完成情况
list_homework_finished()
{
	take_directory=take/$student_ID		# 学生选课信息文件
	while read line
	do
		each_course_ID=` echo $line | cut -d ' ' -f1 `  #获取第一个course ID
        each_teacher_ID=` echo $line | cut -d ' ' -f2 ` #获取第二个teacher ID
		homework_direcotry=course_teacher/$each_course_ID"_"$each_teacher_ID/homework
        for work in $homework_direcotry/* #对每一个作业文件目录
		do
			count=` ls $work | grep -c ^"$student_ID" `
            work_name=` basename $work `
			if [ "$count" != 0 ]  #已经提交作业
			then
                each_course_name=` cat course | grep ^"$each_course_ID" | awk '{print $2}' `	# 课程名字-方便使用者阅读
                each_teacher_name=` cat account | grep ^"$each_teacher_ID" | awk '{print $2}' ` # 老师名字-方便使用者阅读
				echo "you have finished the homework $workname in ${each_course_ID} $each_course_name taught by ${each_teacher_ID} ${each_teacher_name}"
            fi
		done
	done < $take_directory
	echo "process done"
	echo 
	echo "return to the previous menu in 2 seconds"
    sleep 2
    s_operate
}

# 列出尚未提交的作业
list_homework_unfinished()
{
	take_directory=take/$student_ID
	while read line
	do
		each_course_ID=` echo $line | cut -d ' ' -f1 ` #获取第一个course ID
        each_teacher_ID=` echo $line | cut -d ' ' -f2 ` #获取第二个teacher ID
		homework_direcotry=course_teacher/$each_course_ID"_"$each_teacher_ID/homework
        for work in $homework_direcotry/* #对每一个作业文件目录
		do
			count=` ls $work | grep -c ^"$student_ID" `
            work_name=` basename $work `
			if [ "$count" = 0 ]  # 尚未提交作业
			then
                each_course_name=` cat course | grep ^"$each_course_ID" | awk '{print $2}' `
                each_teacher_name=` cat account | grep ^"$each_teacher_ID" | awk '{print $2}' `
				echo "you have not finished the homework $workname in ${each_course_ID} $each_course_name taught by ${each_teacher_ID} ${each_teacher_name}"
            fi
		done
	done < $take_directory
	echo "process done"
	echo
	echo "return to the previous menu in 2 seconds"
    sleep 2
    s_operate
}
