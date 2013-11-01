#!/bin/sh

ENV=$( basename ${0} | cut -d\_ -f1 )
APP=$( basename ${0} | cut -d\_ -f2 )
APP_HOME=/home/{{ ansible_user_id }}/${ENV}
STARTUP_SCRIPT=${APP_HOME}/current/bin/${project}-${APP}
LOGS=/var/logs/${APP}
CURRENT=$( readlink ${APP_HOME}/current )
GREP_PATTERN="\-Denv=${ENV} \-Dsecrets=${APP_HOME}/secret.conf"
PID=$( ps -ea -o "pid ppid args" | grep -v grep | grep "${GREP_PATTERN}" | sed -e 's/^  *//' -e 's/ .*//' | head -1 )
PORT=$( ps -ea -o "args" | grep "${GREP_PATTERN}" | ps -ea -o "args" | grep "${GREP_PATTERN}" | sed 's/.*-Dport=\([1-9]...\).*/\1/' | head -1 )

if [ -n "${PORT}" ] ; then
  [ ${PORT} -eq 7002 ] && [ "${ENV}" = "prod" ] && NEW_PORT=7003
  [ ${PORT} -eq 7003 ] && [ "${ENV}" = "prod" ] && NEW_PORT=7002
  [ ${PORT} -eq 7004 ] && [ "${ENV}" = "test" ] && NEW_PORT=7005
  [ ${PORT} -eq 7005 ] && [ "${ENV}" = "test" ] && NEW_PORT=7004
else
  [ "${ENV}" = "test" ] && NEW_PORT=7004 || NEW_PORT=7002
fi

PARAMS="-mem 256 -Dport=${NEW_PORT} -Denv=${ENV} -Dsecrets=${APP_HOME}/secret.conf > ${APP_HOME}/current/myapp.out 2>&1 &"

case "${1}" in
  start)
    NUMBER_OF_PROCS=$( ps -ef | grep "${GREP_PATTERN}" | wc -l )
    [ ${NUMBER_OF_PROCS} ] && [ ${NUMBER_OF_PROCS} -gt 1 ] && echo "More than one process running. Exiting..." && exit 1
    echo "Starting ${ENV} ${APP} on port ${NEW_PORT}..."
    ${STARTUP_SCRIPT} ${PARAMS} 1>$LOGS/${ENV}_stdout.log 2>$LOGS/${ENV}_stderr.log &
    NEW_PID=$!
    ONLINE=""
    while ( test -z "${ONLINE}" )
    do
      echo "Waiting for ${ENV} ${APP} to be available on port ${NEW_PORT}"
      ONLINE=$( lsof -i:${NEW_PORT} | grep TCP )
      sleep 1
    done
    echo "Started ${ENV} ${APP} on port ${NEW_PORT} (PID=${NEW_PID})"
    ;;
  stop)
    echo "Stopping ${APP}..."
    if [ -z "${PID}" ]; then
      echo "${ENV} ${APP} is already stopped"
    else
      kill ${PID}
      echo "Killed ${ENV} ${APP} on port ${PORT} (PID=${PID})."
    fi
    ;;
  status)
    PIDS=$( ps -ea -o "pid ppid args" | grep -v grep | grep "${GREP_PATTERN}" | sed -e 's/^  *//' -e 's/ .*//' )
    test -n "${PIDS}" && echo "${ENV} ${APP} is running (${PIDS})." || echo "${ENV} ${APP} is not running."
    ;;
  restart)
    $0 start
    $0 stop
    ;;
  *)
    echo "Usage: $0 {start|stop|restart|status}"
    ;;
esac
