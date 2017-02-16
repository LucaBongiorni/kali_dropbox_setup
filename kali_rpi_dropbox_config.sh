#!/bin/bash
#
# Date: FEB 2017
# Author:  paveway
# Purpose:  Build a drop box from a fresh install of Kali Linux (ARM).
#


###############################
#Update function
function runUpdates
{
    echo "Running updates..."
    apt-get update && apt-get -y upgrade && apt-get -y autoremove && apt-get -y autoclean && apt-get -y dist-upgrade && apt-get -y autoremove && apt-get autoclean
    echo -e "\n\nUpdates complete.\n\n"
}


###############################
#New hostname function
function newHostname
{
    echo "Please enter a new hostname for this machine:  "
    hostnameNew=""
    hostnameOld=$(cat /etc/hostname)
    read hostnameNew
    sed -i "s/$hostnameOld/$hostnameNew/g" /etc/hosts
    sed -i "s/$hostnameOld/$hostnameNew/g" /etc/hostname
    hostname $hostnameNew
    echo -e "\n\nHostname changed.\n\n"
}


###############################
#Tool installation function
function instTools
{
    echo "Installing additional tools..."
    apt-get -y install \
    nmap \
    git \
    arp-scan \
    dnsutils \
    nbtscan \
    openvpn \
    aircrack-ng \
    enum4linux \
    patator \
    john \
    silversearcher-ag \
    tcpdump \
    traceroute \
    virtualenvwrapper \
    libssl-dev \
    libffi-dev \
    python-dev \
    build-essential \
    locate \
    etherape \
    moreutils \
    mitmf \
    ncdu \
    pydf \
    yersinia \
    metasploit-framework \
    screen \
    passing-the-hash 

    echo "Cloning git repos..."
    cd /opt
    git clone https://github.com/lgandx/Responder
    git clone https://github.com/KMGbully/situational-awareness
    git clone https://github.com/byt3bl33d3r/CrackMapExec
    git clone https://github.com/pentestgeek/smbexec
    git clone https://github.com/commonexploits/livehosts
    git clone https://github.com/gentilkiwi/kekeo
    git clone https://github.com/samratashok/nishang
    git clone https://github.com/sivel/speedtest-cli
    git clone https://github.com/EmpireProject/Empire
    echo "Initializing Metasploit Database..."
    msfdb init
    #echo "Configuring CrackMapExec..."
    #cd CrackMapExec && git submodule init && git submodule update --recursive
    #python setup.py install

    echo -e "\n\nTool installation complete.\n\n"
}


###############################
#.bashrc configuration function
# This function simply enables
# convenient bash modificaitons
function confTerminal
{
echo "Configuring bash aliases..."
cat << EOF > ~/.bash_aliases_load
#dir listing
alias ll='ls -al --color=auto'
alias la='ls -A --color=auto'
alias l='ls -CF --color=auto'

#grep coloring
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

#update everything
alias apt-update-all='apt-get update && apt-get -y upgrade && apt-get -y autoremove && apt-get -y autoclean && apt-get -y dist-upgrade && apt-get -y autoremove && apt-get autoclean'

#print internal IP
alias intip='hostname -I'

#print external IP
alias extip='curl canihazip.com/s && echo ""'

function finddc {
echo "Running bash alias 'finddc'"
nslookup -type=srv _ldap._tcp.dc._msdcs.$1
}

EOF
cat ~/.bash_aliases_load > ~/.bash_aliases
echo "Configuring terminal..."
if [ ! -f ~/.bashrc.bak ]; then
    cp ~/.bashrc ~/.bashrc.bak
fi
cat << EOF > ~/.bashrc_load

# don't put duplicate lines or lines starting with space in the history.
# See bash for more options
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE
HISTTIMEFORMAT="%d/%m/%y@%T--> "
HISTCONTROL=ignorespace
HISTFILESIZE=20000
HISTSIZE=10000

# Alias definitions.

if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

EOF
cat ~/.bashrc.bak > ~/.bashrc
cat ~/.bashrc_load >> ~/.bashrc
echo "Refreshing bash source..."
source /root/.bashrc
echo -e "\n\nBash configuration routine complete.\n\n"
}


###############################
#OpenVPN configuration function
function confOVPN
{
echo "Starting Drop Box configuration (OpenVPN)..."

echo "IP address of the OpenVPN server the Drop Box will connect to: "
read serverIp

echo "User on OpenVPN server to connect with:  "
read ovpnUser

echo "Obtaining keys from OpenVPN server..."
scp $ovpnUser@$serverIp:/etc/openvpn/\{ca.crt,client.crt,client.key\} /etc/openvpn/

echo "Retrieving SSH key from OpenVPN server..."
ssh $ovpnUser@$serverIp 'cat ~/.ssh/id_rsa.pub' >> ~/.ssh/authorized_keys

echo "Adding /etc/openvpn/client.conf..."
cat << EOF > /etc/openvpn/client.conf
client
dev tap
proto tcp
EOF
echo "remote $serverIp 443" >> /etc/openvpn/client.conf
cat << EOF >> /etc/openvpn/client.conf
resolv-retry infinite
nobind
persist-key
persist-tun
ca ca.crt
cert client.crt
key client.key
ns-cert-type server
comp-lzo
verb 3
EOF

echo "Configuring SSH and OpenVPN to start at bootup..."
update-rc.d openvpn enable
update-rc.d ssh enable

echo -e "\n\nOpenVPN configuration routine complete.  Please address any errors and make sure the necessary files are in the correct place.  Don't forget to test functionality before deploying!\n\n"
}

###############################
#expand filesystem
function expandFS
{
fdisk /dev/mmcblk0 <<EOF
p
d
2
n
p
2
125001
 
 
p
w
EOF

cat << EOF > /etc/init.d/expand_kali_rpi_fs_step2.sh
#!/bin/bash
sleep 20
resize2fs /dev/mmcblk0p2
sleep 5
rm $0
sleep 5
reboot
EOF

chmod +x /etc/init.d/expand_kali_rpi_fs_step2.sh
update-rc.d expand_kali_rpi_fs_step2.sh 
echo "The system will now reboot TWICE.  After the first reboot, it will pause at the login promt, then reboot again."
sleep 5
reboot
}


###############################
#All functions
function allFunctions
{
    newHostname
    confTerminal
    runUpdates
    instTools
    confOVPN
    expandFS
}


###############################
#Main Menu
until [ "$menuSelection" = "0" ]; do
    echo "------------------------------------------------"
    echo "Kali Linux Drop Box Configuration Script"
    echo "Run this script as root from the rPi drop box."
    echo "------------------------------------------------"
    echo "1. Run updates"
    echo "2. Change hostname"
    echo "3. Install additional tools"
    echo "4. Configure bash prompt"
    echo "5. Configure OpenVPN server connection"
    echo "6. Expand the file system"
    echo "7. RUN ALL FUNCTIONS"
    echo "X. Exit"
    echo ""
    read menuSelection
    echo "" 
    case $menuSelection in 
        1 ) runUpdates;;
        2 ) newHostname;;
        3 ) instTools;;
        4 ) confTerminal;;
        5 ) confOVPN;;
        6 ) expandFS;;
        7 ) allFunctions;;
        X ) echo -e "\n\nExiting...  You should reboot just for good measure!\n\n" && exit;;
        x ) echo -e "\n\nExiting...  You should reboot just for good measure!\n\n" && exit;;
        * ) echo "Invalid selection"
    esac
done