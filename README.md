# tekeche

Marketing website for Tekeche — a ride-hailing service in Ivory Coast. Static HTML/CSS/JS, served by IIS on Windows Server, auto-deployed via GitHub Actions.

## Stack

- **Static HTML** — no build step, no framework
- **IIS** (Windows Server) — web server
- **GitHub Actions** — auto-deploy on push to `main` (self-hosted runner)

## Pages

| File | URL |
|---|---|
| `index.html` | `/` — home |
| `chauffeur.html` | `/chauffeur` — driver landing page |
| `a-propos.html` | `/a-propos` — about |
| `contact.html` | `/contact` — contact form |
| `blog.html` | `/blog` |
| `cgu.html` | `/cgu` — terms of service |
| `confidentialite.html` | `/confidentialite` or `/privacy` |
| `cookies.html` | `/cookies` — cookie policy |
| `suppression-compte.html` | `/suppression-compte` or `/delete-account` |
| `presse.html` | `/presse` — press |
| `admin.html` | `/admin` |
| `404.html` | Custom 404 error page |
| `500.html` | Custom 500 error page |

## Project structure

```
css/
  style.css         global styles
  chauffeur.css     driver page styles
  contact.css       contact page styles
js/
  main.js           shared scripts
assets/
  favicon.svg
web.config          IIS URL rewriting, MIME types, HTTPS redirect, custom errors
.github/workflows/
  deploy.yml        auto-deploy on push to main
```

## Deployment

Pushes to `main` are automatically deployed to the IIS server via a self-hosted GitHub Actions runner:

```
push to main → GitHub Actions → git pull on server → live
```

The server is at `C:\inetpub\wwwroot\tekeche` and serves `tekeche.com`.

## URL rewrites (web.config)

- `/privacy` → `/confidentialite.html`
- `/delete-account` → `/suppression-compte.html`
- HTTP → HTTPS redirect for `tekeche.com` and `www.tekeche.com`
