#!/bin/bash

#Thanks to skeeto for creating endlessh! its a harmless yet effective way to waste the time and freeze up
#script kiddies and scary hackermen (lol)

#Check out the original script at https://github.com/skeeto/endlessh 

echo "Downloading endlessh from github... (https://github.com/skeeto/endlessh)"
wget https://github.com/skeeto/endlessh/archive/master.tar.gz

echo "Extracting files..."
tar -xvf master.tar.gz
cd endlessh-master/

echo "Checking if make and gcc are installed..."

if { apt list --installed make | grep "make" } == ""; 
then
    make_installed = "no"
else 
    make_installed = ""
fi

if { apt list --installed gcc | grep "gcc" } == ""; 
then
    gcc_installed = "no"
else 
    gcc_installed = ""
fi

apt install make
apt install gcc

echo "Building endlessh..."
make 

echo "Copying to binaries and services..."
cp endlessh /usr/local/bin/
cp util/endlessh.service /etc/systemd/system/

echo "Beginning user configuration..."
mkdir /etc/endlessh/
touch /etc/endlessh/config

echo "Please choose a port for endlessh(leave blank for 22)"
read endlesshport
if $endlesshport == ""; 
then
	endlesshport="22"
fi

echo "Please choose a delay (in milliseconds) between individual lines(leave blank for 10000)"
read endlesshdelay
if $endlesshdelay == ""; 
then
	endlesshdelay = "10000"
fi

echo "Please choose the Max Line Length(leave blank for 32 characters)"
read endlesshmaxllength
if $endlesshmaxllength == ""; 
then
	endlesshmaxllength = "32"
fi

echo "Please choose the max number of clients(leave blank for 1024)"
read endlesshmaxclients
if $endlesshmaxclients == ""; 
then
	endlesshmaxclients = "1024"
	echo "Max clients chosen: $endlesshmaxclients"
fi

echo "Please choose the logging level(0 for quiet, 1 for standard (useful log messages), 2(debugging, noisy)"
read endlesshloglevel
case $endlesshloglevel in 

	"1" | "2" | "3")
		echo "You've chosen logging level $endlesshloglevel"
		;;

	*)
		echo "Invalid logging level!"
		exit
		;;

esac

echo "Please choose the family of the listening socket(enter 'ipv4', 'ipv6', or 'both' with no quotations)"
read endlesshipfamily
case $endlesshipfamily in 

	"ipv4")
		echo "You've chosen ipv4"
		endlesshipfamily = "4"
		;;

	"ipv6")
		echo "You've chosen ipv6"
		endlesshipfamily = "6"
		;;

	"both")
		echo "You've chosen both"
		endlesshipfamily = "0"
		;;

	*)
		echo "Invalid ip family!"
		exit
		;;

esac

echo "Applying configuration..."
echo "Port $endlesshport" >> /etc/endlessh/config
echo "Delay $endlesshdelay" >> /etc/endlessh/config
echo "MaxLineLength $endlesshmaxllength" >> /etc/endlessh/config
echo "MaxClients $endlesshmaxclients" >> /etc/endlessh/config
echo "LogLevel $endlesshloglevel" >> /etc/endlessh/config
echo "BindFamily $endlesshipfamily" >> /etc/endlessh/config

echo "Allowing endlessh to communicate on reserved 1-1024 ports..."
setcap 'cap_net_bind_service=+ep' /usr/local/bin/endlessh

echo "Enabling and starting the service..."
systemctl enable endlessh.service
systemctl start endlessh.service

echo "Verifying and checking everything..."

endlessh_revert () {
	echo "Stopping service and disabling"
	systemctl stop endlessh.service
	systemctl disable endlessh.service
	echo "Removing files created by installer"
	rm -r /etc/endlessh/
	rm -r /usr/local/bin/
	rm /etc/systemd/system/endlessh.service
	rm master.tar.gz
	rm -r endlessh-master/
    if $make_installed == "no"; 
    then
        echo "Removing make"
        apt remove make
    fi
    if $gcc_installed == "no"; 
    then 
        echo "Removing GCC"
        apt remove gcc
    fi
    echo "Done reverting"
    echo "Something went wrong! Please try again or report the issue on my github page."
}

#checks if the service is active, if not it will revert all changes made by the script
systemctl is-active --quiet endlessh.service && echo "Successfully installed and running on $endlesshport!" && systemctl status endlessh.service || echo "something went wrong... reverting installation" && endlessh_revert
