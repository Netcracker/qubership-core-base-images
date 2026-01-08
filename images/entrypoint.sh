#!/usr/bin/env bash

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

# Java automatically picks up JAVA_TOOL_OPTIONS, so we don't need to pass it explicitly
export JAVA_TOOL_OPTIONS="$X_JAVA_ARGS"
echo "JAVA_TOOL_OPTIONS: $JAVA_TOOL_OPTIONS"

if [[ "$1" != "bash" ]] && [[ "$1" != "sh" ]] ; then
    run_init_scripts

    echo "Run subcommand:" "$@"
    # shellcheck disable=SC2068
    exec $@
    # TODO unreachable code: how to end crash dumps?
    pid="$!"
    wait "$pid" ; retCode=$?
    echo "Process ended with return code ${retCode}"

    # save crash dump for future analysis
    [ "$(type -t send_crash_dump)" = "function" ]  && send_crash_dump

    exit $retCode
else
    # For interactive shell commands, execute directly
    echo "Run subcommand:" "$@"
    # shellcheck disable=SC2068
    exec $@
fi


