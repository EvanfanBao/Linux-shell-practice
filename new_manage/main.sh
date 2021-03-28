#!/bin/bash
# UTF-8
# 程序名称: main.sh
# 作者: 鲍奕帆
# 学号: 3180103499
# 程序功能: 根据用户输入选择模式 进入对应的模块

# 进入菜单
while true; do
	# 欢迎菜单
	echo "##############################################"
	echo "#   Welcome to homework management system    #"
	echo "#   Author: Bao Yifan                        #"
	echo "#   SID   : 3180103499                       #"
	echo "##############################################"

	echo "Please enter your option"		# 提示输入选项
	echo "1 Student"					# 1为学生
	echo "2 Teacher"					# 2为老师
	echo "3 Administrator"				# 3为管理员
	echo "q exit"						# q退出
	read option	
	case $option in						# source命令 进入不同模块
		1) . ./student.sh				# 学生模块
			student;;
		2) . ./teacher.sh				# 老师模块
		   teacher;;
		3) . ./admin.sh					# 管理员模块
			admin;;
		#正常退出
		q) exit 0;; 
		*) echo "Please enter the right command"    
	esac
done
