#!/usr/bin/env bash

hugo

aws s3 sync public s3://drn-ie

aws cloudfront create-invalidation --distribution-id E1COIAH0MYDTYX --paths "/*"

curl -s https://drn.ie > /dev/null