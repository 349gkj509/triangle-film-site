# triangle-film-site

Static site for the weekly **Triangle Film Brief**, published at
<https://film.pilesofcr.app>.

Same shape as `construction-dashboard`: a Claude session pushes to `main`, LXC 102
on the homelab pulls every 10 minutes, and Cloudflare serves it through the
`tunnel-of-love` tunnel. Nothing builds; the HTML is the artifact.

## Layout

```
index.html              current week
archive/index.html      list of past weeks, newest first
archive/YYYY-MM-DD.html frozen copy of each week
publish.sh              archive + commit + push
```

`YYYY-MM-DD` is the Friday the week starts on.

## Weekly publish

The Friday 7:00 AM ET brief run does this:

1. Rewrites `index.html` for the new week.
2. Runs the publish script:

   ```bash
   bash publish.sh 2026-07-31 "Week of July 31 - August 6, 2026" \
     "Muppet Movie + Dark Crystal retro double; Rocky Horror at the Rialto"
   ```

   That copies the new index to `archive/2026-07-31.html`, prepends an entry to
   the archive list, commits, and pushes.
3. The container's cron pulls within 10 minutes, so the site is current by about
   7:15.

Doing it by hand is the same three steps; the script only exists so the scheduled
run does it identically every week.

### The one fixup

`index.html` links to the archive as `archive/`. Inside `archive/` that path is
wrong, so the script rewrites it to `./` in the archived copy. If you ever add
another root-relative link to the page, teach `publish.sh` about it too.

### Archive list marker

`archive/index.html` contains `<!-- ARCHIVE-LIST-TOP -->`. New entries go directly
after it. Don't remove it or the script fails loudly rather than silently doing
nothing.

## Serving

See `film-site-runbook.md` in the vault (`TECH & COMPUTING/HOMELAB/`) for the
container and tunnel setup. Short version: `/srv/triangle-film-site` is a clone of this
repo, Caddy serves it on a host-matched block, and `film.pilesofcr.app` is a
public hostname on `tunnel-of-love` pointing at `192.168.1.157:80`.

This repo is public, so the container clones it without a credential and there is
no token sitting in `.git/config`. Caddy still 404s anything under `/.git`, which
costs nothing and keeps the repo's history off the web. Keep that block if you
edit the Caddyfile.

## Checking on it

```bash
curl -sI https://film.pilesofcr.app              # 200
curl -sI https://film.pilesofcr.app/.git/config  # 404
git -C /srv/triangle-film-site log -1            # on the container
```

If the site is stale: `systemctl status caddy`, then compare that `git log`
against GitHub, then `journalctl -u cron | tail`.
