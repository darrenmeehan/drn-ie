---
title: "Raspberry PI SSH Tips"
date: 2020-06-14T11:18:09+01:00
draft: true
# visible: true
---

# Raspberry PI SSH Tips

In this post I'll be sharing some tips to help when using your Raspberry PI.

## What is SSH?

FIXME

## Do you need SSH?

The best way to secure anything in IT is to ensure it doesnt exist in the first place! So before enabling SSH, have a thing about whether you need it or not.

## Enable SSH

Raspberry PIs do not come with SSH enabled by default. This is a good thing!
Enabling SSH opens up your Raspberry PI to a lot of attacks. With the first section of this post I'll cover some tips for ensuring your precious pi is kept safe.



# Security

The inital password is generally something along the lines of `raspberry` - not ideal!! Password based SSH isnt great, here's some reasons why.

Instead of having to remember *another* password (Pro tip: Use a password manager). we'll setup something called a key pair. A keypair consists of a public and private key. As you can guess from their names - we'll keep one secret, like a password. The other one could be public, but we'll just share it with our raspberry pi for now.

FIXME Add some more information on what a keypair is.

To generate these keys we'll use a tool called `openssl`.
