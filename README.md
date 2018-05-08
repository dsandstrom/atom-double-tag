# Double Tag

###### An Atom Package - [Atom.io](https://atom.io/packages/double-tag) : [Github](https://github.com/dsandstrom/atom-double-tag)
[![Build Status](https://travis-ci.org/dsandstrom/atom-double-tag.svg?branch=master)](https://travis-ci.org/dsandstrom/atom-double-tag)

Edit both the start and end HTML tags at the same time.

![Screen Recording](https://cloud.githubusercontent.com/assets/1400414/15229336/75130366-1845-11e6-9ad7-f6f9359c1eca.gif)

### How To Use
Edit the start tag (`<div>`) and the matching end tag (`</div>`) will be changed automatically. Likewise for the end tag.

### Configs
* **enabledScopes** - Language scopes that are active (Default: `text.html, text.html.basic, text.xml, text.marko, source.js.jsx, source.tsx, text.html.erb, text.html.php, text.html.php.blade`)
* **ignoredTags** - HTML tags that are ignored.  (Default:
`area, base, body, br, col, command, embed, head, hr, html, img, input, keygen, link, meta, param, source, title, track, wbr`)
* **allowEndTagSync** - Whether editing the end tag will change the start tag.  (Default: `false`)

### Notes
* Supported Languages: HTML, PHP, ERB, JSX, XML, marko
* Issues and Pull Requests are welcome.
* Recording done with: [screen-recorder](https://atom.io/packages/screen-recorder)
