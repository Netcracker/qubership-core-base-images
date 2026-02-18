#!/usr/bin/env bash

[[ ${LOG_ENTRYPOINT_COMMANDS,,} == "true" ]] && set -x

severity_to_number() {
  case "$1" in
    DEBUG) echo 1 ;;
    INFO)  echo 2 ;;
    WARN|WARNING) echo 3 ;;
    ERROR) echo 4 ;;
    *) echo 2 ;;
  esac
}
CURRENT_LOG_LEVEL=$(severity_to_number "${LOG_LEVEL^^:-INFO}")
SCRIPT_PATH="${BASH_SOURCE[0]}"
SCRIPT_NAME="$(basename "$SCRIPT_PATH")"

log() {
  local severity severity_number _timestamp
  severity=${1^^:-INFO}
  shift
  severity_number=$(severity_to_number "$severity")

    if [ "$severity_number" -ge "$CURRENT_LOG_LEVEL" ]; then
      _timestamp=$(date +%Y-%m-%dT%H:%M:%S$(printf ".%03d" $(date +%N | cut -c1-3)))

       printf '[%s] [%s] [request_id=-] [tenant_id=-] [thread=-] [class=-] [%s] %s\n' "${_timestamp}" "${severity}" "${SCRIPT_NAME}" "$*"
    fi
}

export -f log

load_certificates() {
    # shellcheck disable=SC2016
    cert_search_dirs="/tmp/cert"
    kube_cert_dir="/var/run/secrets/kubernetes.io/serviceaccount"

    log INFO "Load certificates to image trust store..."

    if [ -d "$kube_cert_dir" ]; then
      cert_search_dirs="$cert_search_dirs $kube_cert_dir"
    fi
    certs_found=$(find $cert_search_dirs -type f \( -name '*.crt' -o -name '*.cer' -o -name '*.pem' \))
    for cert in $certs_found; do
      log DEBUG "Preprocess certificates file: ${cert}"
      <"${cert}" awk "
        /-----BEGIN CERTIFICATE-----/ {
            found = 1
            filename = sprintf(\"${CERTIFICATE_FILE_LOCATION}/$(basename ${cert%.*})_%03d.${cert##*.}\", n++);
        }
        filename { print > filename }
        END { if (!found) exit 1 }" || log ERROR "Error process certificates file ${cert}: invalid certificates file data format. " >&2
    done
    update-ca-certificates > /dev/null 2>&1 || log ERROR "Error updating CA certificates store" >&2
    log INFO "Done"

    if [[ -x /usr/bin/keytool ]]; then
      pass=${CERTIFICATE_FILE_PASSWORD:-changeit}
      # Change password if passed and default one set as old
      if [ "$pass" != "changeit" ]; then
        log INFO "Change default keystore password: "
        chmod u+w /etc/ssl/certs/java/cacerts
        keytool -v -storepasswd -cacerts -storepass changeit -new "$pass"
        chmod u-w /etc/ssl/certs/java/cacerts
      fi
    fi
}

create_user() {
    if ! whoami >/dev/null 2>&1; then
        log INFO "Current user is absent, create entry for it"
        cp /etc/passwd /app/nss/passwd
        if [ -w /app/nss/passwd ]; then
            echo "${USER_NAME:-appuser}:x:$(id -u):$(id -g):${USER_NAME:-appuser} user:${HOME}:/bin/sh" >> /app/nss/passwd
            log INFO "Created appuser"
            export LD_PRELOAD=libnss_wrapper.so:$LD_PRELOAD
            export NSS_WRAPPER_PASSWD=/app/nss/passwd
            export NSS_WRAPPER_GROUP=/etc/group
        else
            log WARN "Can't create ${USER_NAME:-appuser} entry in /app/nss/passwd for nss_wrapper"
        fi
    else
      log INFO "No need to create appuser"
    fi
}

restore_volumes_data() {
    [ -d /app/volumes/certs ] && cp -Rn /app/volumes/certs/. /etc/ssl/certs
}

run_init_scripts() {
  if [ -d "/app/init.d" ]; then
    local scripts
    scripts=$(find /app/init.d/ -maxdepth 1 -type f -name '*.sh' | sort)
    if [ -n "$scripts" ]; then
        log INFO "Found init scripts in /app/init.d:"
        for f in $scripts; do basename "$f"; done

        for script in $scripts; do
            log INFO "Running init script $script"
            sh "$script" && exit_code=0 || exit_code=$?
            if [ "$exit_code" != "0" ]; then
                log ERROR "Script $script failed, exit code=$exit_code" && exit 127
            fi
            log INFO "Script $script completed successfully"
        done
        log INFO "All init scripts completed successfully"
    fi
  fi
}

rethrow_handler() {
    log DEBUG "Caught $1 sig in entrypoint"

    # To prevent 503\502 error on rollout new deployment
    # https://rtfm.co.ua/en/kubernetes-nginx-php-fpm-graceful-shutdown-and-502-errors/
    if [ "$1" = "SIGTERM" ]; then
        sleep "${SIGTERM_EXIT_DELAY:-10}"
    fi

    if kill -0 "$pid" 2>/dev/null; then
        log DEBUG "Rethrow $1 to subprocess: $pid"
        kill -"$1" "$pid"
    fi
}


log INFO "Base image version: $(cat /etc/base-image-release)"

# Load diag-bootstrap.sh (and diag-lib.sh) to make functions from profiler agent available
if [ -f /app/diag/diag-bootstrap.sh ]; then
  source /app/diag/diag-bootstrap.sh
  log INFO "/app/diag/diag-bootstrap.sh file was found. Diagnostic functions are enabled."
fi

log INFO "Run entrypoint.sh:"
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
  log INFO "JAVA_TOOL_OPTIONS: $JAVA_TOOL_OPTIONS"
fi

if [[ "$1" != "bash" ]] && [[ "$1" != "sh" ]] ; then
# We don't want to mess with shell signal handling in terminal mode.
# Otherwise we need to rethrow signals to service to terminate it gracefully
# in case of need, while also executing post-mortem if available.
    log INFO "run init scripts"
    run_init_scripts
    # shellcheck disable=SC2064
    for sig in $SIGNALS_TO_RETHROW; do trap "rethrow_handler $sig" "$sig"; done
    log INFO "Run subcommand:" "$@"
    # shellcheck disable=SC2068
    $@ &
    pid=$!

    while true; do
        wait "$pid"
        retCode=$?
        # If wait returned >= 128, either wait was interrupted by a signal or the child
        # exited with that status (e.g. killed by signal). Only continue when the child
        # is still running (wait was interrupted); otherwise break with the real exit status.
        if [[ $retCode -ge 128 ]] && kill -0 "$pid" 2>/dev/null; then
            continue
        fi
        break
    done
    log INFO "Process ended with return code ${retCode}"

    # save crash dump for future analysis
    [ "$(type -t send_crash_dump)" = "function" ]  && send_crash_dump

    exit $retCode
else
    # shellcheck disable=SC2068
    log INFO "Run subcommand:" "$@"
    exec $@
fi


