var page = 1;
var zoom = 40;
//var pageHeight = 2970;
//var pageWidth = 2100;
var swipe_pages = false;
var format = 'mei';
var outputFilename = 'output.mei'
var ids = [];
var pdfFormat = "A4";
var pdfOrientation = "portrait";
var savedOptions = undefined;
var customOptions = undefined;
var target = "";
var disabledOptions = ["adjustPageHeight", "breaks", "landscape", "pageHeight", "pageWidth", "mmOutput", "noFooter"];


// Verovio options
// pageWidth * scale % = calculated width 
// page width is deliberately set too narrow to force Verovio to use alle line breaks 
var $defaultVerovioOptions = {
    mmOutput:             1,
    pageHeight:           400,
    pageWidth:            500,
    scale:                100,
    noHeader:             1,
    noFooter:             1,
    staffLineWidth:       0.25,
    lyricTopMinMargin:    4,
    lyricSize:            4.2,
    lyricNoStartHyphen:   1,
    spacingStaff:         3,
    spacingLinear:        0.92,
    spacingNonLinear:     0.28,
    font:                 'Bravura',
    noJustification:      1,
    adjustPageHeight:     1,
    breaks:               'auto'
}
    

// global variables - do not change
var host = "https://salmer.dsl.dk/"

var $mei = [];  // The array holding the MEI objects 

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
 
var transformOrder = ['show', 'highlight', 'transpose', 'clef', 'noteValues', 'beams'];


function renderData(data) { 
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

    vrvToolkit.setOptions($mei[id].verovioOptions);
    vrvToolkit.loadData(xmlString);
    vrvToolkit.redoLayout();
     
    $("#" + targetId).html("");
   
    for (i = 0; i < vrvToolkit.getPageCount(); i++) {
        svg = vrvToolkit.renderToSVG(i + 1, {});
        $("#" + targetId).html($("#" + targetId).html() + "<br/>" + svg);
     }    
}


function getOptionsFromQuery(id) {
    // Add the relevant transformations as transmitted in the query string
    var urlParams = new URLSearchParams(window.location.search);
    if(urlParams.get('mdiv')) {
        console.log("Set mdiv:" + urlParams.get('mdiv'));
        $mei[id].xsltOptions['show'].parameters['mdiv'] = urlParams.get('mdiv');
    };
    if(urlParams.get('transposeVal') != '0') {
        console.log("Transpose:" + urlParams.get('transposeVal') + urlParams.get('direction'));
        $mei[id].xsltOptions['transpose'] = $.extend(true, {}, $transpose);
        $mei[id].xsltOptions['transpose'].parameters['interval']   =  parseInt(urlParams.get('transposeVal'));
        $mei[id].xsltOptions['transpose'].parameters['direction'] =  urlParams.get('direction');
    };
    if(urlParams.get('clef')!= null && urlParams.get('clef')!='original') {
        console.log("Set clef:" + urlParams.get('clef'));
        $mei[id].xsltOptions['clef'] = $.extend(true, {}, $setClef);
        $mei[id].xsltOptions['clef'].parameters['clef'] = urlParams.get('clef');
    };
    if(urlParams.get('factor') != null) {
        console.log("Note values factor:" + urlParams.get('factor'));
        $mei[id].xsltOptions['noteValues'] = $.extend(true, {}, $setNoteValues);
        $mei[id].xsltOptions['noteValues'].parameters['factor']   =  parseInt(urlParams.get('factor'));
        /* second run: add beams if relevant */
        $mei[id].xsltOptions['beams'] = $.extend(true, {}, $setBeams);
    };
}





function loadMeiFromDoc() {
    $(".mei").each( function() {
        id = $(this).attr("id");
        console.log('Reading ' + id);
        $mei[id] = new meiObj({});
        $mei[id].verovioOptions = $defaultVerovioOptions;
        $mei[id].xsltOptions['id'] = id;
        $mei[id].xsltOptions['doc'] = filename_from_dataId(id) + '.xml';
        $mei[id].xsltOptions['show'].parameters['mdiv'] =  mdivId(id);
        
        getOptionsFromQuery(id);
        
        $("#"+id+"_options .highlight_list").each( function() {
            console.log("Highlight:" + $(this).html());
            $mei[id].xsltOptions['highlight'] = $.extend(true, {}, $highlight);
            $mei[id].xsltOptions['highlight'].parameters['ids'] = $(this).html();
        });
        // send a POST request to get the MEI data
        $.post('https://salmer.dsl.dk/transform_mei.xq',$mei[id].xsltOptions,function(data){ renderData(data); },'xml');
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


$(document).ready(function() {        
    console.log("Document ready");
    loadMeiFromDoc();    
});

    