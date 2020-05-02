#!/usr/bin/env bash

hugo -D

aws s3 sync public s3://drn-ie
