#!/bin/bash

read -p "Nombre de CA ? " nbCa
read -p "Certs name list ? (Client Server mail) " certList
read -s -p "Passphrase ? " pass

confTemplate=$(ls *.conf)

sed -i 's?$dirPath?'`pwd`'?' $confTemplate


### create self-signed root-ca 
mkdir -p ca/root-ca/private ca/root-ca/db crl certs
chmod 700 ca/root-ca/private
cp /dev/null ca/root-ca/db/root-ca.db
cp /dev/null ca/root-ca/db/root-ca.db.attr
echo 01 > ca/root-ca/db/root-ca.crt.srl
echo 01 > ca/root-ca/db/root-ca.crl.srl

expect -c 'spawn openssl req -new -config root-ca.conf -out ca/root-ca.csr -keyout ca/root-ca/private/root-ca.key ; expect "PEM" ; send "'$pass'\r" ; expect "PEM" ; send "'$pass'\r" ; expect EOF'

expect -c 'spawn openssl ca -selfsign -config root-ca.conf -in ca/root-ca.csr -out ca/root-ca.crt -extensions root_ca_ext ; expect "pass" ; send "'$pass'\r" ; expect "y" ; send "y\r" ; expect "y" ; send "y\r" ; expect EOF'

### create CA
for i in `seq 1 $nbCa`
do
    mkdir -p ca/ca$i/private ca/ca$i/db crl certs/ca$i
    chmod 700 ca/ca$i/private

    cp /dev/null ca/ca$i/db/ca$i.db
    cp /dev/null ca/ca$i/db/ca$i.db.attr
    echo 01 > ca/ca$i/db/ca$i.crt.srl
    echo 01 > ca/ca$i/db/ca$i.crl.srl


    cp ca.conf ca$i.conf
    sed -i s'/$caName/ca'$i'/'g ca$i.conf
    expect -c 'spawn openssl req -new -config ca'$i'.conf -out ca/ca'$i'.csr -keyout ca/ca'$i'/private/ca'$i'.key  ; expect "PEM" ; send "'$pass'\r" ; expect "PEM" ; send "'$pass'\r" ; expect EOF'

    expect -c 'spawn openssl ca -config root-ca.conf -in ca/ca'$i'.csr -out ca/ca'$i'.crt ; expect "pass" ; send "'$pass'\r" ; expect "y" ; send "y\r" ; expect "y" ; send "y\r" ; expect EOF'
    cat ca/ca$i.crt >> ca/chain.pem

    ### create Final CERT
    for certName in ${certList[@]}
    do
        if [[ ${certName^^} == *"EXPIRED"* ]]
        then 
            expect -c 'spawn openssl req -new -config cert-tls.conf -out certs/ca'$i'/CERT'$i'_'$certName'.csr -keyout certs/ca'$i'/CERT'$i'_'$certName'.key ; expect "certName" ; send "CERT'$i'_'$certName'\r" ; expect EOF ' 
            expect -c 'spawn openssl ca -config ca'$i'.conf -in certs/ca'$i'/CERT'$i'_'$certName'.csr -out certs/ca'$i'/CERT'$i'_'$certName'.crt --enddate 201001010000Z ; expect "pass" ; send "'$pass'\r"  ; expect "y" ; send "y\r" ; expect "y" ; send "y\r" ; expect EOF '
        elif [[ ${certName^^} == *"REVOKED"* ]]
        then   
            expect -c 'spawn openssl req -new -config cert-tls.conf -out certs/ca'$i'/CERT'$i'_'$certName'.csr -keyout certs/ca'$i'/CERT'$i'_'$certName'.key ; expect "certName" ; send "CERT'$i'_'$certName'\r" ; expect EOF ' 
            expect -c 'spawn openssl ca -config ca'$i'.conf -in certs/ca'$i'/CERT'$i'_'$certName'.csr -out certs/ca'$i'/CERT'$i'_'$certName'.crt ; expect "pass" ; send "'$pass'\r"  ; expect "y" ; send "y\r" ; expect "y" ; send "y\r" ; expect EOF ' 
            revokedSN=$(cat ca/ca$i/db/ca$i.db | grep -i revoked | cut -f4)
            expect -c 'spawn openssl ca -config ca'$i'.conf -revoke ca/ca'$i'/'$revokedSN'.pem -crl_reason unspecified ; expect "pass" ; send "'$pass'\r" ; expect EOF'
        else   
            expect -c 'spawn openssl req -new -config cert-tls.conf -out certs/ca'$i'/CERT'$i'_'$certName'.csr -keyout certs/ca'$i'/CERT'$i'_'$certName'.key ; expect "certName" ; send "CERT'$i'_'$certName'\r" ; expect EOF ' 
            expect -c 'spawn openssl ca -config ca'$i'.conf -in certs/ca'$i'/CERT'$i'_'$certName'.csr -out certs/ca'$i'/CERT'$i'_'$certName'.crt -extensions server_ext ; expect "pass" ; send "'$pass'\r"  ; expect "y" ; send "y\r" ; expect "y" ; send "y\r" ; expect EOF '
        fi
    done

    ### create global CRL
     expect -c 'spawn openssl ca -gencrl -config ca'$i'.conf -out crl/ca'$i'.crl ; expect "pass" ; send "'$pass'\r" ; expect EOF '
done

### Create Global CA Chain
cat ca/root-ca.crt >> ca/chain.pem


rm -f certs/*.csr

sed -i s?`pwd`?'$dirPath'? $confTemplate