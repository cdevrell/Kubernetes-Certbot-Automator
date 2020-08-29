FROM mcr.microsoft.com/powershell:lts-alpine-3.10

RUN apk update && apk add certbot
RUN mkdir /certbot

COPY Get-Certs.ps1 /Get-Certs.ps1
RUN chmod +x /Get-Certs.ps1

CMD [ "pwsh", "-File", "/Get-Certs.ps1" ]
