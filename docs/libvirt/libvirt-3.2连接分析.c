//libvirt.c
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
    return ret;
}


