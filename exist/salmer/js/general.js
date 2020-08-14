/// Tools etc. useable on all pages

function removeParameterFromURL(name) {
    var qstring = window.location.search.replace(/^\?/, ''); // strip any leading question mark
    var urlParams = qstring.split('&') // split into ["foo=bar", "baz=boo"]
    var filtered = '';
    for (i=0; i<urlParams.length; i++) {
        if (urlParams[i].split('=')[0] !== name && urlParams[i] !== '') {
            if (filtered !== '') { 
                filtered += '&' + urlParams[i];
            } else {
                filtered += urlParams[i];
            }
        }
    }
    return window.location.href.split('?')[0] + '?' + filtered; 
}
