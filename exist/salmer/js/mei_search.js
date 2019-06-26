var data_dir = "data/";

var pQuery = [];
var pae         = "@clef:G-2\n @data:";
var pae_data    = "4-";
var pae_octaves = [",,", ",", "'", "''", "'''"];
var pae_pitches = ["C", "xC", "D", "bE", "E", "F", "xF", "G", "bA", "A", "bB", "B"];
var pae_changed = false;

var verovio_options = {
    format:        'mei',
    scale:              40,
    pageWidth:          1800,
    pageHeight:         20000,
    pageMarginTop:      30,
    pageMarginLeft:     0,
    noHeader:           1,
    noFooter:           1,
    lyricTopMinMargin:  4,
    lyricSize:          4,
    spacingSystem:      1,
    spacingStaff:       3,
    spacingLinear:      0.9,
    spacingNonLinear:   0.3,
    font:               'Bravura',
    adjustPageHeight:   1,
    noJustification:    1,
    breaks:             'encoded'
};

var verovio_options_search = {
    format:        'pae',
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
    noJustification:    1 
};

// Global variables for search selection
var selectionmode  = "";
var selectionMEI   = "";
var selectionStart = "";
var selection      = [];
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

function load_data(data, id, options) {
    var svg = vrvToolkit.renderData( data + "\n", options );
    //console.log( options );
    output_div = document.getElementById(id);
    output_div.innerHTML = svg;
      

    //////////////////////////////////////////////
    /* Bind click and hover events to each note */
    //////////////////////////////////////////////
    $("#" + id + " .note").click(function() {
        var noteID = $(this).attr("id");
        if(isPlaying) { jumpTo(noteID); }
        // If not playing, start selection
        if(isPlaying !== true) {
            if(selectionmode == "open" && noteID != selectionStart && id == selectionMEI) {
                // Range selected
                selectionmode = "closed";
                selectionChangeClass(id, noteID, "add", "selected");
                saveSelection();
            } else 
            if(selectionmode == "closed" || noteID == selectionStart || (selectionmode == "open" && id != selectionMEI) ){
                // Deselect and reset
                selectionmode = "";
                selectionStart = "";
                selectionMEI = "";
                selection = [];
                $(".selectionBox").remove();
                $(".selected").removeClass('selected');
                $(".hover").removeClass('hover');
            } else {
                // Start selection
                selectionmode = "open";
                selectionStart = noteID;
                selectionMEI = id;
                $(this).addClass('selected');
            }
        }
    })
    /* Bind a hover event handler on notes in selection mode */
    .mouseover(function() {
            var noteID = $(this).attr("id");
            if(selectionmode == "open" && selectionMEI == id && $(this).attr("id") !== selectionStart) {
                // One end of the selection is made; higlight all notes in between 
                selectionChangeClass(id, noteID, "add", "hover");
            } else if(selectionmode != "closed" && (selectionMEI == id || selectionMEI == "")) {
                // Selection not started yet; highlight only the hovered note
                $(this).addClass('hover'); 
            } else {
                // Selection complete; do nothing 
            }
    })
    .mouseout(function() {
        $(".hover").removeClass('hover');
    });
    
 
    
}

function reset_a() {
    pQuery = [];
    $("#absp").attr("value","");
    pae_data = "4-";
    pae_changed = true;
    load_data(pae + pae_data, "pQueryOut", verovio_options_search);
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
                load_data(pae + pae_data, "pQueryOut", verovio_options_search);
                pae_changed = true;

                // play the added note; start with a 64th rest – otherwise the MIDI player skips the first note;
                // play halves instead of quarter notes to get a reasonable note length
                play_midi_data(pae + "6-" + pnum_to_pae(pnum).replace("4","1"), verovio_options_search);
                
            }
        });
    });
    /* Render the data and insert it as content of the target div */
    var absp_query = getParameterByName("a");
    if(absp_query) { pae_data = absp_to_pae(absp_query,"-"); }
    load_data(pae + pae_data, "pQueryOut", verovio_options_search);
}

function loadResults() {
    $(".mei").each(function(){
        var divId = $(this).attr("id");
        var data = $("#" + divId + "_data").html();
        console.log("Rendering " + divId);
        load_data(data, divId, verovio_options);
        // store note IDs (needed for selecting)
        var noteIDs = [];
        $(".note").each(function(){ noteIDs.push(this.id); });
        notes[divId] = noteIDs;
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
    // generate a string containing the publications to be searched
    var q = "";
    if(document.getElementById("allPubl").checked === false) {
        $("#publication input").each(function() {
            if($(this).is(":checked")){q += $(this).attr("value") + ","}
        }) 
    }
    return q.substring(0,q.length - 1);
}

function allPublClicked() {
    if(document.getElementById("allPubl").checked) {
        $('#publication input').prop('checked', true);
    } else {
        $('#publication input').prop('checked', false);
    }
}

function publClicked() {
    var all = $("#publication input").length;
    var checked = $("#publication input:checked").length;
    if(checked < all) {
        $('#allPubl').prop('checked', false);
    } else {
        $('#allPubl').prop('checked', true);
    }
}


// Functions for phrase selection

// Add or remove CSS class on all notes in selection
function selectionChangeClass (id, noteID, mode, className) {
    var start = notes[id].indexOf(selectionStart);
    var end = notes[id].indexOf(noteID);
    if(notes[id].indexOf(selectionStart) > notes[id].indexOf(noteID) && notes[id].indexOf(noteID) > -1) {
        // Selection is "backwards"; swap start and end positions 
        start = end;
        end = notes[id].indexOf(selectionStart);
    } 
    for (index = start; index <= end; index++) {
        if(mode == "add") {
            $("#" + notes[id][index]).addClass(className);
        } else {
            $("#" + notes[id][index]).removeClass(className);
        }
    }
}

// Store selection in global variable
function saveSelection() {
    // Calculate bounding box of selection layer-wise and store IDs
    $(".selected").parent(".layer").each(function() {
        var layer = $(this).attr("id");
        var x1 = 999999;
        var y1 = 999999;
        var x2 = 0;
        var y2 = 0;
        // Iterate over selected notes in this layer
        $("#" + layer + " .selected").each(function() {
            var noteID = $(this).attr("id");
            selection.push(noteID);
            var BB = document.getElementById(noteID).getBBox();
            if(BB.x < x1) { x1 = BB.x; }
            if(BB.y < y1) { y1 = BB.y; }
            if(BB.width + BB.x > x2) { x2 = BB.width + BB.x; }
            if(BB.height + BB.y > y2) { y2 = BB.height + BB.y; }
        });
        if(x1 !== 999999 && y2 !== 999999 && x2 !== 0 && y2 !== 0) {
            // Draw a box
            var svgns = "http://www.w3.org/2000/svg";
            var rect = document.createElementNS(svgns, 'rect');
            var w = x2 - x1;
            var h = y2 - y1;
            rect.setAttributeNS(null, 'x', x1);
            rect.setAttributeNS(null, 'y', y1);
            rect.setAttributeNS(null, 'height', h);
            rect.setAttributeNS(null, 'width', w);
            rect.setAttributeNS(null, 'class', 'selectionBox');
            rect.setAttributeNS(null, 'id', 'selectionBox_' + layer);
            // Draw the box in the inner SVG element
            document.getElementById(selectionMEI).querySelector('svg').querySelector('svg').appendChild(rect);
            // Add a hover title
            var title = document.createElementNS(svgns, 'title');
            title.setAttributeNS(null, 'class', 'labelAttr');
            title.innerHTML = "Klik for at søge efter den markerede frase";
            document.getElementById('selectionBox_' + layer).appendChild(title);
            
            // Bind a click event handler to the box
            $('#selectionBox_' + layer).click(function() {
                var qNotes = [];
                // Look up MIDI pitch numbers in the original MEI
                for (nID in selection) {
                    qNotes.push($('#' + selectionMEI + '_data note[xml\\:id="' + selection[nID] + '"]').attr('pnum'));
                }
                // Limit query length to 12 notes
                if(qNotes.length > 12) {
                    alert("Søgning er begrænset til tolv toner. \nSøger efter de første tolv toner i markeringen.");
                    qNotes.length = 12;
                }
                // Transpose to around octave 4 (aiming at average pitch around a4 = 69)
                var transposeOctaves = Math.round((69 - (qNotes.reduce(add, 0) / qNotes.length)) / 12);
                for (i in qNotes) {
                    qNotes[i] = parseInt(qNotes[i]) + transposeOctaves * 12;
                }
                // Search!
                //window.location.href = "mei_search_solr.xq?a=" + qNotes.join("-");
                window.location.href = "mei_search.xq?a=" + qNotes.join("-");
            });
            
        }
    });
}

function add(a, b) {
    return parseInt(a) + parseInt(b);
}

$(document).ready(function() {
    initPiano();
    initMidi();
    loadResults();
    validateInput();
});