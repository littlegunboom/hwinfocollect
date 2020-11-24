#!/bin/bash
if [ -f /root/hw_light.json ];then
	rm /root/hw_light.json
fi
if [ -f /root/hwinfoall ];then
	echo > /root/hwinfoall
fi

SYSTEMPATH='./1-system_bios_ipmi'
mkdir -p $SYSTEMPATH
dmidecode -t 1 > $SYSTEMPATH/ori_system.log
system_Manufacturer=$(echo `grep "Manufacturer" $SYSTEMPATH/ori_system.log|cut -d ":" -f 2`)
system_Product_Name=$(echo `grep "Product Name" $SYSTEMPATH/ori_system.log|cut -d ":" -f 2`)
system_Serial_Number=$(echo `grep "Serial Number" $SYSTEMPATH/ori_system.log|cut -d ":" -f 2`)
echo "----------System----------"
echo "Manufacturer: ${system_Manufacturer}"
echo "Product Name: ${system_Product_Name}"
echo "Serial Number: ${system_Serial_Number}"

#To_json
echo "{\"System\":{\"Product\":\"${system_Product_Name}\",\"SN\":\"${system_Serial_Number}\"}," > /root/hw_light.json

dmidecode -t bios > $SYSTEMPATH/ori_bios_ipmi.log
bios_bmc_BIOS_Revision=$(echo `grep "BIOS Revision" $SYSTEMPATH/ori_bios_ipmi.log|cut -d ":" -f 2`)
bios_bmc_Release_Date=$(echo `grep "Release Date" $SYSTEMPATH/ori_bios_ipmi.log|cut -d ":" -f 2`)
bios_bmc_Firmware_Revision=$(echo `grep "Firmware Revision" $SYSTEMPATH/ori_bios_ipmi.log|cut -d ":" -f 2`)
echo "----------BIOS----------"
echo "BIOS Revision: ${bios_bmc_BIOS_Revision}"
echo "Release Date: ${bios_bmc_Release_Date}"
echo "----------IPMI----------"
echo "IPMI Firmware Revision: ${bios_bmc_Firmware_Revision}"

rm -r $SYSTEMPATH

CPUPATH='./2-cpu'
mkdir -p $CPUPATH
dmidecode -t processor > $CPUPATH/ori_cpu.log
cpu_Version=$(echo `grep "Version:" $CPUPATH/ori_cpu.log |uniq |cut -d ":" -f 2`)
cpu_Num=$(echo `grep "Version:" $CPUPATH/ori_cpu.log |wc -l`)
cpu_Core_Count=$(echo `grep "Core Count" $CPUPATH/ori_cpu.log |uniq |cut -d ":" -f 2`)
cpu_Thread_Count=$(echo `grep "Thread Count" $CPUPATH/ori_cpu.log |uniq |cut -d ":" -f 2`)

echo "----------CPU----------"
echo "Processor model: ${cpu_Version}"
echo "Socket Counts: ${cpu_Num}"
echo "Core Count Per Socket: ${cpu_Core_Count}"
echo "Thread Count Per Socket: ${cpu_Thread_Count}"
echo "----------Kernel----------"
echo `uname -a`

#To_json
echo "\"CPU\":{\"Model\":\"${cpu_Version}\",\"Counts\":\"${cpu_Num}\"}," >> /root/hw_light.json

rm -r $CPUPATH

echo "----------Memory----------"
MEMPATH='./3-mem'
mkdir -p $MEMPATH
dmidecode -t memory > $MEMPATH/ori_dmimem.log
cat $MEMPATH/ori_dmimem.log |sed 's/^/#/g' |sed 's/$/;/g' > $MEMPATH/mod_dmimem_1.log
sed -i "s/#;//g" $MEMPATH/mod_dmimem_1.log
cat $MEMPATH/mod_dmimem_1.log |awk -v RS= '{$1=$1}1' > $MEMPATH/mod_dmimem_2.log
sed -i '1,2d' $MEMPATH/mod_dmimem_2.log 
grep -vE 'NO DIMM|No Module Installed' $MEMPATH/mod_dmimem_2.log > $MEMPATH/new_dmimem.log

echo -e "Memory_Size\t Memory_Locator\t Memory_Bank_Locator\t Memory_Type\t Memory_Speed\t Memory_Manufacturer\t Memory_Serial_Number\t Memory_Part_Number\t Memory_Configured_Clock_Speed\t"

while read -r line; do
	mem_Size=$(echo `echo "$line" |cut -d "#" -f8|cut -d ":" -f2|cut -d ";" -f1`)
	echo `echo "$line" |cut -d "#" -f8|cut -d ":" -f2|cut -d ";" -f1` >> $MEMPATH/mem_Size 
	mem_Locator=$(echo `echo "$line" |cut -d "#" -f11|cut -d ":" -f2|cut -d ";" -f1`)
	mem_Bank_Locator=$(echo `echo "$line" |cut -d "#" -f12|cut -d ":" -f2|cut -d ";" -f1`)
	mem_Type=$(echo `echo "$line" |cut -d "#" -f13|cut -d ":" -f2|cut -d ";" -f1`)
	mem_Speed=$(echo `echo "$line" |cut -d "#" -f15|cut -d ":" -f2|cut -d ";" -f1`)
	mem_Manufacturer=$(echo `echo "$line" |cut -d "#" -f16|cut -d ":" -f2|cut -d ";" -f1`)
	mem_Serial_Number=$(echo `echo "$line" |cut -d "#" -f17|cut -d ":" -f2|cut -d ";" -f1`)
	mem_Part_Number=$(echo `echo "$line" |cut -d "#" -f19|cut -d ":" -f2|cut -d ";" -f1`)
	mem_Configured_Clock_Speed=$(echo `echo "$line" |cut -d "#" -f21|cut -d ":" -f2|cut -d ";" -f1`)
	echo -e "${mem_Size}\t ${mem_Locator}\t ${mem_Bank_Locator}\t ${mem_Type}\t ${mem_Speed}\t ${mem_Manufacturer}\t ${mem_Serial_Number}\t ${mem_Part_Number}\t ${mem_Configured_Clock_Speed}"
done < $MEMPATH/new_dmimem.log

#To_json
mem_Counts=`cat $MEMPATH/mem_Size |wc -l`
mem_AllSize=`sort $MEMPATH/mem_Size |uniq`
echo "\"MEM\":{\"Size\":\"${mem_AllSize}\",\"Counts\":\"${mem_Counts}\"}," >> /root/hw_light.json

rm -r $MEMPATH

echo "----------NIC----------"
NICPATH='./4-nic'
mkdir -p $NICPATH
lshw -c network -numeric -businfo >> $NICPATH/lshw.log
eth=`grep "pci" -i $NICPATH/lshw.log |awk '{print $2}'`
for nic in $eth
do
#		bus=`ethtool -i $nic|grep bus-info|awk -F ":" '{print $3":"$4}'`
		bus=`grep $nic -i $NICPATH/lshw.log |awk -F " " '{print $1}' |cut -d "@" -f 2`
		des=$(echo `grep $nic -i $NICPATH/lshw.log |awk '{$1=$2=$3=""; print $0}'|cut -d '[' -f 1`)
		pciid=`grep $nic -i $NICPATH/lshw.log |cut -d '[' -f2|cut -d ']'  -f1`
		msi=`lspci -vvv -s $bus|grep "MSI-X"|awk -F " " '{print $5}'|awk -F "=" '{print $2}'`
		if lspci -vvv -s $bus |grep -i "IOV" >/dev/null; then
			vfs=`lspci -vvv -s $bus|grep VFs|awk -F " " '{print $6}' |grep -o '[[:digit:]]*'`
			sriov="YES, VFs:$vfs"
		else
			sriov="NO"
		fi
		echo "Interface:$nic, $bus, MSI-X:$msi, Support SRIOV:$sriov, PCI_ID:$pciid, Model:$des" 
#		ethtool -i $nic >>${NICPATH}/sysinfo.log
done

rm -r $NICPATH
  
echo "----------Disk----------"
if [[ `smartctl --scan-open | grep "bus"` == "" ]];then
#       echo no_bus
        device_paths=(`smartctl --scan-open | grep "SAT"| awk '{print $1}'`)
        device_types=(`smartctl --scan-open | grep "SAT" | awk '{print $3}'`)
else
        device_paths=(`smartctl --scan-open | grep "bus"| awk '{print $1}'`)
        device_types=(`smartctl --scan-open | grep "bus" | awk '{print $3}'`)
fi
length=${#device_paths[@]}

echo -e "Disk_Model\t\t Disk_Serial\t Disk_Capacity\t Disk_Form_Factor\t"  

for ((index=0; index<=$[$length-1]; index++))
do
   disk_model[$index]=$(echo `sudo smartctl -i ${device_paths[$index]} -d ${device_types[$index]} 2>/dev/null | grep -E 'Device Model|Product' | cut -d ':' -f 2`)
   disk_serial[$index]=$(echo `sudo smartctl -i ${device_paths[$index]} -d ${device_types[$index]} 2>/dev/null | grep -E 'Serial Number|Serial number' | cut -d ':' -f 2`)
   disk_capacity[$index]=$(echo `sudo smartctl -i ${device_paths[$index]} -d ${device_types[$index]} 2>/dev/null | grep 'User Capacity' | cut -d ':' -f 2 |cut -d '[' -f 2|cut -d ']' -f 1`)
   echo `sudo smartctl -i ${device_paths[$index]} -d ${device_types[$index]} 2>/dev/null | grep 'User Capacity' | cut -d ':' -f 2 |cut -d '[' -f 2|cut -d ']' -f 1` >> /tmp/disk_size
   disk_form[$index]=$(echo `sudo smartctl -i ${device_paths[$index]} -d ${device_types[$index]} 2>/dev/null | grep 'Form Factor' | cut -d ':' -f 2`)
   echo -e "${disk_model[$index]}\t ${disk_serial[$index]}\t ${disk_capacity[$index]}\t ${disk_form[$index]}\t"

done

#To_json
sort /tmp/disk_size |uniq -c  > /tmp/disk_size_Counts
echo -e "\"Disk\":[\c" >> /root/hw_light.json
i=0
while read line; 
do
	disk_allsize[$i]=$(echo `echo $line |awk '{$1="";print $0}'`);
	disk_counts[$i]=$(echo `echo $line |awk '{print $1}'`); 
	echo -e "{\"Size${i}\":\"${disk_allsize[$i]}\",\"Counts${i}\":\"${disk_counts[$i]}\"},\c" >> /root/hw_light.json
	i=$((i+1));
done < /tmp/disk_size_Counts
sed '$ s/.$//' -i /root/hw_light.json
echo "]," >> /root/hw_light.json

rm /tmp/disk_size /tmp/disk_size_Counts

bonding_mode=$(echo `cat /proc/net/bonding/bond0 | grep "Bonding Mode" |cut -d  ":" -f 2`)
NIC_count=$(echo `cat /proc/net/bonding/bond0 | grep 10000| wc -l`)
echo "\"Bonding\":{\"Mode\":\"${bonding_mode}\",\"NIC_count\":\"${NIC_count}\"}" >> /root/hw_light.json
echo "}" >> /root/hw_light.json


