// DEFAULT VALUES FOR PAGE OPTIONS 
// To change page settings, override defaults on the hosting page. Example:
//    <script type="text/javascript">
//        var enableMidi = true;
//        var enableSearch = false;
//        var enableMenu = true;
//        var enableComments = true;
//    </script>   

var midi = (typeof enableMidi !== 'undefined') ? enableMidi : true; // enable MIDI playback
var searchForSelection = (typeof enableSearch !== 'undefined') ? enableSearch : true; // enable selection for searching
var showMenu = (typeof enableMenu !== 'undefined') ? enableMenu : true;  //  show menu for customization of the notation
var comments = (typeof enableComments !== 'undefined') ? enableComments : true;  // enable editorial comments


// Verovio options
// pageWidth * scale % = calculated width (should be 550-600px for DSL)
var $defaultVerovioOptions = {
    inputFormat:               'mei',
    scale:                40,
    pageWidth:            1800,
    pageHeight:           20000,
    pageMarginTop:        0,
    pageMarginLeft:       0,
    noHeader:             1,
    noFooter:             1,
    staffLineWidth:       0.25,
    lyricTopMinMargin:    4,
    lyricSize:            4.5,
    lyricNoStartHyphen:   1,
    spacingStaff:         3,
    spacingLinear:        0.9,
    spacingNonLinear:     0.3,
    font:                 'Bravura',
    adjustPageHeight:     1,
    noJustification:      1,
    breaks:               'encoded'
};

// global variables - do not change
var $mei = [];  // The array holding the MEI objects 
var page = 1;
var saxonReady = false;
var selectionmode  = "";
var selectionMEI    = "";
var selectionStart = "";
var selection      = [];

var vrvToolkit = new verovio.toolkit({});
 
// Define MEI object model
function meiObj (data, xml, verovioOptions) {
    this.data = data;  // MEI data as string
    this.xml = xml;    // MEI data as an XML document
    this.verovioOptions = verovioOptions;
    this.xsltOptions = [];
    this.notes = [];   // Array holding all note IDs (for phrase selection)
}
 
 
// Define optional transformations
/*
To add a transformation, clone the desired transformation option object. For example: 
    $mei[id].xsltOptions['clef'] = jQuery.extend(true, {}, $setClef);
Then change the properties as desired   
    $mei[id].xsltOptions['clef'].parameters['clef'] = 'G';
*/
 
var $show = {
    xslt:       'show.xsl',
    parameters: {
        mdiv:   ''
    }
}
 
var $transpose = {
    xslt:       'transpose.xsl',
    parameters: {
        interval:   0,
        direction:  ''
    }
}
 
var $setClef = {
    xslt:       'clef.xsl',
    parameters: {   
        clef:   ''
    }
}
 
var $setNoteValues = {
    xslt:       'duration.xsl',
    parameters: {   
        factor:   1
    }
}
 
var $setBeams = {
    xslt:       'beam.xsl',
    parameters: {}
}
 
var transformOrder = ['show', 'transpose', 'clef', 'noteValues', 'beams'];

var midiMenu = '\
    <div class="midi_player">\
        <div class="midi_button play" id="play_{id}">\
            <a href="javascript:void(0);" title="Afspil" onclick="play_midi(\'{id}\');"><span class=\'label\'>Afspil</span></a>\
        </div>\
        <div class="midi_button stop" id="stop_{id}">\
            <a href="javascript:void(0);" title="Stop afspilning" onclick="stop()"><span class=\'label\'>Stop</span></a>\
        </div>\
    </div>\
    <hr/>';
    
var meiOptionsMenu = ' \
    <form id="optionsForm_{id}" action="" class="mei_menu"> \
        <div> \
            <div class="menu_block">\
                <label for="clef_{id}">N&oslash;gle: </label> \
                <br/> \
                <input type="radio" name="clef" id="clef_{id}" value="original" checked="checked" onchange="updateFromForm(\'{id}\')"/> Original &#160;&#160; \
                <input type="radio" name="clef" value="G" onchange="updateFromForm(\'{id}\')"/> <span class="musical_symbols cursorHelp" title="G-nøgle på 2. linje">&#x1d11e;</span> &#160;&#160; \
                <input type="radio" name="clef" value="G8" onchange="updateFromForm(\'{id}\')"/> <span class="musical_symbols cursorHelp" title="Oktaverende G-nøgle">&#x1d120;</span> &#160;&#160; \
                <input type="radio" name="clef" value="F" onchange="updateFromForm(\'{id}\')"/> <span class="musical_symbols cursorHelp" title="F-nøgle på 4. linje (basnøgle)">&#x1d122;</span> &#160;&#160; \
            </div> \
            <hr/> \
            <div class="menu_block">\
                <label for="transposeVal_{id}">Transposition: </label> \
                <br/> \
                <select id="transposeVal_{id}" name="transposeVal" onchange="updateFromForm(\'{id}\')" class="custom_input"> \
                    <option value="0">Ingen</option> \
                    <option value="1">Lille sekund</option> \
                    <option value="2">Stor sekund</option> \
                    <option value="3">Lille terts</option> \
                    <option value="4">Stor terts</option> \
                    <option value="5">Kvart</option> \
                    <option value="6">Formindsket kvint</option> \
                    <option value="7">Kvint</option> \
                    <option value="8">Lille sekst</option> \
                    <option value="9">Stor sekst</option> \
                    <option value="10">Lille septim</option> \
                    <option value="11">Stor septim</option> \
                </select> \
                <input type="radio" name="direction" value="up" id="direction_{id}" checked="checked" onchange="updateFromForm(\'{id}\')"/> Op \
                <input type="radio" name="direction" value="down" onchange="updateFromForm(\'{id}\')"/> Ned \
            </div> \
            <hr/> \
            <div class="menu_block">\
                <label for="factor_{id}">Nodeværdier: </label> \
                <br/> \
                <input type="radio" name="factor" value="1" id="factor_{id}" checked="checked" onchange="updateFromForm(\'{id}\')"/> 1:1 &#160;&#160;&#160;&#160; \
                <input type="radio" name="factor" value="2" onchange="updateFromForm(\'{id}\')"/> 1:2 &#160;&#160;&#160;&#160; \
                <input type="radio" name="factor" value="4" onchange="updateFromForm(\'{id}\')"/> 1:4 &#160;&#160;&#160;&#160; \
            </div>\
            <div id="mdiv-select_{id}"> \
                <!--  mdiv-select indsættes automatisk her  --> \
            </div> \
        </div> \
    </form>';
 
 
function updateFromForm(id) {
    $('.wait_overlay').addClass('visible');
    console.log(id + ": Options changed");
    var result = { };
    $.each($('#optionsForm_' + id).serializeArray(), function() {
        result[this.name] = this.value;
    });
    updateFromOptions(id, result);
    $('.wait_overlay').removeClass('visible');
}
 
 
function updateFromOptions(id, options) {
    // Add the relevant transformations and remove those not needed
    if(options.mdiv) {
        console.log("Set mdiv:" + options.mdiv);
        $mei[id].xsltOptions['show'].parameters['mdiv'] = options.mdiv;
    };
    if(options.transposeVal != 0) {
        console.log("Transpose:" + options.transposeVal + options.direction);
        $mei[id].xsltOptions['transpose'] = $.extend(true, {}, $transpose);
        $mei[id].xsltOptions['transpose'].parameters['interval']   =  parseInt(options.transposeVal);
        $mei[id].xsltOptions['transpose'].parameters['direction'] =  options.direction;
    } else { 
        delete $mei[id].xsltOptions['transpose'] 
    };
    if(options.clef!='' && options.clef!='original') {
        console.log("Set clef:" + options.clef);
        $mei[id].xsltOptions['clef'] = $.extend(true, {}, $setClef);
        $mei[id].xsltOptions['clef'].parameters['clef'] = options.clef;
    } else { 
        delete $mei[id].xsltOptions['clef'] 
    };
    if(options.factor != 1) {
        console.log("Note values factor:" + options.factor);
        $mei[id].xsltOptions['noteValues'] = $.extend(true, {}, $setNoteValues);
        $mei[id].xsltOptions['noteValues'].parameters['factor']   =  parseInt(options.factor);
        /* second run: add beams if relevant */
        $mei[id].xsltOptions['beams'] = $.extend(true, {}, $setBeams);
    } else { 
        delete $mei[id].xsltOptions['noteValues'];
        delete $mei[id].xsltOptions['beams']
    };
    loadMei(id);
}
 
 
function loadPage(id) {
    // Verovio 1.1.6 needs: svg = vrvToolkit.renderPage(page, {});
    svg = vrvToolkit.renderToSVG(page, {});
    $("#" + id).html(svg);

    /* Handle editorial comments */
 
    /* Verovio only handles plain text in <annot>; to support formatting and links, get annotation contents from the data */
    var xsl = Saxon.requestXML("xsl/comments.xsl");
    var processor = Saxon.newXSLT20Processor(xsl);
    // transform annotations to HTML
    var annotations = processor.transformToDocument($mei[id].xml);
    if($(annotations).find("span").length > 0) { console.log("Retrieving annotations"); }
 
    /* Bind a click event on all editorial comment markers */
    if(comments) {
        $("#" + id + " .comment").each(function() {
            var commentId = $(this).attr("id");
            // Create a div for each comment 
            var div = '<div id="' + commentId + '_div" class="mei_comment"></div>';
            $("#" + id).append(div);
            // Make the div a hidden jQuery dialog 
            $("#" + commentId + "_div").dialog({
                  autoOpen: false,
                  closeOnEscape: true
            });
            // Put the annotation in it
            $("#" + commentId + "_div").html($(annotations).find("#" + commentId.replace('_dir','_content')).html());
            /* Make the bounding box clickable (works on Opera only )*/
            $(this).attr("pointer-events", "bounding-box");
            $(this).click(function(event) {
                /* Close all open dialogs? */
                //$(".ui-dialog-content").dialog("close");
                /* Reposition the dialog */
                $("#" + commentId + "_div").dialog( "option", "position", { my: "left top", at: "left bottom", of: event } );
                $("#" + commentId + "_div").dialog( "option", "height", "auto" );
                $("#" + commentId + "_div").dialog( "option", "minHeight", "32px" );
                $("#" + commentId + "_div").dialog( "option", "resizable", false );
                $("#" + commentId + "_div").dialog( "option", "title", "Tekstkritisk note" );
                /* Show the dialog */
                $("#" + commentId + "_div").dialog("open");
                $("#" + commentId + "_div").find("a").blur();
            });
            // Add a hover title
            var svgns = "http://www.w3.org/2000/svg";
            var title = document.createElementNS(svgns, 'title');
            title.setAttributeNS(null, 'class', 'labelAttr');
            title.innerHTML = "Tekstkritisk note";
            $(this).append(title);
            // Make the comment marker visible
            $(this).addClass('visible');
        });
    }
    
    /* Bind a click event handler on every note (MIDI jumping doesn't seem to work with rests) */
    $("#" + id + " .note").click(function() {
        var noteID = $(this).attr("id");
        if(isPlaying) { jumpTo(noteID); }
        // If not playing, start selection
        if(searchForSelection === true && isPlaying !== true) {
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
        if(midi || searchForSelection) {
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
        }
    })
    .mouseout(function() {
        $(".hover").removeClass('hover');
    });
    
    // Close selection mode when clicking outside selection
    // Overrides note clicking, unfortunately...
/*    $("#" + id).click(function() {
        if(selectionmode) {
            selectionmode = false;
            $(".selected").each(function() {
               $(this).removeClass('selected'); 
            });
        }
    });
*/    

    
};
 
function transform(mei, options) {
    if(saxonReady) {
        console.log("xslt: xsl/" + options.xslt);
        var xsl = Saxon.requestXML("xsl/" + options.xslt);
        var processor = Saxon.newXSLT20Processor(xsl);
        for (var property in options.parameters) {
            if (options.parameters.hasOwnProperty(property)) {
                processor.setParameter(null, property , options.parameters[property]);
                console.log("Parameter " + property + ": " + options.parameters[property]);                
            }
        }    
        var transformedMei = processor.transformToDocument(mei);
        return transformedMei;
    }
}
 
/* Apply the transformations and load the data */
function loadMei(id) {
    //stop midi playback before making any changes
    if(isPlaying === true) { stop(); }    
    var transformedMei = $mei[id].xml; 
    for (var index in transformOrder) {
        var key = transformOrder[index];
        if ($mei[id].xsltOptions.hasOwnProperty(key)) {
            transformedMei = transform(transformedMei, $mei[id].xsltOptions[key]);
        }
    }
    vrvToolkit.setOptions($mei[id].verovioOptions);
    vrvToolkit.loadData(Saxon.serializeXML(transformedMei));
//Debug:   
//alert(Saxon.serializeXML(transformedMei));    
//$("#debug_text").html(Saxon.serializeXML(transformedMei));
    loadPage(id);
}
 
 
function loadMeiFromDoc() {
    /* Read MEI data from <DIV> elements in the HTML document.
       @DSL: The @id of the target DIV is supposed to be the MEI file name without extension.
       The actual MEI data are read from a script element with @id = the MEI file name (without extension) + '_data'.
       To display options for transposition etc., add another <DIV> for the menu as shown below.
       If an MDIV other than the first is wanted, the word "MDIV" and its id must be appended to the DIV ids (except for the data DIV as explained below).
       Example: 
       <div id="Ul_1535_LN0076_000a04vMDIVmdiv-02_options" class="mei_options"><!-- menu will be generated here; must not be empty --></div>
       <div id="Ul_1535_LN0076_000a04vMDIVmdiv-02" class="mei"><!-- SVG will be put here; must not be empty --></div>
       To avoid duplicate IDs, the data must only be included once in the document _without_ any MDIV indication: 
       <script id="Ul_1535_LN0076_000a04v_data" type="text/xml">[MEI data here]</script> */
    $(".mei").each( function() {
        id = $(this).attr("id");
        console.log('Reading ' + id);
        var data = $(dataId(id)).html();
        $mei[id] = new meiObj({});
        $mei[id].verovioOptions = $defaultVerovioOptions;
        $mei[id].xsltOptions['show'] = $.extend(true, {}, $show);
        $mei[id].data = $(dataId(id)).html();
        var xml = $.parseXML($mei[id].data);
        $mei[id].xml = xml;
        // See if a particular <MDIV> is requested (i.e., hard-coded in the <div>'s @id)
        $mei[id].xsltOptions['show'].parameters['mdiv'] =  mdivId(id);

// Problem: på visse computere bliver alle @xml:id tomme, hvis der bruges mere end en transformation ??

//alert(xml.getElementsByTagName("mei")[0].namespaceURI);

        // See if the <script> element really contains an MEI document with a <body> element
        if (xml.getElementsByTagNameNS("http://www.music-encoding.org/ns/mei","body").length > 0) {
            // If so, render
//alert(id); 

            loadMei(id);
            // Make a list of all <note> IDs 
            $mei[id].notes = [];
            $("#" + id).find(".note").each(function(){ $mei[id].notes.push(this.id); });            
        }
        if(showMenu) { createMenu(id); };
    });
}

function dataId(id) {
    // Return the id of the <script> element that holds the relevant data (necessary for IDs also containing information about the <mdiv> section to extract).
    // If there is no data marked specifically for the desired <mdiv>, we assume that data is to be taken from the original data containing all the MDIVs  
    var dataElementId = (id.indexOf('MDIV') > 0 && $('#' + id + '_data').length == 0) ? '#' + id.substring(0, id.indexOf('MDIV')) + '_data' : '#' + id + '_data';  
    return dataElementId;
}

function mdivId(id) {
    // Return the id of the desired <mdiv> element specified as part of a compound ID
    var mdiv = (id.indexOf("MDIV") > 0) ? id.substring(id.indexOf("MDIV")+4) : "";  
    return mdiv;
}

function createMenu(id){
    // Create a menu for an MEI object in the document
    if(showMenu) {
        var menu = meiOptionsMenu.replace(/{id}/g, id);
        if(midi) { menu = midiMenu.replace(/{id}/g, id) + menu}
        $("#" + id + "_options").html(menu);
        var xml = $mei[id].xml;
        // Add an MDIV select box to the menu if applicable
        if(typeof $mei[id] != "undefined") {
            var mdivs = xml.getElementsByTagNameNS("http://www.music-encoding.org/ns/mei","mdiv");
            // if the encoding has more than one MDIV element and no selection is hard-coded, generate a select element
            if (id.indexOf("MDIV") < 0 && mdivs.length > 1) {
                var select = '<div class="menu_block"> \
                    <hr/> \
                    <label for="mdiv_' + id + '">Satsdel: </label> \
                    <select name="mdiv" id="mdiv_' + id + '" onchange="updateFromForm(\'' + id + '\')">';
                for (var i = 0; mdivs[i]; i++) {
                    var mdiv = mdivs[i].getAttribute("xml:id");
                    select = select + '<option value="' + mdiv + '">' + mdiv + '</option>';
                }
                select = select + '</select>'; 
                $("#mdiv-select_" + id).html(select);
            }
        }
        $("#" + id +"_options").css("display","block");
    }
}

// Functions for phrase selection

// Add or remove CSS class on all notes in selection
function selectionChangeClass (id, noteID, mode, className) {
    var start = $mei[id].notes.indexOf(selectionStart);
    var end = $mei[id].notes.indexOf(noteID);
    if($mei[id].notes.indexOf(selectionStart) > $mei[id].notes.indexOf(noteID) && $mei[id].notes.indexOf(noteID) > -1) {
        // Selection is "backwards"; swap start and end positions 
        start = end;
        end = $mei[id].notes.indexOf(selectionStart);
    } 
    for (index = start; index <= end; index++) {
        if(mode == "add") {
            $("#" + $mei[id].notes[index]).addClass(className);
        } else {
            $("#" + $mei[id].notes[index]).removeClass(className);
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
            // Add the box to the inner SVG element
            document.getElementById(selectionMEI).querySelector('svg').querySelector('svg').appendChild(rect);
            // Add a hover title
            var title = document.createElementNS(svgns, 'title');
            title.setAttributeNS(null, 'class', 'labelAttr');
            title.innerHTML = "Søg efter den markerede frase";
            document.getElementById('selectionBox_' + layer).appendChild(title);

            // Parse original XML from string in document
            var xml = $mei[selectionMEI].data;
            var xmlDoc = $.parseXML(xml);

            // Bind a click event handler to the box
            $('#selectionBox_' + layer).click(function() {
                var qNotes = [];
                // Look up MIDI pitch numbers in the original MEI
                for (nID in selection) {
                    qNotes.push(FindByAttributeValue(xmlDoc,"xml:id",selection[nID]).getAttribute("pnum"));
                }
                // Limit query length to 12 notes
                if(qNotes.length > 12) {
                    alert("Søgning er begrænset til tolv toner. \nSøger efter de første tolv toner i markeringen.");
                    qNotes.length = 12;
                }
                // Check for user-defined transposition
                if($("#transposeVal_" + selectionMEI + " option:selected").val() > 0) {
                    var val = parseInt($("#transposeVal_" + selectionMEI + " option:selected").val());
                    var transpose = ($("input[name='direction_" + selectionMEI + "']:checked").val() == "up") ? val : -1 * val;
                    for (i in qNotes) {
                        qNotes[i] = add(qNotes[i], transpose);
                    } 
                }
                // Transpose to around octave 4 (aiming at average pitch around a4 = 69)
                var transposeOctaves = Math.round((69 - (qNotes.reduce(add, 0) / qNotes.length)) / 12);
                for (i in qNotes) {
                    qNotes[i] = add(qNotes[i], transposeOctaves * 12);
                }
                // Search!
                window.location.href = "http://salmer.dsl.lan:8080/exist/rest/db/salmer/mei_search.xq?a=" + qNotes.join("-");
//                window.location.href = "http://dcm-udv-01.kb.dk:8080/exist/rest/db/dsl/mei_search.xq?a=" + qNotes.join("-");
            });

        }
    });
}
 
function FindByAttributeValue(doc, attribute, value, element_type)    {
    // rather slow solution; querySelector would be better but didn't seem to work with '[xml:\\id = "value"]'
    element_type = element_type || "*";
    var All = doc.getElementsByTagName(element_type);
    for (var i = 0; i < All.length; i++)       {
    if (All[i].getAttribute(attribute) == value) { return All[i]; }
    }
} 
 
function add(a, b) {
    return parseInt(a) + parseInt(b);
}
 
// For debugging
function getAttributes ( $node ) {
      $.each( $node[0].attributes, function ( index, attribute ) {
      console.log(attribute.name+':'+attribute.value);
   } );
}
 
// File uploading
 
// These functions are used by local MEI viewer only
function uploadFile(id){
    var file = window.URL.createObjectURL(document.getElementById('upload').files[0]);
    var filename = document.getElementById("upload").value.replace(/.*[\/\\]/, '');
    $mei[id] = new meiObj({});
    $mei[id].verovioOptions = $defaultVerovioOptions;
    $mei[id].xsltOptions['show'] = $.extend(true, {}, $show);
    $mei[id].xml = Saxon.requestXML(file);
    if(document.getElementById("meiFileName")) { document.getElementById("meiFileName").innerHTML = filename; } 
    if(document.getElementById("renderMeiFileLabel")) { document.getElementById("renderMeiFileLabel").style.visibility="visible"; }
    if(document.getElementById(id + "_options") && showMenu) { document.getElementById(id + "_options").style.visibility="visible"; }
    if(document.getElementById(id + "_data")) {
        //An identity transform seems to be necessary to get the right data type for serialization
        var xsl = Saxon.requestXML("xsl/nop.xsl");
        var processor = Saxon.newXSLT20Processor(xsl);
        var MEIdata = processor.transformToDocument($mei[id].xml);
        document.getElementById(id + "_data").innerHTML = Saxon.serializeXML(MEIdata);
    }
    loadMeiFromDoc();
    if(showMenu) { $("#" + id +"_options").css("display","block"); }
}
 
function resetOptions(id) {
    if(showMenu) {
        document.getElementById('clef_' + id).checked = true;
        document.getElementById('transposeVal_' + id).value = '0';
        document.getElementById('factor_' + id).checked = true;
        document.getElementById('mdiv-select_' + id).innerHTML = '';
    }
}
 
 
var onSaxonLoad = function() {        
    console.log("Loaded Saxon");
    saxonReady = true;
    if(midi) { initMidi() }
    loadMeiFromDoc();    
};