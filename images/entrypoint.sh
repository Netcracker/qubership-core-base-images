#!/usr/bin/env bash

[[ ${LOG_ENTRYPOINT_COMMANDS,,} == "true" ]] && set -x

echo "Base image version: $(cat /etc/base-image-release)"

load_certificates() {
    # shellcheck disable=SC2016
    cert_search_dirs="/tmp/cert"
    kube_cert_dir="/var/run/secrets/kubernetes.io/serviceaccount"

    echo "Load certificates to image trust store..."
    if [ -d "$kube_cert_dir" ]; then
      cert_search_dirs="$cert_search_dirs $kube_cert_dir"
    fi
    certs_found=$(find $cert_search_dirs -type f \( -name '*.crt' -o -name '*.cer' -o -name '*.pem' \))
    for cert in $certs_found; do
      echo "  Preprocess certificates file: ${cert}"
      <"${cert}" awk "
        /-----BEGIN CERTIFICATE-----/ {
            found = 1
            filename = sprintf(\"${CERTIFICATE_FILE_LOCATION}/$(basename ${cert%.*})_%03d.${cert##*.}\", n++);
            print \"    \" filename
        }
        filename { print > filename }
        END { if (!found) exit 1 }" || echo "    Error process certificates file ${cert}: invalid certificates file data format. " >&2
    done
    update-ca-certificates
    echo "Done"

    if [[ -x /usr/bin/keytool ]]; then
      pass=${CERTIFICATE_FILE_PASSWORD:-changeit}
      # Change password if passed and default one set as old
      if [ "$pass" != "changeit" ]; then
        echo -n "Change default keystore password: "
        chmod u+w /etc/ssl/certs/java/cacerts
        keytool -v -storepasswd -cacerts -storepass changeit -new "$pass"
        chmod u-w /etc/ssl/certs/java/cacerts
      fi
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

rethrow_handler() {
    echo "Caught $1 sig in entrypoint"
    #To prevent 503\502 error on rollout new deployment https://rtfm.co.ua/en/kubernetes-nginx-php-fpm-graceful-shutdown-and-502-errors/
    if [ "$1" == "SIGTERM" ]; then
      /bin/sleep "${SIGTERM_EXIT_DELAY:-10}"
    fi
    local subRetCode=0
    if [ $pid -ne 0 ]; then
        echo "Rethrow $1 to subprocess: $pid"
        kill -"$1" "$pid"
        wait "$pid" ; subRetCode=$?
    fi
    echo "Subcommand signaled with $1, exit code $subRetCode"
    exit $subRetCode
}

# Load diag-bootstrap.sh (and diag-lib.sh) to make functions from profiler agent available
if [ -f /app/diag/diag-bootstrap.sh ]; then
  source /app/diag/diag-bootstrap.sh
else
  echo "/app/diag/diag-bootstrap.sh file not found. Diagnostic functions are disabled."
fi

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

# Java automatically picks up JAVA_TOOL_OPTIONS, so we don't need to pass it explicitly
if [[ -n $X_JAVA_ARGS ]]; then
  export JAVA_TOOL_OPTIONS="$X_JAVA_ARGS"
  echo "JAVA_TOOL_OPTIONS: $JAVA_TOOL_OPTIONS"
fi

if [[ "$1" != "bash" ]] && [[ "$1" != "sh" ]] ; then
# We don't want to mess with shell signal handling in terminal mode.
# Otherwise we need to rethrow signals to service to terminate it gracefully
# in case of need, while also executing post-mortem if available.
    echo "run init scripts"
    run_init_scripts
    # shellcheck disable=SC2064
    for sig in $SIGNALS_TO_RETHROW; do trap "rethrow_handler $sig" "$sig"; done
    echo "Run subcommand:" "$@"
    # shellcheck disable=SC2068
    $@ &
    pid=$!
    wait "$pid" ; retCode=$?
    echo "Process ended with return code ${retCode}"

    # save crash dump for future analysis
    [ "$(type -t send_crash_dump)" = "function" ]  && send_crash_dump

    exit $retCode
else
    # shellcheck disable=SC2068
    echo "Run subcommand:" "$@"
    exec $@
fi


