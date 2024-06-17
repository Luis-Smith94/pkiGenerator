<<<<<<< HEAD
# pkiGenerator
A simple bash script that builds one PKI for certificate testing purpose
=======
### Basic PKI Generator
A simple bash script that builds one PKI for certificate testing purpose. It is not recommended to use in a production environment

## Usage
```sh
./gen_pki.sh
How many CA ? $Enter_the_number_of_CA_you_want
Certificate names ? (Client Server Expired Revoked etc...) $Enter_the_names_of_your_certificates
Passphrase for key encryption ? $Strong_Passphrase_for_the_keys
```
Note that if the magic name '**revoked**' or '**expired**' is set, the certificate will be created but invalid. Useful for testing purposes. (It ignores case sensitivity)  
  
## Example
```sh
./gen_pki.sh
How many CA ? 2
Certificate names ? Client Expired Revoked Test
Passphrase for key encryption ? Strongpass321!
```
1 root CA ( root-ca )  
2 CA ( ca1 ca2 )  
4 Certificates for each CA ( Client Expired Revoked Test )  
  

## Needs
- OpenSSL ( Tested on 3.0.7 )
- Expect ( Tested on 5.45.4 )
>>>>>>> 909089c (The initial commit: Add conf files and the scripts)
