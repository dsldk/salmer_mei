// JS for MIDI playback.
// Requires that midiplayer.js and MeiAjax.js are loaded

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
    //var data = $mei[id].data;  
    $("#play_" + id).addClass('playing');
    $("#stop_" + id).addClass('playing');
    
    // temporarily add the MIDI preparation XSL to the list of transformations
    $mei[id].xsltOptions['midi'] = $.extend(true, {}, $midi);

    // send a POST request to get the MIDI-playable MEI data
    $.post('https://salmer.dsl.dk/transform_mei.xq',$mei[id].xsltOptions,function(data){

        if (isPlaying === true) {pause();}
        var options = {
            from: 'mei'
        };
        console.log("Playing MIDI");

        // strip off the wrapping <response> element to get the MEI root element
        var mei = data.firstChild;
        
        // make a document fragment containing the MEI
        var frag = document.createDocumentFragment();
        while(mei.firstChild) {
            frag.appendChild(mei.firstChild);
        }
        var xmlString = (new XMLSerializer()).serializeToString(frag);    

        vrvToolkit.setOptions(options);
        vrvToolkit.loadData(xmlString);
        var base64midi = vrvToolkit.renderToMIDI();
        var song = 'data:audio/midi;base64,' + base64midi;
        // Using a hidden player
        // $("#player").show();
        $("#player").midiPlayer.play(song);
        isPlaying = true;
    },'xml');

    // remove the MIDI XSL from the transformation list
    delete $mei[id].xsltOptions['midi'];
}

//////////////////////////////////////////////////////
/* Similar to play_midi, only download MIDI instead */
//////////////////////////////////////////////////////
function download_midi(id) {
    if(midiDownload) {

        console.log("Preparing for download: " + id);
        
        // temporarily add the MIDI preparation XSL to the list of transformations
        $mei[id].xsltOptions['midi'] = $.extend(true, {}, $midi);
    
        // send a POST request to get the MIDI-playable MEI data
        $.post('https://salmer.dsl.dk/transform_mei.xq',$mei[id].xsltOptions,function(data){
    
            var options = {
                from: 'mei'
            };
    
            // strip off the wrapping <response> element to get the MEI root element
            var mei = data.firstChild;
            
            // make a document fragment containing the MEI
            var frag = document.createDocumentFragment();
            while(mei.firstChild) {
                frag.appendChild(mei.firstChild);
            }
            var xmlString = (new XMLSerializer()).serializeToString(frag);    
    
            vrvToolkit.setOptions(options);
            vrvToolkit.loadData(xmlString);
            var base64midi = vrvToolkit.renderToMIDI();
            var binaryMidi = atob(base64midi);
            
            // Some data conversion necessary to produce a valid MIDI file.
            // See https://blog.logrocket.com/binary-data-in-the-browser-untangling-an-encoding-mess-with-javascript-typed-arrays-119673c0f1fe/
            // for a description of what we are doing here (basically converting a UTF-8 string to binary data) 
            var u16 = new Uint16Array(binaryMidi.length);
            var u8 = new Uint8Array(binaryMidi.length);
            // Copy over all the values
            for(var i=0;i<binaryMidi.length;i++){
              u16[i] = binaryMidi[i].charCodeAt(0);
              u8[i] = u16[i];
            }
            saveAs(new Blob([u8], {type:'audio/midi'}),id + ".mid");
    
            // Alternatively: This also works, but behaviour (playback in browser or download) depends on the browser and user settings:
            // var song = 'data:audio/midi;base64,' + base64midi;
            // window.open(song, "My MIDI file", "resizable=yes,scrollbars=no,status=no");
    
        },'xml');
    
        // remove the MIDI XSL from the transformation list
        delete $mei[id].xsltOptions['midi'];

    }
}

function base64DecodeUnicode(str) {
    // Convert Base64 encoded bytes to percent-encoding, and then get the original string.
    percentEncodedStr = atob(str).split('').map(function(c) {
        return '%' + ('00' + c.charCodeAt(0).toString(16)).slice(-2);
    }).join('');
    return decodeURIComponent(percentEncodedStr);
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
    var vrvTime = Math.max(0, time - 750);
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
