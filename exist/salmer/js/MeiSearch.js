var pQuery = [];
var pae         = "@clef:G-2\n @data:";
var pae_data    = "4-";
var pae_octaves = [",,", ",", "'", "''", "'''"];
var pae_pitches = ["C", "xC", "D", "bE", "E", "F", "xF", "G", "bA", "A", "bB", "B"];
var pae_changed = false;

// Verovio settings for rendering of search results. Overrides default settings defined in MeiAjax.js 
$defaultVerovioOptions = {
    from:              'mei',
    svgViewBox:         true,
    scale:              36,
    pageWidth:          2500,
    pageHeight:         20000,
    pageMarginTop:      30,
    pageMarginLeft:     0,
    header:             'none',
    footer:             'none',
    lyricTopMinMargin:  4,
    lyricSize:          4,
    spacingSystem:      1,
    spacingStaff:       3,
    spacingLinear:      0.9,
    spacingNonLinear:   0.3,
    font:               'Bravura',
    adjustPageHeight:   true,
    noJustification:    true,
    breaks:             'auto',
    systemDivider:      'none'
};

// Verovio settings for the piano input 
var verovio_options_search = {
    from:               'mei',
    svgViewBox:         true,
    scale:              100,
    pageWidth:          1200,
    pageHeight:         260,
    pageMarginTop:      90,
    pageMarginLeft:     0,
    header:             'none',
    footer:             'none',
    spacingStaff:       10,
    spacingLinear:      0.9,
    spacingNonLinear:   0.36,
    font:               'Bravura',
    adjustPageHeight:   false,
    noJustification:    true, 
    systemDivider:      'none'
};

// An array of arrays holding the note IDs in each MEI instance
var notes          = [];

function getParameterByName(name, url) {
    if (!url) url = window.location.href;
    name = name.replace(/[\[\]]/g, '\\$&');
    var regex = new RegExp('[?&]' + name + '(=([^&#]*)|&|#|$)'),
        results = regex.exec(url);
    if (!results) return null;
    if (!results[2]) return '';
    return decodeURIComponent(results[2].replace(/\+/g, ' '));
}

function reset_a() {
    pQuery = [];
    $("#absp").attr("value","");
    pae_data = "4-";
    pae_changed = true;
    render_query(pae + pae_data, "pQueryOut");
}

function pnum_to_pae(pnum) {
     // convert MIDI pitch number to PAE code
     var pitch = pnum % 12;
     var oct = Math.floor(pnum/12) - 3;
     return pae_octaves[oct] + "4" + pae_pitches[pitch];
}

function check_accidental(pae, add) {
    // adds a natural if necessary and avoids repeated accidentals 
    var pitch = add.split("4")[1];
    var acc = pitch.replace(/[A-G,V-Z]/g,'');
    var pname = pitch.replace(/[n,b,x]/g,'');
    var oct = add.split("4")[0];
    var notated_acc = "";
    // make a reverse copy of the PAE string
    var rev_pae = pae.split("").reverse().join("");
    var last_flat = rev_pae.indexOf(pname + 'b4');
    var last_natural = rev_pae.indexOf(pname + 'n4');
    var last_sharp = rev_pae.indexOf(pname + 'x4');
    switch (acc) {
        case "b":
            if(last_flat == -1 || (last_natural > -1 && last_flat > last_natural)) notated_acc = "b";
            break;
        case "x":
            if(last_sharp == -1 || (last_natural > -1 && last_sharp > last_natural)) notated_acc = "x";
            break;
        default:
            if(last_flat > -1 && (last_flat < last_natural || last_natural == -1)) notated_acc = "n";
            if(last_sharp > -1 && (last_sharp < last_natural || last_natural == -1)) notated_acc = "n";
    }
    return oct + "4" + notated_acc + pname;
}

function absp_to_pae(absp, separator) {
    // convert list of absolute pitches (string) to PAE string
    var pitches = absp.split(separator);
    var to_pae = "";
    for (i = 0; i < pitches.length; i++) {
        to_pae += check_accidental(to_pae, pnum_to_pae(pitches[i]));
    }
    return to_pae;
}

function render_query(pae) {
    // a rendering function for the piano input
    // first rendering is for conversion to MEI only              
    vrvToolkit.renderData(pae + "\n", {from: 'pae'});
    // remove stems before displaying
    var stemless = vrvToolkit.getMEI(-1, true).replace(new RegExp('<note ', 'g'),'<note stem.len="0" ');
    vrvToolkit.setOptions(verovio_options_search);
    vrvToolkit.loadData(stemless);
    document.getElementById("pQueryOut").innerHTML = vrvToolkit.renderToSVG(page, {});
}

function initPiano() {
    $(".key").each(function() {
        $(this).click(function(event) {
            if(pQuery.length < 12) {
                var pnum = $(this).attr("data-key");
                pQuery.push(pnum);
                // transfer values to search form
                $("#absp").attr("value",pQuery.join("-"));
                // display query
                if(pae_data == "4-" | !pae_changed) { pae_data = ""; }
                new_data = check_accidental(pae_data, pnum_to_pae(pnum));
                pae_data += new_data;
                render_query(pae + pae_data,"pQueryOut");
                pae_changed = true;
                // play the added note; start with a 64th rest – otherwise the MIDI player skips the (first) note;
                // play halves instead of quarter notes to get a reasonable note length
                play_midi_data(pae + "6-" + pnum_to_pae(pnum).replace("4","2"), {from: 'pae'});                
            }
        });
    });
    /* Render the initial staff and insert it as content of the target div */
    var absp_query = getParameterByName("a");
    if(absp_query) { pae_data = absp_to_pae(absp_query,"-"); }
    render_query(pae + pae_data, "pQueryOut");
}

function updateAction() {
    // generate a string containing the publications to be searched
    var q = ""
    $("#search-form .checkbox-container input").each(function() {
        if($(this).is(":checked")){q += $(this).attr("value") + " "}
    })
    q = q.substring(0,q.length - 1);
    // don't return checked values if all 
    if (q.split(" ").length == $("#search-form .checkbox-container input").length) {q = "";}    
    return q;
}

function allPublClicked() {
    if(document.getElementById("allPubl").checked) {
        $('.publicationCheckbox input').prop('checked', true);
    } else {
        $('.publicationCheckbox input').prop('checked', false);
    }
}

function publClicked() {
    var all = $(".publicationCheckbox input").length;
    var checked = $(".publicationCheckbox input:checked").length;
    if(checked < all) {
        $('#allPubl').prop('checked', false);
    } else {
        $('#allPubl').prop('checked', true);
    }
}

// Validate search query
function validateInput() {
    $("#pnames").keyup(function (e) {
        this.value = this.value.toLocaleUpperCase();
        this.value = this.value.replace(/[^A-H|^V-Z]/gi,'');
        this.value = this.value.replace(/[H]/gi,'B');
    });
    $("#contour").keyup(function (e) {
        this.value = this.value.replace(/[dD]/gi,'\\');
        this.value = this.value.replace(/[uU]/gi,'\/');
        this.value = this.value.replace(/[rR]/gi,'-');
        this.value = this.value.replace(/[^/\\|^//|^/-]/gi,'');
    });
}


function initTextSelect() {
//Adapted from javascript.js

	// when expanding/collapsing search field, calculate the proper height
	$('#text-select-toggle').change(function (event, settings) {
		var checked = $(this).prop('checked');
		var searchBox = $('#text-select');
		var height = checked ? searchBox.get(0).scrollHeight + 'px' : '';
		requestAnimationFrame(function () {
			if (settings && settings.instant) {
				searchBox.css('transition-duration', '0s');
			}
			else {
				searchBox.css('transition-duration', '');
			}
			searchBox.css('height', height);
		});
		$('#text-select-label').toggleClass('open');
	})
	
	// initialize
    if(params.txt) {
        // hide text selection if no texts or all are selected
        if(params.txt!='' && params.txt!='1+2+3+4+5+6') {
            $('#text-select').css('height', $('#text-select').get(0).scrollHeight + 'px');
            $('#text-select-label').removeClass('open');
        }
    } 
}

function openTab(evt, tabName) {
  // Declare all variables
  var i, tabcontent, tablinks;
  // Get all elements with class="tabcontent" and hide them
  tabcontent = document.getElementsByClassName("tabcontent");
  for (i = 0; i < tabcontent.length; i++) {
    tabcontent[i].style.display = "none";
  }
  // Get all elements with class="tablinks" and remove the class "active"
  tablinks = document.getElementsByClassName("tablinks");
  for (i = 0; i < tablinks.length; i++) {
    tablinks[i].className = tablinks[i].className.replace(" active", "");
  }
  // Show the current tab, and add an "active" class to the button that opened the tab
  document.getElementById(tabName).style.display = "block";
  evt.currentTarget.className += " active";
} 


$(document).ready(function() {
    initPiano();
    validateInput();
    initTextSelect();
});