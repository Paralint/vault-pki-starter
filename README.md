# vault-pki-starter
A small project to get you started running your own PKI with Vault (on Consul storage backend). This guide will setup Vault with a Consul storage backend by following these steps:

   1. [Install the binaries](#installing-the-binaries)
   1. [Start Consul (the storage back-end)](#start-consul-the-storage-backend)
   1. [Start Vault](#start-vault)
   1. [Initialize Vault](#initialize-vault)

# Installing the binaries

Hashicorp's binaries do not need any kind of installation procedure, just download and run.

This starter project was written and tested in Windows, running the Linux version of Vault in Windows subsystem for Linux as well as Windows native version. Except for the initial download and configuration, every command work as is in either Windows or Linux (and probably Mac, too!).

## Download and install Vault

### Windows installation 
Although [I have my share of Windows scripting](https://stackoverflow.com/search?q=user%3A591064+%5Bbatch-file%5D), I feel there are too numerous options and too few tools to provide a copy-paste procedure like in Linux. If you are on Windows 10 and have [Windows Subsystem for Linux installed](https://docs.microsoft.com/en-us/windows/wsl/install-win10), then you should start bash on Windows and run one of the Linux guides below. I would not run that configuration in production though.

If you must use Windows, here are the steps to follow

 1. Download the [latest Windows binaries for Vault from the download page](https://www.vaultproject.io/downloads.html). 
 2. Unzip the file `vault.exe` it contains to a directory 
 3. Make vault.exe runnable from anywhere on the command line, using one of these methods
     * Add the folder you copied vault.exe to your path or
     * Create an alias to Vault 
      ```
      pushd <path where Vault is installed>
      doskey vault=if $1. equ . ^(%CD%\vault.exe^) else ^(%CD%\vault.exe $*^)
      popd
      ```

### Vault Linux download and installation (if you have root privileges)
These commands will download, install and give enhanced security permissions to Vault.

```bash
#Download the latest binary
curl -kO https://releases.hashicorp.com/vault/0.9.1/vault_0.9.1_linux_amd64.zip
#Copy the binary in the path
sudo unzip vault_0.9.1_linux_amd64.zip -d /usr/local/bin
#(Optional) Allow Vault to lock memory and prevent paging of sensitive key material
sudo setcap cap_ipc_lock=+ep /usr/local/bin/vault
```

### Vault Linux download and installation (without root privileges)
These commands will download and install Vault to your account.

```bash
#Download the latest binary
curl -kO https://releases.hashicorp.com/vault/0.9.1/vault_0.9.1_linux_amd64.zip
#Unzip the binary anywhere
unzip vault_0.9.1_linux_amd64.zip 
#Make an alias to Vault (to simulate it beign in your path)
alias vault=$PWD/vault
```

## Testing your installation
Vault should be ready to run. Try this commmand (same command on all OS):

```bash
vault version
```

# Running Vault on a Consul storage backend

## Running Consul, the storage backend
Vault has a pluggable storage engine. Storing to a file is fine, but will not provide you HA capabilites. Considering that you cannot change storage backends and that running Consul is very straighforward, let's bite the bullet and use that from the start.

### Windows installation 
Just like Vault, Consul on Windows is easy but Windows lacks basic scripting tools. If you are on Windows 10 and have [Windows Subsystem for Linux installed](https://docs.microsoft.com/en-us/windows/wsl/install-win10), then you should start bash on Windows and run one of the Linux guides below.

If you must use Windows, here are the steps to follow

 1. Download the [latest Windows binaries for Consul from the download page](https://www.consul.io/downloads.html). 
 2. Unzip the file `consul.exe` the zip file contains to any directory you have write access to
 3. Make consul.exe runnable from anywhere on the command line, using one of these methods
     * Add the folder you copied consul.exe to your path or
     * Create an alias to Consul
      ```
      pushd <path where Consul is installed>
      doskey consul=if $1. equ . ^(%CD%\consul.exe^) else ^(%CD%\consul.exe $*^)
      popd
      ```

### Consul Linux download and installation (if you have root privileges)
These commands will download and install Consul and make it available to everyone.

```bash
#Download the latest binary
curl -kO https://releases.hashicorp.com/consul/1.0.2/consul_1.0.2_linux_amd64.zip
#Copy the binary in the path
sudo unzip consul_1.0.2_linux_amd64.zip -d /usr/local/bin
```

### Consul Linux download and installation (without root privileges)
These commands will download and install Consul to your account.

```bash
#Download the latest binary
curl -kO https://releases.hashicorp.com/consul/1.0.2/consul_1.0.2_linux_amd64.zip
#Unzip the binary anywhere
unzip consul_1.0.2_linux_amd64.zip
#Make an alias to Vault (to simulate it beign in your path)
alias consul=$PWD/consul
```

## Testing your installation
Consul should be ready to run. Try this commmand (same command on all OS):

```bash
consul version
```

# Start Consul (the storage back-end)
A Consul configuration file was created in this repository. It disables update checks and sets a cluster of 1. On a production system, Consul (or whatever storage backend you choose) plays an important part in your high-availability configuration. 

To run `consul` with that configuration file, issue this command:

```bash
consul agent --server --data-dir ./data --config-file ./consul-config.json --ui --bind 127.0.0.1 
```

# Start Vault
It is easy to run vault in development mode, but changes are not persisted to disk. This configuration is somewhat scaled down, but still quite close to a real production deployment. Just so you know, this configuration

  - Listens on localhost. Production deployment must listen on an address that can be reached by other members of the cluster
  - Disables mlock. On Linux, you will get [better security by preventing paging](https://www.vaultproject.io/docs/configuration/index.html#disable_mlock).
  - TLS is disabled. We will enable it later in this tutorial

These changes do not affect Vault's functionality and they won't get in the way of your learning.

So for now, just run Vault with the provided configuration file, using this command:

```bash
vault server --config ./vault-config.hcl
```

# Initialize Vault 

