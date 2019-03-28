libguestfs/p2v/main.c

int main(int argc, char *argv[]){

	gboolean gui_possible;	使用gui配置
	int c;	传参解析结果
	int option_index;	
	char **cmdline = NULL;	cmdline字段
	int cmdline_source = 0;	指示从何处解析cmdline
	struct config *config = new_config ();	配置

	gui配置
	gui_possible = gtk_init_check (&argc, &argv);

  	for (;;) {
	    c = getopt_long (argc, argv, options, long_options, &option_index);
	    if (c == -1) break;

	    switch (c) {
	    case 0:	
	    	根据解析出的命令行选项进行处理
	    	else if (STREQ (long_options[option_index].name, "cmdline")) {
		        cmdline = parse_cmdline_string (optarg);
		        cmdline_source = CMDLINE_SOURCE_COMMAND_LINE;
		    ...
		    force_colour = 1;
		    set_nbd_option (optarg);
		    break;
	    ...
	    case HELP_OPTION:
	      usage (EXIT_SUCCESS);

	    default:
	      usage (EXIT_FAILURE);
    }

    测试nbd服务
    test_nbd_servers ();

    初始化config
    set_config_defaults (config);

    解析 /proc/cmdline 或使用传参 --cmdline 中的 内核启动参数 初始化配置
  	if (cmdline == NULL) {
  		//Returns a list of key, value pairs, terminated by C<NULL>.
	    cmdline = parse_proc_cmdline ();
	    if (cmdline != NULL)
	      cmdline_source = CMDLINE_SOURCE_PROC_CMDLINE;
  	}

  	if (cmdline)
    	update_config_from_kernel_cmdline (config, cmdline);

    如果p2v.server存在，就使用非交互式的kernel模式转换，否则使用GUI
  	if (config->server != NULL)
	    kernel_conversion (config, cmdline, cmdline_source);
			//kernel.c
			//使用内核方式执行转换
			执行 Pre-conversion 命令
			run_command ("p2v.pre", p);
			测试网络连接
			test_connection (config)
				建立ssh连接
				h = start_ssh (0, config, NULL, 1);
				执行一些检查，有异常情况就返回失败
			检查硬盘数量
			guestfs_int_count_strings (config->disks) ！= 0
			开始转换//notify_ui_callback 是ui回显函数，返回转换过程中的信息
			start_conversion (config, notify_ui_callback)
			失败了就执行 fail-conversion 命令
			run_command ("p2v.fail", p);
			通知转换成功
			执行 Post-conversion 命令
			run_command ("p2v.post", p);
  	else {
	    if (!gui_possible)
	    	报错
	    gui_conversion (config);
	    	//gui.c
	    	创建连接对话框
	    	创建转换对话框
	    	创建运行对话框
	    	显示连接对话框

	    	设置config

	    	最终也去执行
	    	copy = copy_config (config);
	    	start_conversion (copy, notify_ui_callback);
  	}

  	释放资源之后退出
}

//conversion.c
/* Data per NBD connection / physical disk. */
struct data_conn {
  mexp_h *h;                /* miniexpect handle to ssh */
  pid_t nbd_pid;            /* NBD server PID */
  int nbd_remote_port;      /* remote NBD port on conversion server */
};

int start_conversion (struct config *config,
                  void (*notify_ui) (int type, const char *data))
{
	const size_t nr_disks = guestfs_int_count_strings (config->disks); 磁盘数量
	CLEANUP_FREE struct data_conn *data_conns = NULL;	NBD连接
  	CLEANUP_FREE char *remote_dir = NULL;	
	定义一系列初始状态的文件数组
	char name_file[]        = "/tmp/p2v.XXXXXX/name";
	...

	全局控制句柄置空
	set_control_h (NULL);
	将运行状态置1
  	set_running (1);

	为每个硬盘建立一个NBD连接
	for (i = 0; config->disks[i] != NULL; ++i) {
	    data_conns[i].h = NULL;
	    data_conns[i].nbd_pid = 0;
	    data_conns[i].nbd_remote_port = -1;
	}

	为每块硬盘开启数据连接和NBD服务进程
	for (i = 0; config->disks[i] != NULL; ++i) {
		const char *nbd_local_ipaddr; 地址
	    int nbd_local_port;	端口
	    CLEANUP_FREE char *device = NULL;	设备

	    获取设备
		if (config->disks[i][0] == '/') {
	      	device = strdup (config->disks[i]);
	    }
	    else asprintf (&device, "/dev/%s", config->disks[i])

	    在给定的端口开启NBD服务监听
		data_conns[i].nbd_pid = 
			start_nbd_server (&nbd_local_ipaddr, &nbd_local_port, device);
			//nbd.c
			switch (use_server) {
		  		case QEMU_NBD:
		  			*ipaddr = "127.0.0.1";
    				*port = open_listening_socket (*ipaddr, &fds, &nr_fds);
    				在本地开启一个qemu-nbd进程
    				pid = start_qemu_nbd (device, *ipaddr, *port, fds, nr_fds);
		  		case QEMU_NBD_NO_SA:
		  			*ipaddr = "localhost";
				    *port = get_local_port ();
				    return start_qemu_nbd (device, *ipaddr, *port, NULL, 0);
		  		case NBDKIT:	与上述方法类似
		  		case NBDKIT_NO_SA:	与上述方法类似
			}

		等待NBD服务启动、监听
		wait_for_nbd_server_to_start (nbd_local_ipaddr, nbd_local_port)

		打开SSH数据连接，反向端口转发回NBD服务
		//开启ssh子进程，提取出端口号赋值给nbd_remote_port
		data_conns[i].h = open_data_connection (config,
                                            nbd_local_ipaddr, nbd_local_port,
                                            &data_conns[i].nbd_remote_port);
	}
	创建远程文件夹名字
	asprintf (&remote_dir,
            "/tmp/virt-p2v-%04d%02d%02d-XXXXXXXX",
            tm.tm_year + 1900, tm.tm_mon + 1, tm.tm_mday)

	将后8位即"XXXXXXXX"替换成随机字符
	guestfs_int_random_string (&remote_dir[len-8], 8);

	创建本地临时文件夹，将"/tmp/p2v.XXXXXX"后六位替换为随机字符文件夹
	mkdtemp (tmpdir)
	将那些文件重命名
	memcpy (name_file, tmpdir, strlen (tmpdir));
	...

	生成静态文件，填充其内容
  	generate_name (config, name_file);
	generate_libvirt_xml (config, data_conns, libvirt_xml_file);
	generate_wrapper_script (config, remote_dir, wrapper_script);
	generate_system_data (dmesg_file,
	                    lscpu_file, lspci_file, lsscsi_file, lsusb_file);
	generate_p2v_version_file (p2v_version_file);

	打开远程控制连接。创建远程文件夹 remote_dir。
	set_control_h (start_remote_connection (config, remote_dir));
		//start_remote_connection 创建ssh子进程，创建文件夹，写入time文件。返回ssh句柄
		//set_control_h 将全局变量 control_h 设置为 传参

	发送上述的静态文件到转换服务器
	scp_file (config, remote_dir,
            name_file, libvirt_xml_file, wrapper_script, NULL)
	scp_file (config, remote_dir,
                      dmesg_file, lscpu_file, lspci_file, lsscsi_file,
                      lsusb_file, p2v_version_file, NULL)

	执行转换，运行到 virt-v2v 退出为止
	//执行virt-v2v-wrapper.sh脚本
	mexp_printf (control_h,
				"%s/virt-v2v-wrapper.sh; "
               	"exit $(< %s/status)\n",
               	remote_dir, remote_dir)

	从virt-v2v进程读取输出，然后通过notify函数打印，直到virt-v2v关闭连接
	while (!is_cancel_requested ()) {
	    char buf[257];
	    ssize_t r;

	    r = read (mexp_get_fd (control_h), buf, sizeof buf - 1);
	    if (r == 0)
	      	break;                    /* EOF */
	    buf[r] = '\0';
		打印
	}

	out:
	关闭连接
	if (control_h) {
		mexp_h *h = control_h;
	    set_control_h (NULL);
	    status = mexp_close (h);
	}

	清理数据
	将运行状态归零
	return ret;
}