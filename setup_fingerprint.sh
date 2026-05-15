#!/usr/bin/env bash
# fingerprint-setup.sh
# Enable the Synaptics 06cb:009a "Metallica MIS Touch" fingerprint reader
# on a fresh Fedora install (tested on 40–44). Targets ThinkPads using that
# sensor: P52, P72, T480/s, X1C6, X280, etc.
#
# Run as root:  sudo ./fingerprint-setup.sh
# Enrollment is interactive — do that as your normal user afterwards.

set -euo pipefail

log()  { printf '\033[1;34m>>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!!\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31mxx\033[0m %s\n' "$*" >&2; exit 1; }

# ---- preflight --------------------------------------------------------------

[[ $EUID -eq 0 ]] || die "Run as root: sudo $0"

. /etc/os-release
[[ "${ID:-}" == "fedora" ]] || die "Not Fedora (ID=$ID); aborting."
log "Fedora $VERSION_ID detected."

if ! lsusb | grep -qi '06cb:009a'; then
    warn "Synaptics 06cb:009a not found on the USB bus."
    warn "If lsusb shows a different ID (e.g. 06cb:00a2, Goodix 27c6:*),"
    warn "this driver will NOT work. Check the hardware first:"
    lsusb | grep -iE 'fingerprint|synaptics|validity|goodix' || true
    die "Aborting."
fi
log "Sensor present: $(lsusb | grep -i '06cb:009a')"

# ---- packages ---------------------------------------------------------------

log "Enabling sneexy/python-validity COPR (maintained fork)."
dnf -y install dnf-plugins-core >/dev/null
dnf -y copr enable sneexy/python-validity

log "Installing fprintd and python-validity."
dnf -y install fprintd fprintd-pam open-fprintd python3-validity

# ---- services ---------------------------------------------------------------

log "Enabling python3-validity and open-fprintd services."
systemctl enable --now python3-validity.service
systemctl enable --now open-fprintd.service

log "Waiting up to 30s for sensor firmware init..."
for _ in $(seq 1 30); do
    systemctl is-active --quiet python3-validity && break
    sleep 1
done
systemctl is-active --quiet python3-validity \
    || warn "python3-validity did not become active; check 'journalctl -u python3-validity -b'."

# ---- PAM integration --------------------------------------------------------

log "Wiring fingerprint auth into PAM via authselect."
authselect enable-feature with-fingerprint
authselect apply-changes

# ---- done -------------------------------------------------------------------

cat <<'EOF'

Setup complete. ------------------------------------------------------------

Enroll a finger as your NORMAL user (not root):

    fprintd-enroll                       # right index by default
    fprintd-enroll -f left-index-finger  # specific finger
    fprintd-list  "$USER"                # list enrolled
    fprintd-verify                       # test match

Troubleshooting:

  * "Failed to claim device" / "already claimed":
        sudo systemctl restart python3-validity fprintd
        sudo rm -rf /var/lib/fprint/*    # wipe enrollments, then retry

  * Sensor was paired to Windows previously (common on ex-Windows ThinkPads):
        Reboot → Enter BIOS (F1) → Security → Fingerprint →
        "Reset Fingerprint Data". Reboot, then retry enrollment.

  * Sensor unresponsive after suspend:
        Add a resume hook restarting python3-validity. See
        https://github.com/uunicorn/python-validity (Known issues).

  * SELinux denials:
        sudo ausearch -c python3 --raw | audit2allow -M python-validity
        sudo semodule -i python-validity.pp

  * Live logs:
        journalctl -u python3-validity -f

EOF
