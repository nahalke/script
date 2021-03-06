#!/bin/bash

##Check if system compatible before install
#compatible(){
	##Check if distribution is supported
	#if [[ -z "$(uname -a | grep Ubuntu)" && -z "$(uname -a | grep Debian)" ]];then
		#echo Distro not supported
		#exit 1
	
	##Check if systemd is running
	#if [[ -z "$(pidof systemd)" ]]; then
		#echo systemd not running
		#exit 2
	#fi

	#if [ "$UID" -ne 0 ]; then
		#echo Must be root to run the script
		#exit 3
	#fi
#}

##Ask user to install the app
installApp(){
	clear
	while true;	do
		read -r -p 'Do you want to install '$1'?(Y/n)' choice
		case "$choice" in
			n|N) return 1;;
			y|Y|"") return 0;;
			*) echo 'Response not valid';;
		esac
	done
}

##Updates && Upgrades
updates(){
	sudo apt-get update;
	sudo apt-get upgrade;
}

sonarr(){
	sudo apt-get install libmono-cil-dev;
	sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys FDA5DFFC;
	sudo echo "deb http://apt.sonarr.tv/ master main" | sudo tee /etc/apt/sources.list.d/sonarr.list;
	sudo apt-get update;
	sudo apt-get install nzbdrone;

	sudo echo "[Unit]
	Description=Sonarr Daemon
	[Service]
	User=${username}
	Type=simple
	PermissionsStartOnly=true
	ExecStart=/usr/bin/mono /opt/NzbDrone/NzbDrone.exe -nobrowser
	TimeoutStopSec=20
	KillMode=process
	Restart=on-failure
	[Install]
	WantedBy=multi-user.target
	" > /etc/systemd/system/sonarr.service;

	sudo chown -R ${username}:${username} /opt/NzbDrone/

	systemctl enable sonarr.service;
	sudo service sonarr start;

}

radarr(){
	sudo apt update && apt install libmono-cil-dev curl mediainfo;
	sudo apt-get install mono-devel mediainfo sqlite3 libmono-cil-dev -y;
	cd /tmp;
	wget https://github.com/Radarr/Radarr/releases/download/v0.2.0.45/Radarr.develop.0.2.0.45.linux.tar.gz;
	sudo tar -xf Radarr* -C /opt/;
	sudo chown -R ${username}:${username} /opt/Radarr;

	sudo echo "[Unit]
	Description=Radarr Daemon
	After=syslog.target network.target
	[Service]
	User=${username}
	Type=simple
	ExecStart=/usr/bin/mono /opt/Radarr/Radarr.exe -nobrowser
	TimeoutStopSec=20
	KillMode=process
	Restart=on-failure
	[Install]
	WantedBy=multi-user.target
	" > /etc/systemd/system/radarr.service;
	sudo chown -R ${username}:${username} /opt/Radarr

	sudo systemctl enable radarr;
	sudo service radarr start;
}

jackett(){
	sudo apt-get install libcurl4-openssl-dev;
	wget https://github.com/Jackett/Jackett/releases/download/v0.7.1622/Jackett.Binaries.Mono.tar.gz;
	sudo tar -xf Jackett* -C /opt/;
	sudo chown -R ${username}:${username} /opt/Jackett;

	sudo echo "[Unit]
	Description=Jackett Daemon
	After=network.target
	[Service]
	WorkingDirectory=/opt/Jackett/
	User=${username}
	ExecStart=/usr/bin/mono --debug JackettConsole.exe --NoRestart
	Restart=always
	RestartSec=2
	Type=simple
	TimeoutStopSec=5
	[Install]
	WantedBy=multi-user.target
	" > /etc/systemd/system/jackett.service;
	sudo systemctl enable jackett;
	sudo service jackett start;

	rm Jackett.Binaries.Mono.tar.gz;
}

createUser(){
	clear
        read -p "Enter user name : " username

        ##if user already exists quit the function
        grep -q $username /etc/passwd
        if [ $? -eq 0 ]; then
                echo "Using existing user '$username'"
                sleep 2
                return 1
        fi

        ##otherwise ask for a password for the newly created user
        read -p "Enter password : " password
        sudo adduser $username --gecos "First Last,RoomNumber,WorkPhone,HomePhone" --disabled-password
        echo "${username}:${password}" | sudo chpasswd
}

main(){
	##call compatible to check if distro is either Debian or Ubuntu
	compatible

	##create user
	createUser

	##call updates to upgrade the system
	updates

	##dictionnary to associate fonction with string name
	declare -A arr
	arr["plex"]=PlexMediaServer
	arr+=( ["sonarr"]=Sonarr ["radarr"]=Radarr ["jackett"]=Jackett )
	for key in ${!arr[@]}; do
		installApp ${arr[${key}]}
		if [ $? == 0 ]; then
			${key}
		fi
	done
}

main

BLUE=`tput setaf 4`
echo "Thanks for using this script"
