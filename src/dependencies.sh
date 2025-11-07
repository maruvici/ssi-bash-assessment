dependencies_array=(mailx epel-release msmtp)

# Check if dependency exist; If not, install
for dep in "${dependencies_array[@]}"; do
    if [[ "$dep" == "epel-release" ]]; then
        if rpm -q epel-release >/dev/null 2>&1; then
            sudo dnf install epel-release >/dev/null 2>&1
        fi
    else
        if ! ( command -v $dep >/dev/null 2>&1 ); then
            sudo dnf install $dep
        fi
    fi
done

# Check if msmtp conf file exists; If not, create one
# Handles gmail only (for now)
msmtprc_dir="$HOME/.msmtprc"
if ! [ -e $msmtprc_dir ]; then
    read -p "Enter your email address to be used for email sending:" from_email
    echo -e "For mstp, app password is required. For gmail accounts, follow the steps below:
    1) Go to https://myaccount.google.com
    2) Head to Security -> App Passwords
    3) Create new app password for Mail
    4) Enter the password below
    To access the conf, use: ~/.msmtprc"
    read -p "Enter your app password:" app_password
    cat >"$msmtprc_dir" << EOF
#~/.msmtprc
defaults
    tls on
    tls_trust_file /etc/ssl/certs/ca-bundle.crt
    auth on
    logfile ~/.msmtp.log

account gmail
    host smtp.gmail.com
    port 587
    from  $from_email
    user $from_email
    auth on
    tls on
    password $app_password

account default: gmail
EOF
fi

# Set permissions 
chmod 600 ~/.msmtprc

# Check if mail uses msmtp as mta;  If not, configure to do so
mailrc="$HOME/.mailrc"
if ! grep -q 'set mta=' "$mailrc" 2>/dev/null; then
    echo 'set mta="/usr/bin/msmtp"' >> "$mailrc"
fi




