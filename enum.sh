#!/bin/bash

echo -e "[+] Creating folder"

if [ ! -d "$1" ];then
mkdir $1
echo -e "[+] Folder Created"
else
echo -e "[+] Folder Was Created"
fi
echo -e "\n[+] Searching subdomain with Sublist3r.."
python3 /opt/Sublist3r/sublist3r.py -d $1 -o "$1/$1_sublist3r.txt" | sort -u
echo -e "[+] Done."

echo -e "\n[+] Searching subdomain with amass"
amass enum -d $1 -o "$1/$1_amass.txt" | sort -u
echo -e "[+] Done."

echo -e "\n[+] Listing Live domains.."
cat "$1/$1_sublist3r.txt" | sort -u| httprobe >> "$1/$1_live_subdomain.txt"
cat "$1/$1_amass.txt" |sort -u | httprobe >> "$1/$1_live_subdomain.txt"
echo -e "[+] Done."

echo -e "\n[+] Testing Subdomain Takeover"
cat "$1/$1_live_subdomain.txt" | sort -u >> "$1/$1_subdomains.txt"
python3 /opt/takeover/takeover.py -l "$1/$1_subdomains.txt" -o "$1/$1_takeover_results.txt" -v

echo -e "\n[+] Testing CORS "

while read line; do
cors='$(curl -k -s -v $line -H "Origin: https://www.google.cl" > /dev/null)'
    if [[ $cors =~ "Access-Control-Allow-Origin: *" ]]; then
        echo -e $line " .... it's seem vulnerable to CORS"
	echo -e 'curl -k -s -v $line -H "Origin: https://www.google.cl"' >> $1/$1_cors.txt
    fi
done < $1/$1_subdomains.txt
echo -e "[+] Done"

echo -e "\n[+] Testing Methods HTTP"

while read line; do
put='$(curl -i -X OPTIONS $line > /dev/null)'
    if [[ $put =~ "PUT" ]]; then
        echo -e $line " .... it's seem vulnerable to method PUT"
	echo -e "curl -i -X OPTIONS $line " >> $1/$1_method_put.txt
    fi
done < $1/$1_subdomains.txt
echo -e "[+] Done"

echo -e "\n[+] Testing Host Header Attack"

while read line; do
host='$(curl -H "Host: https://www.google.cl" $line > /dev/null)'
    if [[ $host =~ "Location: https://www.google.cl" ]]; then
        echo -e $line " .... it's seem vulnerable to Host Header Attack"
        echo -e 'curl -H "Host: https://www.google.cl" $line ' >> $1/$1_hostheader.txt
    fi
done < $1/$1_subdomains.txt
echo -e "[+] Done"

