// DEFAULT VALUES FOR PAGE OPTIONS
// To change page settings, override defaults on the hosting page. Example:
//    <script type="text/javascript">
//        var enableMenu = true;             // show options menu
//        var enableLink = false;            // do not show link to melody database
//        var enablePrint = true;            // show link to print version
//        var enableMidi = true;             // enable MIDI playback
//        var enableMidiDownload = true;     // enable binary MIDI download
//        var enableOptions = true;          // enable notation customization options
//        var enableSearch = false;          // disable phrase selection for melodic search
//    </script>

var showMenu = (typeof enableMenu !== 'undefined') ? enableMenu : true;  // options menu main switch
var showPrint = (typeof enablePrint !== 'undefined') ? enablePrint : true;  // show link to print version?
var linkToExist = (typeof enableLink !== 'undefined') ? enableLink : true;  // show link to melody database?
var midi = (typeof enableMidi !== 'undefined') ? enableMidi : true; // enable MIDI playback?
var midiDownload = (typeof enableMidiDownload !== 'undefined') ? enableMidiDownload : false; // disable MIDI download?
var showOptions = (typeof enableOptions !== 'undefined') ? enableOptions : true;  //  show menu for customization of the notation?
var searchForSelection = (typeof enableSearch !== 'undefined') ? enableSearch : true; // enable phrase selection for melodic search?
var comments = true;  // show editorial comments

var params = {}
var language = 'da';  // default language


// Verovio options
var $defaultVerovioOptions = {
    from:                 'mei',
    scale:                40,
    svgViewBox:           true,
    pageMarginTop:        0,
    pageMarginLeft:       0,
    header:               'none',
    footer:               'none',
    staffLineWidth:       0.25,
    lyricTopMinMargin:    4,
    lyricSize:            5.5,
    lyricNoStartHyphen:   1,
    spacingSystem:        0,
    spacingLinear:        0.75,
    spacingNonLinear:     0.35,
    spacingDurDetection:  true,
    font:                 'Bravura',
    adjustPageHeight:     1,
    adjustPageWidth:      1,
    noJustification:      1,
    breaks:               'encoded',
    systemDivider:        'none'
};

// global variables - do not change
var host = "https://melodier.dsl.dk"

var $mei = [];  // The array holding the MEI objects
var page = 1;
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
    this.xsltOptions = {
        id:   {},
        doc:  {},
        show: {
            xslt:       'show.xsl',
            parameters: {
                mdiv:   ''
            }
        }
    };
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

var $highlight = {
    xslt:       'highlight.xsl',
    parameters: {
        ids:   '',
        excerpt: 'yes'
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

var transformOrder = ['show', 'highlight', 'transpose', 'clef', 'noteValues', 'beams', 'midi'];

var midiMenu = '\
    <div class="mei_menu_content"> \
        <div class="midi_player">\
            <div class="midi_download" onclick="download_midi(\'{id}\')" title="Download som MIDI-fil">\
                <!-- download link here -->\
            </div>\
            <div class="midi_button play" id="play_{id}" onclick="play_midi(\'{id}\');">\
                <span class="symbol"><span class="label"><span class="lang da" title="Afspil">Afspil</span><span class="lang en" title="Play">Play</span></span></span>\
            </div>\
            <div class="midi_button stop" id="stop_{id}" onclick="stop()">\
                <span class="symbol"><span class="label"><span class="lang da" title="Stop afspilning">Stop</span><span class="lang en" title="Stop">Stop</span></span></span>\
            </div>\
        </div>\
    </div>';

var printMenu = '\
    <div class="mei_menu_content"> \
        <div class="print_link">\
            <a href="javascript:void(0);" onclick="printPage(\'{id}\')">\
                <div class="menu_button pdf_download">\
                    <span class="label"><span class="lang da" title="Download noder og tekst som PDF">Download PDF</span><span class="lang en" title="Download music and text as PDF">Download PDF</span></span>\
                </div>\
                <!--<div class="menu_button print"/>\
                    <span class="label"><span class="lang da" title="Printervenlig version">Printervenlig version</span><span class="lang en" title="Printer version">Printer version</span></span>\
                </div>-->\
            </a>\
        </div>\
    </div>';

var existMenu = '\
    <div class="mei_menu_content"> \
        <div class="exist_link">\
            <a href="' +  host + '/document.xq?doc={id}.xml">\
                <div class="menu_button database">\
                    <span class="label"><span class="lang da">Slå op i melodibasen</span><span class="lang en">See database entry</span></span>\
                </div>\
            </a>\
        </div>\
    </div>';

var meiOptionsMenu = ' \
    <div class="mei_menu_content"> \
        <form id="optionsForm_{id}" action="' + host + '/print.xq" method="GET" target="_blank" class="mei_menu">\
            <div class="menu_block"><span class="lang da">N&oslash;gle</span><span class="lang en">Clef</span>:<br/>\
                <input type="hidden" name="doc" value="{id}.xml"/>\
                <input type="radio" name="clef" id="clef_{id}" value="original" checked="checked" onchange="updateFromForm(\'{id}\')"/> <label for="clef_{id}" class="cursorHelp"><span class="lang da" title="Original nøgle">Original</span><span class="lang en" title="Original clef">Original</span></label> &#160;&#160; \
                <input type="radio" name="clef" id="Gclef_{id}" value="G" onchange="updateFromForm(\'{id}\')"/> <label for="Gclef_{id}" class="musical_symbols cursorHelp"><span class="lang da" title="G-nøgle på 2. linje">&#x1d11e;</span><span class="lang en" title="G clef on 2. line (treble clef)">&#x1d11e;</span></label> &#160;&#160; \
                <input type="radio" name="clef" id="G8clef_{id}" value="G8" onchange="updateFromForm(\'{id}\')"/> <label for="G8clef_{id}" class="musical_symbols cursorHelp"><span class="lang da" title="Oktaverende G-nøgle">&#x1d120;</span><span class="lang en" title="Transposing G clef">&#x1d120;</span></label> &#160;&#160; \
                <input type="radio" name="clef" id="Fclef_{id}" value="F" onchange="updateFromForm(\'{id}\')"/> <label for="Fclef_{id}" class="musical_symbols cursorHelp"><span class="lang da" title="F-nøgle på 4. linje (basnøgle)">&#x1d122;</span><span class="lang en" title="F clef on 4. line (bass clef)">&#x1d122;</span></label> &#160;&#160; \
            </div> \
            <hr/> \
            <div class="menu_block" id="duration_{id}"><span class="lang da">Nodeværdier</span><span class="lang en">Note values</span>:<br/> \
                <input type="radio" name="factor" value="1" id="factor_{id}" checked="checked" onchange="updateFromForm(\'{id}\')"/> <label for="factor_{id}" class="cursorHelp"><span class="lang da" title="Originale nodeværdier">1:1</span><span class="lang en" title="Originale note values">1:1</span></label>&#160;&#160;&#160;&#160; \
                <input type="radio" name="factor" value="2" id="factor2_{id}" onchange="updateFromForm(\'{id}\')"/> <label for="factor2_{id}" class="cursorHelp"><span class="lang da" title="Halve nodeværdier">1:2</span><span class="lang en" title="Diminish note values by factor 2">1:2</span></label> &#160;&#160;&#160;&#160; \
                <input type="radio" name="factor" value="4" id="factor4_{id}" onchange="updateFromForm(\'{id}\')"/> <label for="factor4_{id}" class="cursorHelp"><span class="lang da" title="Kvarte nodeværdier">1:4</span><span class="lang en" title="Diminish note values by factor 4">1:4</span></label> &#160;&#160;&#160;&#160; \
                <hr/> \
            </div>\
            <div class="menu_block"><span class="lang da">Transposition</span><span class="lang en">Transposition</span>:<br/> \
                <select id="transposeVal_{id}" name="transposeVal" onchange="updateFromForm(\'{id}\')" class="custom_input"> \
                    <option value="0" class="lang da">Ingen</option> \
                    <option value="0" class="lang en">None</option> \
                    <option value="1" class="lang da">Lille sekund</option> \
                    <option value="1" class="lang en">Minor second</option> \
                    <option value="2" class="lang da">Stor sekund</option> \
                    <option value="2" class="lang en">Major second</option> \
                    <option value="3" class="lang da">Lille terts</option> \
                    <option value="3" class="lang en">Minor third</option> \
                    <option value="4" class="lang da">Stor terts</option> \
                    <option value="4" class="lang en">Major third</option> \
                    <option value="5" class="lang da">Kvart</option> \
                    <option value="5" class="lang en">Fourth</option> \
                    <option value="6" class="lang da">Formindsket kvint</option> \
                    <option value="6" class="lang en">Diminished fifth</option> \
                    <option value="7" class="lang da">Kvint</option> \
                    <option value="7" class="lang en">Fifth</option> \
                    <option value="8" class="lang da">Lille sekst</option> \
                    <option value="8" class="lang en">Minor sixth</option> \
                    <option value="9" class="lang da">Stor sekst</option> \
                    <option value="9" class="lang en">Major sixth</option> \
                    <option value="10" class="lang da">Lille septim</option> \
                    <option value="10" class="lang en">Minor seventh</option> \
                    <option value="11" class="lang da">Stor septim</option> \
                    <option value="11" class="lang en">Major seventh</option> \
                </select> \
                <input type="radio" name="direction" value="up" id="direction_{id}" checked="checked" onchange="if(document.getElementById(\'transposeVal_{id}\').value > 0) {updateFromForm(\'{id}\')} else {return false;}"/> <label for="direction_{id}" class="cursorHelp"><span class="lang da" title="Transponer op">Op</span><span class="lang en" title="Transpose up">Up</span></label> \
                <input type="radio" name="direction" value="down" id="directionDown_{id}" onchange="if(document.getElementById(\'transposeVal_{id}\').value > 0) {updateFromForm(\'{id}\')} else {return false;}"/> <label for="directionDown_{id}" class="cursorHelp"><span class="lang da" title="Transponer ned">Ned</span><span class="lang en" title="Transpose down">Down</span></label> \
            </div> \
            <div id="mdiv-select_{id}"> \
                <!--  mdiv-select indsættes automatisk her  --> \
            </div> \
        </form> \
    </div>';


function updateFromForm(id) {
    console.log("Re-rendering " + id);
    var result = { };
    $.each($('#optionsForm_' + id).serializeArray(), function() {
        result[this.name] = this.value;
    });
    updateFromOptions(id, result);
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
    // send a POST request to get the MEI data
    $.post(host + '/transform_mei.xq',$mei[id].xsltOptions,function(data){ renderData(data); },'xml');
}

function addComments(data) {
    /* Verovio only handles plain text in <annot>; to support formatting and links, get annotation contents from the data */

    console.log("Retrieving editorial comments");
    var targetId = $(data.firstChild).attr('targetId')
    // strip off the wrapping <response> element to get the MEI root element
    var xml = data.firstChild;
    // make a document fragment containing the MEI
    var frag = document.createDocumentFragment();
    while(xml.firstChild) {
        frag.appendChild(xml.firstChild);
    }
    // too much serializing and re-parsing here, but the 'data' parameter does not seem to be an xml document;
    // the following seems to get the data types right:
    var xmlString = (new XMLSerializer()).serializeToString(frag);
    var annotations = $.parseXML(xmlString);

    /* Bind a mouseover event on all editorial comment markers */
    $("#" + targetId + " .comment").each(function() {
        var commentId = $(this).attr("id");
        // Create a div for each comment
        var div = '<div id="' + commentId + '_div" class="mei_comment"></div>';
        $("#" + targetId).append(div);        
        // Make the div a hidden jQuery dialog
        initializeComment(commentId + "_div");
        // Put the annotation in it
        $("#" + commentId + "_div").html($(annotations).find("#" + commentId.replace('_dir','_content')).html());
        $(this).mouseover(function(event) {
            openOnMouseover(commentId + "_div");
        });
        if(comments) {
            // Make comment markers visible
            $(this).css('display','inline');
        } else {
            $(this).css('display','none');
        }
        $("#" + commentId + "_div").parent().mouseleave(function(){
            $("#" + commentId + "_div").dialog("close");
        }); 
    });
}

function renderData(data) {
    if(isPlaying === true) { stop(); }
    var targetId = $(data.firstChild).attr('targetId')
    // strip off the wrapping <response> element to get the MEI root element
    var mei = data.firstChild;
    // make a document fragment containing the MEI
    var frag = document.createDocumentFragment();
    while(mei.firstChild) {
        frag.appendChild(mei.firstChild);
    }
    // too much serializing and re-parsing here, but the 'data' parameter does not seem to be an xml document;
    // the following seems to get the data types right:
    var xmlString = (new XMLSerializer()).serializeToString(frag);
    // save the MEI xml for later;
    $mei[targetId].xml = $.parseXML(xmlString);

    vrvToolkit.setOptions($mei[targetId].verovioOptions);
    vrvToolkit.loadData(xmlString);
    svg = vrvToolkit.renderToSVG(page, {});
    $("#" + targetId).html(svg);

    // Make a list of all <note> IDs
    $mei[targetId].notes = [];
    $("#" + targetId).find(".note").each(function(){ $mei[targetId].notes.push(this.id); });

    // create menu if not done already
    if(showMenu && $("#" + targetId +"_options").css("display")=="none") { createMenu(targetId); };

    /* Bind a click event handler on every note (MIDI jumping doesn't seem to work with rests) */
    $("#" + targetId + " .note").click(function() {
        var noteID = $(this).attr("id");
        if(isPlaying) { jumpTo(noteID); }
        // If not playing, start selection
        if(searchForSelection === true && isPlaying !== true) {
            if(selectionmode == "open" && noteID != selectionStart && targetId == selectionMEI) {
                // Range selected
                selectionmode = "closed";
                selectionChangeClass(targetId, noteID, "add", "selected");
                saveSelection();
            } else
            if(selectionmode == "closed" || noteID == selectionStart || (selectionmode == "open" && targetId != selectionMEI) ){
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
                selectionMEI = targetId;
                $(this).addClass('selected');
            }
        }
    })
    /* Bind a hover event handler on notes in selection mode */
    .mouseover(function() {
        if(midi || searchForSelection) {
            var noteID = $(this).attr("id");
            if(selectionmode == "open" && selectionMEI == targetId && $(this).attr("id") !== selectionStart) {
                // One end of the selection is made; higlight all notes in between
                selectionChangeClass(targetId, noteID, "add", "hover");
            } else if(selectionmode != "closed" && (selectionMEI == targetId || selectionMEI == "")) {
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

    /*  Disable note value reduction in neume-only notation */
    if($("#" + targetId + " .note").length <= $("#" + targetId + " .neume").length){
        $("#duration_" + targetId).css("display","none");
        console.log("hiding #duration_" + targetId);
    };


    // Close selection mode when clicking outside selection
    // Overrides note clicking, unfortunately...
/*    $("#" + targetId).click(function() {
        if(selectionmode) {
            selectionmode = false;
            $(".selected").each(function() {
               $(this).removeClass('selected');
            });
        }
    });
*/

    // Set max. SVG width to initial width to avoid up-scaling 
    var outerSvg = document.getElementById(targetId).firstChild;
    var viewBox = outerSvg.getAttribute('viewBox').split(' ');
    console.log('Set SVG width to ' + viewBox[2] + 'px');  
    outerSvg.setAttribute('style', 'max-width: ' + viewBox[2] + 'px;');
    
    // Set width of .mei_wrapper container accordingly
    var containerWidth = parseInt(viewBox[2]) + 300;
    if ($(".metadata")) {
        document.getElementById(targetId).parentNode.parentNode.setAttribute('style', 'max-width: ' + containerWidth + 'px;');
    }

    // send a POST request to get the editorial comments formatted as HTML
    $.post(host + '/transform_mei.xq?doc=' + $mei[targetId].xsltOptions['doc'] + '&id=' + targetId + '&xsl=comments.xsl',
    '',function(data){ addComments(data); },'xml');

    // In search results, move the '[...]' omission markers all to the left
    $(".fragment text").each(function() {
        $(this).attr('x','750');
    });

    gotoAnchor();

}

function rerenderAllSVG() {
    console.log("Re-rendering all SVGs");
    $('.mei').each(function() {
        updateFromForm($(this).attr('id'));
    });
}

function loadMeiFromDoc() {
    /* Read MEI data from <DIV> elements in the HTML document.
       @DSL: The @id of the target DIV is supposed to be the MEI file name without extension.
       To display options for transposition etc., add another <DIV> for the menu as shown below.
       If an MDIV other than the first is wanted, the word "MDIV" and its id must be appended to the DIV ids (except for the data DIV as explained below).
       Example:
       <div id="Ul_1535_LN0076_000a04vMDIVmdiv-02" class="mei"><!-- SVG will be put here; must not be empty --></div>
       <div id="Ul_1535_LN0076_000a04vMDIVmdiv-02_options" class="mei_options"><!-- menu will be generated here; must not be empty --></div>
       If content is to be highlighted on loading (like search matches), a whitespace-separated list of xml:ids should be put in an invisible <div> inside the 'options' <div>:
       <div id="Ul_1535_LN0076_000a04vMDIVmdiv-02_options" class="mei_options">
           <div class="highlight_list" style="display:none">Ul_1535_LN0076_000a04v_m-42 Ul_1535_LN0076_000a04v_m-43</div>
       </div> */

    $(".mei").each( function() {
        id = $(this).attr("id");

        // break floating layout after score and menu (forcing following elements and text to appear below)
        $("<div class='clear_both'><!-- clear --></div>").insertAfter($(this).parent());

        console.log('Reading ' + id);
        $mei[id] = new meiObj({});
        $mei[id].verovioOptions = $defaultVerovioOptions;
        $mei[id].xsltOptions['id'] = id;
        $mei[id].xsltOptions['doc'] = filename_from_dataId(id) + '.xml';
        $mei[id].xsltOptions['show'].parameters['mdiv'] =  mdivId(id);
        $("#"+id+"_options .highlight_list").each( function() {
            //console.log("Highlight:" + $(this).html());
            $mei[id].xsltOptions['highlight'] = $.extend(true, {}, $highlight);
            $mei[id].xsltOptions['highlight'].parameters['ids'] = $(this).html();
        });
        // send a POST request to get the MEI data
        $.post(host + '/transform_mei.xq',$mei[id].xsltOptions,function(data){ renderData(data); },'xml');
    });
}

function filename_from_dataId(id) {
    // Return the name of the file corresponding to a data ID.
    var filename = id.indexOf('MDIV') > 0 ? id.substring(0, id.indexOf('MDIV')) : id;
    return filename;
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
        var menu = '';
        if(showPrint) { menu = printMenu.replace(/{id}/g, id)}
        if(linkToExist) { menu = existMenu.replace(/{id}/g, id) + menu}
        if((linkToExist || showPrint) && showOptions) { menu = '<hr class="mei_menu_content"/>' + menu}
        if(showOptions) { menu = meiOptionsMenu.replace(/{id}/g, id) + menu}
        if((midi || showPrint || linkToExist) && showOptions) { menu = '<hr class="mei_menu_content"/>' + menu}
        if(midi) { menu = midiMenu.replace(/{id}/g, id) + menu}
        if(menu != '') { menu = '<div id="' + id + '_menu_container" class="mei_menu_container">\
                <div class="menu_icon_container"><img src="' + host + '/style/img/menulink.png" alt="menu" class="mei_menu_icon"/></div>\
                ' + menu + '</div>'; }
        $("#" + id + "_options").html(menu);
        var xml = $mei[id].xml;
        // Add an MDIV select box to the menu if applicable
        if(typeof $mei[id] != "undefined") {
            var mdivs = xml.getElementsByTagNameNS("http://www.music-encoding.org/ns/mei","mdiv");
            // if the encoding has more than one MDIV element and no selection is hard-coded, generate a select element
            if (id.indexOf("MDIV") < 0 && mdivs.length > 1) {
                var select = '<div class="menu_block mei_menu_content"> \
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
        // set menu language
        $("#" + id +"_options .lang:not(." + language + ")").hide();
        $("#" + id +"_options .lang." + language).show();
        // avoid selecting a hidden value
        $("#transposeVal_" + id)[0].selectedIndex = $("#transposeVal_" + id + " option." + language).first().index();
        if(!midiDownload){
            $("#" + id + "_options .midi_download").remove();
        }
    }
}


function makeQueryFromForm(id) {
  const formData = new FormData(document.getElementById("optionsForm_" + id));
  const data = [...formData.entries()];
  const asString = data
      .map(x => `${encodeURIComponent(x[0])}=${encodeURIComponent(x[1])}`)
      .join('%26');
  // or, ignoring IE 11: 
  // const asString = new URLSearchParams(formData).toString();
  return asString;
}

// Printing or PDF download
function printPage(id) {
    // Generate PDF:
    var formObj = document.getElementById("optionsForm_" + id);
    var requestedURI = encodeURIComponent(formObj.action) + "%3F" + makeQueryFromForm(id) 
    // Make a PDF file from the desired page
    //console.log(host + "/pdf.xq?url=" + requestedURI);
    location.href = host + "/pdf.xq?url=" + requestedURI;
    
    // Alternatively, show the printer-friendly page:
    // $("#optionsForm_" + id).submit();
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
            title.innerHTML = "Søg efter de markerede toner";
            document.getElementById('selectionBox_' + layer).appendChild(title);

            // Parse original XML from string in document
            var xmlDoc = $mei[selectionMEI].xml;

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
                window.location.href = host + "/mei_search.xq?a=" + qNotes.join("-");
            });

        }
    });
}

function loadMeiMetadata() {
    /* Retrieve MEI metadadata if applicable */
    var doc = params.doc;
    $(".mei_metadata").each( function() {
        var id = $(this).attr("id");
        console.log('Retrieving MEI metadata');
        $.post(host + '/document_metadata.xq?language=' + language + '&doc=' + doc,function(data){
            $("#" + id).html(data);
            // make certain elements foldable
            $(".trigger_foldable").click(function(){
                var fold_id = $(this).attr("id").substr(8);
                $("#" + fold_id).slideToggle();
                $("#unfolded_" + fold_id).toggle();
                $("#folded_" + fold_id).toggle();
            });
            gotoAnchor();            
        },'html');
    });
}

function loadTeiText() {
    /* Retrieve TEI vocal text if applicable. */
    if(params.doc) {
        /* Filter away MDIV information from the file name */
        var doc = params.doc.search('MDIV') > 0 ? params.doc.substring(0,params.doc.indexOf('MDIV')) + '.xml' : params.doc;
        $(".tei_vocal_text").each( function() {
            var id = $(this).attr("id");
            /*  TEI file name and MEI mdiv ID are stored in the DIV's @class */
            var params = $(this).attr("class").split(" ");
            console.log('Retrieving TEI text');
            $.post(host + '/document_text.xq?doc=' + doc + '&tei=' + params[1] + '&mdiv=' + params[2],function(data){
                $("#" + id).html(data);
                addTeiComment(id);
                if(comments) {
                    // Make comment markers visible
                    $("#" + id).find(".textcriticalnote.annotation-marker").css('display','inline');
                } else {
                    $("#" + id).find(".textcriticalnote.annotation-marker").css('display','none');
                }
                gotoAnchor();
            },'html');
        });
    }
}

function addTeiComment(targetId) {
    /* Bind a mouseover event on all editorial comment markers */
    $("#" + targetId + " .appnotecontents").each(function() {
        var commentId = $(this).attr("id");
        var markerId = "appnotelink" + commentId;
        // Make the comment a hidden jQuery dialog
        initializeComment(commentId);
        $("#" + markerId).mouseover(function(event) {
            openOnMouseover(commentId);
        });
        if(comments) {
            // Make comment markers visible
            $("#" + markerId).css('display','inline');
        } else {
            $("#" + markerId).css('display','none');
        }
        $(this).parent().mouseleave(function(){
            $("#" + commentId).dialog("close");
        }); 
    });
}

function initializeComment(commentId) {
    $("#" + commentId).dialog({
        autoOpen: false,
        closeOnEscape: true,
        show: {
            effect: "fade",
            duration: 300
        },
        hide: {
            effect: "fade",
            duration: 300
        }
    });
}

function openOnMouseover(commentId) {
// Opens a textcritical note dialog. 
    // Close all open dialogs 
    $(".ui-dialog-content").dialog("close");
    // Reposition the dialog 
    $("#" + commentId).dialog( "option", "position", { 
        my: "left-20 top-20",
        at: "left top",
        of: event,
        offset: "20 200",
        collision: "none",
        resizable: false,
        draggable: false } );
    $("#" + commentId).dialog( "option", "height", "auto" );
    $("#" + commentId).dialog( "option", "minHeight", "32px" );
    $("#" + commentId).dialog( "option", "resizable", false );
    $("#" + commentId).dialog( "option", "title", "Tekstkritik" );
    // Show the dialog 
    $("#" + commentId).dialog("open");    
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


function resetOptions(id) {
    if(showMenu) {
        document.getElementById('clef_' + id).checked = true;
        document.getElementById('transposeVal_' + id).value = '0';
        document.getElementById('factor_' + id).checked = true;
        document.getElementById('mdiv-select_' + id).innerHTML = '';
    }
}

function gotoAnchor() {
    if(window.location.hash) {
        window.location.href=window.location.hash; 
    }
}

// HTML table sorting adapted from https://www.w3schools.com/howto/howto_js_sort_table.asp
function sortTable(tableId, n, numeric) {
  // function made asynchronous to allow the "busy" overlay to get activated first
  setTimeout(function() {
          var table, rows, switching, i, x, y, shouldSwitch, dir, switchcount = 0;
          table = document.getElementById(tableId);
          switching = true;
          dir = "asc";
          while (switching) {
            switching = false;
            rows = table.rows;
            for (i = 1; i < (rows.length - 1); i++) {
              shouldSwitch = false;
              x = rows[i].getElementsByTagName("TD")[n];
              y = rows[i + 1].getElementsByTagName("TD")[n];
              xval = numeric ? Number(x.textContent) : x.textContent.toLowerCase()
              yval = numeric ? Number(y.textContent) : y.textContent.toLowerCase()
              if (dir == "asc") {
                if (xval > yval) {
                  shouldSwitch = true;
                  break;
                }
              } else if (dir == "desc") {
                if (xval < yval) {
                  shouldSwitch = true;
                  break;
                }
              }
            }
            if (shouldSwitch) {
              rows[i].parentNode.insertBefore(rows[i + 1], rows[i]);
              switching = true;
              switchcount ++;
            } else {
              if (switchcount == 0 && dir == "asc") {
                dir = "desc";
                switching = true;
              }
            }
          }
          // update sort indicators
          for (i = 0; i < 3; i++) {
            if (i == n) {
              if (dir == "asc") {
                document.getElementById(tableId + "_sort_" + i).src = "/style/img/sort_up.png";
              } else if (dir == "desc") {
                document.getElementById(tableId + "_sort_" + i).src = "/style/img/sort_down.png";
              }
            } else {
              document.getElementById(tableId + "_sort_" + i).src = "/style/img/sort_no.png";
            }
          }
          $(".wait_overlay").hide();
    }, 10);
    $(".wait_overlay").show();
}

function initMusic(lang) {
    if(lang) { 
        language = lang;
    }
    if(midi) { initMidi() }
    loadMeiFromDoc();
    loadMeiMetadata();
    if(window.location.hostname.search('melodier.dsl.dk') >= 0) { loadTeiText() };
}

$(document).ready(function() {
    // construct a map of URL params. Would be nice to use new URLSearchParams(),
    // but it is not supported by IE11 :'-(
    var qstring = window.location.search.replace(/^\?/, '') // strip any leading question mark
    var urlParams = qstring.split('&') // split into ["foo=bar", "baz=boo"]
    urlParams.forEach(function (param) {
        param = param.split('=')
        params[param[0]] = param[1]
    })
    scriptLang = new URL(host + "/" + $("script[src*='MeiAjax.js']").attr("src")).searchParams.get("lang");
    // language priority: 1) language requested in the querystring; 2) language requested in the js script tag; 3) default language
    if(params.lang) {language = params.lang} else if(scriptLang) {language = scriptLang}
    $(".lang:not(." + language + ")").hide();
    $(".lang." + language).show();
    console.log("Language set to " + language);    
    initMusic(language);
    console.log("Document ready");
});
