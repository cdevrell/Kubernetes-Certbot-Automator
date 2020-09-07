if ((Test-Path /certbot/certs-to-acquire.txt) -eq $false){
    Write-Error "No certs to aquire"
    break
}

if ((Test-Path /etc/letsencrypt/.well-known/acme-challenge/) -eq $false){
    New-Item /etc/letsencrypt/.well-known/acme-challenge -ItemType Directory -Force
}

if (!(Get-ChildItem /etc/letsencrypt/accounts -ErrorAction SilentlyContinue)){
    Write-Output "Account not registered. Setting up...."
    & certbot register --email $env:EmailAddress --agree-tos --non-interactive
}

$Certs = Get-Content "/certbot/certs-to-acquire.txt"
$certsAlreadyAcquired = Get-ChildItem /etc/letsencrypt/live -ErrorAction SilentlyContinue

foreach($cert in $Certs){
    $cert = $Cert.replace(' ','')
    if (!($certsAlreadyAcquired.Name -contains $cert)){
        & certbot certonly --webroot -w /etc/letsencrypt -d $cert
    }
}

& certbot renew