$(document).ready(function(){
  var lookupUrl = '' //wstest.dsl.dk/lex/query?app=brandes&version=1.0&q='
  $('.chapter-box').on('click', '.theActualDocument #region-content', function(event) {
    if($('#click-lookup-note-checkbox').prop('checked')) { // only do lookup if setting is activated
      // Gets clicked on word (or selected text if text is selected)
      var t = '';
      var sel = window.getSelection();
      var str = sel.anchorNode.nodeValue;
      var parentNode = $(sel.anchorNode.parentNode);
      // only allow lookups of words that are not people, works of art, characters etc.
      if (str && !parentNode.hasClass('persName') && !parentNode.hasClass('fictionalpersName') && !parentNode.hasClass('bibl') && !parentNode.hasClass('placeName')) {
        var len = str.length;
        var a = b = sel.anchorOffset;
        while (str[a] != ' ' && a--) {
          // count backwards until we reach a space
        }
        if (str[a] == ' ') {
          a++; // start of word. if the last character we got was a space, go forward one step
        }
        while (str[b] != ' ' && b++ < len) {
          // go forward until we reach a space
        }; // end of word + 1. Plus one because substring does not include the end index
        t = str.substring(a, b);
        // strip any weird characters from end or beginning of string
        t = t.replace(/[^a-åA-Å]/gi, '')
        if (t.length > 0) {
          if (lookupUrl) {
            $.ajax({
              url: lookupUrl + t,
              method: 'GET',
              dataType: 'html'
            })
            .done(function(response){
              $('#dictionary-lookup-tab').html(response);
              var tabIndex = $('#tabs > div > div').index($('#dictionary'));
              $('#tabs').tabs('option', 'active', tabIndex);
            })
          } else {
            console.warn('lookupUrl is not defined')
          }
        }
      }
    }
  });
});
