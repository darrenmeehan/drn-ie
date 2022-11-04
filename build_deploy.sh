#!/usr/bin/env bash

hugo

aws s3 sync public s3://drn-ie
