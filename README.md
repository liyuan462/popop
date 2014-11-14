# PoPop

## 概述

PoPop是一个小工具，方便用Linux的同学及时地收到Windows虚拟机里面的泡泡新消息提示。这个工具fork自[popo-plugin](https://github.com/cedricporter/popo-plugin)，在其基础上消除Windows客户端对Python的依赖，直接采用socket进行通信，Windows端提供打包好的exe，Linux提供方便后台运行的daemon。

## 安装使用

分为Linux宿主机端和Windows虚拟机端。

### Linux宿主机

1. 用git检出代码，进入linux/目录

2. 安装：

        $ python setup.py install

3. Linux端提供了两种使用方式，一种是命令行，一种是daemon。

命令行方式如下，可用-p指定端口，默认为12345：

        $ popop -p <port>

daemon方式如下：

        $ popop daemon start|stop|restart|status

可将daemon方式启动的命令配置到系统的开机自启动程序里面，要添加的命令如下: `popop daemon restart`

daemon方式下，用`-p`选项指定12345之外的端口，`-i`选项可指定pid文件的路径(默认是`/var/tmp/popopd.pid`)，`-l`选项可指定log文件的路径(默认是`/tmp/popopd.log`)。需要注意的是，如果`popop daemon start`时用`-i`选项指定了自己的pid路径，那么在运行`popop daemon stop|status|restart`时也请带上相同的pid路径。
    
### Windows虚拟机

下载windows/目录下的PoPop.zip压缩包，解压后双击PoPop.exe即可运行，请放心，绿色无毒！

第一次运行会弹出窗口供你配置Linux宿主机的IP和端口，IP即Linux宿主机的IP，端口保持和Linux端设置一致即可。设好后请点击保存，这样下次运行时就不会自动弹出配置窗口，如果要更改配置，请右键单击系统右下角的应用托盘图标，选择"配置"；如果要退出程序，请右击托盘图标后选择"退出"；要设置成开机自启动请将程序(快捷方式)放到[开始]->[所有程序]->[启动]下面。

祝使用愉快！
