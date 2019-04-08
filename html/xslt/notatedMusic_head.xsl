<?xml version="1.0" encoding="UTF-8"?>
<xsl:if test="//tei:notatedMusic" 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" 
    xmlns:tei="http://www.tei-c.org/ns/1.0">
    <!-- A module to include necessary header elements if the TEI file contains notated music. -->
    
    <!-- External JS libraries -->
    <link rel="stylesheet" href="http://code.jquery.com/ui/1.12.1/themes/smoothness/jquery-ui.css" />
    <!-- Note highlighting only works with jQuery 3+ -->
    <script type="text/javascript" src="http://code.jquery.com/jquery-3.2.1.min.js"><!-- jquery --></script>
    <script type="text/javascript" src="http://code.jquery.com/ui/1.12.1/jquery-ui.js"><!-- jquery UI --></script>
    <!-- Remote Verovio toolkit? -->
    <!--<script type="text/javascript" src="http://www.verovio.org/javascript/latest/verovio-toolkit.js"> </script>-->
    <!--<script type="text/javascript" src="http://www.verovio.org/javascript/develop/verovio-toolkit.js"> </script>-->
    
    <!-- Local JS libraries -->
    <script type="text/javascript" src="js/libs/verovio/2.0.2-95c61b2/verovio-toolkit.js"> </script>
    <script type="text/javascript" src="js/libs/Saxon-CE_1.1/Saxonce/Saxonce.nocache.js"> </script>
    <script type="text/javascript" src="js/MeiLib.js"> </script>
    <!-- MIDI -->        
    <script type="text/javascript" src="js/wildwebmidi.js"><!-- MIDI library --></script>
    <script type="text/javascript" src="js/midiplayer.js"><!-- MIDI player --></script>
    <script type="text/javascript" src="js/midiLib.js"><!-- Custom MIDI library --></script>
    
    <!-- SVG CSS styling -->
    <link rel="stylesheet" type="text/css" href="css/mei.css" />
    
</xsl:if>
