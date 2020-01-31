class: middle, center
# What makes certificates so special (compared to regular keys and passwords)?

Hello, World!

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

1. Goto 1 every 2 years or so... Don't forget!

---

# Who/What should generate the key ?

Private key **can be exported** unless it is on a smartcard
 - If you can use the key, you can export it (iSECPartner's [jailbreak](https://github.com/iSECPartners/jailbreak))
 - Using smartcards is not pratical unless you are on bare metal

Private key reuse is a handy Wireshark hack
 - Most CA don't check for that
 - It lowers security

Vault can generate the private key and certificate at once


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
# Issue a certificate and use it

---
# Renew a certificate

---
# Permissions

---
# Certificate templates

---
# Keeping the private key private

---
# Certificate revocation

