# Kerberos and SSH

- [Kerberos and SSH](#kerberos-and-ssh)
  - [Vagrant and VirtualBox](#vagrant-and-virtualbox)
  - [Vagrantfile](#vagrantfile)
    - [The main Vagrant commands](#the-main-vagrant-commands)
  - [Setting up the servers](#setting-up-the-servers)
  - [Running and testing the lab](#running-and-testing-the-lab)
    - [Delegation Credentials](#delegation-credentials)
  - [Notes](#notes)

This is a simple guide to setting up Kerberos and SSH on a Debian-based system. This guide is based on the [MIT Kerberos documentation](https://web.mit.edu/kerberos/krb5-1.12/doc/index.html).

The intention of this lab is configure a Kerberos server and a client, and then configure SSH to use Kerberos for authentication.

## Vagrant and VirtualBox

To setup the lab, we will use Vagrant and VirtualBox. Both are free and open-source software and should be available in your package manager. The executables should be also available in the PATH.

To check the availability of Vagrant and VirtualBox, execute the following commands:

```bash
# Vagrant
vagrant --version

# VirtualBox
vboxmanage --version
```

## Vagrantfile

The Vagrantfile is a Ruby script that describes the configuration of the virtual machines. The Vagrantfile for this lab is located in the Vagrantfile.

The Vagrantfile describes the following virtual machines:

- `kerberos-server`: The Kerberos server and where the KDC will be running.
- `kerberos-client`: A client machine which will be on the same network as the Kerberos server and will be able to authenticate using Kerberos.

> By default, Vagrant with share the current directory with the virtual machine. This is useful for sharing files between the host and the guest machine. The shared directory is mounted at `/vagrant` in the guest machine. In this exemple, the kerberos configuration files and keytabs are shared between the host and the guest machine.

### The main Vagrant commands

To execute and run Vagrant there are a several subcommands and plugins but to run this lab the main instructions are the following:

- `vagrant up`: This command creates and configures guest machines according to your Vagrantfile.
- `vagrant destroy`: This command stops the running machine Vagrant is managing and destroys all resources that were created during the machine creation process.
- `vagrant ssh <machine>`: This command will SSH into a running Vagrant machine.
    > When using the `vagrant ssh` command, you will login as the `vagrant` user. To login as the root user, use the `sudo su -` command, or to login as another user, use the `su - <user>` command. In this Lab the user `datalab` is created on the machines.
- `vagrant status`: This command will tell you the state of the machines Vagrant is managing.
- `vagrant global-status`: This command will output the status of all active Vagrant environments on the system.

## Setting up the servers

To setup the Kerberos server and client using a Vagrantfile, a provision script is used. The provision script is a shell script that is executed when the virtual machine is created. Some steps executed by the provision script are:

1. Create a local user (`datalab`) for the server and client.
2. Install the necessary packages for the Kerberos server and client.
3. Copy the Kerberos configuration files.
4. Create the Kerberos database and add the necessary principals.
5. Create the keytab file for the client.
6. Configure the SSH Daemon to use Kerberos for authentication.

In addition to the provision script, the Vagrantfile also contains the necessary configurations for the virtual machines, such as the IP address, hostname, and memory. There are also the configurations for hosts file, which is used to resolve the hostnames of the virtual machines.

## Running and testing the lab

To start the lab, execute `vagrant up` in the same directory as the Vagrantfile. This will create the virtual machines and execute the provision script.

After the virtual machines are created, you can SSH into the Kerberos server and client with `vagrant ssh kerberos-server` and `vagrant ssh kerberos-client`, respectively.

To test connection follow the steps below:

1. SSH into the Kerberos Client machine:

    ```bash
    vagrant ssh kerberos-client
    ```

2. In the Kerberos Client machine, execute the following command to authenticate with the Kerberos server:

    ```bash
    kinit -kt /vagrant/datalab.keytab datalab@DATALAB.LOCAL
    ```

3. After authenticating, you can SSH into the Kerberos server without providing a password:

    ```bash
    ssh <user>@kerberos-server.datalab.local
    ```

### Delegation Credentials

By default the credential on client machine is not delegated to the server. To enable delegation credentials, you need to add the option `GSSAPIAuthentication yes` in the `/etc/ssh/ssh_config` file on the client machine or use the -K option in the `ssh` command.

```bash
ssh -K <user>@kerberos-server.datalab.local
```

Now if you use `klist` command on the server machine you will see the delegation credentials.

## Notes

To understand all the steps and configurations, I really recommend reading the files in the current directory. The files are well documented and should help you understand the configurations.

Some important points:

- The server should have a fully qualified domain name (FQDN) and the client should be able to resolve the server's FQDN.
- The server should have a principal `host/<hostname>@REALM` in the Kerberos database, where hostname is the FQDN.
- The Server that will receive the connection should have the `GSSAPIAuthentication yes` and `GSSAPICleanupCredentials yes` in the `/etc/ssh/sshd_config` file.
- The Server that will receive the connection should have the `/etc/krb5.keytab` file with the principal `host/<hostname>@REALM`.
- The Client making connection should have a valid ticket initialized with the principal intended to use in the connection.
