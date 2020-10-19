$(function(){

	/* checkCookie(); // Uncomment to enable cookie popup */

	// attach click functionality to annotation controls
  $('#text-critical-note-checkbox').click(function(event) {colorAllTextCriticalNotes(this,'.mei svg .dir.comment, .textcriticalnote','.textcriticalnote','blue');});
  // determine whether notes should be shown in MeiAjax.js
  comments = $('#text-critical-note-checkbox').prop('checked')
	$('#click-lookup-note-checkbox').click(function(event) {enableDictLookup(this);});
  $('#tabs').tabs();

	// on page load, replace the "vanilla" browser state with one we define ourselves,
	// so that we can be sure that all navigational states have a state object.
	// this is needed so we can distinguish anchor links -- which also push a state to
	// the history stack -- from navigation actions.
	pushToHistory(window.location.href, 1)

	// save selected tab in browser storage, so we can activate this tab on page load
	$('#tabs').on('tabsactivate', function (event, ui) {
		sessionStorage.setItem('active-tab', ui.newTab.attr('aria-controls'));
	});

  // if we are on the text view, handle the tabs at page load
  if ($('#tabs').length) {
    var tabId = getFirstVisibleTab().attr('id');
  	if (sessionStorage.getItem('active-tab')) {
  		// if the prev tab is not currently hidden, select it instead of the first visible tab
  		if (!$('#' + tabId).hasClass('hidden')) {
        tabId = sessionStorage.getItem('active-tab');
  		}
  	}
    activateTab(tabId);
  }


	// when expanding/collapsing search field, calculate the proper height
	$('#search-field-toggle').change(function (event, settings) {
		var checked = $(this).prop('checked');
		var searchBox = $('#search-field');
		var height = checked ? searchBox.get(0).scrollHeight + 'px' : '';
		requestAnimationFrame(function () {
			if (settings && settings.instant) {
				searchBox.css('transition-duration', '0s');
			}
			else {
				searchBox.css('transition-duration', '');
			}
			searchBox.css('height', height);
			searchBox.find('input[name="q"]').focus();
		});
	})

	var isSearch = /http.*?\/search/.test(window.location.href);
	if (isSearch) {
		$('#search-field-toggle').trigger('change', { instant: true }); // calculate height and animate

    $('#search-mobile').submit(function(){
      // copy the checkbox values from the search form so that this
      // form can respect those settings.
      var documentIds = $('#search-form [name="document_id"]:checked').map(function(){
        return $('<input>', {
          name: 'document_id',
          value: $(this).val(),
          type: 'hidden'
        }).get(); // "expand" with .get() because otherwise we get nested objects
      });

      $(this).append(documentIds);
    });
	}

	// when submitting the search form on the results page, we should
	// copy the input value from the text field to the hidden field,
	// in case the text field was changed.
	$('form[name="manuscripts"]').submit(function () {
		$(this).find('input[name="q"]').val($('#search-mobile input[name="q"]').val());
	});

  // select/deselect search options
  $('#search-form .select-all').click(function(){
    $('input[name=document_id]').prop('checked', true);
  });
  $('#search-form .deselect-all').click(function(){
    $('input[name=document_id]').prop('checked', false);
  });

	// when expanding/collapsing nav, calculate the proper height
	$('#header__menu-toggle').change(function () {
		var checked = $(this).prop('checked');
		var headerMenu = $('.header__menu');
		var height = checked ? headerMenu.get(0).scrollHeight + 'px' : '';

		requestAnimationFrame(function () {
			headerMenu.css('height', height);
		});
	})

	// Get new page from backend when paginating a text in primary language (left side of screen)
	$('.chapter-box').on('change', '.chapter-dropdown', paginateText);
	// We need to perform the same operation for clicks on pagination links
	$('.chapter-box').on('click', '.chapter-selector-wrapper a, .nextPreviousbox a', paginateText);

	// when clicking a comment link in the text column, focus the comment tab
	$('.chapter-box').on('click', '.comment-link', function () {
		activateTab('#comments');
	});

	// Get new page from backend when paginating a text on a secondary language
	$('#translations').on('change', '.chapter-dropdown', function() {
		$('#lang-chapter-wrapper').addClass('loading');
		getManuscript($(this), '/text')
		.done(function(result) {
			updateTextWrapper('#lang-chapter-wrapper', result);
			$('#lang-chapter-wrapper').removeClass('loading');
		});
	});

	// // When paginating a primary language, just submit the form as usual
	// $('.chapter-box').on('change', '.chapter-dropdown', function() {
	// 	var form = $(this).closest('form').get(0); // .get(0) to convert to DOMElement
	// 	form.submit();
	// });

	// When paginating via prev/next buttons or links (i.e. not changing select)
	// in secondary langauge, prevent default (= follow link), and instead get text
	// via AJAX.
	$('#translations').on('click', '.chapter-selector .arrow-r, .chapter-selector .arrow-l, .nextPreviousbox a', function(e) {
		e.preventDefault();
		var href = $(this).attr('href');
		if (href) {
			$('#lang-chapter-wrapper').addClass('loading');
			requestText('/text' + href)
			.done(function(result) {
				updateTextWrapper('#lang-chapter-wrapper', result);
				$('#lang-chapter-wrapper').removeClass('loading');
			});
		}
	})

	// map of translations that exist for each text
	var translations = [
		{
			'Dansk': 'christian-3-bibel',
		},
		{
			'Dansk': 'claus-mortensen-messe-1528',
		},
		{
			'Dansk': 'dietz-salmebog-1529',
		},
		{
			'Dansk': 'dietz-salmebog-1536',
		},
		{
			'Dansk': 'jespersen_1573',
		},
		{
			'Dansk': 'malmoe-salmebog',
		},
		{
			'Dansk': 'oluf-ulriksen-messe-1535',
		},
		{
			'Dansk': 'oluf-ulriksen-messehaandbog-1539',
		},
		{
			'Dansk': 'thomissoen_1569',
		},
	]

	// ugly way to transform array of translations to array of text ids
	var textIds = [].concat.apply([], translations.map(function (lang) {
		return Object.entries(lang).map(function (entry) {
			return entry[1] // item 1 is text id, item 0 is language label
		})
	}))

	// convenience function for making AJAX requests
	function requestText(url) {
		return $.ajax({
			url: url,
			method: 'GET',
			dataType: 'html'
		})
	}

	// convenience function for getting text via AJAX based on the paginator form in the template
	function getManuscript(elem, urlPrefix) {
		var baseUrl = '';
		if (elem.is('select')) {
			baseUrl = elem.children(':selected').attr('data-ajax-url');
		} else if (elem.is('a')) {
			baseUrl = elem.attr('href');
		}
		if (baseUrl) {
			return requestText(urlPrefix + baseUrl);
		}
		var form = elem.closest('form');
		var elements = form.get(0).elements; // .get(0) to convert to DOMElement
		var qstring = $.map(elements, function(element, idx) {
			return element.name + '=' + element.value;
		});
		qstring = '/?' + qstring.join('&') + '&text_only=1';

		return requestText(qstring)
	}

	// convenience function to update text wrapper with result of ajax request
	function updateTextWrapper(wrapperSelector, result) {
		$(wrapperSelector).html(result)
		activateNotesInLeftColumn(); // generate new popups as these new ones weren't ready when we initialized the page
		activateNotesInRightColumn();

    if (wrapperSelector === '.chapter-box') {
      initMusic(loc); // call initMusic from MeiAjax.js
    }
	}

	// event handler for pagination in left-hand text
	function paginateText (e) {
		e.preventDefault(); // prevent links from being followed (arrow buttons)
		e.stopPropagation(); // prevent the form from submitting
		$('.chapter-box').addClass('loading');
		getManuscript($(this), '/text')
		.done(function(result) {
			updateTextWrapper('.chapter-box', result);
			$('.chapter-box').removeClass('loading');
		})
		.done(function(){
			var textPath = this.url.replace(/^\/text/, ''); // strip leading '/text' as we don't want it to show in the URL. this.url refers to the url property of the ajax method
			pushToHistory(textPath);
			// window.scrollTo(window.pageXOffset, 0); // scroll to top, but keep x scroll position
		})
		.fail(function() {
			showStatusPopup(__[loc]('Der skete en fejl. Teksten kunne ikke indlæses.'));
		})

		// also get any notes for the notes tab
		// with the getManuscript as AJAX request
		updateCommentBox(getManuscript($(this), '/notes'));
	}

	// show status popup
	function showStatusPopup(statusText) {
		var popup = $('body').append($('<div/>', {
			'class': 'ajax-status',
			'text': statusText
		}));
		setTimeout(function () {
			var statusBox = $('.ajax-status')
			statusBox.addClass('move-left'); // move the notice to the left
			setTimeout(function () {
				statusBox.remove();
			}, 300); // delete the element from the DOM after 300ms, corresponding to CSS transition duration
		}, 3000); // hide notice after 3s
	}

	// handle comment box
	function updateCommentBox(jqXHR) {
		var commentBox = $('#comments');
		var commentTab = $('[href="#comments"]').closest('li');
		commentBox.scrollTop(0);
		commentBox.addClass('loading');
		jqXHR.done(function(result) {
			commentBox.removeClass('loading');
			if (result.length > 1) { // only show the comment tab if there are comments to show
				commentBox.removeClass('hidden');
				commentTab.removeClass('hidden');
				// activateTab('#comments');
				updateTextWrapper('#comments', result);
			} else {
				commentBox.addClass('hidden');
				commentTab.addClass('hidden');
				// if the comment tab was active, simply activate the first visible tab instead
				if ($('#tabs > div > div').index($('#comments')) == $('#tabs').tabs('option', 'active')) {
					var firstVisibleTab = getFirstVisibleTab();
					activateTab(firstVisibleTab.attr('id'));
				}
			}
		})
		.fail(function() {
			showStatusPopup(__[loc]('Der skete en fejl. Kommentarer kunne ikke indlæses.'));
		});
	}

	// activate tab by id
	function activateTab(tabId) {
		tabId = tabId.replace(/^#/, ''); // strip any leading hashmark
		var tabIndex = $('#tabs > div > div').index($('#' + tabId));
		if (tabIndex >= 0) {
			$('#tabs').tabs('option', 'active', tabIndex);
		} else {
			$('#tabs').tabs('option', 'active', 0);
		}
	}

  // get first visible tab
  function getFirstVisibleTab() {
    return $('#tabs > div > div:not(.hidden)').eq(0)
  }

	// push a state to the history stack
	function pushToHistory(url, replace) {
		var dropdowns = ['#translations select[name="chapter"]', 'select[name="meta"]', 'select[name="language"]']; // CSS selectors for the dropdowns whose state we want to (re)load on popstate
		var stateObj = {}

		dropdowns.forEach(function (dropdown) { // add the current value of all the relevant dropdowns to the state obj
			stateObj[dropdown] = $(dropdown).val()
		});
		if (replace) {
			return history.replaceState(stateObj, '', url);
		}
		return history.pushState(stateObj, '', url);
	}

  // clicking a facsimile link should show it in the right-hand pane.
  $('.chapter-box').on('click', '.facsimile-link', function(e) {
    e.preventDefault();
    var pg = $(this).text();
    var href = $(this).attr('href');
    var imgUrl = href.replace(/\.(.*?)$/, '_small.$1');
    // check if the small version exists
    $.ajax({
      url: imgUrl,
      method: 'HEAD',
      complete: function (jqXHR, status) {
        var injectedHtml = '';
        var status = jqXHR.status;
        if (status === 200) {
          injectedHtml = '<div class="facsimile-thumb">' + '<span class="facsimile-title">' +
            __[loc]('Faksimile for side') + ' ' +
            pg + '</span>' +
            '<a href="' + href + '" target="_blank">' +
            '<img src="' + imgUrl + '" alt="">' +
            '<span>' + __[loc]('Se en stor udgave af') + ' ' + pg + '</span>'
            '</a>' + '</div>';
        }
        else {
          injectedHtml = '<div class="facsimile-thumb">' +
            __[loc]('Faksimilen') + ' ' + pg + ' ' + __[loc]('kunne ikke findes');
        }

        $('#facsimile-tab').html(injectedHtml);
        activateTab('#facsimile');
      }
    });
  });
});

function checkCookie()
{
	var cookies = document.cookie;
	var cookie_start = cookies.indexOf('cookieAccept');

	if (cookie_start === -1) {
		var html = '<div class="cookies"><div class="container"><div class="row"><div class="col-md-12"><div class="left"><h1>Acceptér cookies fra siden her</h1><button>Acceptér</button><a href="#" class="">Læs mere om cookies</a></div><div class="right"><p>Danicum Diplomatarium bruger cookies til at indsamle oplysninger om brugen af webstedet. Du kan altid slette cookies fra Danicum Diplomatariumt igen, hvis du ønsker. Når du accepterer cookies bliver denne bjælke ikke længere vist.</p></div></div></div></div></div>';
		$('body').prepend(html);

		$('.cookies button').on('click', function(){
			var date = new Date();
			var days = 365;

			date.setTime(date.getTime() + (days*24*60*60*1000));
			var expires = '; expires=' + date.toGMTString();

			document.cookie = 'cookieAccept=yes; ' + expires;
			$('.cookies').hide();
		});
	}
}

function setCookie(name,value,days) {
    var expires = "";
    if (days) {
        var date = new Date();
        date.setTime(date.getTime() + (days*24*60*60*1000));
        expires = "; expires=" + date.toUTCString();
    }
    document.cookie = name + "=" + (value || "")  + expires + "; path=/";
}

function colorAllNotes(checkbox, note_class, background_color) {
  if (checkbox.checked) {
    $(note_class).each(function() {
      $(this).css({
        'backgroundColor': background_color,
        cursor: 'pointer'
      });
    });
    setCookie(note_class, 'checked', 365);
  } else {
    $(note_class).each(function() {
      $(this).css({
        'backgroundColor': 'transparent',
        cursor: 'default'
      });
    });
    setCookie(note_class, '', 365);
  }
}

function enableDictLookup (checkbox) {
	if(checkbox.checked) {
		setCookie('.clickLookup', 'checked', 365);
	}
	else {
		setCookie('.clickLookup', '', 365);
	}
}

function colorAllNotesByCookie(checkbox, note_class, background_color) {
/* if (getCookie(note_class) != 'checked') { } */
}

function colorAllTextCriticalNotes(checkbox, note_class, cookie_name, background_color) {
  if (checkbox.checked) {
    $(note_class).each(function() {
      $(this).css({
        color: background_color,
        display: 'inline',
        cursor: 'pointer',
        visibility: 'visible'
      });
      $(this).removeClass('hidden');
    });
    setCookie(cookie_name, 'checked', 365);
  } else {
    $(note_class).each(function() {
      $(this).css({
        display: 'none',
        cursor: 'default',
        visibility: 'hidden'
      });
    });
    setCookie(cookie_name, '', 365);
  }
  // determine whether notes should be shown in MeiAjax.js
  // note the variable name! It should not be "enableComments" here,
  // as this variable name is only used upon initialization. Instead,
  // we should change "comments" directly as this is the variable eventually
  // evaluated during initMusic()
  comments = checkbox.checked
}

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
