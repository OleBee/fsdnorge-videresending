# fsdnorge-videresending

GitHub Pages-repo som videresender **fsdnorge.no** → **tadnorge.no**.

## Status

- Workflowen `Redirect to tadnorge.no` bygger redirect-sider fra `OleBee/tesla-fsd-norge` (main) hvert 10. minutt, plus `workflow_dispatch` og push.
- Custom domain **fsdnorge.no** skal **ikke** settes her før cutover (hovedsiden ligger fortsatt på `tesla-fsd-norge` med `fsdnorge.no`).
- Artefaktet inneholder **ingen** `CNAME`-fil før cutover.

## Cutover

Når DNS for `tadnorge.no` peker på GitHub Pages, kjør `/workspace/tadnorge-cutover.sh`. Rekkefølge:

1. DNS for tadnorge.no → GitHub (4× A + www CNAME)
2. `tesla-fsd-norge` bytter CNAME/Pages-domene til tadnorge.no (vent på sertifikat)
3. Dette repoet får Pages-domene fsdnorge.no (+ CNAME-fil)
4. Enforce HTTPS på begge

## Lokalt

```bash
bash scripts/generate-redirects.sh /path/to/tesla-fsd-norge /tmp/redirect-out
```
