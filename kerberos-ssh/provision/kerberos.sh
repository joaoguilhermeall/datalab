#!/bin/bash

server_type=$1

# Add a datalab user, set password, and add to sudoers
sudo useradd -s /bin/bash -m datalab && echo "datalab:datalab" | sudo chpasswd

sudo touch "/etc/sudoers.d/datalab"
sudo sh -c "echo '# DataLab Sudoers' >> '/etc/sudoers.d/datalab'"
sudo sh -c "echo 'datalab ALL=(ALL) NOPASSWD: ALL' >> '/etc/sudoers.d/datalab'"

# Copy the kerberos configuration files
sudo cp /vagrant/etc/krb5.conf /etc/krb5.conf

export DEBIAN_FRONTEND=noninteractive

if [[ "$server_type" = "server" ]]; then
    # The installation of krb5-kdc and krb5-admin-server normally prompts for the realm name
    # but this is avoided by setting the environment variable DEBIAN_FRONTEND=noninteractive
    # and executing sudo with the -E option to preserve the environment variables
    sudo apt-get update && sudo -E apt-get install -y krb5-kdc krb5-admin-server

    # To create a new kerberos realm, and setup the password for the database file
    # the following command is used. The password is set to 'datalab'
    # The database file is located at /var/lib/krb5kdc/principal by default
    echo -e "datalab\ndatalab" | sudo krb5_newrealm

    sudo systemctl restart krb5-kdc
    sudo systemctl restart krb5-admin-server

    # Add the kerberos user
    sudo kadmin.local -q "addprinc -pw admin root/admin"
    sudo kadmin.local -q "addprinc -pw datalab datalab"
    sudo sh -c "echo '*/admin@KDC.DATALAB *' >> /etc/krb5kdc/kadm5.acl"

    # Create a keytab file for the kerberos user and copy it to the vagrant shared folder
    sudo rm -f /vagrant/datalab.keytab
    sudo kadmin.local -q "ktadd -k /vagrant/datalab.keytab datalab"
    sudo chown datalab:datalab /vagrant/datalab.keytab

    # Configure sshd to use kerberos and restart the service: GSSAPIAuthentication and GSSAPICleanupCredentials to yes
    # Password Authentication is disabled to force the use of kerberos
    sudo cp /vagrant/etc/ssh/sshd_config /etc/ssh/sshd_config
    sudo systemctl restart sshd

elif [[ "$server_type" = "client" ]]; then
    sudo apt-get update && sudo -E apt-get install -y krb5-user

else
    echo "Invalid server type"
    exit 1
fi

# Install and configure ntp (Network Time Protocol)
sudo apt-get install -y ntp
sudo systemctl start ntp
