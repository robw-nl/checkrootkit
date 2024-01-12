#!/bin/bash
#
# chkrootkit command to check if system is infected by rootkits
#
# For daily execution create a symlink to the script in cron.daily:
# sudo ln -s /path/to/this/script checkrootkit
#
# created by rob wijhenke november 2020
#
# use 'sudo systemctl status sshd.service' to check if ssh ports are open
# (related to Linux/Xor.DDoS false positives warning. So line 1283 to 1298
# commented out in /usr/bin/chkrootkit file
#
# updated on January 5, 2023
# v1.11 (rev 3)
#

# Source the configuration file
CONFIG_FILE="/home/rob/Files/Scripts/checkrootkit.conf"
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
else
    echo "Configuration file not found: $CONFIG_FILE"
    exit 1
fi

# Function to log messages with timestamp
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$SCANLOG"
}

# Function to check for rootkits
check_rootkits() {
    if ! command -v chkrootkit &> /dev/null; then
        log_message "chkrootkit could not be found"
        exit 1
    fi

    notify-send "*** Checking for rootkits ***"
    sudo chkrootkit > "$SCANLOG"

    if grep -qw "INFECTED" "$SCANLOG"; then
        grep "INFECTED" "$SCANLOG" > "$SCANPOS"
        kate "$SCANPOS"
        log_message "Rootkits found. Check $SCANPOS for details."
    else
        notify-send "*** NO ROOTKITS FOUND ***"
        log_message "No rootkits found."
    fi
}

# Function to check if ssh is enabled
check_ssh() {
    sudo systemctl status sshd.service > "$SCANSSH"
    if grep -qw "inactive" "$SCANSSH"; then
        notify-send "*** GOOD: SSH NOT ACTIVE ***"
        log_message "SSH is not active."
    else
        kate "$SCANSSH"
        log_message "SSH is active. Check $SCANSSH for details."
    fi
}

# Run the functions
check_rootkits
check_ssh