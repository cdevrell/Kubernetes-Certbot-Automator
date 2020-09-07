# Automatically acquire and renew LetsEncrypt certificates through Kubernetes

When running a web server through Kubernetes, this Docker image and CronJob will automtaically check for LetsEncrypt certificates, acquire them if they are not already present, and renew them if they are approaching the expiry date.

This can be ran either as a one off 'Job' or scheduled as a 'CronJob'

## Usage
Clone the repo locally to be able to edit the email address, domains etc.

The Job and CronJob manifests mount a volume to /etc/letsencrypt. This is the default location for certbot to export certificates to.

At present, the manifest file mounts an NFS share located at /ssl but this can be changed to any volume type which supports multiple read/write access.

Within the web server pod, mount this same volume to a volume mount path accessible to the web server. For example /ssl.

The cert and private key should then be accessible within the pod with the path '/ssl/live/DOMAINNAME/fullchain.pem' and '/ssl/live/DOMAINNAME/privkey.pem'

### HTTP challenge
LetsEncrypt is configured to use HTTP to verify ownership of the domain. To do this, it writes a unique file to the path /etc/letscrypt/.well-known/acme-challenge and then checks the URL http://DOMAINNAME/.well-known/acme-challenge for said file. This means the web server needs to be exposed on port 80 for this path. An example on how to do this is available below in the Examples section.

### Manual changes required
#### Specify domains
Within the kubernetes/certbot-automator_configmap.yaml, enter a domain per line for each domain you which to acquire/renew a certificate.

#### Enter email address
Within the kubernetes/certbot-automator_job.yaml or kubernetes/certbot-automator_cronjob.yaml, update the environment variable to include a valid email address.

### One off
To generate or renew a cert as a one off (without having to wait for the next scheduled cronjob), run
~~~
kubectl apply -f kubernetes/certbot-automator_job.yml
~~~

### Scheduled
To automatically generate/renew certs on a schedule, run
~~~
kubectl apply -f kubernetes/certbot-automator_cronjob.yml
~~~
Change the schedule to suit your requirements. Currently this is configured for 1:20am every day.


## Nginx Example
~~~
server {
    listen 80;
    server_name "DOMAINNAME";

    location / {
        return 444; ## Return a 444 so data cannot be accessed over port 80.
    }

    location /.well-known/acme-challenge {
        root /ssl;
    }
}

server {
    listen      443 ssl;
    server_name "DOMAINNAME";

    ssl_certificate /ssl/live/DOMAINNAME/fullchain.pem;
    ssl_certificate_key /ssl/live/DOMAINNAME/privkey.pem;

    # modern configuration
    ssl_protocols TLSv1.3;
    ssl_prefer_server_ciphers off;

    # HSTS (ngx_http_headers_module is required) (63072000 seconds)
    add_header Strict-Transport-Security "max-age=63072000" always;

    # OCSP stapling
    ssl_stapling on;
    ssl_stapling_verify on;

    location / {
        root /www-data;
    }
}
~~~