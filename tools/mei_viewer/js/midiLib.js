// JS for MIDI playback.
// Requires that MeiLib.js is loaded

// MIDI-related  variables
var ids = [];
var isPlaying = false;

// Parameters for the XSL transformation
var $midi = {
    xslt:       'midi.xsl',
    parameters: {}
}
 
/* Reverse a string */
function reverse(s){
    return s.split("").reverse().join("");
}    

//////////////////////////////////////////////////////////
/* A function that starts playing data identified by ID */
//////////////////////////////////////////////////////////
function play_midi(id) {
    console.log("Rendering for playing: " + id);
    var data = $mei[id].data;  
    $("#play_" + id).addClass('playing');
    $("#stop_" + id).addClass('playing');

    // temporarily add the MIDI preparation XSL to the list of transformations
    $mei[id].xsltOptions['midi'] = $.extend(true, {}, $midi);

    if(clientSideXSLT) {
        // apply relevant transformations
        transformedMei = Saxon.parseXML(data);
        for (var index in transformOrder) {
            var key = transformOrder[index];
            if ($mei[id].xsltOptions.hasOwnProperty(key)) {
                transformedMei = transform(transformedMei, $mei[id].xsltOptions[key]);
            }
        }
        data = Saxon.serializeXML(transformedMei);
    }
    
    // Add a rest at the beginning to make the first note play (bug in midi player?)
    data = data.replace('<note ','<rest dur="4"/><note ');
    // Add a rest at the end too to prevent the player from stopping too early
    data = reverse(reverse(data).replace(reverse('</layer>'),reverse('<rest dur="4"/></layer>'))); 

//$("#debug_text").html(data);

    if (isPlaying === true) {pause();}
    var options = {
        inputFormat: 'mei'
    };
    console.log("Playing MIDI");
    // MIDI needs a dummy re-rendering to make sure the correct data are loaded
    var svg_dummy = vrvToolkit.renderData( data + "\n", options );
    var base64midi = vrvToolkit.renderToMIDI();
    var song = 'data:audio/midi;base64,' + base64midi;
    // Using a hidden player
    // $("#player").show();
    $("#player").midiPlayer.play(song);
    isPlaying = true;

    // remove the MIDI XSL from the transformation list
    delete $mei[id].xsltOptions['midi'];
}
 
 
////////////////////////////////////////////
/* A function playing submitted data      */
////////////////////////////////////////////
function play_midi_data(data) {
    if (isPlaying === true) {pause();}
    var options = {
        inputFormat: 'mei'
    };
    console.log("Playing MIDI");
    // MIDI needs a dummy re-rendering to make sure the correct data are loaded
    var svg_dummy = vrvToolkit.renderData( data + "\n", options );
    var base64midi = vrvToolkit.renderToMIDI();
    var song = 'data:audio/midi;base64,' + base64midi;
// Using a hidden player
// $("#player").show();
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
    if ((elementsattime.notes.length > 0) && (ids != elementsattime.notes)) {
        ids.forEach(function(noteid) {
            if ($.inArray(noteid, elementsattime.notes) == -1) {
                $("#" + noteid).removeClass("playing");
            }
        });
        ids = elementsattime.notes;
        ids.forEach(function(noteid) {
            if ($.inArray(noteid, elementsattime.notes) != -1) {
                $("#" + noteid).addClass("playing");
            }
        });
    }
}

var midiStop = function() {
    ids.forEach(function(noteid) {
        $("#" + noteid).removeClass("playing");
    });
    $(".midi_button").removeClass('playing');
    isPlaying = false;
}
 
function jumpTo(id) {
    var time = vrvToolkit.getTimeForElement(id);
    $("#player").midiPlayer.seek(time);
}
 
function initMidi() {
    // insert a hidden MIDI player  
    var $playerHTML = $("<div id='player' style='display: none'> <!-- hidden MIDI player --> </div>").appendTo('body'); 
    
    $("#player").midiPlayer({
        color: "#c00",
        onUpdate: midiUpdate,
        onStop: midiStop,
        width: 250
    });
    
    //////////////////////////////////////////
    /* Enable jumping by clicking on a note */
    //////////////////////////////////////////
    $(".note").click(function() {
        var id = $(this).attr("id");
        var time = vrvToolkit.getTimeForElement(id);
        $("#player").midiPlayer.seek(time);
//alert(id);
    });
    
}

// END MIDI
