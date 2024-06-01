# drn.ie

This repository powers [drn.ie](https://drn.ie)

## About

The site is generated using [Zola](https://getzola.org) and is currently hosted on Netlify. For more information on changes to this site, check out my site's [about page](https://drn.ie/about/site).

## Development Environment

This is defined using [Nix](https://nixos.org/).

To create a temporary development environment, will all required tools installed run

```shell
nix-shell
```

## Architecture

1. Make changes on laptop
   1. Eventually CMS within private network
2. Save markdown files and push to git
3. Run zola to convert to html - fly app
   1. This could be on laptop for now?
4. Copy html and static files to Internet?
   1. Fly volume?
5. Dockerized app on fly.io should run and server files
   1. I dont want to have to build this each time it starts up
   2. Eventually app should build volume at start up



➜  drn-ie git:(master) ✗ podman build . -f http-cmd.Dockerfile -t http-cmd                                        


podman run -v $(pwd)/content:/app/content:ro -v $(pwd)/public:/app/public http-cmd
