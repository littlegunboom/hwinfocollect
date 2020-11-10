#!/bin/bash
export http_proxy="http://10.11.1.2:3129"
export https_proxy="http://10.11.1.2:3129"
sn=`sudo dmidecode -t system |grep  "Serial Number:"| awk '{$1="";$2="";sub(/^[ \t]+/,"");print $0}'`
if [ -f /root/${sn}_cpu_linpack.log ];then
  mv /root/${sn}_cpu_linpack.log /root/${sn}_cpu_linpack.log.bak
  mv /root/${sn}_mem_mlc.log /root/${sn}_mem_mlc.log.bak
  mv /root/${sn}_cpu_benchmark /root/${sn}_cpu_benchmark.bak
fi  

wget https://agora-devops-public-2.oss-cn-beijing.aliyuncs.com/Stress-testing/compressed_tools/linpack_2020.2.001.tar -P ~/linkpack/
cd ~/linkpack/linpack
tar -xvf linpack_2020.2.001.tar 1>/dev/null 2>&1
sudo ./runme_xeon64 > /root/${sn}_cpu_linpack.log

wget https://agora-devops-public-2.oss-cn-beijing.aliyuncs.com/Stress-testing/compressed_tools/mlc_v3.9.tgz -P ~/intel-mlc
cd ~/intel-mlc && mkdir mlc_v3.9
tar -zxvf mlc_v3.9.tgz -C mlc_v3.9 1>/dev/null 2>&1
cd mlc_v3.9/Linux
sudo modprobe msr
sudo ./mlc > /root/${sn}_mem_mlc.log

cpu_benchmark=`grep Average /root/${sn}_cpu_linpack.log -A 1|awk "NR==2"|awk '{print $4}'`
echo "${cpu_benchmark} GFlops" > /root/${sn}_cpu_benchmark
