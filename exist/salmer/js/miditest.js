var data_dir = "data/";

var pQuery = [];
var pae         = "@clef:G-2\n @data:";
var pae_data    = "4-";
var pae_octaves = [",,", ",", "'", "''", "'''"];
var pae_pitches = ["C", "xC", "D", "bE", "E", "F", "xF", "G", "bA", "A", "bB", "B"];
var pae_changed = false;

var verovio_options = {
    inputFormat:        'mei',
    scale:              40,
    pageWidth:          1800,
    pageHeight:         20000,
    pageMarginTop:      0,
    pageMarginLeft:     0,
    noHeader:           1,
    noFooter:           1,
    lyricTopMinMargin:  4,
    lyricSize:          4,
    spacingStaff:       3,
    font:               'Bravura',
    adjustPageHeight:   1,
    noJustification:    1,
    breaks:             'encoded'
};

var verovio_options_search = {
    inputFormat:        'pae',
    scale:              40,
    pageWidth:          980,
    pageHeight:         240,
    pageMarginTop:      0,
    pageMarginLeft:     0,
    noHeader:           1,
    noFooter:           1,
    spacingStaff:       10,
    font:               'Bravura',
    adjustPageHeight:   0,
    noJustification:    1, 
    breaks:             'encoded'
};


// MIDI-related  variables
var ids = [];
var isPlaying = false;


function getParameterByName(name, url) {
    if (!url) url = window.location.href;
    name = name.replace(/[\[\]]/g, '\\$&');
    var regex = new RegExp('[?&]' + name + '(=([^&#]*)|&|#|$)'),
        results = regex.exec(url);
    if (!results) return null;
    if (!results[2]) return '';
    return decodeURIComponent(results[2].replace(/\+/g, ' '));
}

function load_data(data, output_div, options) {
        var svg = vrvToolkit.renderData( data + "\n", options );
        //console.log( options );
        output_div.innerHTML = svg;
        
        
// MIDI
    ////////////////////////////////////////
    /* Bind a on click event to each note */
    ////////////////////////////////////////
    $(".note").click(function() {
        var id = $(this).attr("id");
        var time = vrvToolkit.getTimeForElement(id);
        $("#midi-player").midiPlayer.seek(time);
    });
        
        
    }


function loadResults() {
    $(".mei").each(function(){
        var divId = $(this).attr("id");
        var data = $("#" + divId + "_data").html();
        console.log("Rendering " + divId);
        load_data(data, document.getElementById(divId), verovio_options);
    });
}

function validateInput() {
    $("#pnames").keyup(function (e) {
        this.value = this.value.toLocaleUpperCase();
        this.value = this.value.replace(/[^A-H|^V-Z]/gi,'');
        this.value = this.value.replace(/[H]/gi,'B');
    });
    $("#contour").keyup(function (e) {
        this.value = this.value.replace(/[^/\\|^//|^/-]/gi,'');
        this.value = this.value.replace(/[H]/gi,'B');
    });
}

function updateAction() {
    var q = "";
    $("#publ_form input").each(function() {
        if($(this).is(":checked")){q += $(this).attr("value") + ","}
    }) 
    return q.substring(0,q.length - 1);
}

// MIDI 

////////////////////////////////////////////
/* A function that start playing the file */
////////////////////////////////////////////
function play_midi(id) {
    if (isPlaying === true) {pause();}
    console.log("Rendering for playing: " + id);
    var data = $("#" + id + "_data").html();   
    // MIDI needs a dummy re-rendering to make sure the correct data are loaded
    var svg_dummy = vrvToolkit.renderData( data + "\n", verovio_options );
    var base64midi = vrvToolkit.renderToMIDI();
    var song = 'data:audio/midi;base64,' + base64midi;

//    $("#player").show();
    $("#player").midiPlayer.play(song);
    isPlaying = true;
}

//////////////////////////////////////////////////////
/* Two callback functions passed to the MIDI player */
//////////////////////////////////////////////////////
var midiUpdate = function(time) {
    // Verovio time needs adjustment to synchronize
    var vrvTime = Math.max(0, time - 500);
    var elementsattime = vrvToolkit.getElementsAtTime(vrvTime);
// It is assumed that the entire score is shown on a single page    
//    if (elementsattime.page > 0) {
//        if (elementsattime.page != page) {
//            page = elementsattime.page;
//            loadPage();
//        }
        if ((elementsattime.notes.length > 0) && (ids != elementsattime.notes)) {
            ids.forEach(function(noteid) {
                if ($.inArray(noteid, elementsattime.notes) == -1) {
                    $("#" + noteid).attr("fill", "#000").attr("stroke", "#000");
                }
            });
            ids = elementsattime.notes;
            ids.forEach(function(noteid) {
                if ($.inArray(noteid, elementsattime.notes) != -1) {
                    $("#" + noteid).attr("fill", "#c00").attr("stroke", "#c00");
                }
            });
        }
//    }
}

var midiStop = function() {
    ids.forEach(function(noteid) {
        $("#" + noteid).attr("fill", "#000").attr("stroke", "#000");
    });
    $("#player").hide();
    isPlaying = false;
}

function initMidi() {
    $("#player").midiPlayer({
        color: "#c00",
        onUpdate: midiUpdate,
        onStop: midiStop,
        width: 250
    });
}

// END MIDI

$(document).ready(function() {
    initMidi();
    loadResults();
});   
