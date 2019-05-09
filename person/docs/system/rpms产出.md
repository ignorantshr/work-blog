rpms产出

vdc-refa:
    vdc-1.0.0-142.gitd62ccbc.refa.x86_64.rpm
    vdc-debuginfo-1.0.0-142.gitd62ccbc.refa.x86_64.rpm
    vdc-plugin-net-1.0.0-142.gitd62ccbc.refa.x86_64.rpm
    vdc-plugin-vpn-1.0.0-142.gitd62ccbc.refa.x86_64.rpm

vdc-zhgf:
    vdc-1.0.0-29.gitdefba2a.zhgf.x86_64.rpm
    vdc-debuginfo-1.0.0-29.gitdefba2a.zhgf.x86_64.rpm

vdc-sec-2.5.10
    vdc-1.0.0-194.git7cb4d66.sec.x86_64.rpm
    vdc-debuginfo-1.0.0-194.git7cb4d66.sec.x86_64.rpm
    vdc-plugin-net-1.0.0-194.git7cb4d66.sec.x86_64.rpm
    vdc-plugin-vpn-1.0.0-194.git7cb4d66.sec.x86_64.rpm


rpms:
vms-sec-2.5.9

vms-sec-sec-2.5.9/ovirt-engine
vms-sec-sec-2.5.9/ovirt-engine-api
vms-sec-sec-2.5.9/ovirt-engine-audit-portal
vms-sec-sec-2.5.9/ovirt-engine-backend
vms-sec-sec-2.5.9/ovirt-engine-dbscripts
vms-sec-sec-2.5.9/ovirt-engine-extend-portal
vms-sec-sec-2.5.9/ovirt-engine-lib
vms-sec-sec-2.5.9/ovirt-engine-secrecy-portal
vms-sec-sec-2.5.9/ovirt-engine-setup-base
vms-sec-sec-2.5.9/ovirt-engine-setup-plugin-ovirt-engine
vms-sec-sec-2.5.9/ovirt-engine-setup-plugin-ovirt-engine-common
vms-sec-sec-2.5.9/ovirt-engine-setup-plugin-vmconsole-proxy-helper
vms-sec-sec-2.5.9/ovirt-engine-setup-plugin-websocket-proxy
vms-sec-sec-2.5.9/ovirt-engine-tools
vms-sec-sec-2.5.9/ovirt-engine-tools-backup
vms-sec-sec-2.5.9/ovirt-engine-vmconsole-proxy-helper
vms-sec-sec-2.5.9/ovirt-engine-webadmin-portal
vms-sec-sec-2.5.9/ovirt-engine-websocket-proxy
vms-sec-sec-2.5.9/ovirt-engine-dashboard
vdsm-sec/vdsm
vdsm-sec/vdsm-api
vdsm-sec/vdsm-cli
vdsm-sec/vdsm-hook-vmfex-dev
vdsm-sec/vdsm-infra
vdsm-sec/vdsm-jsonrpc
vdsm-sec/vdsm-python
vdsm-sec/vdsm-xmlrpc
vdsm-sec/vdsm-yajsonrpc
qemu-kvm-ev-sec/qemu-kvm-tools-ev
qemu-kvm-ev-sec/qemu-kvm-ev
qemu-kvm-ev-sec/qemu-kvm-common-ev
qemu-kvm-ev-sec/qemu-img-ev
ovirt-provider-ovn-sec/ovirt-provider-ovn-driver
ovirt-provider-ovn-sec/ovirt-provider-ovn
secretclient-sec/secretclient
ACloudAge-release-sec/ACloudAge-release
ovs-sec/openvswitch
ovs-sec/openvswitch-ovn-central
ovs-sec/openvswitch-ovn-common
ovs-sec/openvswitch-ovn-host
ovs-sec/python-openvswitch
tripwire-sec/tripwire
spice-html5-sec/spice-html5


vms-vgpu

vms-sec-vgpu/ovirt-engine
vms-sec-vgpu/ovirt-engine-api
vms-sec-vgpu/ovirt-engine-audit-portal
vms-sec-vgpu/ovirt-engine-backend
vms-sec-vgpu/ovirt-engine-dbscripts
vms-sec-vgpu/ovirt-engine-extend-portal
vms-sec-vgpu/ovirt-engine-lib
vms-sec-vgpu/ovirt-engine-secrecy-portal
vms-sec-vgpu/ovirt-engine-setup-base
vms-sec-vgpu/ovirt-engine-setup-plugin-ovirt-engine
vms-sec-vgpu/ovirt-engine-setup-plugin-ovirt-engine-common
vms-sec-vgpu/ovirt-engine-setup-plugin-vmconsole-proxy-helper
vms-sec-vgpu/ovirt-engine-setup-plugin-websocket-proxy
vms-sec-vgpu/ovirt-engine-tools
vms-sec-vgpu/ovirt-engine-tools-backup
vms-sec-vgpu/ovirt-engine-vmconsole-proxy-helper
vms-sec-vgpu/ovirt-engine-webadmin-portal
vms-sec-vgpu/ovirt-engine-websocket-proxy
vms-sec-sec-2.5.9/ovirt-engine-dashboard
vdsm-vgpu/vdsm
vdsm-vgpu/vdsm-api
vdsm-vgpu/vdsm-cli
vdsm-vgpu/vdsm-hook-vmfex-dev
vdsm-vgpu/vdsm-infra
vdsm-vgpu/vdsm-jsonrpc
vdsm-vgpu/vdsm-python
vdsm-vgpu/vdsm-xmlrpc
vdsm-vgpu/vdsm-yajsonrpc
qemu-kvm-2.6.0-sec/qemu-kvm-tools-ev
qemu-kvm-2.6.0-sec/qemu-kvm-ev
qemu-kvm-2.6.0-sec/qemu-kvm-common-ev
qemu-kvm-2.6.0-sec/qemu-img-ev
ovirt-provider-ovn-sec/ovirt-provider-ovn-driver
ovirt-provider-ovn-sec/ovirt-provider-ovn
secretclient-sec/secretclient
ACloudAge-release-sec/ACloudAge-release
ovs-sec/openvswitch
ovs-sec/openvswitch-ovn-central
ovs-sec/openvswitch-ovn-common
ovs-sec/openvswitch-ovn-host
ovs-sec/python-openvswitch
tripwire-sec/tripwire
spice-html5-sec/spice-html5

tools.iso打包

remote_isos_path=http://172.16.6.189/pub/iso_output/tools
iso_path=/home/pub/iso_output/tools
output_name=tools-test.iso
output_path=root@172.16.6.189:/home/pub/iso_output/vms
rsync_url=rsync://172.16.6.189/extras_tools
vdc_win=/home/pub/pkg_output/vdc-group/vdc-win/
branch_path=http://172.16.6.189/pub/pkg_output/vdc-group/vdc-win

isos=`ssh root@172.16.6.189 "ls --sort=time -r $iso_path"`
for iso in $isos
do
        real=$iso
done
echo ${real}
wget -P /tmp $remote_isos_path/$real
if [ $? -ne 0 ]; then
    echo "Failed to get iso!"
    exit 1
fi

mkdir /tmp/${output_name}.tmp
mount /tmp/$real /tmp/${output_name}.tmp
if [ $? -ne 0 ]; then
    echo "Failed to mount iso!"
    exit 1
fi

mkdir /tmp/$output_name
cd /tmp/$output_name

# first rsync, then cp iso
rsync --delete -avrt $rsync_url  .
if [ $? -ne 0 ]; then
    echo "Failed to rsync iso base files!"
    exit 1
fi

cp -r /tmp/${output_name}.tmp/. /tmp/$output_name/
umount -v /tmp/${output_name}.tmp && rm -rf /tmp/${output_name}.tmp && rm -f /tmp/$real

# get vdc-win.exe
branchs=`ssh root@172.16.6.189 "ls ${vdc_win}"`
for branch in $branchs
do
    exes=`ssh root@172.16.6.189 "ls --sort=time -r ${vdc_win}/${branch}/output/"`
    echo $exes
    for exe in $exes
    do
        real_exe=$exe
    done
    echo ${branch_path}/$branch/output/${real_exe}
    wget --quiet ${branch_path}/$branch/output/${real_exe}
done

mkisofs -J -rational-rock -full-iso9660-filenames -o ${output_name} .
if [ $? -ne 0 ]; then
    echo "Failed to make iso!"
    exit 1
fi

scp $output_name $output_path
rm -rf /tmp/$output_name/


ks-release-packer.sh
------------------------

version=v1.4
date=`date +%Y%m%d%H%M%S`
buildid=1
ssh_path=root@172.16.6.189
vms_iso_path=http://172.16.6.189/pub/iso_output/vms
vdc_iso_path=http://172.16.6.189/pub/iso_output/vdc
tools_iso_path=http://172.16.6.189/pub/iso_output/tools
remote_repo=root@172.16.6.189:/home/pub/release
modify_rpms=rpms.list

vms_iso_server_path=/home/pub${vms_iso_path#*pub}
vdc_iso_server_path=/home/pub${vdc_iso_path#*pub}
tools_iso_server_path=/home/pub${tools_iso_path#*pub}

mkdir ${version}_${date} && cd ${version}_${date}
rpms=build_${date}_${buildid}.info
mkdir $rpms
mkdir -p packages/vms packages/vdc

# get modified rpms
OLD_IFS="$IFS"
for item in `cat ../${modify_rpms}`
do
    IFS="/"
    arr=($item)
    IFS="$OLD_IFS"
    prod=${arr[0]}
    repo=${arr[1]}
    name=${arr[2]}
    yum clean all --enablerepo=$repo
    yumdownloader --enablerepo=$repo --destdir=packages/${prod} $name
    if [ $? -ne 0 ]; then
        echo "Failed to get ${prod} package $name in $repo!"
        exit 1
    fi
done

# get last vms-iso
vms_isos=`ssh ${ssh_path} "cd ${vms_iso_server_path} && ls --sort=time -r *${version}*.iso"`
for vms_iso in ${vms_isos}
do
    vms_iso_real=$vms_iso
done
wget -O ACloudAge_KS_vms_${version}.iso ${vms_iso_path}/${vms_iso_real}

# get vms-iso-rpms
vms_iso_main=${vms_iso_real%.iso}
wget -P ${rpms}/ ${vms_iso_path}/${vms_iso_main}-rpm.list

# get last vdc-iso
vdc_isos=`ssh ${ssh_path} "cd ${vdc_iso_server_path} && ls --sort=time -r *${version}*.iso"`
for vdc_iso in ${vdc_isos}
do
    vdc_iso_real=$vdc_iso
done
wget -O ACloudAge_KS_vdc_${version}.iso ${vdc_iso_path}/${vdc_iso_real}

# get vdc-iso-rpms
vdc_iso_main=${vdc_iso_real%.iso}
wget -P ${rpms}/ ${vdc_iso_path}/${vdc_iso_main}-rpm.list

# get last tools-iso
tools_isos=`ssh ${ssh_path} "cd ${tools_iso_server_path} && ls --sort=time -r *${version}*.iso"`
for tools_iso in ${tools_isos}
do
    tools_iso_real=$tools_iso
done
wget -O ACloudAge_KS_tools_${version}.iso ${tools_iso_path}/${tools_iso_real}

cd ..
scp -r ${version}_${date} ${remote_repo}
#rm -rf ${version}_${date}


