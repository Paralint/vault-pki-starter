# vault-pki-starter
A small project to get you started running your own PKI with Vault (on Consul storage backend)

# Installing the binaries

Hashicorp's binaries do not need any kind of installation procedure, just download and run.

This starter project was built on Windows, running the Linux version of Vault in Windows subsystem for Linux. 

## Download and install Vault

### Windows installation 
Although [I have my share of Windows scripting](https://stackoverflow.com/search?q=user%3A591064+%5Bbatch-file%5D), I feel there are too numerous options and too few tools to provide a copy-paste procedure like in Linux. If you are on Windows 10 and have Windows Subsystem for Linux installed, then you should run on of the Linux guides below. I would not run that configuration in production though.

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

### Linux configuration (if you have root privileges)
These commands will download, install and give enhanced security permissions to Vault.

```bash
#Download the latest binary
curl -kO https://releases.hashicorp.com/vault/0.9.1/vault_0.9.1_linux_amd64.zip
#Copy the binary in the path
sudo unzip vault_0.9.1_linux_amd64.zip -d /usr/local/bin
#(Optional) Allow Vault to lock memory and prevent paging of sensitive key material
sudo setcap cap_ipc_lock=+ep /usr/local/bin/vault
```

### Linux configuration (without root privileges)
These commands will download and install Vault to your account.

```bash
#Download the latest binary
curl -kO https://releases.hashicorp.com/vault/0.9.1/vault_0.9.1_linux_amd64.zip
#Unzip the binary in the path
unzip vault_0.9.1_linux_amd64.zip 
#Make an alias to Vault (to simulate it beign in your path)
alias vault=$PWD/vault
```

## Testing your installation
Vault should be ready to run. Try this commmand :

```bash
vault version
```


# Running Consul, the storage backend
-----------------------------------
```bash
consul agent --server --data-dir ./data --config-file ./consul-config.json -ui --bind 127.0.0.1 
```

# Running Vault
-----------------------------------
