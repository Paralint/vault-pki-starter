# vault-pki-starter
A small project to get you started running your own PKI with Vault (on Consul storage backend). This guide will setup Vault with a Consul storage backend by following these steps:

   1. [Install the binaries](#installing-the-binaries)
   1. [Start Consul (the storage back-end)](#start-consul-the-storage-back-end)
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
Everything Vault persists to disk is encrypted. There is no hardcoded key in Vault, you must generate one at instllation time. There is a single key shared by all members of a cluster. 

To increase security, Vault's master is never saved to disk, not even in encrypted form. When the master key is created, it is split in a number of key shards. To unseal Vault, a certain number of these shards must be provided so Vault can reconstruct the master key in memory. The number of key required to unseal Vault is called the 'quorum'.

By default, the master key is split in 5 shards, and 3 must be presented to unseal Vault. We will make it 2 out of 7 for demonstration purpose.

To initialize Vault with a 2 out of 7 quorum, run this command:

```bash
vault init --key-threshold=2 --key-shares=7 
```

You will receive the requested number of shards as well as an initial, all powerful root token:

```
Unseal Key 1: buZ8bOMdTzKnjUVJFl/RIC0lkmRboOSxc7XWnk1R7d/m
Unseal Key 2: l4G0uDHhOZq+2LtPlOP1jV8FfBZW/sHh1Oc7ty1rNZaL
Unseal Key 3: eFNC9jbuppDmunoGEUQmZ0dRlw6jIHVj5at5kdHO6UyC
Unseal Key 4: 7tlSeabl82vkNI0Zkv2cAfEIwbjj8bFwokStazoXWF0p
Unseal Key 5: ie0mnF+QncRnHQUFUBo0vH5B4DcoD+pLO4KCCOHTheU5
Unseal Key 6: LXrYGBAXpT4+ODLOGWy6ZT20IHT9NDxNpDSqU+WXjLro
Unseal Key 7: dGu4F10tQBIyMTaMPtcLKqR5z+1m5JInLWBkeal3B9w/
Initial Root Token: 2672f8c0-2bc4-b745-bb91-40900af9ec7e
```

You must save this information very carefully, and distribute it amongst 7 different person. There are a number of other options that increase the security of the process, and you should the time to reflect on this to get the rigth balance between security and convience.

But Vault is still not in a state where it can store and retrieve secrets. If you issue any command, you will get this message back :

```
Error reading secret/test: Error making API request.

URL: GET http://localhost:8200/v1/secret/test
Code: 503. Errors:

* Vault is sealed
```

Vault is ready, but just as if it was restarted (after upgrading version or OS restart), it has to be unsealed.

# Unseal vault
To read its own data, Vault needs the master key. That master is reconstructed at runtime from a number of key shards, only 2 in our example.

To unseal Vault, issue this command:

```
vault unseal
```

When prompted, enter any of the shards generated when Vault was initialized. Any shard in any order will do. After entering one, Vault will display this message :

```
Key (will be hidden):
Sealed: true
Key Shares: 7
Key Threshold: 2
Unseal Progress: 1
Unseal Nonce: 4fcc8e83-6050-aeef-d2ff-0ac710d4d5cd
```

Keep entering shards (one more in our example) until you get the `Sealed: false` message:

```
Key (will be hidden):
Sealed: false
Key Shares: 7
Key Threshold: 2
Unseal Progress: 0
Unseal Nonce
```

# Configuring Vault
## Gain root privileges (in Vault, not Linux)
To authenticate to Vault, you need a token. In a fully configured production environment, this token will be given after you authenticate to an external source, like an LDAP server or GitHub. But at this point, the only token there is is the root token provided when Vault was initialized. 

To use the root token, just set the `VAULT_TOKEN` environment variable:

### Use the root token on Linux
```bash
#DO NOT USE THIS VALUE, use the root token you got back from vault init
export VAULT_TOKEN=2672f8c0-2bc4-b745-bb91-40900af9ec7e
```

### Use the root token on Windows
```bash
REM : DO NOT USE THIS VALUE, use the root token you got back from vault init
set VAULT_TOKEN=2672f8c0-2bc4-b745-bb91-40900af9ec7e
```

You should now be able to write to Vault:

```bash
vault write secret/test hello=world
```

## Next steps
I suggest you continue playing around with the concepts of policies, authentication back end and roles by continuing to the [cuisine tutorial](cuisine.md), where we store the secret ingredients of some of my favorite cuisine.

# Cuisine secrets
## Mount a username/password backend
There are multiple authentication backends. To reduce dependencies for this sample, let's use Vault own username-password storage

```
vault auth-enable userpass
```

With that backend mounted, lets write some users to it:

```
vault write auth/userpass/users/chef password=secret123 policies=manage-cuisine
vault write auth/userpass/users/cook password=secret123 policies=work-cuisine
vault write auth/userpass/users/plunge password=secret123 
```

## Authenticate with a user
Authentication with a user is pretty much the same thing regardless of authentication backend. You just have to specify the authentication method (userpass in this example) when you issue the auth command:

```bash
#Make sure you don't have another token set (like the root token), because it will take precedence.
unset VAULT_TOKEN
vault auth --method=userpass username=chef
```

# Define Policies
We haven't defined what the policy is, but it does not matter. The policy will be assigned to the user, but it won't give the user any rights. You can use that mechanism to map some external policy system to Vault policy. But we want to create two policies:

| Policy name | Policy rights |
|-------------|---------------|
| manage-cuisine | Full read and write access to cuisine secrets, but not to Vault itself|
| work-cuisine | Read access to cuisine secrets only |

```
vault policy-write manage-cuisine @manage-cuisine-policy.hcl
vault policy-write work-cuisine @work-cuisine-policy.hcl
```

On Linux, I like to use the "herefile" syntax to specify a policy. I will continue to use a platform independant way of working in this tutorial, but here is how you do it:

```
vault policy-write manage-cuisine - << EOF
path "secret/cuisine/*" {
  capabilities = [
        "create",
        "read",
        "update",
        "delete",
        "list"
   ]
}
EOF
```

# Write and read some secrets
Ok, we are ready to write our first secrets! We went to all this trouble, so lets use the "chef" account instead of the root token. 

```bash
#Make sure you don't have another token set (like the root token), because it will take precedence.
unset VAULT_TOKEN
vault auth --method=userpass username=chef
```

## Write a secret
I create two JSON files that list the secret ingredients of French and Indian cuisine. Ok, not a very big secret, but it does show you the flexibility of the key/value secret backend.

Let's persist the secrets with these commands:

```bash
vault write secret/cuisine/indian @indian.json
vault write secret/cuisine/french @french.json
```

The chef's job is done, let's log him out:

```
vault token-revoke --self
```


## Read a secret
Let's login with as a cook and read the secret of French cuisine:

```
vault auth --method=userpass username=cook
vault read secret/cuisine/french
```

