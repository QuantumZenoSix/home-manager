#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

function initialize_files(){

    sudo mkdir -p /etc/home-manager/
    sudo chmod 700 /etc/home-manager/


    echo "These files in /etc/home-manager/ must be updated in order to proceed:"
    printf "\trestic-b2.env\n"
    printf "\trestic-password\n"
    printf "\trestic-password-b2\n"
    printf "\tsmbpassword.env\n"
    printf "\tkuma.env\n"
    printf "\tkuma-b2.env\n"
    printf "\tremote-server-details.env\n"
    echo 
    echo "These files will be copied to /etc/home-manager/ once they have all been updated"
    echo 

    read -p "Can you confirm they have all been updated? [Yy/Nn] " -n 1 -r
    echo # move to a new line
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Confirmed."
    else
        echo "Aborted."
        return 1
    fi   

    # Copy credentials + environment vars
    echo "[+] Copying files..."
    sudo install -o root -g root -m 600 $SCRIPT_DIR/kuma-b2.env /etc/home-manager/
    sudo install -o root -g root -m 600 $SCRIPT_DIR/kuma.env /etc/home-manager/
    sudo install -o root -g root -m 600 $SCRIPT_DIR/remote-server-details.env /etc/home-manager/
    sudo install -o root -g root -m 600 $SCRIPT_DIR/restic-b2.env /etc/home-manager/
    sudo install -o root -g root -m 600 $SCRIPT_DIR/restic-password /etc/home-manager/
    sudo install -o root -g root -m 600 $SCRIPT_DIR/restic-password-b2 /etc/home-manager/
    sudo install -o root -g root -m 600 $SCRIPT_DIR/restic.env /etc/home-manager/
    sudo install -o root -g root -m 600 $SCRIPT_DIR/smbpassword.env /etc/home-manager/

}

function mount_shares_and_setup_services(){

    REMOTE_SERVER=$(sudo cat /etc/home-manager/remote-server-details.env | xargs)     # home lab server name
    source "$SCRIPT_DIR/remote-server-details.env"

    if [[ -z "$REMOTE_SERVER" ]]; then
        echo "[!] Remote server hostname is empty. Check ./remote-server-details.env file."
        echo "Aborting."
    return 1
fi

    # Copy systemd services/timer/scripts
    echo "[+] Creating service unit files..."
    sudo install -o root -g root -m 644 $SCRIPT_DIR/restic-backup-system.service /etc/systemd/system/
    sudo install -o root -g root -m 644 $SCRIPT_DIR/restic-backup-system.timer /etc/systemd/system/
    sudo install -o root -g root -m 700 $SCRIPT_DIR/restic_backup_system.sh /usr/local/sbin/

    # Mount SMB shares
    echo "[+] Attempting to mount shares..."
    sudo mkdir -p /mnt/data/ /mnt/data-backup/

    # Remove existing entries for these mountpoints
    sudo sed -i -E '\|^[^#].*[[:space:]]/mnt/data(-backup)?[[:space:]]|d' /etc/fstab

    if [[ $(sudo grep "//${REMOTE_SERVER}/myhdd /mnt/data" /etc/fstab | wc -l) -eq 0 ]];then
        echo "//${REMOTE_SERVER}/myhdd /mnt/data         cifs  credentials=/etc/home-manager/smbpassword.env,vers=3.0,iocharset=utf8,noperm,x-systemd.automount 0 0" | sudo tee -a /etc/fstab > /dev/null
    fi

    if [[ $(sudo grep "//${REMOTE_SERVER}/myhdd-backup /mnt/data-backup" /etc/fstab | wc -l) -eq 0 ]];then
        sudo echo "//${REMOTE_SERVER}/myhdd-backup /mnt/data-backup         cifs  credentials=/etc/home-manager/smbpassword.env,vers=3.0,iocharset=utf8,noperm,x-systemd.automount 0 0" | sudo tee -a /etc/fstab > /dev/null
    fi

    # Reload and mount
    sudo systemctl daemon-reload
    sudo mount -a


    if mountpoint -q /mnt/data/ && mountpoint -q /mnt/data-backup/; then

        echo "[+] Shares successfully mounted on /mnt/data/ & /mnt/data-backup"
        #sudo systemctl start restic-backup-system.timer
        #sudo systemctl enable restic-backup-system.timer
        sudo systemctl enable --now restic-backup-system.timer
        sudo systemctl status restic-backup-system.timer

        if sudo systemctl is-active --quiet restic-backup-system.timer; then
            echo "[+] Backup timer is active."
        else
            echo "[!] Backup timer failed to start."
            return 1
        fi

    else
        echo "[!] Shares not mounted on /mnt/data/ - cannot start service timers!"
            return 1
    fi

}


initialize_files || exit 1
mount_shares_and_setup_services || exit 1


exit 0
