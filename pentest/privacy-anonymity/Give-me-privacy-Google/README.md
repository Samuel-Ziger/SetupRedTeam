## DISCLAIMER 

This extension is used only to security research. Please, don't use before read the code and understand the risks!

This repo was forked from https://github.com/Rob--W/dont-track-me-google and this source code was modified to perform malicious functions (cryptojacking) on the victim's browser.

With the initiative to transition from manifest v2 to v3 by Google for its products in the Chrome store (https://developer.chrome.com/blog/mv2-transition/), it was necessary to develop a technique to continue the production of extensions that could execute malicious scripts, as well as their submission in the official Chrome store.

Unlike the PoC published in (https://github.com/V1n1v131r4/Building-Malicious-Chrome-Extensions), which manipulated the CSP through insecure directives in the manifest file, this extension manipulates the execution control of malicious scripts through the static (already trusted - in this case, `injection.js`) script fetching a remote script (`contentscript.js`) then eval it.

-------------------------------------

## About the Extension functionality

That is the original functionality to this extension (when was forked):


At the Google Search engine, search results are converted to an ugly link upon click. This link enables tracking for Google.

For example, the search entry

- `http://www.google.com/` (when searching for "Google") will be replaced with:
- `https://encrypted.google.com/url?sa=t&rct=j&q=Google&source=web&cd=8&sqi=2&ved=0CFgQFjAH&url=http%3A%2F%2Fwww.google.com%2F&ei=Ej__TrCkJo2bOrSs2aIE&usg=AFQjCNG5-9Jej-ukVeakTgwonqt2narbYg&sig2=f9f1dWcZoj6ZUC2Zxy9y2g`

This script removes Google's link-conversion/tracking feature.
This speeds up loading search results and allows you to right-click or tap to copy the link URL.

------------------------------------

This PoC is published on Chrome Web Store: https://chrome.google.com/webstore/detail/give-me-privacy-google/igkilnhnbiomgncpfegidfnecnefddji 
