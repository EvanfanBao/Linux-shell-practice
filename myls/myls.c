#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <time.h>
#include <sys/stat.h>
#include <sys/stat.h>
#include <unistd.h>
#include <sys/types.h>
//#include <sys/syslimits.h>
#include <limits.h>	 //Ubuntu下使用
#include <dirent.h>
#include <grp.h>
#include <pwd.h>
#include <errno.h>
#include <termios.h>
#include <stdbool.h>


void displayDir(char *dir);               //显示文件夹
void displayFile(char *path,char *name);  //显示文件夹中的文件
int cmpTime(const void *a, const void *b);//qsort回调函数
int cmpSize(const void *a,const void *b); //qsort回调函数
void ls_S_func();                              //ls -S具体实现
void ls_t_func();                              //ls -t具体实现
void parseParam(int argc,char* argv[]);   //解析读入参数
int evalTotal(char *dir);                 //计算total值

//参数读入判定
bool ls_a = 0;     // ls -a，显示隐藏文件
bool ls_l = 0;     // ls -l，列出文件的详细信息
bool ls_o = 0;     // ls -o，显示文件的除组信息外的详细信息
bool ls_1 = 0;     // ls -1，一行只输出一个文件
bool ls_i = 0;     // ls -i，输出文件的i节点的索引信息
bool ls_d = 0;     // ls -d，将目录像文件一样显示，而不是显示其下的文件
bool ls_N = 0;     // ls -N，输出不限制文件长度
bool ls_t = 0;     // ls -t，将文件以时间排序
bool ls_S = 0;     // ls -S，以文件大小排序
bool ls_n = 0;     // ls -n，用数字的UID,GID代替名称
bool ls_s = 0;     // ls -s，在每个文件名后输出该文件的大小
bool ls_F = 0;     // ls -F，显示不同的符号来区别文件
bool ls_u = 0;     // ls -u，以文件上一次的访问时间排序
bool ls_R = 0;     // ls -R，列出所有子目录下的文件
bool ls_Q = 0;     // ls -Q，把输出的文件名用双引号括起来
bool ls_A = 0;     // ls -A，显示除"."和".."外的所有文件
bool ls_m = 0;     // ls -m，横向输出文件名，并以","作分隔符
bool ls_r = 0;     // ls -r，对目录反向排序
bool ls_g = 0;     // ls -g，列出文件的详细信息，但不列出文件拥有者
bool ls_B = 0;     // ls -B，不输出以~结尾的备份文件 --- 好像macos不是这么说的
bool ls_c = 0;	   // ls -c，以文件修改时间排序
bool ls_f = 0;     // ls -f，显示隐藏文件 不排序输出
bool ls_none = 0;  // 没有参数读入

#define FILENUM  200 //程序支持的目录中包含文件的最多个数

int n = 0;          //目录中的文件数量

//文件结构用于实现某些ls命令
typedef struct fileToSort
{
    int theSize;    //文件的大小
    time_t theTime; //文件的修改时间/访问时间
    char theName[NAME_MAX + 1]; //NAME_MAX 为最长的文件名
}fileToSort;

fileToSort files[FILENUM];//定义文件结构数组用于排序

//定义排序函数 降序排列
//@a: 用于比较的第一个地址
//@b: 用于比较的第二个地址
int cmpTime(const void *a, const void *b)
{
    //指针类型转换
    fileToSort c = *(fileToSort*)a;
    fileToSort d = *(fileToSort*)b;
    //比较时间 c的时间大则返回-1
    if(c.theTime > d.theTime)
        return -1;
    else if(c.theTime == d.theTime)
        return 0;
    else return 1;
}

//@a: 用于比较的第一个地址
//@b: 用于比较的第二个地址
int cmpSize(const void *a,const void *b)
{
    //指针类型转换
    fileToSort c = *(fileToSort*)a;
    fileToSort d = *(fileToSort*)b;
    //比较时间 c的大小大则返回-1
    if(c.theSize > d.theSize)
        return -1;
    else if(c.theSize == d.theSize)
        return 0;
    else return 1;
}

//ls -t命令的具体实现
void ls_t_func()
{
    int i;
    qsort(files,n,sizeof(fileToSort),cmpTime); //降序根据时间排序
    for(i=0;i<n;i++)
        printf("%s    ",files[i].theName);     //每个输出后增加4个空格
    //注: MACOS中的大部分ls命令都是换行显示 而Ubuntu 18.04中多为分屏显示
    //虽然实验时在MACOS中完成的 但ls命令仍然是按Ubuntu服务器上的man手册实现
    //此处未实现分屏显示算法
}
//ls -S命令的具体实现
void ls_S_func()
{
    int i;
    qsort(files,n,sizeof(fileToSort),cmpSize); //降序根据文件大小排序
    for(i=0;i<n;i++)
        printf("%s    ",files[i].theName);     //输出文件名
}
 

//设置文件模式, 即文件的类型与权限
//@filemode: 文件模式(文件的类型与权限)
//@mode_file: stat的mode_t类型属性
void setFileMode(char *filemode,mode_t mode_file)
{
    if(S_ISLNK(mode_file)){
        filemode[0] = 'l';    //符号链接文件
    }else if(S_ISREG(mode_file)){
        filemode[0] = '-';    //普通文件
    }else if(S_ISDIR(mode_file)){
        filemode[0] = 'd';    //目录文件
    }else if(S_ISCHR(mode_file)){
        filemode[0] = 'c';    //字符设备文件
    }else if(S_ISBLK(mode_file)){
        filemode[0] = 'b';    //块设备文件
    }else if(S_ISFIFO(mode_file)){
        filemode[0] = 'f';    //管道文件
    }else if(S_ISSOCK(mode_file)){
        filemode[0] = 's';    //套接字文件
    }
    //权限相关内容
    //所有者相关权限
    if(S_IRUSR & mode_file){
        filemode[1] = 'r';   //所有者读权限
    }else{
        filemode[1] = '-';   //无
    }
    if(S_IWUSR & mode_file){
        filemode[2] = 'w';  //所有者写权限
    }else{
        filemode[2] = '-';  //无
    }
    if(S_ISUID & mode_file){
        if(S_IXOTH & mode_file){
            filemode[3] = 's'; //SUID+其他人执行权限
        }else{
            filemode[3] = 'S'; //SUID
        }
    }else if(S_IXUSR & mode_file){
        filemode[3] = 'x';     //所有者执行权限
    }else{
        filemode[3] = '-';     //无
    }
    //组相关权限
    if(S_IRGRP & mode_file){
        filemode[4] = 'r';     //组读权限
    }else{
        filemode[4] = '-';     //无
    }
    if(S_IWGRP & mode_file){
        filemode[5] = 'w';     //组写权限
    }else{
        filemode[5] = '-';     //无
    }
    if(S_ISGID & mode_file){
        if(S_IXOTH & mode_file){
            filemode[6] = 's'; //SGID 其他人执行权限
        }else{
            filemode[6] = 'S'; //SGID
        }
    }else if(S_IXGRP & mode_file){
        filemode[6] = 'x';     //组执行权限
    }else{
        filemode[6] = '-';     //无
    }
    //其他用户权限
    if(S_IROTH & mode_file){
        filemode[7] = 'r';     //其他人读权限
    }else{
        filemode[7] = '-';     //无
    }
    if(S_IWOTH & mode_file){
        filemode[8] = 'w';     //其他人鞋权限
    }else{
        filemode[8] = '-';     //无
    }
    if(S_ISVTX & mode_file){  //stick
        if(S_IXOTH & mode_file){
            filemode[9] = 't';
        }else {
            filemode[9] = 'T';
        }
    }else if(S_IXOTH & mode_file){
        filemode[9] = 'x';    //其他人执行权限
    }else{
        filemode[9] = '-';    //无
    }
    filemode[10] = '\0';      //NULL terminated
}



void ls_lLike_func(char *filemode,char *name,const struct stat* buf)
{
    struct tm *t;      // 存储时间类型
    printf("%s ",filemode);//输出文件类型
    printf("%2d ",buf->st_nlink);//文件的硬链接数目
    if(ls_l == 1)
    printf(" %s\t%s\t",getpwuid(buf->st_uid)->pw_name,getgrgid(buf->st_gid)->gr_name);//输出用户名和组名
    else if(ls_n == 1)
        printf(" %d\t%d\t",getpwuid(buf->st_uid)->pw_uid,getgrgid(buf->st_gid)->gr_gid);//输出UID和GID
    else if(ls_o == 1)
        printf(" %s\t",getpwuid(buf->st_uid)->pw_name);//输出用户名
    else if(ls_g == 1)
        printf(" %s\t", getgrgid(buf->st_gid)->gr_name); //输出组名
    //如果文件类型是区块装置和字符装置
    if(filemode[0] == 'c' || filemode[0] == 'b')
    {
        printf("%5d,",buf->st_rdev >> 8);
        printf("%2d",buf->st_rdev &0xff);
    }
    else
        printf("%8lld ",buf->st_size);
    
    //调用localtime函数取时间
    t = localtime(&buf->st_mtime);
    //输出月日时分
    printf("%d %2d %2d:%d ",t->tm_mon+1,t->tm_mday,t->tm_hour,t->tm_min);
    printf("%s",name);  //输出文件名
    printf("\n");
}

//对每个文件根据选项进行显示
//@path: 文件路径
//@name: 文件名字
void displayFile(char *path,char *name)
{
    struct stat buf;   // 存储文件信息结构
	int i = 8;
    int j = 0;
    int k;
	struct tm *t;      // 存储时间类型
	char filemode[11]; // 存储文件类型
	if(lstat(path,&buf) < 0) // 读取对应数据
	{
		perror("stat");
		return ;
	}
    
    mode_t mode_file = buf.st_mode;
    setFileMode(filemode,mode_file); //设置文件模式-文件类型+权限
    if(ls_none == 1)
    {
        printf("%s    ",name);  //缺少分屏显示--自动适应屏幕
    }
    //ls -l 命令 ls -n 命令 ls -o 命令 ls -g命令
    if(ls_l == 1 || ls_n == 1 || ls_o == 1 || ls_g == 1)
    {
        ls_lLike_func(filemode,name,&buf);
    }
    //ls -i 命令
    else if(ls_i == 1)
    {
        printf("%7llu %s      ",buf.st_ino,name);  //输出inode+名字
        printf("\n");
    }
    //递归ls -R命令
    else if(ls_R == 1)
    {   
        if(filemode[0] == 'd')
        {
            printf("%s",name);
            printf("\n");
            displayDir(path);
            printf("\n");
        }
        else printf("%s    ",name);   
    }
    //ls -s命令
    else if(ls_s == 1)
    {
        printf("%4lld ",buf.st_blocks/2); //输出占用磁盘ls block大小,Ubuntu下除以2
        printf("%s     ",name);
    }
    //ls -m命令 逗号分隔
    //末尾逗号多余
    else if(ls_m == 1)
    {
        printf("%s,  ",name);
    }
    //ls -A命令 直接显示即可 已经在displayDir中处理
    else if(ls_A == 1)
    {
        printf("%s    ",name);
    }

    //ls -t命令 修改时间排序
    //计算全局结构数组变量files 在displayDir中处理
    else if(ls_t == 1)
    {
        strcpy(files[n].theName,name);
        files[n++].theTime = buf.st_mtime;
    }

    //ls -u命令 访问时间排序
    else if(ls_u == 1)
    {
        strcpy(files[n].theName,name);
        files[n++].theTime = buf.st_atime;  //访问时间排序
    }
	else if(ls_c == 1)
	{
		strcpy(files[n].theName,name);
        files[n++].theTime = buf.st_ctime;  //change时间排序
	}

    //ls -B命令
    else if(ls_B == 1)
    {
        if(name[strlen(name) - 1] != '~')  // 不以～结尾
            printf("%-15s",name);
    }
    //当输入 ls -S 按文件大小排序
    //计算全局结构数组变量files 在displayDir中处理
    else if(ls_S == 1)
    {
        strcpy(files[n].theName,name);
        files[n++].theSize = buf.st_size;
    }

    //ls -N命令
    else if(ls_N == 1)
    {
        printf("%s    ",name); // 不限制文件长度 直接输出即可
    }
    //ls -Q命令
    else if(ls_Q == 1)
    {
        printf("\"%s\"  ",name);//输出时增加双引号即可
    }
    //ls -1命令
    else if(ls_1 == 1)
    {
        printf("%s  ",name); //换行输出 在displayDir中实现换行
    }
    //ls -a命令 直接显示即可 已经在displayDir中处理
    else if(ls_a == 1)
    {
        printf("%s  ",name);
    }
    //ls -F命令 添加不同记号
    else if(ls_F == 1)
    {
        printf("%s",name);
        switch(filemode[0])
        {
             case 'd': printf("/");break;  //目录文件
             case 'l': printf("@");break;  //符号链接文件
             case 'p': printf("|");break;  //管道文件
             case 's': printf("=");break;  //套接字文件
             case '-':if(buf.st_mode & S_IXUSR) //可执行文件
                 printf("*");break;
        }
        printf("    ");
       // printf("\n");
    }
}


//计算列表下文件分配的磁盘空间--total值
//@dir: 对应目录路径
int evalTotal(char *dir)
{
    int total = 0;     //初始化total=0
    DIR *dirp;         //目录流指针
    struct dirent *dp; //目录项指针
    char path[PATH_MAX + 1]; //文件路径
    struct stat buf;   // 存储文件信息结构

    //打开目录
    if((dirp = opendir(dir)) == NULL)
    {
        perror("opendir");
        exit(1);
    }
    //循环读取目录项
    while((dp = readdir(dirp)) != NULL)
    {
        //ls -a没有 则不显示.和..文件 因此也不计入total
        if(ls_a == 0)
        {
            if((!strcmp(dp->d_name,".")) || (!strcmp(dp->d_name,"..")))
                continue;
        }
        //ls -A和ls -a没有 则不显示隐藏文件, 因此也不计入total
        if(ls_A == 0 && ls_a == 0)
        {
            if(dp->d_name[0] == '.')
                continue;
        }
        sprintf(path,"%s/%s",dir,dp->d_name); //文件完整路径
        if(lstat(path,&buf) < 0) //读取对应数据
        {
            perror("stat");
            exit(1);
        }
        total += buf.st_blocks/2;  //计算total, Ubuntu服务器上要除以2 MACOS上不用
    }
    closedir(dirp);  //关闭目录流
    return total;
}

//列出目录内容
//@dir: 目录路径
void displayDir(char *dir)
{
	DIR *dirp;         //目录流指针
	struct dirent *dp; //目录项指针
	char path[PATH_MAX + 1]; //文件路径
    int i=0;    //index
    long fileCount = 0;//文件个数计数
    char  fileNames[FILENUM][NAME_MAX + 1];
    
    int total = evalTotal(dir);    //计算total
    //打开目录
	if((dirp = opendir(dir)) == NULL)
	{
		perror("opendir");
		return ;
	}
    //对于需要输出total的命令 输出total值并换行
    if(ls_s == 1 || ls_n ==1 || ls_l == 1 || ls_s == 1 || ls_o == 1 || ls_g)
    {
        printf("total %d\n",total);
    }
    //循环读取目录项
	while((dp = readdir(dirp)) != NULL)
	{
        //ls -a没有 则不显示.和..文件
		if(ls_a == 0)
		{
            if((!strcmp(dp->d_name,".")) || (!strcmp(dp->d_name,"..")))
				continue;
		}
        //ls -A和ls -a没有 则不显示隐藏文件
        if(ls_A == 0 && ls_a == 0)
        {
            if(dp->d_name[0] == '.')
                continue;
        }
        //ls -d 命令
        if(ls_d == 1)
        {
            printf("%s\n",dir); //直接输出目录名路径
            return;
        }
		sprintf(path,"%s/%s",dir,dp->d_name);       //获取文件名路径
        strcpy(fileNames[fileCount++],dp->d_name);  // 实时记录文件名 用于倒序输出
		if(ls_R == 1 && fileCount == 1)
            printf("%s\n",dir);   
        displayFile(path,dp->d_name);   //对目录项的每个文件调用displayFile显示
        //ls -1 命令 每次调用displayFile输出后换行
        if(ls_1 == 1)
        {
            printf("\n");
        }
        
	}
    closedir(dirp);     //关闭文件流
    
    if(ls_F == 1)printf("\n");    
    //ls -r命令 将文件以和ls相反的顺序输出
    if(ls_r == 1)
    {
        for(i = fileCount - 1; i >= 0;i--)
            printf("%s    ",fileNames[i]);
    }
    //ls -S
    if(ls_S == 1)
    {
        ls_S_func();  //调用ls_S_func利用排序输出实现
    }
    // ls -t与ls -u命令 ls -c命令
    // 其中t是修改时间 u是访问时间
    if(ls_t == 1 || ls_u == 1 || ls_c == 1)
    {
        ls_t_func();  //调用ls_t_func利用排序输出实现
    }
    
    if(!(ls_l || ls_1 || ls_i || ls_n || ls_F || ls_s || ls_o || ls_g))
        printf("\n");
}

//main函数
int main(int argc,char **argv)
{
	struct stat buf;
	int i = 8;
	char filename[NAME_MAX];
    int havePath = 0;   //表征参数中是否有文件路径(绝对路径或者相对路径)
	memset(filename,0,sizeof(filename));  //将filename数组中的内容置为0
    parseParam(argc,argv);
    
    while(--argc != 0){ //检查路径选项
        ++argv;
        if((*argv)[0] != '-'){ //非参数选项
            havePath = 1;
            if(stat(*argv,&buf) < 0)    //stat调用失败 报错
            {
                perror("stat");
                return -1;
            }
            if(S_ISDIR(buf.st_mode))  //是目录
                displayDir(*argv);    //调用目录显示函数
            else{
                //获取文件名
                char* path = *argv;   //文件路径
                for(i = strlen(path) - 1; i > 0 && path[i - 1] != '/'; i--){
                    ; //获取文件名的开始位置
                }
                strcpy(filename, &path[i]);  //文件的基准名字
                displayFile(*argv,filename); //调用文件显示函数
            }
        }
    }
    if(havePath == 0) // 如果没有路径参数
    {
        char *buffer; //获取当前目录
        if((buffer = getcwd(NULL,0))==NULL){
            perror("getcwd error");     //获取失败 报错
        }
        else{
            displayDir(buffer); //显示当前目录
            free(buffer);
        }
    }
	return 0;
}


//命令解析函数
//@argc: main函数参数个数
//argv: main函数参数数组
void parseParam(int argc,char* argv[])
{
    int i;  //index
    int count = 0;      //命令个数
    while(--argc != 0){ //逐一解读
        ++argv;         //解读选项
        if((*argv)[0] == '-'){ //命令中有参数选项
            count++;
            //读取该命令参数数组中的**所有**选项参数
            for(i = 1; (*argv)[i] != '\0'; i++){
                switch((*argv)[i])
                {
                    case 'a':ls_a = 1;;continue;break;  //a选项
                    case 'l':ls_l = 1;continue;break;   //l选项
                    case '1':ls_1 = 1;continue;break;   //1选项
                    case 'i':ls_i = 1;continue;break;   //i选项
                    case 'd':ls_d = 1;continue;break;   //d选项
                    case 'o':ls_o = 1;continue;break;   //o选项
                    case 'N':ls_N = 1;continue;break;   //N选项
                    case 'n':ls_n = 1;continue;break;   //n选项
                    case 't':ls_t = 1;continue;break;   //t选项
                    case 'F':ls_F = 1;continue;break;   //F选项
                    case 'Q':ls_Q = 1;continue;break;   //Q选项
                    case 'R':ls_R = 1;continue;break;   //R选项
                    case 'g':ls_g = 1;continue;break;   //g选项
                    case 'A':ls_A = 1;continue;break;   //A选项
                    case 's':ls_s = 1;continue;break;   //s选项
                    case 'B':ls_B = 1;continue;break;   //B选项
                    case 'u':ls_u = 1;continue;break;   //u选项
                    case 'm':ls_m = 1;continue;break;   //m选项
                    case 'r':ls_r = 1;continue;break;   //r选项
                    case 'S':ls_S = 1;continue;break;   //S选项
					case 'c':ls_c = 1;continue;break;   //c选项
                    case 'f':ls_a = 1;continue;break;   //f选项
                    default:printf("%s: invalid option: %c\n", argv[0], (*argv)[i]);
                            exit(1);
                }
            }
        }
    }
    if(count==0)ls_none = 1; //没有选项 但可能有参数-路径
}


