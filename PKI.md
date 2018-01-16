# Mount the PKI secret backend (as the root CA)
Vault natively supports PKI operations. It is not as full featured as other commercial PKI like Microsoft Certificate Services or EJBCA, but it is much simpler to use and more secure than a scripted `openssl`.

We will mount 2 PKI back ends:

 1. The root CA, which will be offline most of the time (mounted at rootCA)
 2. The issuing CA, which will produce the certificates (mounted at issuingCA)

## Mount and configure the root CA

```bash
#You have a valid Vault root token for this
vault mount --path=rootCA pki
vault mount --path=issuingCA pki
```

We then create the root CA key and self signed certificate. Note that the root CA private key will not be exported. It will never leave Vault and that's a good thing.

```bash
#Create the root CA self signed private key (good for about 25 years)
vault write --format=yaml rootCA/root/generate/internal common_name=root.paralint.test ttl=220000
```

We set some default metadata to go in the certificates. These can be changed later. These URL are used by client to retrieve the current list of revoked certificate. 

```bash
vault write rootCA/config/urls issuing_certificates="http://www.paralint.test/v1/rootCA/ca" crl_distribution_points="http://www.paralint.test/v1/rootCA/crl"
```

And create a role that will allow to request certificates.

```bash
vault write rootCA/roles/manage-paralint-test allowed_domains=paralint.test allow_subdomains=true max_ttl=72h
```

## Mount and configure the issuing CA
The issuing CA is much like the root CA. Creating it will export CSR that we will send to the root CA for signature.

Let's go through all of the commands at once to setup the issuing CA:

```bash
#Create the issuing CA self signed private key. Output only the CSR
vault write --field=csr issuingCA/intermediate/generate/internal common_name=issuing.paralint.test > issuing.csr
#Set default CRL URLs
vault write issuingCA/config/urls issuing_certificates="http://www.paralint.test/v1/pki/issuign/ca" crl_distribution_points="http://www.paralint.test/v1/pki/issuign/crl"
#Create a policy, and make an absolute upper bound of about 2 years for a certificate
vault write issuingCA/roles/manage-paralint-test allowed_domains=paralint.test allow_subdomains=true max_ttl=18000h
```

```bash
vault write --format=yaml rootCA/root/sign-intermediate csr=@issuing.csr
```

