#!/bin/bash
sn=`sudo dmidecode -t system |grep  "Serial Number:"| awk '{$1="";$2="";sub(/^[ \t]+/,"");print $0}'`

wget https://agora-devops-public-2.oss-cn-beijing.aliyuncs.com/Stress-testing/compressed_tools/linpack_2020.2.001.tar -P ~/linkpack/
cd ~/linkpack/linpack
tar -xvf linpack_2020.2.001.tar 1>/dev/null 2>&1
sudo ./runme_xeon64 > /root/${sn}_cpu_linpack.log

wget https://agora-devops-public-2.oss-cn-beijing.aliyuncs.com/Stress-testing/compressed_tools/mlc_v3.9.tgz -P ~/intel-mlc
cd ~/intel-mlc && mkdir mlc_v3.9
tar -zxvf mlc_v3.9.tgz -C mlc_v3.9 1>/dev/null 2>&1
cd mlc_v3.9/Linux
sudo modprobe msr
sudo ./mlc > /root/${sn}_cpu_linpack.log

