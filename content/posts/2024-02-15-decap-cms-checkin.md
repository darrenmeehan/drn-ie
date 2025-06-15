---
template: blog-page.html
# visible: true
title: "Decap CMS Checkin "
date: 2024-02-15T06:41:46.218Z
draft: true
extra:
  images:
    - https://res.cloudinary.com/difx30h6p/image/upload/v1707980010/2024-02-15-13-53-05-969_qene6e.jpg
---
I'm still using Decap CMS.

I'm still ironing outsome issues with it, there's elements I really like, and as with all software, elements I dislike.

As I write this post (on a squashed, bumpy bus on Thailand!) I'm mainly thinking about authentication to the site. To make setup easier I used Netlify's Indentity service. I eventually want to move the admin portion of this site into an internal network, and off the public facing Internet.
Another limitation I currently have is people contributing to the site need to have a Github account. 

I'm not sure where I'll end up with what I'm building, but the current plan looks like this. 

1. Build my own Github OAuth provider for logging into DecapCMS
2. Add other IdP to my new identity provider, while still allowing Decap access to my git repository. 
3. Consider building out IndieAuth for authorisation, mainly for fun. Might be useful for other capabilites at some point.. This is more outside the CMS, such as private posts, commenting. 
