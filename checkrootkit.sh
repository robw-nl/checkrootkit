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
# updated on January 5, 2023 v1.11 (rev 3) 
# refactored and extended check en logs, january 12, 2024
# more improvements, better SSH check. february 3, 2024
#

# Check if the run file exists and was last modified today
check_run_file() {
    # Check if the run file exists and was last modified today
    if [[ -f "${RUN_FILE}" ]] && [[ "$(date -r "${RUN_FILE}" +%Y%m%d)" == "$(date +%Y%m%d)" ]]; then
        # The run file exists and was last modified today, so exit the script
        exit 0
    fi

    # The run file doesn't exist or wasn't last modified today, so touch the run file and continue with the script
    touch "${RUN_FILE}"
}

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

# Check if SSH is active. If it is enabled it may interfere with scanning for rootkits
check_ssh() {
    if systemctl is-active --quiet sshd; then
        notify-send -t 5000 "$(echo -e "*** SSH is active ***\nDisable before checking for rootkits")"
    fi
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

# Wait for 10 seconds for the desktop to load as this script runs on first startup
sleep 5

# Run the functions
check_run_file
check_ssh
check_rootkits