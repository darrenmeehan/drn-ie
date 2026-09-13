+++
title = "About this site"
template = "page.html"
+++

Built with [Zola](https://getzola.org) and served by a small Rust server ([src/main.rs](https://github.com/darrenmeehan/drn-ie)), hosted on **Fly.io**.

Publishing is plain markdown + git. `just new-post "Title"` scaffolds a draft, `just serve` previews it locally, and pushing to `main` deploys automatically via GitHub Actions (`flyctl deploy`). No CMS — the workflow is documented in the [README](https://github.com/darrenmeehan/drn-ie).

Development environment is [Nix](https://nixos.org/) (`nix-shell`) or the devcontainer (`.devcontainer/`), both with the same toolchain.

## Credit

This section is vastly out of date. I've taken inspirations from lots of places. I'll endevour to reference and thank them more!

- [How images are displayed on dive logs](https://12daysofweb.dev/2021/image-display-elements/)
- [Various CSS tips](https://moderncss.dev/)
