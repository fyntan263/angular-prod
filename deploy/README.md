# Deployment

The app is packaged as a Docker image that serves the compiled Angular bundle
via nginx on **port 4200**. On the target server, a host nginx vhost
reverse-proxies `cases.hsc.org.zw` to the container on `127.0.0.1:4200`.

```
Internet ──> cases.hsc.org.zw (host nginx :80/:443)
                     │  proxy_pass
                     ▼
             127.0.0.1:4200  (Docker container: nginx serving Angular SPA)
```

## Files
- `../Dockerfile` – multi-stage build (Node build -> nginx runtime on 4200).
- `nginx-container.conf` – in-container nginx vhost (listens on 4200, SPA fallback).
- `nginx-cases.hsc.org.zw.conf` – host nginx reverse proxy for the domain.
- `deploy.sh` – build, push to registry, pull + run on server, configure nginx.

## One-shot deploy

Prerequisites on the machine running the script: Docker, an authenticated
registry session (`docker login -u fyntan263`), and SSH access to the server.

```bash
export DEPLOY_HOST=<server-ip>       # e.g. 203.0.113.10
export DEPLOY_USER=<ssh-user>        # e.g. ubuntu
export SSH_KEY=~/.ssh/id_ed25519     # optional if using ssh-agent
export IMAGE=fyntan263/angular-prod
export TAG=latest

./deploy/deploy.sh
```

The script will:
1. `docker build` the image.
2. `docker push` it to `fyntan263/angular-prod:latest`.
3. SSH to the server, `docker pull`, and (re)start the container publishing
   `127.0.0.1:4200 -> 4200`.
4. Install the `cases.hsc.org.zw` nginx vhost and reload nginx.

## Manual steps (equivalent)

```bash
# Local
docker build -t fyntan263/angular-prod:latest .
docker push fyntan263/angular-prod:latest

# On the server
docker pull fyntan263/angular-prod:latest
docker run -d --name angular-prod --restart unless-stopped \
  -p 127.0.0.1:4200:4200 fyntan263/angular-prod:latest

sudo cp deploy/nginx-cases.hsc.org.zw.conf /etc/nginx/sites-available/cases.hsc.org.zw
sudo ln -sf /etc/nginx/sites-available/cases.hsc.org.zw /etc/nginx/sites-enabled/cases.hsc.org.zw
sudo nginx -t && sudo systemctl reload nginx
```

## TLS

After DNS for `cases.hsc.org.zw` points at the server and the HTTP vhost is
live, enable HTTPS:

```bash
sudo certbot --nginx -d cases.hsc.org.zw
```

## Verify

```bash
curl -I http://cases.hsc.org.zw/         # expect HTTP 200
curl -I https://cases.hsc.org.zw/        # after certbot
```
