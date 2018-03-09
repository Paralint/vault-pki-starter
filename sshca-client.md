# Using Vault to sign SSH certificates of clients

## Configure Vault as an SSH signing authority for clients

To reduce attack surface, almost nothing is mounted by default. You must start by mouting the SSH secret engine. 
We will follow best practice and use an SSH authority for clients and another one for servers. Let's first mount 
the server SSH CA:

```bash
vault secrets enable --path=ssh-client-signer ssh
```

There is not much configuration to do but to make Vault generate its own private key. You will get the public key back. No need to save it, we will get it back from Vault soon. 

```bash
vault write --format=yaml ssh-client-signer/config/ca generate_signing_key=true
```

Here we create a template that will be used to sign certificates for clients.

```bash
vault write ssh-client-signer/roles/clientrole - << EOF
{
  "default_extensions": [
    {
      "permit-pty": ""
    }
  ],
  "key_type": "ca",
  "ttl": "30m",
  "zzzdefault_user": "ubuntu",
  "allow_user_certificates": true,
  "allowed_users": "*"
}
EOF
```

Save Vault's certificate to the server's SSH configuration, for it to trust Vault's signature.

```bash
sudo curl -k $VAULT_ADDR/v1/ssh-client-signer/public_key -o /etc/ssh/trusted-user-ca-keys.pem
echo TrustedUserCAKeys /etc/ssh/trusted-user-ca-keys.pem | sudo tee -a /etc/ssh/sshd_config
```

## Create a role that allows a Linux admin to sign client keys

Signing a client key is seen as an update operation in Vault. We give that right on the path where we will send our public key for signature soon.

```bash
#Vault policy allowing to sign host's SSH key
vault policy write ssh-client-auth - << EOF
path "ssh-client-signer/sign/clientrole" {
  capabilities = [
        "update",
   ]
}
EOF
```

You should never use the root token to sign server certificates, and this time is not an exception. Let's create a role that will allow authorized users to sign their host's SSH key.
Let's simulate that with the userpass authentication backend.

The following command will create:
  - User `user1`
  - Password `user`
  - Policy `ssh-client-configuration` assigned in Vault

```bash
vault write auth/userpass/users/user1 password=user policies=ssh-client-auth
```


Vault is all set now. Let's configure a server.

## Sign the client SSH key

Authenticate with a user that can sign a client key. The root token can do that, 
but you must not run with the root token unless you are configuring Vault itself. 

```bash
#Command to get a token from Vault, enter the password when prompted
vault login --method=userpass username=admin2
```

