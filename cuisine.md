# Cuisine secrets
## Mount a username/password backend
There are multiple authentication backends. To reduce dependencies for this sample, lets use Vault own username-password storage

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


