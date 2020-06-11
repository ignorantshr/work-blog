src/libvirt.c:
	添加条件编译swvm驱动头文件

src/swvm/:
	swvm_conf配置文件及其相应的头文件与源文件
	swvm_domain头文件与源文件。虚拟机时间队列
	swvm_driver头文件与源文件。swvm驱动

src/util/:
	virarch.h\.c：
		添加swvm架构
	virerror.c：
		添加swvm错误类型

src/conf/:
	domain_conf.h\.c:
		添加swvm hypervisor类型

include/libvirt/virterror.h：
	添加swvm driver错误来源

daemon/libvirtd.c：
	添加swvm驱动的条件编译头文件
	添加swvm载入模块（注册）的条件编译

构建系统对swvm的补充：
	configure.ac
	src/Makefile.am
	m4/virt-driver-swvm.m4

名词解释：transient-瞬态；persistent-持久的；

结构体说明：

驱动
struct _virSWVM2Driver
{
    virMutex lock;

    /* Atomic increment only */
    int lastvmid;

    /* Require lock to get reference on 'config',
     * then lockless thereafter */
    //配置结构体
    virSWVM2DriverConfigPtr config;

    /* Require lock to get a reference on the object,
     * lockless access thereafter */
    virCapsPtr caps;

    /* Immutable pointer, Immutable object */
    virDomainXMLOptionPtr xmlopt;

    /* Immutable pointer, lockless APIs*/
    virSysinfoDefPtr hostsysinfo;

    // /* Atomic inc/dec only */
    // unsigned int nactive;

    /* Immutable pointer */
    char *swvm2ImgBinary;

    /* SW platfrom use 32G memory */
    unsigned long long memory_left;
    /* Immutable value */
    bool privileged;

    /* Immutable pointers. Caller must provide locking */
    virStateInhibitCallback inhibitCallback;
    void *inhibitOpaque;

    /* Immutable pointer, self-locking APIs */
    virDomainObjListPtr domains;

    /* Immutable pointer, self-locking APIs */
    virObjectEventStatePtr domainEventState;

    // /* Immutable pointer. self-locking APIs */
    // virSecurityManagerPtr securityManager;

    /* Immutable pointer, self-locking APIs */
    virCloseCallbacksPtr closeCallbacks;

    virPortAllocatorPtr vncPorts;
};

驱动配置：
struct _virSWVM2DriverConfig{
    virObject parent;

    const char *uri;

    char *configDir;
    char *autostartDir;
    char *stateDir;
    char *logDir;
    char *cacheDir;
    char *snapshotDir;
    unsigned long long memory_total;

    char *sys_disk;

    int have_netns;

    unsigned int vncPortMin;
    unsigned int vncPortMax;

    unsigned int maxQueuedJobs;

    bool autoStartBypassCache;
    bool allowDiskFormatProbing;
};

带有驱动连接的虚拟机：包含了虚拟机的名字、id、uuid
struct _virDomain {
    virObject object;
    virConnectPtr conn;                  /* pointer back to the connection */
    char *name;                          /* the domain external name */
    int id;                              /* the domain ID */
    unsigned char uuid[VIR_UUID_BUFLEN]; /* the domain unique identifier */
};

虚拟机对象vm：封装了虚拟机的配置及其状态
struct _virDomainObj {
    virObjectLockable parent;
    virCond cond;

    pid_t pid;
    virDomainStateReason state;

    unsigned int autostart : 1;
    unsigned int persistent : 1;
    unsigned int updated : 1;
    unsigned int removing : 1;

    virDomainDefPtr def; /* The current definition */
    virDomainDefPtr newDef; /* New definition to activate at shutdown */

    virDomainSnapshotObjListPtr snapshots;
    virDomainSnapshotObjPtr current_snapshot;

    bool hasManagedSave;

    void *privateData;
    void (*privateDataFreeFunc)(void *);

    int taint;

    unsigned long long original_memlock; /* Original RLIMIT_MEMLOCK, zero if no
                                          * restore will be required later */
};

虚拟机主要配置
struct _virDomainDef {
    virDomainVirtType virtType;
    int id;
    unsigned char uuid[VIR_UUID_BUFLEN];
    char *name;
    char *title;
    char *description;
    ...
}