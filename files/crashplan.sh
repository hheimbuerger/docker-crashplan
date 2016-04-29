#!/bin/bash

# SIGTERM-handler
term_handler() {

    # Stop crashplan
    /etc/init.d/crashplan stop

    exit 143; # 128 + 15 -- SIGTERM
}

trap 'kill "$tail_pid"; term_handler' INT QUIT KILL TERM

# experiment with modified JAVA_OPTS from http://www.oracle.com/technetwork/java/javase/clopts-139448.html#gbzrr
# printf 'SRV_JAVA_OPTS="-Dfile.encoding=UTF-8 -Dapp=CrashPlanService -DappBaseName=CrashPlan -Xms20m -Xmx1024m -Dsun.net.inetaddr.ttl=300 -Dnetworkaddress.cache.ttl=300 -Dsun.net.inetaddr.negative.ttl=0 -Dnetworkaddress.cache.negative.ttl=0 -Dc42.native.md5.enabled=false -XX:+HeapDumpOnOutOfMemoryError -XX:+ShowMessageBoxOnError -XX:HeapDumpPath=/var/crashplan/dumps"\nGUI_JAVA_OPTS="-Dfile.encoding=UTF-8 -Dapp=CrashPlanDesktop -DappBaseName=CrashPlan -Xms20m -Xmx512m -Dsun.net.inetaddr.ttl=300 -Dnetworkaddress.cache.ttl=300 -Dsun.net.inetaddr.negative.ttl=0 -Dnetworkaddress.cache.negative.ttl=0 -Dc42.native.md5.enabled=false -XX:+HeapDumpOnOutOfMemoryError -XX:+ShowMessageBoxOnError -XX:HeapDumpPath=/var/crashplan/dumps"' > /var/crashplan/bin/run.conf

# try to start crashplan as a foreground app
# /etc/init.d/crashplan start
export TARGETDIR="/usr/local/crashplan"
export SRV_JAVA_OPTS="-Dfile.encoding=UTF-8 -Dapp=CrashPlanService -DappBaseName=CrashPlan -Xms20m -Xmx512m -Dsun.net.inetaddr.ttl=300 -Dnetworkaddress.cache.ttl=300 -Dsun.net.inetaddr.negative.ttl=0 -Dnetworkaddress.cache.negative.ttl=0 -Dc42.native.md5.enabled=false -XX:+HeapDumpOnOutOfMemoryError -XX:+ShowMessageBoxOnError -XX:HeapDumpPath=/var/crashplan/dumps"
export FULL_CP="$TARGETDIR/lib/com.backup42.desktop.jar:$TARGETDIR/lang"
echo $JAVACOMMON > /var/crashplan/dumps/javacommon
. /usr/local/crashplan/install.vars

printenv > /var/crashplan/dumps/full_env
cd $TARGETDIR
nice -n 19 $JAVACOMMON $SRV_JAVA_OPTS -classpath $FULL_CP com.backup42.service.CPService > $TARGETDIR/log/engine_output.log 2> $TARGETDIR/log/engine_error.log

# THIS SHOULD NOT EVER BE EXECUTED -----------------------------
touch /var/crashplan/dumps/java_process_died

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
