ship:
    echo 'Lets ship!'
    rm -rf public
    zola build
    netlify deploy --prod
