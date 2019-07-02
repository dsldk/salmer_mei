// MIDI-related  variables
var ids = [];
var isPlaying = false;

/* Reverse a string */
function reverse(s){
    return s.split("").reverse().join("");
}    
    
/////////////////////////////////////////////////////////
/* A function that start playing data identified by ID */
/////////////////////////////////////////////////////////
function play_midi(id, options) {
    console.log("Rendering for playing: " + id);
    var data = $("#" + id + "_data").html();  
    // Add a rest at the beginning to make the first note play (bug in midi player?)
    data = data.replace('note','rest dur="16"/><note');
    // try adding a rest at the end too to prevent the player from stopping too early... (doesn't seem to have any effect, though)
    data = reverse(reverse(data).replace('eton',reverse('note><rest dur="8"/'))); 
//document.getElementById("debug_text").value = id;    
    play_midi_data(data, options);
    $("#play_" + id).addClass('playing');
    $("#stop_" + id).addClass('playing');
}
 
 
////////////////////////////////////////////
/* A function playing submitted data      */
////////////////////////////////////////////
function play_midi_data(data, options) {
    if (isPlaying === true) {pause();}
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
 
function initMidi() {
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
//alert(time);
    });
}

// END MIDI