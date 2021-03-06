# Check if user is root
[ $(id -u) != "0" ] && { echo "${CFAILURE}Error: You must be root to run this script${CEND}"; exit 1; }

# Check if wget installed
if  [ ! -e '/usr/bin/wget' ]; then
    echo "Error: wget command not found. You must be install wget command at first."
    exit 1
fi


# Check release
if [ -f /etc/redhat-release ]; then
    release="centos"
elif cat /etc/issue | grep -Eqi "debian"; then
    release="debian"
elif cat /etc/issue | grep -Eqi "ubuntu"; then
    release="ubuntu"
elif cat /etc/issue | grep -Eqi "centos|red hat|redhat"; then
    release="centos"
elif cat /proc/version | grep -Eqi "debian"; then
    release="debian"
elif cat /proc/version | grep -Eqi "ubuntu"; then
    release="ubuntu"
elif cat /proc/version | grep -Eqi "centos|red hat|redhat"; then
    release="centos"
fi


# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
SKYBLUE='\033[0;36m'
PLAIN='\033[0m'


# Install Virt-what
if  [ ! -e '/usr/sbin/virt-what' ]; then
    echo "Installing Virt-What......"
    if [ "${release}" == "centos" ]; then
        yum update > /dev/null 2>&1
        yum -y install virt-what > /dev/null 2>&1
    else
        apt-get update > /dev/null 2>&1
        apt-get -y install virt-what > /dev/null 2>&1
    fi      
fi

# Install Besttrace
if  [ ! -e '/tmp/besttrace' ]; then
    echo "Installing Besttrace......"
    dir=$(pwd)
    cd /tmp/
    wget https://raw.githubusercontent.com/FunctionClub/ZBench/master/besttrace > /dev/null 2>&1
    cd $dir
fi
chmod a+rx /tmp/besttrace

# Check Python
if  [ ! -e '/usr/bin/python' ]; then
    echo "Installing Python......"
    if [ "${release}" == "centos" ]; then
            yum update > /dev/null 2>&1
            yum -y install python
        else
            apt-get update > /dev/null 2>&1
            apt-get -y install python
    fi
fi

# Install Speedtest
if  [ ! -e '/tmp/speedtest.py' ]; then
    echo "Installing SpeedTest......"
    dir=$(pwd)
    cd /tmp/
    wget https://raw.github.com/sivel/speedtest-cli/master/speedtest.py > /dev/null 2>&1
    cd $dir
fi
chmod a+rx /tmp/speedtest.py


# Install Speedtest
if  [ ! -e '/tmp/ZPing.py' ]; then
    echo "Installing ZPing.py......"
    dir=$(pwd)
    cd /tmp/
    wget https://raw.githubusercontent.com/FunctionClub/ZBench/master/ZPing.py > /dev/null 2>&1
    cd $dir
fi
chmod a+rx /tmp/ZPing.py


get_opsy() {
    [ -f /etc/redhat-release ] && awk '{print ($1,$3~/^[0-9]/?$3:$4)}' /etc/redhat-release && return
    [ -f /etc/os-release ] && awk -F'[= "]' '/PRETTY_NAME/{print $3,$4,$5}' /etc/os-release && return
    [ -f /etc/lsb-release ] && awk -F'[="]+' '/DESCRIPTION/{print $2}' /etc/lsb-release && return
}

next() {
    printf "%-74s\n" "-" | sed 's/\s/-/g'
}

speed_test() {
    local speedtest=$(wget -4O /dev/null -T300 $1 2>&1 | awk '/\/dev\/null/ {speed=$3 $4} END {gsub(/\(|\)/,"",speed); print speed}')
    local ipaddress=$(ping -c1 -n `awk -F'/' '{print $3}' <<< $1` | awk -F'[()]' '{print $2;exit}')
    local nodeName=$2
    local latency=$(ping $ipaddress -c 3 | grep avg | awk -F / '{print $5}')" ms"
    printf "${YELLOW}%-26s${GREEN}%-18s${RED}%-20s${SKYBLUE}%-12s${PLAIN}\n" "${nodeName}" "${ipaddress}" "${speedtest}" "${latency}"
}

speed() {
    speed_test 'http://cachefly.cachefly.net/100mb.test' 'CacheFly'
    speed_test 'http://speedtest.tokyo.linode.com/100MB-tokyo.bin' 'Linode, Tokyo, JP'
    speed_test 'http://speedtest.singapore.linode.com/100MB-singapore.bin' 'Linode, Singapore, SG'
    speed_test 'http://speedtest.london.linode.com/100MB-london.bin' 'Linode, London, UK'
    speed_test 'http://speedtest.frankfurt.linode.com/100MB-frankfurt.bin' 'Linode, Frankfurt, DE'
    speed_test 'http://speedtest.fremont.linode.com/100MB-fremont.bin' 'Linode, Fremont, CA'
    speed_test 'http://speedtest.dal05.softlayer.com/downloads/test100.zip' 'Softlayer, Dallas, TX'
    speed_test 'http://speedtest.sea01.softlayer.com/downloads/test100.zip' 'Softlayer, Seattle, WA'
    speed_test 'http://speedtest.fra02.softlayer.com/downloads/test100.zip' 'Softlayer, Frankfurt, DE'
    speed_test 'http://speedtest.sng01.softlayer.com/downloads/test100.zip' 'Softlayer, Singapore, SG'
    speed_test 'http://speedtest.hkg02.softlayer.com/downloads/test100.zip' 'Softlayer, HongKong, CN'
}

speed_test_cn(){
    if [[ $1 == '' ]]; then
        temp=$(python /tmp/speedtest.py --share 2>&1)
        is_down=$(echo "$temp" | grep 'Download') 
        if [[ ${is_down} ]]; then
            local REDownload=$(echo "$temp" | awk -F ':' '/Download/{print $2}')
            local reupload=$(echo "$temp" | awk -F ':' '/Upload/{print $2}')
            local relatency=$(echo "$temp" | awk -F ':' '/Hosted/{print $2}')
            local nodeName=$2

            printf "${YELLOW}%-25s${GREEN}%-18s${RED}%-20s${SKYBLUE}%-12s${PLAIN}\n" "${nodeName}" "${reupload}" "${REDownload}" "${relatency}"
        else
            local cerror="ERROR"
        fi
    else
        temp=$(python /tmp/speedtest.py --server $1 --share 2>&1)
        is_down=$(echo "$temp" | grep 'Download') 
        if [[ ${is_down} ]]; then
            local REDownload=$(echo "$temp" | awk -F ':' '/Download/{print $2}')
            local reupload=$(echo "$temp" | awk -F ':' '/Upload/{print $2}')
            local relatency=$(echo "$temp" | awk -F ':' '/Hosted/{print $2}')
            temp=$(echo "$relatency" | awk -F '.' '{print $1}')
            if [[ ${temp} -gt 1000 ]]; then
                relatency=" 000.000 ms"
            fi
            local nodeName=$2

            printf "${YELLOW}%-25s${GREEN}%-18s${RED}%-20s${SKYBLUE}%-12s${PLAIN}\n" "${nodeName}" "${reupload}" "${REDownload}" "${relatency}"
        else
            local cerror="ERROR"
        fi
    fi
}

speed_cn() {

    speed_test_cn '12637' 'Xiangyang CT'
    speed_test_cn '3633' 'Shanghai  CT'
    speed_test_cn '4624' 'Chengdu   CT'
    speed_test_cn '4863' "Xi'an     CU"
    speed_test_cn '5083' 'Shanghai  CU'
    speed_test_cn '5726' 'Chongqing CU'
    speed_test_cn '5192' "Xi'an     CM"
    speed_test_cn '4665' 'Shanghai  CM'
    speed_test_cn '4575' 'Chengdu   CM'
     
    rm -rf /tmp/speedtest.py
}


io_test() {
    (LANG=C dd if=/dev/zero of=test_$$ bs=64k count=16k conv=fdatasync && rm -f test_$$ ) 2>&1 | awk -F, '{io=$NF} END { print io}' | sed 's/^[ \t]*//;s/[ \t]*$//'
}

calc_disk() {
    local total_size=0
    local array=$@
    for size in ${array[@]}
    do
        [ "${size}" == "0" ] && size_t=0 || size_t=`echo ${size:0:${#size}-1}`
        [ "`echo ${size:(-1)}`" == "K" ] && size=0
        [ "`echo ${size:(-1)}`" == "M" ] && size=$( awk 'BEGIN{printf "%.1f", '$size_t' / 1024}' )
        [ "`echo ${size:(-1)}`" == "T" ] && size=$( awk 'BEGIN{printf "%.1f", '$size_t' * 1024}' )
        [ "`echo ${size:(-1)}`" == "G" ] && size=${size_t}
        total_size=$( awk 'BEGIN{printf "%.1f", '$total_size' + '$size'}' )
    done
    echo ${total_size}
}

cname=$( awk -F: '/model name/ {name=$2} END {print name}' /proc/cpuinfo | sed 's/^[ \t]*//;s/[ \t]*$//' )
cores=$( awk -F: '/model name/ {core++} END {print core}' /proc/cpuinfo )
freq=$( awk -F: '/cpu MHz/ {freq=$2} END {print freq}' /proc/cpuinfo | sed 's/^[ \t]*//;s/[ \t]*$//' )
tram=$( free -m | awk '/Mem/ {print $2}' )
uram=$( free -m | awk '/Mem/ {print $3}' )
swap=$( free -m | awk '/Swap/ {print $2}' )
uswap=$( free -m | awk '/Swap/ {print $3}' )
up=$( awk '{a=$1/86400;b=($1%86400)/3600;c=($1%3600)/60} {printf("%d days, %d hour %d min\n",a,b,c)}' /proc/uptime )
load=$( w | head -1 | awk -F'load average:' '{print $2}' | sed 's/^[ \t]*//;s/[ \t]*$//' )
opsy=$( get_opsy )
arch=$( uname -m )
lbit=$( getconf LONG_BIT )
kern=$( uname -r )
ipv6=$( wget -qO- -t1 -T2 ipv6.icanhazip.com )
disk_size1=($( LANG=C df -hPl | grep -wvE '\-|none|tmpfs|devtmpfs|by-uuid|chroot|Filesystem' | awk '{print $2}' ))
disk_size2=($( LANG=C df -hPl | grep -wvE '\-|none|tmpfs|devtmpfs|by-uuid|chroot|Filesystem' | awk '{print $3}' ))
disk_total_size=$( calc_disk ${disk_size1[@]} )
disk_used_size=$( calc_disk ${disk_size2[@]} )


clear
next
echo -e "CPU model            : ${SKYBLUE}$cname${PLAIN}"
echo -e "Number of cores      : ${SKYBLUE}$cores${PLAIN}"
echo -e "CPU frequency        : ${SKYBLUE}$freq MHz${PLAIN}"
echo -e "Total size of Disk   : ${SKYBLUE}$disk_total_size GB ($disk_used_size GB Used)${PLAIN}"
echo -e "Total amount of Mem  : ${SKYBLUE}$tram MB ($uram MB Used)${PLAIN}"
echo -e "Total amount of Swap : ${SKYBLUE}$swap MB ($uswap MB Used)${PLAIN}"
echo -e "System uptime        : ${SKYBLUE}$up${PLAIN}"
echo -e "Load average         : ${SKYBLUE}$load${PLAIN}"
echo -e "OS                   : ${SKYBLUE}$opsy${PLAIN}"
echo -e "Arch                 : ${SKYBLUE}$arch ($lbit Bit)${PLAIN}"
echo -e "Kernel               : ${SKYBLUE}$kern${PLAIN}"
echo -ne "Virt                 : "
virtua=$(virt-what) 2>/dev/null

if [[ ${virtua} ]]; then
    echo -e "${SKYBLUE}$virtua${PLAIN}"
else
    echo -e "${SKYBLUE}No Virt${PLAIN}"
    echo -ne "Power time of disk   : "
    install_smart
    echo -e "${SKYBLUE}$ptime Hours${PLAIN}"
fi


next
io1=$( io_test )
echo -e "I/O speed(1st run)   :${YELLOW}$io1${PLAIN}"
io2=$( io_test )
echo -e "I/O speed(2nd run)   :${YELLOW}$io2${PLAIN}"
io3=$( io_test )
echo -e "I/O speed(3rd run)   :${YELLOW}$io3${PLAIN}"
next
printf "%-26s%-18s%-20s%-12s\n" "Node Name" "IP Address" "Download Speed" "Latency"
speed && next
printf "%-26s%-18s%-20s%-12s\n" "Node Name" "Upload Speed" "Download Speed" "Latency"
speed_cn && next
python /tmp/ZPing.py
next
echo "TraceRoute to Shanghai Telecom"
/tmp/besttrace 61.129.42.6
next
echo "TraceRoute to Shanghai Mobile"
/tmp/besttrace speedtest2.sh.chinamobile.com
next
echo "TraceRoute to Guangdong Telecom"
/tmp/besttrace 121.14.220.240
next
echo "TraceRoute to Guangdong Mobile"
/tmp/besttrace 211.136.192.6
next



