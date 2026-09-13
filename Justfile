# Build the site into public/
build:
    rm -rf public
    zola build

# Live preview with drafts visible
serve:
    zola serve

# Deploy to Fly.io (CI also deploys on push to main)
deploy:
    flyctl deploy -a drn-ie

# Create a new dated draft post: just new-post "My Great Title"
new-post title:
    ./scripts/new-post.sh "{{title}}"