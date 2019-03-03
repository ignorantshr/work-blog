//libvirt.c
//第一步先连接，然后再根据需要去连接remote
virConnectPtr
virConnectOpen(const char *name){
	//初始化，注册所有的driver
    virInitialize();
        int
        virInitialize(void)
        {
            if (virOnce(&virGlobalOnce, virGlobalInit) < 0)
                return -1;
                //virGlobalInit注册包括远程通过libvirtd调用的驱动，
                static void
                virGlobalInit(void)
                {
                    #ifdef WITH_REMOTE
                        if (remoteRegister() == -1)
                            goto error;
                            //remote_driver.c
                            //注册远程驱动Register driver with libvirt driver system.
                            int
                            remoteRegister(void)
                            {
                                if (virRegisterConnectDriver(&connect_driver,
                                                             false) < 0)
                                    return -1;
                                    //libvirt.c
                                    //注册连接驱动
                                    int
                                    virRegisterConnectDriver(virConnectDriverPtr driver, bool setSharedDrivers)
                                    {
                                        //是否使用外部供应商
                                        if (setSharedDrivers) {
                                            if (driver->interfaceDriver == NULL)
                                                driver->interfaceDriver = virSharedInterfaceDriver;
                                            if (driver->networkDriver == NULL)
                                                driver->networkDriver = virSharedNetworkDriver;
                                            if (driver->nodeDeviceDriver == NULL)
                                                driver->nodeDeviceDriver = virSharedNodeDeviceDriver;
                                            if (driver->nwfilterDriver == NULL)
                                                driver->nwfilterDriver = virSharedNWFilterDriver;
                                            if (driver->secretDriver == NULL)
                                                driver->secretDriver = virSharedSecretDriver;
                                            if (driver->storageDriver == NULL)
                                                driver->storageDriver = virSharedStorageDriver;
                                        }

                                        virConnectDriverTab[virConnectDriverTabCount] = driver;
                                        return virConnectDriverTabCount++;
                                    }
                                if (virRegisterStateDriver(&state_driver) < 0)
                                    return -1;
                                	//注册状态驱动
	                                int
									virRegisterStateDriver(virStateDriverPtr driver)
									{

									    virStateDriverTab[virStateDriverTabCount] = driver;
									    return virStateDriverTabCount++;
									}

                                return 0;
                            }
                    #endif
                }

            if (virGlobalError)
                return -1;
            return 0;
        }
    //
    ret = virConnectOpenInternal(name, NULL, 0);

    	static virConnectPtr
		virConnectOpenInternal(const char *name,
		                       virConnectAuthPtr auth,
		                       unsigned int flags)
		{
			virConnectPtr ret;
		    virConfPtr conf = NULL;
		    char *uristr = NULL;
			//获取与hypervisor的连接
			ret = virGetConnect();
			//加载配置文件
			virConfLoadConfig(&conf, "libvirt.conf")；

			if (name) {
				//复制name到uristr
		        if (VIR_STRDUP(uristr, name) < 0)
		            goto failed;
		    } else {
		    	//使用配置文件中的uri
		        if (virConnectGetDefaultURI(conf, &uristr) < 0)
		            goto failed;
		    }

		    //解析uri，存入ret中
		    if (uristr) {
		    	ret->uri = virURIParse(uristr)；
		    	//uri->scheme, "qemu"
		    	//uri->server, "system"
		    } else {
		        VIR_DEBUG("no name, allowing driver auto-select");
		    }

		    //探测remote类型的driver
		    for (i = 0; i < virConnectDriverTabCount; i++) {
		        if (STREQ(virConnectDriverTab[i]->hypervisorDriver->name, "remote") &&
		            ret->uri != NULL && ret->uri->scheme != NULL &&
		            (
		#ifndef WITH_PHYP
		             STRCASEEQ(ret->uri->scheme, "phyp") ||
		#endif
		#ifndef WITH_ESX
		             STRCASEEQ(ret->uri->scheme, "vpx") ||
		             STRCASEEQ(ret->uri->scheme, "esx") ||
		             STRCASEEQ(ret->uri->scheme, "gsx") ||
		#endif
		#ifndef WITH_HYPERV
		             STRCASEEQ(ret->uri->scheme, "hyperv") ||
		#endif
		#ifndef WITH_XENAPI
		             STRCASEEQ(ret->uri->scheme, "xenapi") ||
		#endif
		#ifndef WITH_VZ
		             STRCASEEQ(ret->uri->scheme, "parallels") ||
		#endif
		             false)) {
		            virReportErrorHelper(VIR_FROM_NONE, VIR_ERR_CONFIG_UNSUPPORTED,
		                                 __FILE__, __FUNCTION__, __LINE__,
		                                 _("libvirt was built without the '%s' driver"),
		                                 ret->uri->scheme);
		            goto failed;
		        }

		        VIR_DEBUG("trying driver %zu (%s) ...",
		                  i, virConnectDriverTab[i]->hypervisorDriver->name);
				//virHypervisorDriver定义了一系列的虚拟化操作
		        ret->driver = virConnectDriverTab[i]->hypervisorDriver;
		        ret->interfaceDriver = virConnectDriverTab[i]->interfaceDriver;
		        ret->networkDriver = virConnectDriverTab[i]->networkDriver;
		        ret->nodeDeviceDriver = virConnectDriverTab[i]->nodeDeviceDriver;
		        ret->nwfilterDriver = virConnectDriverTab[i]->nwfilterDriver;
		        ret->secretDriver = virConnectDriverTab[i]->secretDriver;
		        ret->storageDriver = virConnectDriverTab[i]->storageDriver;
		        //测试每个driver的能否连接
		        res = virConnectDriverTab[i]->hypervisorDriver->connectOpen(ret, auth, conf, flags);
		        VIR_DEBUG("driver %zu %s returned %s",
		                  i, virConnectDriverTab[i]->hypervisorDriver->name,
		                  res == VIR_DRV_OPEN_SUCCESS ? "SUCCESS" :
		                  (res == VIR_DRV_OPEN_DECLINED ? "DECLINED" :
		                  (res == VIR_DRV_OPEN_ERROR ? "ERROR" : "unknown status")));

		        //有一个连接成功了，就跳出循环
		        if (res == VIR_DRV_OPEN_SUCCESS) {
		            break;
		        } else {
		            ret->driver = NULL;
		            ret->interfaceDriver = NULL;
		            ret->networkDriver = NULL;
		            ret->nodeDeviceDriver = NULL;
		            ret->nwfilterDriver = NULL;
		            ret->secretDriver = NULL;
		            ret->storageDriver = NULL;

		            if (res == VIR_DRV_OPEN_ERROR)
		                goto failed;
		        }
		    }
		}
    return ret;
}

//libvirtd.c
int main(int argc, char **argv) {
	char *remote_config_file = NULL;
	搞一下配置文件、日志、host_uuid、socket_path等
	daemonInitialize();
		先载入网络、接口等资源模块，再载入driver模块
		#ifdef WITH_NETWORK
		    VIR_DAEMON_LOAD_MODULE(networkRegister, "network");
		#endif
		    ...
		#ifdef WITH_QEMU
		    VIR_DAEMON_LOAD_MODULE(qemuRegister, "qemu");
		#endif

	对于remote的driver新建program，存储到srv数组中，srv存到dmn中
	//Initialize drivers & then start accepting new clients from network
	daemonStateInit(dmn);
		static int daemonStateInit(virNetDaemonPtr dmn)
		{
		    virThread thr;
		    virObjectRef(dmn);
		    if (virThreadCreate(&thr, false, daemonRunStateInit, dmn) < 0) {
		    	static void daemonRunStateInit(void *opaque)
				{
		    		//Start the stateful HV drivers
					virStateInitialize(virNetDaemonIsPrivileged(dmn), daemonInhibitCallback, dmn);
						//libvirt.c
						//初始化所有的state driver
						int
						virStateInitialize(bool privileged,
						                   virStateInhibitCallback callback,
						                   void *opaque)
						{
						    size_t i;

						    if (virInitialize() < 0)
						        return -1;

						    for (i = 0; i < virStateDriverTabCount; i++) {
						        if (virStateDriverTab[i]->stateInitialize) {
						            VIR_DEBUG("Running global init for %s state driver",
						                      virStateDriverTab[i]->name);
						            if (virStateDriverTab[i]->stateInitialize(privileged,
						                                                      callback,
						                                                      opaque) < 0) {
						                VIR_ERROR(_("Initialization of %s state driver failed: %s"),
						                          virStateDriverTab[i]->name,
						                          virGetLastErrorMessage());
						                return -1;
						            }
						        }
						    }

						    for (i = 0; i < virStateDriverTabCount; i++) {
						        if (virStateDriverTab[i]->stateAutoStart) {
						            VIR_DEBUG("Running global auto start for %s state driver",
						                      virStateDriverTab[i]->name);
						            virStateDriverTab[i]->stateAutoStart();
						        }
						    }
						    return 0;
						}
				}
		        virObjectUnref(dmn);
		        return -1;
		    }
		    return 0;
		}
}



qemu模块：
//qemu_driver.c
int qemuRegister(void)
{
	//libvirt.c中注册，即加到virConnectDriverTab数组中
    if (virRegisterConnectDriver(&qemuConnectDriver,
                                 true) < 0)
        return -1;
    
		//qemuHypervisorDriver重写了虚拟机的API方法
    	static virConnectDriver qemuConnectDriver = {
		    .hypervisorDriver = &qemuHypervisorDriver,
		};

    //libvirt.c中注册，即加到virStateDriverTab数组中
    if (virRegisterStateDriver(&qemuStateDriver) < 0)
        return -1;
		static virStateDriver qemuStateDriver = {
		    .name = QEMU_DRIVER_NAME,
		    .stateInitialize = qemuStateInitialize,
		    .stateAutoStart = qemuStateAutoStart,
		    .stateCleanup = qemuStateCleanup,
		    .stateReload = qemuStateReload,
		    .stateStop = qemuStateStop,
		};
    return 0;
}

为qemu的daemon初始化方法
//qemu_driver.c
virQEMUDriverPtr qemu_driver = NULL;
static int
qemuStateInitialize(bool privileged,
                    virStateInhibitCallback callback,
                    void *opaque)
{
	virConnectPtr conn = NULL;
    virQEMUDriverConfigPtr cfg;
    初始化qemu_driver
    qemu_driver->config = cfg = virQEMUDriverConfigNew(privileged);
    	初始化qemu_driver的配置
    	cfg->uri = privileged ? "qemu:///system" : "qemu:///session";
    根据配置创建一些文件夹
    根据配置对qemu_driver初始化
    如果是root用户，改变创建的文件夹的所属用户和用户组
    //调用libvirt.c的连接函数
    conn = virConnectOpen(cfg->uri);
