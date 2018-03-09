# Using Vault to sign SSH certificates of servers

## Configure Vault as an SSH signing authority for servers

To reduce attack surface, almost nothing is mounted by default. You must start by mouting the SSH secret engine. 
We will follow best practice and use an SSH authority for servers and another one for clients. Let's first mount 
the server SSH CA:

```bash
vault secrets enable --path=ssh-host-signer ssh
```

There is not much configuration to do but to make Vault generate its own private key. You will get the public key back. No need to save it, we will get it back from Vault soon. 

```bash
vault write --format=yaml ssh-host-signer/config/ca generate_signing_key=true
```

You will also want to tweak the duration of the server certificates. Here I've put an upper limit of 10 years.

```bash
vault secrets tune --max-lease-ttl=87600h ssh-host-signer
```

Here we create a template that will be used to sign certificates for hosts in the current domain (as returned by `hostname --domain`).

```bash
#Defaults to using your configured domain or localdomain. Adjust to your reality
vault write ssh-host-signer/roles/hostrole - << EOF
{
    "key_type":"ca",
    "ttl":"87600h",
    "allow_host_certificates":"true",
    "allowed_domains":"localdomain,$(hostname --domain)",
    "allow_subdomains":"true"
}
EOF
```

## Create a role that allows a Linux admin to sign host keys

Signing a server key is seen as an update operation in Vault. We give that right on the path where we will send our public key for signature soon.

```bash
#Vault policy allowing to sign host's SSH key
vault policy write ssh-host-configuration - << EOF
path "ssh-host-signer/sign/hostrole" {
  capabilities = [
        "update",
   ]
}
EOF
```

You should never use the root token to sign server certificates, and this time is not an exception. Let's create a role that will allow authorized users to sign their host's SSH key.
Let's simulate that with the userpass authentication backend.

The following command will create:
  - User `admin1`
  - Password `admin`
  - Policy `ssh-host-configuration` assigned in Vault

```bash
vault write auth/userpass/users/admin1 password=admin policies=ssh-host-configuration
```


Vault is all set now. Let's configure a server.

## Sign the host SSH key

Authenticate with a user that can sign a host key. The root token can do that, 
but you must not run with the root token unless you are configuring Vault itself. 

```bash
#Command to get a token from Vault, enter the password when prompted
vault login --method=userpass username=admin1
```

Sign the host key with this command, and save the resulting certificate in a file. If you use the default paths, this command should work on every server.

```bash
#Sign the host key
vault write -field=signed_key ssh-host-signer/sign/hostrole cert_type=host public_key=@/etc/ssh/ssh_host_rsa_key.pub > ssh_host_rsa_key-cert.pub
#Save the certificate
sudo mv ssh_host_rsa_key-cert.pub /etc/ssh/ssh_host_rsa_key-cert.pub
sudo chmod 0640 /etc/ssh/ssh_host_rsa_key-cert.pub
#Add the certificate to the configuration
echo HostCertificate /etc/ssh/ssh_host_rsa_key-cert.pub | sudo tee -a /etc/ssh/sshd_config
```

You must **restart `sshd`** service for the changes to take effect.

Note : if you received a host certificate via email, you can sign it with a copy and paste using this command:

```bash
#If you do not perform the signature right on the server, pass the public key on the command line
vault write --format=yaml ssh-host-signer/sign/hostrole cert_type=host "public_key=ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDL0UEP8PybLSAzEJJ/u7gTacsp/of4Yzil9aP718FX6qsl7Ym73DTN3CASNSiNDo5dCssLwH3paLgqIx3b8lQd4sNMG1cmavFIP6+L5aeImJ+y7VNdjn87uv/DlnsSzWtuxacfPb48202DkGtWKSQc0jGf0eF971Q7i7LtUuTTjnBMCq68BdojZa2aVLYy/SUP0+L+Y7vEiVtjgqjVlyNwBOTbp3BRxyswsRuSeI8iqx8L35sftl38LAVFuVfahf0oV36D+23I9ylt51BtDnzUDFFylKUZ9yDEEYlEQi11K6qo6kYo8gNFfukEhuU9wM7oMN/QtNe7pBRt5I+sncCR"
```

## Prepare the client

## Mount the SSH secret engine

We mount a second instance of the the SSH secret engine that will be used to sign client's public keys. These commands must be run with the root token.

```bash
vault secrets enable --path=ssh-client-signer ssh
```

### Add Vault SSH server signing certificate to your client's configuration

```bash
mkdir -p ~/.ssh
echo "@cert-authority *.$(hostname --domain) $(curl -s $VAULT_ADDR/v1/ssh-host-signer/public_key)" >> ~/.ssh/known_hosts
```

Everything is in place now for the client to trust a public key it never saw, because it is now signed by Vault.


