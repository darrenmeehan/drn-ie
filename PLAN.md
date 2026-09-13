# Plan: Update drn.ie dependencies + make content publishing easy

Status: **implemented 2026-09-13** (see §9 for how it landed and deviations).
Date: 2026-09-13

## 1. Current state (verified this session)

**Stack**

- Static site built with **Zola**, custom theme in `templates/` + `sass/`, content in `content/` (posts, dives, photos, pages).
- Served by a small **Rust binary** (`src/main.rs`, ~80 lines: axum/tower-http ServeDir + custom `x-source` header, file logging) running on **Fly.io** (live: `server: Fly/...`, `x-source: github.com/darrenmeehan/drn-ie`).
- Deploy: push to `main` → `.github/workflows/build.yaml` → flyctl deploy → Dockerfile: build Rust binary + `zola build` in a custom image, runtime Ubuntu 25.04, serves `/app/public`.
- **No CMS** (decision: both the Decap CMS at `static/admin/` and the half-finished Pages CMS config (`.pages.yml`) get **deleted**). Publishing is plain markdown + git push.

**Version drift (inconsistent Zola across environments)**

| Where | Zola version |
| --- | --- |
| `shell.nix` (nixos-unstable) | **0.23.4** — nixpkgs lags upstream (verified with `nix eval`; PR NixOS/nixpkgs#550565) |
| `.devcontainer/Dockerfile` | **0.18.0** (Sep 2023) |
| Docker build image `darrenmeehan42/zola-rust:images` | unknown, ~June 2025 |
| **Target pin everywhere** | **0.23.6** — latest GitHub release (user-confirmed) |

**Verified problems**

1. **Site does not build on latest Zola.** `zola build` with 0.23.4 fails:
   `config.toml` line 24: `highlight_code = false` → unknown field, expected `highlighting`. The repo has never been migrated past ~0.19 config schema.
2. **The CMS never worked on Fly.io.** Decap backend is `git-gateway` (Netlify-specific, needs Netlify Identity — `admin/index.html` loads `netlify-identity-widget.js`), but the site is served by Fly. Nothing could log in. **Decision: delete both CMS attempts** — `static/admin/` (Decap) and `.pages.yml` (Pages CMS) — publishing is markdown + git push.
3. **Branch mismatch (dead config).** Decap config says `branch: master`; the repo's default branch is `main`.
4. **Leftover/dead config.** README says "hosted on Netlify" (live host is Fly). `Justfile` ships to Netlify. `config.toml` has a commented `[context.deploy-preview]` block (Netlify). `.github/workflows/rust.yml` builds against a Postgres service ("scones") that nothing in `src/` uses.
5. **Actions are stale.** `actions/checkout@v2`, `superfly/flyctl-actions/setup-flyctl@master` (unpinned); rust.yml uses ancient bundles vs the active deploy workflow.
6. **Crate deps unpinned to patch level** (Cargo.toml pins majors only) — fine, but nothing has confirmed they still compile against latest tower/axum/tokio patch releases.

## 2. Goals

- One consistent, pinned toolchain (Zola + Rust) across devcontainer, nix, Docker, CI.
- Site builds cleanly with no warnings on the pinned Zola.
- A publishing path I actually *use*: edit → preview locally → merge → auto-deploy. Zero manual steps.
- The CMS works where the site is actually hosted (or is removed, replaced by a dead-simple git flow) — no Netlify-specific pieces on a Fly-hosted site.
- Docs (README, Justfile, workflow) describe the real deploy target and real commands.

## 3. Phase 1 — Dependencies (do this first, it's mechanical)

1. **Pin Zola 0.23.6 everywhere** (latest GitHub release; note nixpkgs only ships 0.23.4, so nix needs an override too):
   - `.devcontainer/Dockerfile`: replace the 0.18.0 .deb install with the official **0.23.6** release tarball (`zola-v0.23.6-*-linux-x86_64.tar.gz` from getzola/zola releases; the `zola-debian` repo lags).
   - `Dockerfile` (build stage): stop relying on the mystery `darrenmeehan42/zola-rust:images` tag. Either bump that image to a tagged Zola version, or (simpler) add a small build stage that fetches the pinned 0.23.6 zola binary into the image. Keep `images`-base only if it also provides something else we use.
   - `shell.nix`: nixpkgs is at 0.23.4, so add a small `zola` override that fetches the official 0.23.6 binary tarball (stdenv mkDerivation, ~15 lines) instead of relying on nixos-unstable. Keeps all three environments on exactly 0.23.6. **Temporary** — an automatic bump PR is already open upstream ([NixOS/nixpkgs#562808](https://github.com/NixOS/nixpkgs/pull/562808), `zola: 0.23.4 → 0.23.6`, opened 2026-09-13 by the nixpkgs-update bot, verified + merge-bot eligible). Once it merges, upstream nixpkgs ships 0.23.6 and this override gets deleted — don't bother maintaining it beyond that.
   - State the pin in `README.md`.
2. **Migrate `config.toml` to current schema**: `highlight_code` → `highlighting` (check the settings table in Zola docs for the equivalent config, e.g. `highlight_theme`/`highlighting_theme` renames) and re-run `zola build` until clean at 0.23.6. Delete the commented Netlify `DEPLOY_PRIME_URL` block.
3. **Rust deps**: run `cargo update` + `cargo build` in nix shell; bump majors deliberately if tower/axum/tokio released breaking versions (check `cargo outdated`/docs per crate). Keep the deprecated-feature list in Cargo.toml honest — `cargo build` will flag feature renames.
4. **GitHub Actions**:
   - `build.yaml`: `actions/checkout@v4`, pin `superfly/flyctl-actions/setup-flyctl` to a release tag (not `@master`).
   - `rust.yml`: this is cruft from a different app (Postgres "scones" DB, no consumer in `src/`). Recommend **delete**; if kept, strip the DB service and pin to stable toolchain.
5. **Devcontainer**: drop Node + netlify-cli install (only there to support the Netlify deploy we're removing) once the Justfile no longer deploys to Netlify. Keep `just`.
6. **Delete both CMSes**: remove `static/admin/` (Decap: `config.yml` + `index.html` + the Cloudinary API key in the repo) and `.pages.yml` (Pages CMS). `/admin` then 404s — no login surface, no keys in the repo, nothing to maintain.

## 4. Phase 2 — Publishing workflow (the actual ask)

### The publishing problem

Today: write markdown → commit → push → Dockerfile rebuild (cargo build + zola build) on Fly. The admin UI was the intended fix but is dead on Fly (netlify-git-gateway) — and the CMSes never got the wiring (identity/OAuth/branch) they needed, which is exactly the kind of ceremony that rots.

### Decision: no CMS

Both CMSes (Decap, Pages CMS) get deleted. The publishing path is the one that already works, made frictionless:

1. `just new-post "Title"` → a dated markdown file with correct front matter, `draft: true`.
2. `just serve` → local live preview (drafts visible) to review the post.
3. `git push` → CI builds with pinned Zola and ships to Fly. Done.

Zero services, zero OAuth apps, zero keys in the repo, zero admin surface. The section below is now required work instead of an option.

**Trade-off, stated plainly:** no more editing from a phone browser. If that ever matters again, the Decap GitHub-OAuth setup is ~30 min of work on top of the branch-fixed repo — the plan removes it cleanly so it can be re-added later without untangling anything.

## 5. Phase 3 — Make the repo itself publish-friendly

1. **`Justfile` recipes** (replacing the Netlify `ship`):
   - `just new-post "Title"` → creates `content/posts/YYYY-MM-DD-title.md` with correct front matter (template, date, title, `draft: true`). Same for `dives`/`photos` if wanted.
   - `just serve` → `zola serve` (live preview at localhost with drafts visible).
   - `just build` → clean `zola build`.
   - `just deploy` → `flyctl deploy` (or keep deploying via git push; then this is just a doc'd no-op — pick one primary path and say so in README).
2. **Content conventions, documented once** (in README):
   - Slug rule (`YYYY-MM-DD-slug.md`).
   - `draft: true` for work-in-progress (Zola hides drafts outside `zola serve`), then flip to `draft: false` to publish. Also sweep the old `# visible: true` comments out of content files — `visible` is a CMS-only field that means nothing to Zola.
3. **Docs fixes**: README "hosted on Netlify" → "built by Zola, served by a Rust binary on Fly.io"; show the three-command workflow (`just new-post …`, `just serve`, push). Note `/admin` is gone.

## 6. Verification checklist (run before calling this done)

State: ✅ done locally / ⬜ needs a deploy to prove.

- [x] `zola build` clean (no errors/warnings) at pinned 0.23.6, in all three environments (nix `nix-shell`, Docker `Dockerfile` stage, devcontainer image — all built and verified 0.23.6).
- [x] `cargo build --release` clean; local `drn-ie` serves the built site with `x-source` header.
- [x] `draft: true` posts absent from the prod build (`public/posts`), present via `zola serve`.
- [ ] Fly deploy from CI works on push to `main`; old Netlify envs (`NETLIFY_*`) not required anywhere. *(needs FLY_API_TOKEN — happens at next push)*
- [x] `static/admin/` and `.pages.yml` deleted; `git ls-files` shows no CMS configs and no Cloudinary key.
- [x] `/admin` returns 404 (verified in the local container smoke test).
- [x] `git ls-files | grep -i -E 'netlify|decap|pages.yml'` matches only the two historical post slugs (content, not config).
- [ ] CI is green on a fresh PR. *(needs push)*

**Follow-up (when NixOS/nixpkgs#562808 merges):** delete the `shell.nix` zola override (upstream nixpkgs then provides 0.23.6), verify `nix-shell` still resolves to 0.23.6, and note the removal in the README pin line.

## 7. Non-goals (declined on purpose)

- CMS of any kind (Decap/Pages CMS re-added later would be a fresh, 30-min GitHub-OAuth setup on the now-clean repo) — revisit only if the personal-use scale outgrows markdown + git push.
- Search index, emoji rendering, or any content-format expansion.
- Moving hosts (Fly keeps working; file the pages.dev move as a future idea, not part of this).
- Rewriting the Rust server (it works; only dependency bumps).

## 8. Open questions before execution

1. Images: **drop static/media files into `static/images/`** going forward (repo keeps working without Cloudinary)? Old posts keep working — they reference Cloudinary URLs directly as links. Or is there a reason to keep using Cloudinary for new images?
2. Delete `rust.yml`? (It tests a Postgres service nothing uses — I recommend yes.)
3. Primary deploy path: git-push-triggered (current) — keep that as the one way, or also expose `just deploy`?

## 9. Implementation notes (what actually happened, deviations from plan)

Resolved on the day: **Q1** → new images go in `static/images/` (README documents it; old posts keep their Cloudinary URLs). **Q2** → `rust.yml` deleted. **Q3** → git push stays the one real deploy path; `just deploy` is a `flyctl` convenience wrapper.

1. **Zola release asset renamed** upstream: `zola-v0.23.6-x86_64-unknown-linux-gnu.tar.gz` (not `x86_64-linux`). sha256 `8f5132b3…024a4` verified on download and pinned in `shell.nix`, `.devcontainer/Dockerfile`, and the `Dockerfile` site-build stage. The binary is glibc-dynamic, so the Docker site-build stage uses `debian:bookworm-slim`.
2. **Config migration**: `highlight_code` has no boolean equivalent — `[markdown.highlighting]` is now an `Option<Highlighting>` struct that errors if present without a theme, so the fix is *omitting* the table entirely (syntax highlighting stays off, matching the old `highlight_code = false`).
3. **Tera 0.23 forced a template migration** (the build failed on it): removed top-level `<title>` wrappers around `{% block title %}` in `blog-page.html`, `blog.html`, `dive.html`, `photo.html`; removed redundant top-level `{% include "footer.html" %}` in `blog-page.html`, `dive.html`, `dives.html`, `photo.html` (base.html already includes it — the live site was rendering the footer **twice**); `is matching("...")` → `is matching(pat="...")` in `gallery.html`; stripped the dead Netlify-Identity script from `base.html` and `index.html`.
4. **Rust server**: `ServeDir::new("/app/public")` → `ServeDir::new(&args.content_path)` — the CLI arg existed but was ignored; no behavior change on Fly (CMD passes `/app/public`), but relative paths don't resolve, so run it with an absolute path locally.
5. **Deps**: `cargo update` bumped axum → 0.7.9 et al.; `cargo build --release` clean in 3m22s (local rustc 1.96). Dockerfile rust stage pinned to `rust:1.96-bookworm` (matches the machine toolchain).
6. **Devcontainer**: Node 20 + netlify-cli + NodeSource PPA removed; wget → curl for the zola fetch.
7. **Verification done**: nix-shell → zola 0.23.6 + `just --list`; Docker image builds (zola sha verified, 16 pages + 3 sections); container smoke: `/` 200 + `x-source` header, `/admin/` 404, posts 200, page title override correct, single footer; devcontainer image builds with zola 0.23.6 + just 1.58; `just new-post` scaffolds and a test file was created + removed. Remaining: Fly deploy + prod `/admin` check happen on the first push.
8. The live site was **not** deployed — push to `main` when ready (CI deploys). The current prod still runs the old image until then.
