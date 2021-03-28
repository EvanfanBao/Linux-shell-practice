#!/bin/bash
# UTF-8
# 程序名称: admin.sh
# 作者: 鲍奕帆
# 学号: 3180103499
# 程序功能: 管理员模块 提供相应的登陆界面以及各种支持函数

# 调用登陆与操作函数
admin()
{
    a_login
    a_operate
}

# 登陆验证函数
a_login()
{
    read -p "Please enter ID: " admin_ID 		# admin的ID为默认的0--不可修改
    if [ $admin_ID -ne 0 ]						# 如果非0 则报错
    then
	echo "Wrong ID for admin"
	exit 3
    fi
    echo -n  "Please enter your password: "	 	# 提示输入密码
    read -s passwd								# 输入密码
    
    real_passwd=` cat account | grep "admin$" | awk '{print $3}' `	#查找正确的密码
    echo 
    if [ "$passwd" = "$real_passwd" ]			# 验证密码是否正确
    then
	echo "welcome admin!"						# 给出欢迎词
        return 0
    else
	echo "wrong passwd, exit..."				# 密码错误则退出
	exit 3	
    fi
}

# 操作菜单界面
a_operate()
{
    echo "Please enter your operation: "		# 提示用户输入
	echo "1 list teacher info"					# 1列出教师信息
	echo "2 add teahcer info"					# 2增加教师信息
	echo "3 delete teacher info"				# 3删除教师信息
	echo "4 modify teacher info"				# 4修改教师信息
	echo "5 bind course"						# 5绑定课程
	echo "6 cancel course binding"				# 6取消课程绑定
	echo "7 list course info"					# 7显示课程信息
	echo "8 add course info"					# 8增加课程信息
	echo "9 delete course info"					# 9删除课程信息
	echo "10 modify course info"				# 10修改课程信息
    echo "11 reset password"					# 11重置用户密码
	echo "q exit system" 						# q退出系统
    read op										# 读入操作
	# 根据op调用对应函数
	case $op in		
	   1) list_teacher_info 	;;				
	   2) add_teacher_info      ;;
	   3) delete_teacher_info	;;
	   4) modify_teacher_info	;;	
	   5) bind_course			;;
	   6) cancel_course_binding	;;
	   7) list_course_info		;;
	   8) add_course_info		;;
	   9) delete_course_info	;;
	   10)modify_course_info	;;
       11)reset_passwd          ;;
	   "q") exit 0				;;
	esac
	
	exit 1
}

# 在account中添加教师信息
add_teacher_info()
{
	
	read -p "Please enter teacher ID: " teacher_ID	# 提示用户输入教师ID
	count=` cat account | awk '{print $1}' | grep -c "$teacher_ID" `	# 在account中查看对应ID的个数(存在则为1，否则为0)
	if [ "$count" != "0" ] 							# 工号已经存在		
	then
		echo "ID already exists"					
		a_operate 									# 回到选择界面
		exit 1
	fi
	
	#若工号不存在 则添加教师
	read -p "Please enter teacher's name): " teacher_name
	init_passwd=$teacher_ID #初始密码为工号
	#将新添加的教师信息写入passwd
	echo "begin processing..."
    echo
	echo $teacher_ID $teacher_name $init_passwd teacher >> account # 利用追加命令写入
	echo "succeed"
	echo "return to the previous menu after 3 seconds"
    sleep 3
	a_operate 	# 回到选择界面
}



# 删除教师信息
delete_teacher_info()
{
	read -p "Please enter teacher ID: " teacher_ID	# 提示用户输入教师ID
	count=` cat account | awk '{print $1}' | grep -c "$teacher_ID" `; # 统计account中的ID
	if [ $count != 0 ] 								# 工号已经存在,能够进行删除
	then
		echo "the teacher you are going to delete is: "		# 提示用户信息
		cat account | grep ^"$teacher_ID" | awk '{print $1,$2}'
		read -p "are you sure to delete it?[Y/N] " reply	# 确认是否删除
		case $reply in
			y | Y | yes | YES )						# Yes回复
				# 在passwd文件中删除对应的行列
				echo "begin processing..."			# 提示用户执行删除
                echo
				sed -i '/^'$teacher_ID'/d' account  # 删除对应的行
				echo "succeed"						# 提示用户成功--可改进--即验证上一条指令是否执行成功
				;;	
			n | N | no | NO)						# No回复
				echo "give up deletion"		
				;;
		esac
        echo "return to the previous menu after 3 seconds"	# 告知返回上一级目录
        sleep 3										# 等待3s-略长-可修改
		a_operate									# 调用上级目录
		exit 1
	else
		echo "No such teacher ID"					# 告知不存在对应目录
		echo "return to the previous menu after 3 seconds" 
        a_operate									# 返回上级目录
		exit 1
	fi
}

# 显示教师信息
list_teacher_info()
{
	read -p "Please enter your options(press help to display help): " option  # 提示输入选项

	case $option in
		"help") echo "1 --query through ID"					# 1根据ID查询
				echo "2 --query through name"				# 2根据姓名查询
				echo "3 --query all teachers info"   		# 3查询所有的教师信息
				echo "4 --return to the previouse menue"	# 4返回到上一层目录
				echo "5 --exit the system"					# 5退出系统
				echo "help --display this help"				# help列出帮助列表
				list_teacher_info							# 重新进入本目录
				;;
		"1")  read -p "Please enter teacher ID: " teacher_ID # 读取老师ID
				# ID存在且身份为教师
				if ([ ` cat account | grep -c ^"$teacher_ID" ` != "0" ]) && ([ ` cat account | grep  ^"$teacher_ID" | awk '{print $4}' ` == "teacher" ]) 
				then
					# 显示教师信息
					echo "ID name"
					cat account | grep ^"$teacher_ID" | awk '{print $1,$2}'		# 显示教师信息
					list_teacher_info						# 重新进入当前菜单
					exit 1 
				else
					# ID不存在或者不是老师
					echo "ID does not exit"		
					list_teacher_info
					exit 1
				fi
				;;
		"2")  read -p "Please enter teacher name: " teacher_name # 读取老师名字
				# 名字存在且为教师
				if ([ ` cat account | grep -c "$teacher_name" ` != "0" ]) && ([ ` cat account | grep  "$teacher_name" | awk '{print $4}' ` == "teacher" ]) 
				then
					echo "ID name"
					cat account | grep "$teacher_name" | awk '{print $1,$2}' # 显示教师信息
					list_teacher_info
                    exit 1
				else
					# 名字不存在或者不是老师
					echo "Name does not exit"
                    list_teacher_info
                    exit 1
				fi
				;;
		"3")  echo "print all the teachers info"
              while read line
              do
                  if [ `echo $line | awk '{print $4}' ` = "teacher" ] # 检测状态为教师
                  then
                      echo $line | awk '{print $1,$2}'
                  fi
              done < account  # 重定向读入每一行account信息
              list_teacher_info
              ;;
		"4")  echo "return to the previous menu after 3 seconds"	  # 返回上一级菜单
			  sleep 3
			  a_operate
			  ;;
		"5")  echo "exit the system"	# 退出系统
			  exit 0
			  ;;
	esac
    echo "return to the previous menu in 2 seconds" 	# 返回上一级菜单
    sleep 2
    a_operate
}


#个人认为此处不应该
# 修改老师信息--可以修改老师姓名与密码 但不可修改老师ID
modify_teacher_info()
{
	read -p "Please enter teacher ID: " teacher_ID  # 读取教师ID
	count=` cat account | awk '{print $1}' | grep -c ^"$teacher_ID" `; # 统计个数
	if [ $count != 0 ] # 工号已经存在 能够进行修改
	then
		echo -n "the teacher you are going to modify is: "		# 提示用户
		cat account | grep ^"$teacher_ID" | awk '{print $1,$2}'	# 教师信息
		echo "-- Enter p for modifying password"                # p修改密码
		echo "-- Enter n for modifying name"					# n修改名字
		echo "-- Enter pn/np for modifying password and name"   # pn/np修改名字或者密码
		read -p "Please enter your commnad: " command			# 读入命令
		info_line=` cat account | grep ^"$teacher_ID" ` 		#获取整行信息
		teacher_name=` echo $info_line | cut -d ' ' -f2 ` 		#获取名字
		teacher_password=` echo $info_line | cut -d ' ' -f3 ` 	#获取原来的密码
		
		case $command in 
		n)	
			read -p "Please enter new name: " teacher_name
			# 直接用sed进行替换！！
			# 注意sed 使用双引号--可以直接使用变量
			# 如果是单引号--需要在变量外面用单引号在双引号
			sed -i "s/.*${info_line}.*/"$teacher_ID" "$teacher_name" "$teacher_password" "teacher" /" account			
			;;
		p)
			echo -n "Enter password: " 		
			read -s passwd				# 读入密码 输入不回显
			echo
			echo -n "Enter password again: "
			read -s passwd_again		# 再次读入密码
			echo
			if [ "$passwd" != "$passwd_again" ] # 比较 提示
			then
				echo "Different password" 
			else 
				sed -i "s/.*${info_line}.*/"$teacher_ID" "$teacher_name" "$passwd" "teacher" /" account	# 修改密码
			fi
			;;
		np|pn)
			echo -n "Enter password: "  
			read -s passwd			   # 读入密码 输入不回显
			echo
			echo -n "Enter password again: "
			read -s passwd_again	   # 再次读入密码
			echo
			if [ "$passwd" != "$passwd_again" ]
			then
				echo "Different password"
			else
				read -p "Please enter new name: "teacher_name	# 读入名字
				sed -i "s/.*${info_line}.*/"$teacher_ID" "$teacher_name" "$passwd" "teacher" /" account # 修改密码和名字
			fi
			;;
		esac
		echo "succeed"			  	   # 提示成功
		echo "return to previous menu in 3 seconds"		# 3s后返回上一级菜单
		sleep 3
		a_operate
		exit 1
	else
		echo "Teacher ID doesn't exit"	# 老师ID不存在
		echo "return to previous menu in 3 seconds"     # 返回上一级目录
		sleep 3
		a_operate
		exit 1
	fi		
}

# 建立课程绑定
bind_course()
{ 
	read -p "Please enter teacher ID: " teacher_ID 		 # 提示输入教师ID
	#检查教师账户是否存在
	if [ ` cat account | grep -c ^"$teacher_ID" ` = 0 ] 
	then 
		echo "Teacher does not exit"
		echo "return to the previous menu in 3 seconds"
		sleep 3
		a_operate
		exit 1 
	fi

	read -p "Please enter course ID: " course_ID		 # 提示输入课程ID
	#检查课程信息是否存在
	if [ ` cat course | grep -c ^"$course_ID" ` = 0 ] 	 
	then 
		echo "Course does not exit"
		echo "return to the previous menu in 3 seconds"
		sleep 3
		a_operate
		exit 1 
	fi
	
	#老师存在 课程也存在
	#还需要判断是否已经绑定
	if [ -d "course_teacher/$course_ID""_$teacher_ID" ]
	then 
		echo "Binding already exits"
		echo "return to the previous menu in 3 seconds"
		sleep 3
		a_operate
		exit 1 
	fi
	#所有检查均通过 绑定教师与课程 创建  课程教师绑定的目录
	echo "begin binding..."
	echo
	mkdir "course_teacher/$course_ID""_$teacher_ID"
	#同时创建课程有关文件或目录--课程信息目录 作业目录 学生选课信息目录
	mkdir "course_teacher/$course_ID""_$teacher_ID/course_info"
	mkdir "course_teacher/$course_ID""_$teacher_ID/homework"
	touch "course_teacher/$course_ID""_$teacher_ID/student_info"
	echo "succeed"
	echo "return to the previous menu in 3 seconds"
	sleep 3
	a_operate
	exit 1
}

# 取消课程绑定
cancel_course_binding()
{
	read -p "Please enter teacher ID: " teacher_ID  # 读入教师ID
	# 检查教师账户是否存在
	if [ ` cat account | grep -c ^"$teacher_ID" ` = "0" ] 
	then
		echo "teacher doesn't exit" #老师不存在
		echo "return to the previous menu in 3 seconds" # 返回之前菜单
		sleep 3
		a_operate
		exit 1 
	fi

	read -p "Please enter course ID: " course_ID        # 读取课程ID
	# 检查课程信息是否存在
	if [ 0 = `cat course | grep -c ^"$c_id" ` ]
	then
		echo "course doesn't exit" #课程不存在
		echo "return to the previous menu in 3 seconds"
		sleep 3
		a_operate
		exit 1 
	fi

	# 检查教师与课程是否已经绑定
	# 若已经绑定 删除对应文件
	if [ -d "course_teacher/$course_ID""_$teacher_ID" ]
	then
		# 友好提示进行取消绑定
		echo "begin unbinding"
		echo
		rm -r "course_teacher/$course_ID""_$teacher_ID"	 # 删除对应文件
		echo "succeed"	# 提示成功
		echo "return to the previous menu in 3 seconds"
		sleep 3
		a_operate
		exit 1 
	else
		echo "No binding yet"	# 原本未绑定 不可取消
		echo "return to the previous menu in 3 seconds"
		sleep 3
		a_operate
		exit 1
	fi
}

# 增加课程信息
add_course_info()
{
	read -p "Please enter course ID: " course_ID # 读取课程ID
	# 检查课程信息是否已经存在
	if [ "0" != ` cat course | awk '{print $1}' | grep -c "$course_ID" ` ]
	then
		echo "course already exits" # 要添加的课程已经存在
		echo "return to the previous menu in 3 seconds"
		sleep 3
		a_operate
		exit 1 
	fi  
	read -p "Please enter course name: " course_name  # 读取课程名字
	echo "begin adding course info"
	echo $course_ID $course_name >> course  # 追加方式写入
	echo "succeed"		# 提示成功
	echo "return to the previous menu in 3 seconds"
	sleep 3
	a_operate
	exit 1 
}


delete_course_info()
{
	read -p "Please enter course ID: " course_ID # 读取课程ID
	# 检查课程信息是否存在
	if [ "0" != ` cat course | awk '{print $1}' | grep -c "$course_ID" ` ] # 如果课程ID存在
	then
		#显示课程信息
		echo "course_ID" "course_name"
	    cat course | grep ^"$course_ID"
		#确认是否删除
		read -p "are you sure to delete this?[Y/N]: " reply
		case $reply in
			y | Y | YES | yes )
				# 正在删除
				echo "begin deleting..."
				echo
				# 删除课程信息文件中对应的行
				sed -i  "/$course_ID/d" course
				echo "succeed"
				;;
			n | N | NO | no)
				echo "cancel deletion"
				;; 
			# 按任意键取消--等同于no
		esac
		echo "return to the previous menu in 3 seconds"
		sleep 3
		a_operate
		exit 1
	else
		# 课程不存在 无法删除
		echo "course doesn't exit"
		echo "return to the previous menu in 3 seconds"
		sleep 3
		a_operate exit 1
	fi
}

modify_course_info()
{
	read -p "Please enter course ID: " course_ID  # 读取课程ID
	#检查课程信息是否存在
	if [ "0" != ` cat course | awk '{print $1}' | grep -c "$course_ID" ` ]
	then
		echo "course_ID" "course_name"	
		cat course | grep ^"$course_ID"			    	# 显示课程信息
		echo "Please choose your option: "				# 提示输入选项
		echo "-- Enter i for modifying course ID;"  	# i修改课程ID
		echo "-- Enter n for modifying name"			# n修改课程名
		echo "-- Enter in/ni for modifying course ID and name"	# in/ni修改课程名和ID
		info_line=` cat course | grep ^"$course_ID" `
		course_name=` echo $info_line | cut -d ' ' -f2 ` # 获取原本课程名
		read option
		case $option in
			"n")
				read -p "Please enter new course name: "  course_name	# 提示输入课程名
				echo "begin modifying..."
				echo

				sed -i "s/.*${info_line}.*/"$course_ID" "$course_name"/ " course	# sed命令修改对应行
				echo "succeed"
				;;
			"i")
				read -p "Please enter new course ID: " course_ID		# 提示输入课程ID
				echo "begin modifying..."
				echo
				sed -i "s/.*${info_line}.*/"$course_ID" "$course_name"/ " course  # sed命令修改对应行
				echo "succeed"
				;;
			"in"|"ni")
				read -p "Please enter new course ID course Name: " course_ID course_name # 提示输入课程ID和课程名 
				echo "begin modifying..."
				sed -i "s/.*${info_line}.*/"$course_ID" "$course_name"/ " course 		 # sed命令修改对应行
				echo "succeed"
				;;
		esac
		echo "return to the previous menu in 3 seconds"
		sleep 3
		a_operate
		exit 1
	else
		echo "course doesn't exit"	# 课程不存在
		echo "return to the previous menu in 3 seconds"
		sleep 3
		a_operate
		exit 1
	fi
}


# 显示课程信息
list_course_info()
{
	read -p "Please enter your options(press help to display help): " option	# 读取选项
	
	case $option in
		"help") echo "1 --query through ID"				 # 1根据ID查询
				echo "2 --query through name"			 # 2根据名字查询
				echo "3 --query all course info"		 # 3查询所有课程信息
				echo "4 --return to the previouse menue" # 返回上一级菜单
				echo "5 --exit the system"				 # 退出系统
				echo "help --display this help"			 # 显示当前帮助
				list_course_info
				;;
		"1")  read -p "Please enter course ID: " course_ID # 读入课程ID
				if [ ` cat course | grep -c ^"$course_ID" ` != "0" ] 
				then
					echo "ID name"						
					cat course | grep ^"$course_ID" | awk '{print $1,$2}' # 输出课程信息
					list_course_info
					exit 1 
				else
					echo "ID does not exit"
					list_course_info
					exit 1
				fi
				;;
		"2")  read -p "Please enter teacher name: " course_name	# 读入课程名
				if [ `cat course | grep -c "$course_name" ` != "0" ]
				then
					echo "ID name"
					cat course | grep "$course_name" | awk '{print $1,$2}' # 输出课程信息
					list_course_info
					exit 1 
				else 
					echo "Name does not exit"
					list_course_info
					exit 1 
				fi
				;;
		"3")  echo "print all the teachers info"
			  cat course | awk '{print $1,$2}'			# 显示所有课程信息
			  list_course_info
			  ;;
		"4")  echo "return to the previous menu after 3 seconds" # 返回上一级菜单
			  sleep 3
			  a_operate
			  ;;
		"5")  echo "exit the system" 	# 退出系统
			  exit 0
			  ;;
	esac
}

# 重置密码
reset_passwd()
{
	# 重置密码后 用户无法直接知晓
	# 因此谨慎
	echo "**************************************"
	echo "****BE CAREFUL TO USE THIS COMMAND****"
	echo "**************************************"
	sleep 1
	
	read -p "Please enter account ID(press r to return to previous menu): " account_ID
	# 账号只由数字组成
	# 返回上一级目录
	if [ "$account_ID" = "r" ] || [ "$account_ID" = "R" ]
	then
		echo "return to the previous menu"	
		a_operate
	fi
	
	if [ ` cat account | grep -c ^"$account_ID" ` = "0" ]
	then
		echo "account doesn't exit" #账户不存在
		echo "return to the previous menu in 3 seconds"
		sleep 3
		a_operate
		exit 1 
	fi
	
	info_line=` cat account | grep ^"$account_ID" `       # 获取整行信息
	account_name=` echo $info_line | cut -d ' ' -f2 `     # 获取名字
	account_password=` echo $info_line | cut -d ' ' -f3 ` # 获取原来的密码
	account_status=` echo $info_line | cut -d ' ' -f4 `
	
	echo -n "Enter password: " 			# 提示输入密码
	read -s passwd
	echo
	echo -n "Enter password again: "	# 提示再次输入密码
	read -s passwd_again
	echo
	if [ "$passwd" != "$passwd_again" ]
	then
		echo "Different password"
	else 
		sed -i "s/.*${info_line}.*/"$account_ID" "$account_name" "$passwd" "$account_status" /" account	# 替换内容
	fi 
	echo "succeed"
	echo "return to previous menu in 3 seconds"
	sleep 3
	a_operate
	
	exit 1
}


