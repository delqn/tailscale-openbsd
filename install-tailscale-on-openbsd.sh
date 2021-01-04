#!sh

# set -auexo pipefail

# echo "GOPATH is $GOPATH"
# cd $GOPATH
# git clone git@github.com:tailscale/tailscale.git

go get tailscale.com/cmd/tailscale

cd $GOPATH/src/tailscale.com
go build ./...
go install tailscale.com/cmd/tailscale{,d}
doas cp $GOPATH/bin/tailscale* /usr/local/sbin

cat <<EOF | doas tee /etc/rc.d/tailscaled
#!/bin/ksh
#
# \$OpenBSD: tailscaled,v 0.1 \$

daemon="/usr/local/sbin/tailscaled --state=/var/db/tailscale/tailscaled.state --socket=/var/run/tailscale/tailscaled.sock"
daemon_flags="--port 0 --tun tun0"

rc_bg="YES"
rc_reload="NO"

. /etc/rc.d/rc.subr

# these have to be placed below the above rc.subr sourcing so that they override
# default value is: pexp="\${daemon}\${daemon_flags:+ \${daemon_flags}}"
pexp="tailscaled"

rc_start() {
        # default value is: \${rcexec} "\${daemon} \${daemon_flags} \${_bg}"
        # \${_bg} gets replaced with '&' if rc_bg=YES

        \${rcexec} "\${daemon} \${daemon_flags} 2>&1 | logger -t tailscaled \${_bg}"
}

rc_stop() {
        # default value is: pkill -xf "\${pexp}"

        \${rcexec} "\${daemon} --cleanup \${daemon_args} 2>&1 | logger -t tailscaled"
        pkill -xf "\${pexp}"
}

rc_check() {
        # default value is: pgrep -q -xf "\${pexp}"

        pgrep -q -x \${pexp}
}

rc_cmd \$1
EOF

doas chmod 555 /etc/rc.d/tailscaled

doas rcctl enable tailscaled
doas rcctl start tailscaled
