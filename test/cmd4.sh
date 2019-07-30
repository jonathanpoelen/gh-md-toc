#!/bin/bash

set -e

expected='## H2.1
### H3.1
### H3.2
## H2.2
### H3.3'
expected="$expected"$'\n'"$expected"
if [ "$expected" != "$1" ]; then
  echo match error:
  echo
  echo "$1"
  echo
  echo expected:
  echo
  echo "$expected"
  exit 1
fi

echo '<h2>
<a id="user-content-h21" class="anchor" href="#h21" aria-hidden="true"><span aria-hidden="true" class="octicon octicon-link"></span></a>H2.1</h2>
<h3>
<a id="user-content-h31" class="anchor" href="#h31" aria-hidden="true"><span aria-hidden="true" class="octicon octicon-link"></span></a>H3.1</h3>
<h3>
<a id="user-content-h32" class="anchor" href="#h32" aria-hidden="true"><span aria-hidden="true" class="octicon octicon-link"></span></a>H3.2</h3>
<h2>
<a id="user-content-h22" class="anchor" href="#h22" aria-hidden="true"><span aria-hidden="true" class="octicon octicon-link"></span></a>H2.2</h2>
<h3>
<a id="user-content-h33" class="anchor" href="#h33" aria-hidden="true"><span aria-hidden="true" class="octicon octicon-link"></span></a>H3.3</h3>
<h2>
<a id="user-content-h21-1" class="anchor" href="#h21-1" aria-hidden="true"><span aria-hidden="true" class="octicon octicon-link"></span></a>H2.1</h2>
<h3>
<a id="user-content-h31-1" class="anchor" href="#h31-1" aria-hidden="true"><span aria-hidden="true" class="octicon octicon-link"></span></a>H3.1</h3>
<h3>
<a id="user-content-h32-1" class="anchor" href="#h32-1" aria-hidden="true"><span aria-hidden="true" class="octicon octicon-link"></span></a>H3.2</h3>
<h2>
<a id="user-content-h22-1" class="anchor" href="#h22-1" aria-hidden="true"><span aria-hidden="true" class="octicon octicon-link"></span></a>H2.2</h2>
<h3>
<a id="user-content-h33-1" class="anchor" href="#h33-1" aria-hidden="true"><span aria-hidden="true" class="octicon octicon-link"></span></a>H3.3</h3>'
