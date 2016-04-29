#!/bin/bash

# SIGTERM-handler
term_handler() {

    # Stop crashplan
    /etc/init.d/crashplan stop

    exit 143; # 128 + 15 -- SIGTERM
}

trap 'kill "$tail_pid"; term_handler' INT QUIT KILL TERM

# experiment with modified JAVA_OPTS from http://www.oracle.com/technetwork/java/javase/clopts-139448.html#gbzrr
printf 'SRV_JAVA_OPTS="-Dfile.encoding=UTF-8 -Dapp=CrashPlanService -DappBaseName=CrashPlan -Xms20m -Xmx1024m -Dsun.net.inetaddr.ttl=300 -Dnetworkaddress.cache.ttl=300 -Dsun.net.inetaddr.negative.ttl=0 -Dnetworkaddress.cache.negative.ttl=0 -Dc42.native.md5.enabled=false -XX:+HeapDumpOnOutOfMemoryError -XX:+ShowMessageBoxOnError -XX:HeapDumpPath=/var/crashplan/dumps"\nGUI_JAVA_OPTS="-Dfile.encoding=UTF-8 -Dapp=CrashPlanDesktop -DappBaseName=CrashPlan -Xms20m -Xmx512m -Dsun.net.inetaddr.ttl=300 -Dnetworkaddress.cache.ttl=300 -Dsun.net.inetaddr.negative.ttl=0 -Dnetworkaddress.cache.negative.ttl=0 -Dc42.native.md5.enabled=false -XX:+HeapDumpOnOutOfMemoryError -XX:+ShowMessageBoxOnError -XX:HeapDumpPath=/var/crashplan/dumps"' > /var/crashplan/bin/run.conf

/etc/init.d/crashplan start

LOGS_FILES="/var/crashplan/log/service.log.0"
for file in $LOGS_FILES; do
	[[ ! -f "$file" ]] && touch $file
done

tail -n0 -F $LOGS_FILES &
tail_pid=$!

# wait "indefinitely"
while [[ -e /proc/$tail_pid ]]; do
    wait $tail_pid # Wait for any signals or end of execution of tail
done

# Stop container properly
term_handler
