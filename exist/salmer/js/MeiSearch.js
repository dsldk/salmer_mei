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
    from:               'pae',
    svgViewBox:         true,
    scale:              32,
    pageWidth:          1200,
    pageHeight:         240,
    pageMarginTop:      0,
    pageMarginLeft:     0,
    header:             'none',
    footer:             'none',
    spacingStaff:       10,
    spacingLinear:      0.9,
    spacingNonLinear:   0.4,
    font:               'Bravura',
    adjustPageHeight:   0,
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
    render_query(pae + pae_data, "pQueryOut", verovio_options_search);
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

function render_query(data) {
    // a simplified rendering function for the piano input
    var svg = vrvToolkit.renderData( data + "\n", verovio_options_search );
    document.getElementById("pQueryOut").innerHTML = svg;
}

function make_mei_from_piano() {
// preparations for rendering MEI instead of PAE...
    var mei1 = '<?xml version="1.0"?>\
<score>\
    <section>\
        <scoreDef>\
            <staffGrp>\
                <staffDef clef.shape="G" clef.line="2" n="1" lines="5" />\
            </staffGrp>\
        </scoreDef>\
        <section>\
            <measure right="invis">\
                <staff n="1">\
                    <layer n="1">'
    var mei2 = '\
                    </layer>\
                </staff>\
            </measure>\
        </section>\
    </section>\
</score>'
    var note = '<note dur="4" stem.length="0" oct="4" pitchname="c"/>' 
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
                if(pae_data == "1-" | !pae_changed) { pae_data = ""; }
                new_data = check_accidental(pae_data, pnum_to_pae(pnum));
                pae_data += new_data;
                render_query(pae + pae_data, "pQueryOut", verovio_options_search);
                pae_changed = true;
                // play the added note; start with a 64th rest – otherwise the MIDI player skips the (first) note;
                // play halves instead of quarter notes to get a reasonable note length
                play_midi_data(pae + "6-" + pnum_to_pae(pnum).replace("4","2"), verovio_options_search);
                
            }
        });
    });
    /* Render the data and insert it as content of the target div */
    var absp_query = getParameterByName("a");
    if(absp_query) { pae_data = absp_to_pae(absp_query,"-"); }
    render_query(pae + pae_data, "pQueryOut", verovio_options_search);
}

function updateAction() {
    // generate a string containing the publications to be searched
    var q = "";
    if(document.getElementById("allPubl").checked === false) {
        $(".publicationCheckbox input").each(function() {
            if($(this).is(":checked")){q += $(this).attr("value") + ","}
        }) 
    }
    return q.substring(0,q.length - 1);
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
});