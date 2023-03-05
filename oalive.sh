#!/usr/bin/env bash
# by spiritlhl
# from https://github.com/spiritLHLS/Oracle-server-keep-alive-script

ver="2023.02.22.17.53"
_red() { echo -e "\033[31m\033[01m$@\033[0m"; }
_green() { echo -e "\033[32m\033[01m$@\033[0m"; }
_yellow() { echo -e "\033[33m\033[01m$@\033[0m"; }
_blue() { echo -e "\033[36m\033[01m$@\033[0m"; }
reading(){ read -rp "$(_green "$1")" "$2"; }
RED="\033[31m"
PLAIN="\033[0m"
REGEX=("debian" "ubuntu" "centos|red hat|kernel|oracle linux|alma|rocky" "'amazon linux'" "fedora" "arch")
RELEASE=("Debian" "Ubuntu" "CentOS" "CentOS" "Fedora" "Arch")
PACKAGE_UPDATE=("! apt-get update && apt-get --fix-broken install -y && apt-get update" "apt-get update" "yum -y update" "yum -y update" "yum -y update" "pacman -Sy")
PACKAGE_INSTALL=("apt-get -y install" "apt-get -y install" "yum -y install" "yum -y install" "yum -y install" "pacman -Sy --noconfirm --needed")
PACKAGE_REMOVE=("apt-get -y remove" "apt-get -y remove" "yum -y remove" "yum -y remove" "yum -y remove" "pacman -Rsc --noconfirm")
PACKAGE_UNINSTALL=("apt-get -y autoremove" "apt-get -y autoremove" "yum -y autoremove" "yum -y autoremove" "yum -y autoremove" "")
CMD=("$(grep -i pretty_name /etc/os-release 2>/dev/null | cut -d \" -f2)" "$(hostnamectl 2>/dev/null | grep -i system | cut -d : -f2)" "$(lsb_release -sd 2>/dev/null)" "$(grep -i description /etc/lsb-release 2>/dev/null | cut -d \" -f2)" "$(grep . /etc/redhat-release 2>/dev/null)" "$(grep . /etc/issue 2>/dev/null | cut -d \\ -f1 | sed '/^[ ]*$/d')" "$(grep -i pretty_name /etc/os-release 2>/dev/null | cut -d \" -f2)") 
SYS="${CMD[0]}"
[[ -n $SYS ]] || exit 1
for ((int = 0; int < ${#REGEX[@]}; int++)); do
    if [[ $(echo "$SYS" | tr '[:upper:]' '[:lower:]') =~ ${REGEX[int]} ]]; then
        SYSTEM="${RELEASE[int]}"
        [[ -n $SYSTEM ]] && break
    fi
done

[[ $EUID -ne 0 ]] && echo -e "${RED}Please run this script with the root user!${PLAIN}" && exit 1

checkver(){
  running_version=$(grep "ver=\"[0-9]\{4\}\.[0-9]\{2\}\.[0-9]\{2\}\.[0-9]\{2\}\.[0-9]\{2\}" "$0" | awk -F '"' '{print $2}')
  curl -L https://github.com/M00nG/Oracle-server-keep-alive-script/raw/main/oalive.sh -o oalive1.sh && chmod +x oalive1.sh
  downloaded_version=$(grep "ver=\"[0-9]\{4\}\.[0-9]\{2\}\.[0-9]\{2\}\.[0-9]\{2\}\.[0-9]\{2\}" oalive1.sh | awk -F '"' '{print $2}')
  if [ "$running_version" != "$downloaded_version" ]; then
    _yellow "Update script from $ver to $downloaded_version"
    mv oalive1.sh "$0"
    uninstall
    _yellow "Please reset the occupancy after 5 seconds, has automatically uninstalled the original occupancy"
    sleep 5
    bash oalive.sh
  else
    _green "This script is already the latest script no need to update"
    rm oalive1.sh
  fi
}

checkupdate(){
	    _yellow "Updating package management sources"
		${PACKAGE_UPDATE[int]} > /dev/null 2>&1
        ${PACKAGE_INSTALL[int]} dmidecode > /dev/null 2>&1
}

boinc() {
    _green "\n Install docker.\n "
    if ! systemctl is-active docker >/dev/null 2>&1; then
        if [ $SYSTEM = "CentOS" ]; then
          ${PACKAGE_INSTALL[int]} yum-utils
          yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo &&
          ${PACKAGE_INSTALL[int]} docker-ce docker-ce-cli containerd.io
          systemctl enable --now docker
        else
          ${PACKAGE_INSTALL[int]} docker.io
        fi
    fi
    docker ps -a | awk '{print $NF}' | grep -qw boinc && _yellow " Remove the boinc container.\n " && docker rm -f boinc >/dev/null 2>&1
    if [ "$SYSTEM" == "Ubuntu" ] || [ "$SYSTEM" == "Debian" ]; then
      docker run -d --restart unless-stopped --name boinc -v /var/lib/boinc:/var/lib/boinc -e "BOINC_CMD_LINE_OPTIONS=--allow_remote_gui_rpc --cpu_usage_limit=20" boinc/client
    elif [ "$SYSTEM" == "Centos" ] ; then
      docker run -d --restart unless-stopped --name boinc -v /var/lib/boinc:/var/lib/boinc -e "BOINC_CMD_LINE_OPTIONS=--allow_remote_gui_rpc --cpu_usage_limit=20" boinc/client:centos
    else
      echo "Error: The operating system is not supported."
      exit 1
    fi
    systemctl enable docker
    _green "Boinc is installed as docker and using"
}

calculate() {
    curl -L https://github.com/M00nG/Oracle-server-keep-alive-script/raw/main/cpu-limit.sh -o cpu-limit.sh && chmod +x cpu-limit.sh
    mv cpu-limit.sh /usr/local/bin/cpu-limit.sh 
    chmod +x /usr/local/bin/cpu-limit.sh
    curl -L https://github.com/M00nG/Oracle-server-keep-alive-script/raw/main/cpu-limit.service -o cpu-limit.service && chmod +x cpu-limit.service
    mv cpu-limit.service /etc/systemd/system/cpu-limit.service
    line_number=7
    total_cores=0
    if [ -f "/proc/cpuinfo" ]; then
      total_cores=$(grep -c ^processor /proc/cpuinfo)
    else
      total_cores=$(nproc)
    fi
    if [ "$total_cores" == "2" ] || [ "$total_cores" == "3" ] || [ "$total_cores" == "4" ]; then
      cpu_limit=$(echo "$total_cores * 15" | bc)
    else
      cpu_limit=25
    fi
    sed -i "${line_number}a CPUQuota=${cpu_limit}%" /etc/systemd/system/cpu-limit.service
    systemctl daemon-reload
    systemctl enable cpu-limit.service
    systemctl start cpu-limit.service
    _green "The CPU limit script has been installed at /usr/local/bin/cpu-limit.sh"
}

memory(){
    curl -L https://github.com/M00nG/Oracle-server-keep-alive-script/raw/main/memory-limit.sh -o memory-limit.sh && chmod +x memory-limit.sh
    mv memory-limit.sh /usr/local/bin/memory-limit.sh
    chmod +x /usr/local/bin/memory-limit.sh
    curl -L https://github.com/M00nG/Oracle-server-keep-alive-script/raw/main/memory-limit.service -o memory-limit.service && chmod +x memory-limit.service
    mv memory-limit.service /etc/systemd/system/memory-limit.service
    systemctl daemon-reload
    systemctl enable memory-limit.service
    systemctl start memory-limit.service
    _green "The memory limit script has been installed at /usr/local/bin/memory-limit.sh"
}

bandwidth(){
    if ! command -v speedtest-cli > /dev/null 2>&1; then
      echo "speedtest-cli not found, installing..."
      _yellow "Installing speedtest-cli"
      rm /etc/apt/sources.list.d/speedtest.list
      ${PACKAGE_REMOVE[int]} speedtest
      ${PACKAGE_REMOVE[int]} speedtest-cli
      checkupdate
      ${PACKAGE_INSTALL[int]} speedtest-cli
    fi
    curl -L https://github.com/M00nG/Oracle-server-keep-alive-script/raw/main/bandwidth_occupier.sh -o bandwidth_occupier.sh && chmod +x bandwidth_occupier.sh
    mv bandwidth_occupier.sh /usr/local/bin/bandwidth_occupier.sh
    chmod +x /usr/local/bin/bandwidth_occupier.sh
    curl -L https://github.com/M00nG/Oracle-server-keep-alive-script/raw/main/bandwidth_occupier.timer -o bandwidth_occupier.timer && chmod +x bandwidth_occupier.timer
    mv bandwidth_occupier.timer /etc/systemd/system/bandwidth_occupier.timer
    curl -L https://github.com/M00nG/Oracle-server-keep-alive-script/raw/main/bandwidth_occupier.service -o bandwidth_occupier.service && chmod +x bandwidth_occupier.service
    mv bandwidth_occupier.service /etc/systemd/system/bandwidth_occupier.service
    reading "Need to customize bandwidth usage settings? (y/[n]) " answer
    if [ "$answer" == "y" ]; then
        sed -i '/^bandwidth\|^rate/s/^/#/' /usr/local/bin/bandwidth_occupier.sh
        reading "Enter the bandwidth you need (in mbps, for example, enter 10 for 10mbps): " rate_mbps
	rate=$(( rate_mbps * 1000000 ))
        reading "Enter the duration you need to request (in minutes, for example, enter 10m for 10 minutes): " timeout
	sed -i 's/^timeout/#timeout/' /usr/local/bin/bandwidth_occupier.sh
        sed -i '$ a\timeout '$timeout' wget $selected_url --limit-rate='$rate' -O /dev/null &' /usr/local/bin/bandwidth_occupier.sh
	reading "Enter the time interval you need (in minutes, for example, enter 45 for 45 minutes): " interval
        sed -i "s/^OnUnitActiveSec.*/OnUnitActiveSec=$interval/" /etc/systemd/system/bandwidth_occupier.timer
    else
        _green "\nUse the default configuration, 45 minutes interval, request 10 minutes, the request rate is 20% of the maximum speed" 
    fi
    systemctl daemon-reload
    systemctl start bandwidth_occupier.timer
    systemctl enable bandwidth_occupier.timer
    _green "The bandwidth limit script has been installed at /usr/local/bin/bandwidth_occupier.sh"
}

uninstall(){
    docker stop boinc &> /dev/null  
    docker rm boinc &> /dev/null    
    docker rmi boinc &> /dev/null   
    if [ -f "/etc/systemd/system/cpu-limit.service" ]; then
        systemctl stop cpu-limit.service
        systemctl disable cpu-limit.service
        rm /etc/systemd/system/cpu-limit.service
        rm /usr/local/bin/cpu-limit.sh
	      kill $(pgrep dd) &> /dev/null  
	      kill $(ps -efA | grep cpu-limit.sh | awk '{print $2}') &> /dev/null  
    fi
    rm -rf /tmp/cpu-limit.pid &> /dev/null  
    _yellow "Unloaded CPU usage - The cpu limit script has been uninstalled successfully."
    if [ -f "/etc/systemd/system/memory-limit.service" ]; then
        systemctl stop memory-limit.service
        systemctl disable memory-limit.service
        rm /etc/systemd/system/memory-limit.service
        rm /usr/local/bin/memory-limit.sh
	      rm /dev/shm/file
	      kill $(ps -efA | grep memory-limit.sh | awk '{print $2}') &> /dev/null  
        rm -rf /tmp/memory-limit.pid &> /dev/null  
        _yellow "Unloaded memory usage - The memory limit script has been uninstalled successfully."
    fi
    if [ -f "/etc/systemd/system/bandwidth_occupier.service" ]; then
        systemctl stop bandwidth_occupier
        systemctl disable bandwidth_occupier
        rm /etc/systemd/system/bandwidth_occupier.service
        rm /usr/local/bin/bandwidth_occupier.sh
	      systemctl stop bandwidth_occupier.timer
    	  systemctl disable bandwidth_occupier.timer
	      rm /etc/systemd/system/bandwidth_occupier.timer
	      kill $(ps -efA | grep bandwidth_occupier.sh | awk '{print $2}') &> /dev/null  
        rm -rf /tmp/bandwidth_occupier.pid &> /dev/null 
        _yellow "Unloaded bandwidth usage - The bandwidth occupier and timer script has been uninstalled successfully."
    fi
    systemctl daemon-reload
}

main() {
    _green "The current script update time (please pay attention to compare the warehouse instructions)： $ver"
    _green "https://github.com/spiritLHLS/Oracle-server-keep-alive-script"
    checkupdate
    if ! command -v wget > /dev/null 2>&1; then
      echo "wget not found, installing..."
      _yellow "Installing wget"
      ${PACKAGE_INSTALL[int]} wget
    fi
    if ! command -v bc > /dev/null 2>&1; then
      echo "bc not found, installing..."
      _yellow "Installing bc"
    	${PACKAGE_INSTALL[int]} bc
    fi
    if ! command -v fallocate > /dev/null 2>&1; then
      echo "fallocate not found, installing..."
      _yellow "Installing fallocate"
      ${PACKAGE_INSTALL[int]} fallocate
    fi
    if ! command -v nproc > /dev/null 2>&1; then
      echo "nproc not found, installing..."
      _yellow "Installing nproc"
      ${PACKAGE_INSTALL[int]} coreutils
    fi
    echo "Select your options:"
    echo "1. Installation Warranty Service"
    echo "2. Offload Warranty Service"
    echo "3. One Click Update Script"
    echo "4. Exit Processes"
    reading "Select Options：" option
    case $option in
        1)
            echo "Select the program to use when you need to occupy the CPU:"
            echo "1. Local DD simulation occupancy (20%~25%) [Recommended]"
            echo "2. BOINC-docker service (20%) (https://github.com/BOINC/boinc) [not recommended]"
	    echo "3. No restriction"
            reading "Your choice：" cpu_option
            if [ $cpu_option == 2 ]; then
                boinc
	    elif [ $cpu_option == 3 ]; then
    		echo ""
            else
                calculate
            fi
            reading "Do you need to limit the memory? ([y]/n): " memory_confirm
            if [ "$memory_confirm" != "n" ]; then
                memory
            fi
            reading "Do you need to limit the bandwidth? ([y]/n): " bandwidth_confirm
            if [ "$bandwidth_confirm" != "n" ]; then
                bandwidth
            fi
            ;;
        2)
            uninstall
            exit 0
            ;;
        3)
            checkver
            ;;
        *)
            echo "Invalid option, exit the program"
            exit 1
            ;;
    esac
}


main
