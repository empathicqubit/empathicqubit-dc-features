#!/usr/bin/env bash
# A lot of the boilerplate code comes from https://github.com/devcontainers/features/blob/main/src/desktop-lite/install.sh

set -e


echo "Activating feature 'audio-lite'"

USERNAME=${USERNAME:-"automatic"}
MUMBLE_PORT=64738

package_list="
    make \
    cmake \
    libasound2-dev \
    ca-certificates \
    libnotify-dev \
    libnotify4 \
    libssl-dev \
    openssl \
    ^libssl[0-9\.]*\$ \
    pulseaudio \
    cargo \
    mumble-server"

# Clean up
rm -rf /var/lib/apt/lists/*

if [ "$(id -u)" -ne 0 ]; then
    echo -e 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
    exit 1
fi

# Determine the appropriate non-root user
if [ "${USERNAME}" = "auto" ] || [ "${USERNAME}" = "automatic" ]; then
    USERNAME=""
    POSSIBLE_USERS=("vscode" "node" "codespace" "$(awk -v val=1000 -F ":" '$3==val{print $1}' /etc/passwd)")
    for CURRENT_USER in "${POSSIBLE_USERS[@]}"; do
        if id -u ${CURRENT_USER} > /dev/null 2>&1; then
            USERNAME=${CURRENT_USER}
            break
        fi
    done
    if [ "${USERNAME}" = "" ]; then
        USERNAME=root
    fi
elif [ "${USERNAME}" = "none" ] || ! id -u ${USERNAME} > /dev/null 2>&1; then
    USERNAME=root
fi

# Checks if packages are installed and installs them if not
check_packages() {
    if ! dpkg -s "$@" > /dev/null 2>&1; then
        apt-get -y install --no-install-recommends "$@"
    fi
}

##########################
#  Install starts here   #
##########################

# Ensure apt is in non-interactive to avoid prompts
export DEBIAN_FRONTEND=noninteractive

apt-get update
check_packages ${package_list}
apt-get clean
rm -rf /var/lib/apt/lists/*

cargo install --bins --root /usr/share/cargo mum-cli
ln -s /usr/share/cargo/bin/mumctl /usr/local/bin/mumctl
ln -s /usr/share/cargo/bin/mumd /usr/local/bin/mumd

cat << EOF > /usr/local/share/audio-lite-init.sh
#!/bin/bash

user_name="${USERNAME}"
group_name="$(id -gn ${USERNAME})"
mumble_port="${MUMBLE_PORT}"

# Execute the command it not already running
startInBackgroundIfNotRunning()
{
    log "Starting \$1."
    echo -e "\n** \$(date) **" | sudoIf tee -a /tmp/\$1.log > /dev/null
    if ! pidof \$1 > /dev/null; then
        keepRunningInBackground "\$@"
        while ! pidof \$1 > /dev/null; do
            sleep 1
        done
        log "\$1 started."
    else
        echo "\$1 is already running." | sudoIf tee -a /tmp/\$1.log > /dev/null
        log "\$1 is already running."
    fi
}

# Keep command running in background
keepRunningInBackground()
{
    (\$2 bash -c "while :; do echo [\\\$(date)] Process started.; \$3; echo [\\\$(date)] Process exited!; sleep 5; done 2>&1" | sudoIf tee -a /tmp/\$1.log > /dev/null & echo "\$!" | sudoIf tee /tmp/\$1.pid > /dev/null)
}

# Use sudo to run as root when required
sudoIf()
{
    if [ "\$(id -u)" -ne 0 ]; then
        sudo "\$@"
    else
        "\$@"
    fi
}

# Use sudo to run as non-root user if not already running
sudoUserIf()
{
    if [ "\$(id -u)" -eq 0 ] && [ "\${user_name}" != "root" ]; then
        sudo -u \${user_name} "\$@"
    else
        "\$@"
    fi
}

# Log messages
log()
{
    echo -e "[\$(date)] \$@" | sudoIf tee -a \$LOG > /dev/null
}

log "** SCRIPT START **"

log "starting pulseaudio"
if [ "\$user_name" != "root" ]; then
    sudoUserIf pulseaudio -D
else
    sudoUserIf pulseaudio -D --system
fi

log "starting mumble VoIP server"
sudoIf /etc/init.d/mumble-server start

while ! timeout 1 sh -c "echo > /dev/tcp/localhost/\${mumble_port}" ; do
    sleep 1
done

log "starting mumble client mumd"
startInBackgroundIfNotRunning "mumd" sudoUserIf "mumd"
sleep 1
while ! sudoUserIf mumctl connect --port "\${mumble_port}" 127.0.0.1 "\${user_name}" ; do
    sleep 1
done

# Run whatever was passed in
log "Executing \"\$@\"."
exec "\$@"
log "** SCRIPT EXIT **"
EOF

chmod +x /usr/local/share/audio-lite-init.sh

# Clean up
rm -rf /var/lib/apt/lists/*

cat << EOF
You now have working audio! Connect to it by
forwarding port ${MUMBLE_PORT} and using a Mumble client.
(*) Done!
EOF