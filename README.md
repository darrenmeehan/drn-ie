# drn.ie

This repository powers [drn.ie](https://drn.ie).

## Stack

- **Zola** (pinned **0.23.6**) builds the static site from `content/`, `templates/`, `sass/`.
- A small **Rust server** (`src/main.rs`) serves `/app/public` on **[Fly.io](https://fly.io)** with a custom `x-source` header. Pushing to `main` builds and deploys automatically (`.github/workflows/build.yaml`).
- No CMS: content is markdown + git. (`static/admin/` Decap and `.pages.yml` Pages CMS were removed.)

## Publishing content

1. `just new-post "My Post Title"` — creates `content/posts/YYYY-MM-DD-my-post-title.md` with `draft: true`.
2. Edit the file. Add images to `static/images/` and reference them from front matter or the body.
3. `just serve` — preview locally on <http://localhost:1111> (drafts visible), then flip `draft: false` when ready.
4. `git push` — CI deploys to Fly.io.

Other commands: `just build` (dry run), `just deploy` (deploy without pushing, needs `flyctl`).

Content lives in `content/posts`, `content/dives`, `content/photos`, `content/pages`, and `content/*/index.md` pages.

## Deploying

The app is [drn-ie](https://fly.io) on Fly.io; `fly.toml` and the `Dockerfile` define the ship (Rust server + Zola-built site, in one image). Two routes:

**One-time setup**

1. Fly access: `flyctl auth login` (browser login to the Fly account that owns `drn-ie`).
2. Let CI deploy for you: `flyctl auth token` → GitHub → repo `drn-ie` → **Settings → Secrets and variables → Actions** → add secret `FLY_API_TOKEN` (skip if it already exists).

**Route A — normal path (CI deploys on push to `main`)**

```sh
just build       # sanity check before pushing
# or locally: flyctl deploy -a drn-ie (Route B)
git push origin <branch>   # then merge/PR into main
```

Pushing to `main` triggers [`.github/workflows/build.yaml`](.github/workflows/build.yaml), which runs `flyctl deploy -a drn-ie`.

**Route B — deploy directly**

```sh
just deploy   # = flyctl deploy -a drn-ie
```

Builds the image locally and ships it without touching git.

**Notes**

- First deploy is slower: the image downloads `rust:1.96-bookworm` and compiles the crates from scratch (a few extra minutes once); later deploys reuse layer caches.
- Once the new image is live, `/admin` 404s (CMS removed) and the old duplicate footer disappears — those are the changes landing.
- Troubleshooting: `flyctl logs -a drn-ie` tails the server log (file appender writes to `log/`).

## Development environment

Defined with [Nix](https://nixos.org/):

```shell
nix-shell
```

A Containerfile-based devcontainer (`.devcontainer/`) with the same toolchain is also available.

### Pinned versions

| Tool | Version | Pin note |
| --- | --- | --- |
| Zola | 0.23.6 | Fetched as the official release tarball (sha256-verified) in `shell.nix` (temporary override), `.devcontainer/Dockerfile`, and the `Dockerfile` build stage. Disposable once [NixOS/nixpkgs#562808](https://github.com/NixOS/nixpkgs/pull/562808) merges upstream — then delete the `shell.nix` override. |
| Rust | 1.96 | `rust:1.96-bookworm` build stage + devcontainer base. |

## Local build & serve details

- `config.toml`: `base_url = "https://drn.ie"`, syntax highlighting off (no `[markdown.highlighting]` table).
- Records are dated (`YYYY-MM-DD-` prefix); `draft: true` keeps a post out of prod builds.
