name: certificates
class: middle, center
=======
# What makes certificates so special (compared to regular keys and passwords)?

---
# What is a certificate
A certificate is a proof of your identity. 
In computer terms, it prooves that you have a **private** key.

---
# What is it used for
Certificates prove your identity to a third party that shares a common trustee with you.

You don't need prior arrangement. 

Futur entities will be able to identify you if they decide to use the same trustee





---

# Old-school certificate process

1. Generate a key pair 
 - Public that everyone will see
 - Private that **only the owner** will see

1. Generate a certificate signing request (CSR)
 - Prove that you own the private key, without sending it

1. Wait for the Certificate Authority to issue a certificate
 - The CA will sign your public key 

1. Configure your web server to use the private key and certificate

1. Goto 1 every year or so... Don't forget!



---
# Who/What should generate the key ?

Private key **can be exported** unless it is on a smartcard
 - If you can use the key, you can export it (iSECPartner's [jailbreak](https://github.com/iSECPartners/jailbreak))
 - Using smartcards is not pratical unless you are on bare metal

Private key reuse is a handy Wireshark hack
 - Most CA don't check for that
 - It lowers security

Vault can do both
 - Generate the private key and certificate at once
 - Sign a certificate request


---
# Link Vault to your corporate PKI

Your Public Key Infrastructure (PKI) looks like this:
 - A Root Certificate Authority (CA) is used only to sign the Issuing CA's certificates
 - Issuers are the ones actually giving out certificates

Vault will create a CSR, for your PKI CA to sign
 - Old school, long lived certificate, not automated
 - Root CA are usually offline and revived every 2 years, plan accordingly

Vault will be another issuer of your PKI
 - You will need to push the certificate to your corporate desktops


---
# Prepare the PKI backend

Mount the backend
```
vault secrets enable --path=issuer pki
```

Set the URL that will be put in the issued certificates 
```
vault secrets enable --path=issuer pki
vault write issuer/config/urls \
   issuing_certificates="http://localhost:8200/v1/issuer/ca" \
   crl_distribution_points="http://localhost:8200/v1/issuer/crl" \
   ocsp_servers="http://localhost:8200/v1/issuer/ocsp"
```

---
# Create key pair and Certificate Signing Request
```
vault write --field=csr issuer/intermediate/generate/internal \
   common_name=devops-issuer.paralint.lab | tee devops-request.csr
```

---
# Give Vault its certificate
Have it signed by your certificate authority
Add the certificate to Vault

```
#FIXME
vault write issuer/intermediate/set-signed certificate=@devops-cert.pem
```


---
# Define your certificate template (aka Role)

About one template per use case
 - HTTPS for internal applications
 - Email signature
 - User authentication

Template looks like this:

```
```

# Add it to Vault


---
# Issue a certificate and use it

You must be authenticated
Post a hostname to Vault and the get the goods right back
How to use it is up to you
 - Your platform might know how to automate this


---
# Renew a certificate

You don't really renew a certificate, you get a new one

Should you revoke the certificate you are replacing? 
 - Certificates are short lived
 - What happens if you restore a backup?

                                                                
---
# Certificate revocation

The hard part about revocation, is when to do it

You just post the certificate serial number to Vault API

You will likely have this endpoint restricted


---
# Permissions

Use Vault path based ACL, like you would for anything else

||Task||Performed by||Vault path||
| Mount the PKI backend | Vault Root token | sys/mount |
| Create/Update a certificate template | Security administrator | pki/roles/:name |
| Issue a certificate | Infrastructure | pki/issue/:name pki/sign/:name |
| Revoke a certificate | Security Administrator | pki/revoke/ |

In this talk, `pki` was replaced by `issuer`


---
# Integrating with Kubernetes cert-manager

Define an `issuer` resource

```
apiVersion: certmanager.k8s.io/v1alpha1
kind: Issuer
metadata:
  name: vault-issuer
  namespace: default
spec:
  vault:
    path: pki_int/sign/example-dot-com
    server: https://vault.paralint.lab
    caBundle: <base64 encoded caBundle PEM file>
    auth:
      appRole:
        path: approle
        roleId: "291b9d21-8ff5-..."
        secretRef:
          name: cert-manager-vault-approle
          key: secretId
```

