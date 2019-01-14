#!/bin/bash
echo 'Installing nscd services.'
apt-get install nscd -y
echo 'Flushing DNS.'
/etc/init.d/nscd restart
/etc/init.d/nscd force-reload
if [ $# -lt 1 ]; then
        echo $0 'need a parameter'
        echo 'Usage ./ipForward [localPort] [proto] [forwardPort] [domain]'
        exit 0
fi
localPort=$1
proto=$2
forwardPort=$3
domain=$4
ipadd=`ping ${domain} -c 1 | sed '1{s/[^(]*(//;s/).*//;q}'`
echo 'The IP address '${ipadd}' will be used.'
if [ -f "transform.list" ]; then
        echo 'Reading the last record.'
        lastRecord=`tail -n 1 transform.list`
        queryResult=`firewall-cmd --permanent --query-forward-port=port=${localPort}:proto=${proto}:toport=${forwardPort}:toaddr=${lastRecord}`
        if [ ${queryResult} -eq yes ]; then
                firewall-cmd --reload
                echo 'Flushing DNS.'
                /etc/init.d/nscd restart
                /etc/init.d/nscd force-reload
                exit 'The rule is already existing.'
        fi
        echo 'Deleting the similar rule.'
        firewall-cmd --permanent --remove-forward-port=port=${localPort}:proto=${proto}:toport=${forwardPort}:toaddr=${lastRecord}
else
        echo 'Creating domain to IP list.'
        touch transform.list
        queryResult=`firewall-cmd --permanent --query-forward-port=port=${localPort}:proto=${proto}:toport=${forwardPort}:toaddr=${ipadd}`
        if [ ${queryResult} -eq yes ]; then
                firewall-cmd --reload
                echo 'Flushing DNS.'
                /etc/init.d/nscd restart
                /etc/init.d/nscd force-reload
                exit 'This rule is already existing.'
        fi
        echo 'Deleting the similar rule.'
        firewall-cmd --permanent --remove-forward-port=port=${localPort}:proto=${proto}:toport=${forwardPort}:toaddr=${ipadd}

fi
echo 'Adding rule.'
addResult=`firewall-cmd --permanent --add-forward-port=port=${localPort}:proto=${proto}:toport=${forwardPort}:toaddr=${ipadd}`
echo 'Excut success!'
firewall-cmd --reload
echo 'Firewalld reloaded.'
echo 'Process the new IP address.'
echo $ipadd>>transform.list
echo 'Flushing DNS.'
/etc/init.d/nscd restart
/etc/init.d/nscd force-reload
exit 'This shell was written by jacklucascn@gmail.com, github https://github.com/JackLucasCN/LinuxShell, thanks for using!'
