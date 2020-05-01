#!/bin/bash
passwd=`mkpasswd -l 9 -s 1`
echo "${passwd}"

printf "${passwd}\n${passwd}\n"  | sudo -A smbpasswd $1 -s
