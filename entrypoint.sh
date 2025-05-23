#!/usr/bin/env bash

load_certificates() {

    export certs_location="${CERTIFICATE_FILE_LOCATION}"
    # shellcheck disable=SC2016
    certs_found=$(find /tmp/cert -type f \( -name '*.crt' -o -name '*.cer' -o -name '*.pem' \))
    if which keytool; then
      echo "Load certificates to java keystore"
      export pass=${CERTIFICATE_FILE_PASSWORD:-changeit}

      # Change password if passed and default one set as old
      if [ "$pass" != "changeit" ] &&  keytool -list -keystore "${certs_location}" -storepass changeit > /dev/null; then
         keytool -v -storepasswd -keystore "${certs_location}" -storepass changeit -new "$pass"
      fi

      echo $certs_found | xargs -n 1 --no-run-if-empty bash -c  \
        'alias=$(basename "$1"); echo -file "$1" -alias "$alias" ; keytool -keystore ${certs_location} -importcert -file "$1" -alias "$alias"  -storepass ${pass} -noprompt' argv0

    else
      echo "Load certificates to trust store"
      echo $certs_found | xargs -n 1 --no-run-if-empty sh -c \
        'echo -file "$1" ; cp "$1" "$certs_location" ; update-ca-certificates; ' argv0
    fi
}

create_user() {
    if ! whoami >/dev/null 2>&1; then
        echo "Current user is absent, create entry for it"
        cp /etc/passwd /app/nss/passwd
        if [ -w /app/nss/passwd ]; then
            echo "${USER_NAME:-appuser}:x:$(id -u):$(id -g):${USER_NAME:-appuser} user:${HOME}:/bin/sh" >> /app/nss/passwd
            echo "Created appuser"
            export LD_PRELOAD=libnss_wrapper.so:$LD_PRELOAD
            export NSS_WRAPPER_PASSWD=/app/nss/passwd
            export NSS_WRAPPER_GROUP=/etc/group
        else
            echo "Can't create ${USER_NAME:-appuser} entry in /app/nss/passwd for nss_wrapper"
        fi
    else
      echo "No need to create appuser"
    fi
}

restore_volumes_data() {
    cp -Rn /app/volumes/certs/* /etc/ssl/certs
}

run_init_scripts() {
  if [ -d "/app/init.d" ]; then
    local scripts
    scripts=$(find /app/init.d/ -maxdepth 1 -type f -name '*.sh' | sort)
    if [ -n "$scripts" ]; then
        echo "Found init scripts in /app/init.d:"
        for f in $scripts; do basename "$f"; done

        for script in $scripts; do
            echo "Running init script $script"
            sh "$script" && exit_code=0 || exit_code=$?
            if [ "$exit_code" != "0" ]; then
                echo "Script $script failed, exit code=$exit_code" && exit 127
            fi
            echo "Script $script completed successfully"
        done
        echo "All init scripts completed successfully"
    fi
  fi
}

pid=0
subcommandRetCode=0
rethrow_handler() {
    echo "Caught $1 sig in entrypoint"
    #To prevent 503\502 error on rollout new deployment https://rtfm.co.ua/en/kubernetes-nginx-php-fpm-graceful-shutdown-and-502-errors/
    if [ "$1" == "SIGTERM" ]; then
      /bin/sleep 10
    fi
    local subRetCode=0
    if [ $pid -ne 0 ]; then
        echo "Signaling to subcommand"
        kill -"$1" "$pid"
        wait "$pid" ; subRetCode=$?
    fi
    echo "Subcommand signaled with $1, exit code $subRetCode"
    exit $subRetCode
}

echo "Run entrypoint.sh:"
restore_volumes_data
create_user
load_certificates

# See full current list in http://man7.org/linux/man-pages/man7/signal.7.html
export SIGNALS_TO_RETHROW="
SIGHUP
SIGINT
SIGQUIT
SIGILL
SIGABRT
SIGFPE
SIGSEGV
SIGPIPE
SIGALRM
SIGTERM
SIGUSR1
SIGUSR2
SIGCONT
SIGSTOP
SIGTSTP
SIGTTIN
SIGTTOU
SIGBUS
SIGPROF
SIGSYS
SIGTRAP
SIGURG
SIGVTALRM
SIGXCPU
SIGXFSZ
SIGSTKFLT
SIGIO
SIGPWR
SIGWINCH
"

if [[ "$1" != "bash" ]] && [[ "$1" != "sh" ]] ; then
# We don't want to mess with shell signal handling in terminal mode.
# Otherwise we need to rethrow signals to service to terminate it gracefully
# in case of need, while also executing post-mortem if available.
    echo "run init scripts"
    run_init_scripts
    for sig in $SIGNALS_TO_RETHROW; do trap 'rethrow_handler "$sig"' "$sig" > /dev/null 2>&1; done
    if [[ "$1" == "java" || "$1" == "/usr/bin/java" ]]; then
      shift # trim "java"
      if [[ "${PROFILER_ENABLED,,}" == "true" ]]; then
        JAVA_OPTIONS="$JAVA_OPTIONS -javaagent:/app/diag/lib/qubership-profiler-agent.jar"
        JAVA_OPTIONS="$JAVA_OPTIONS -Dprofiler.dump.home=/app/diag"
      fi
      echo "Run command:" java "$JAVA_OPTIONS" "$@"
      java $JAVA_OPTIONS $@ &
    else
      echo "Run subcommand:" "$@"
      $@ &
    fi
    pid="$!"
    wait "$pid" ; retCode=$?
    echo "Process ended with return code ${retCode}"
    exit $retCode
else
    exec $@
fi
