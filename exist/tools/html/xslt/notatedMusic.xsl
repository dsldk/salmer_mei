<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs tei" version="2.0">
    <xd:doc xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl" scope="stylesheet">
        <xd:desc>
            <xd:detail>Licensed by Thomas Hansen under the Creative Commons Attribution-Share Alike
                3.0 United States license. You are free to copy, distribute, transmit, and remix
                this work, provided you attribute the work to Thomas Hansen as the original author
                and reference the Society for Danish Language and Literature [http://dsl.dk] for the
                work. If you alter, transform, or build upon this work, you may distribute the
                resulting work only under the same, similar or a compatible license. Any of the
                above conditions can be waived if you get permission from the copyright holder. For
                any reuse or distribution, you must make clear to others the license terms of this
                work. The best way to do this is with a link to the license
                [http://creativecommons.org/licenses/by-sa/3.0/deed.en].</xd:detail>
            <xd:p>
                <xd:b>Created on:</xd:b> April 8, 2019</xd:p>
            <xd:p>
                <xd:b>Author:</xd:b> Axel Geertinger</xd:p>
            <xd:copyright>2019, Society for Danish Language and Literature</xd:copyright>
        </xd:desc>
    </xd:doc>
 
    <xsl:template match="tei:notatedMusic">
        <!-- Læse filer lokalt: -->
        <!--<xsl:variable name="mei_base" select="'http://salmer.dsl.lan:8080/exist/rest/db/salmer/data/'"/>-->
        <xsl:variable name="mei_base" select="'https://raw.githubusercontent.com/dsldk/middelaldertekster/master/data/mei/'"/>
        <xsl:variable name="mei_dir">
            <xsl:value-of select="tokenize(tei:ptr/@target, '_')[position() &lt;= 2]" separator="_"/>/</xsl:variable>
        <xsl:if test="tei:ptr/@target">
            <xsl:variable name="file">
                <xsl:choose>
                    <xsl:when test="contains(tei:ptr/@target,'#')">
                        <xsl:value-of select="substring-before(tei:ptr/@target,'#')"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="tei:ptr/@target"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:variable>
            <xsl:variable name="mdiv">
                <xsl:choose>
                    <xsl:when test="contains(tei:ptr/@target,'#')">
                        <xsl:value-of select="substring-after(tei:ptr/@target,'#')"/>
                    </xsl:when>
                    <xsl:otherwise/>
                </xsl:choose>
            </xsl:variable>
            <xsl:variable name="id">
                <xsl:value-of select="substring-before($file,'.xml')"/> 
                <xsl:if test="contains(tei:ptr/@target,'#')">
                    <xsl:text>MDIV</xsl:text>
                    <xsl:value-of select="substring-after(tei:ptr/@target,'#')"/>
                </xsl:if>
            </xsl:variable>
            <div>
            <xsl:choose>
                <xsl:when test="doc-available(concat($mei_base,$mei_dir,$file))">
                    <div id="{$id}_options" class="mei_options">
                        <xsl:comment>MEI options menu will be inserted here</xsl:comment>
                    </div>
                    <div id="{$id}" class="mei">
                        <xsl:comment>SVG will be inserted here</xsl:comment>
                    </div>
                </xsl:when>
                <xsl:otherwise>
                    <div style="border: 1px solid black"> 
                        <small>
                                <xsl:value-of select="concat($mei_base,$mei_dir,$file)"/> not found</small>
                    </div>
                </xsl:otherwise>
            </xsl:choose>
            </div>
        </xsl:if>
    </xsl:template>
       
    <xsl:template name="notatedMusic_head">
        <!-- Include additional header elements if the TEI file contains notated music. -->
        <xsl:if test="//tei:notatedMusic">

            <!-- TO DO: Change relative paths to whatever is the right place... -->
            <xsl:variable name="mei_js_base" select="'js/'"/>
            <xsl:variable name="mei_css_base" select="'style/'"/>
            <xsl:variable name="mei_xslt_base" select="'xsl/'"/>

            <!-- External JS libraries -->
            <link rel="stylesheet" href="http://code.jquery.com/ui/1.12.1/themes/smoothness/jquery-ui.css"/>
            <!-- Note highlighting only works with jQuery 3+ -->
            <script type="text/javascript" src="http://code.jquery.com/jquery-3.2.1.min.js"><!-- jquery --></script>
            <script type="text/javascript" src="http://code.jquery.com/ui/1.12.1/jquery-ui.js"><!-- jquery UI --></script>
            
            <!-- Local JS libraries -->
            <script type="text/javascript" src="{$mei_js_base}libs/verovio/2.0.2-95c61b2/verovio-toolkit.js"> </script>
            <script type="text/javascript" src="{$mei_js_base}MeiAjax.js"> </script>
            <!-- MIDI -->        
            <!--<script type="text/javascript" src="{$mei_js_base}wildwebmidi.js"> standard MIDI library (piano sound) </script>-->
            <script type="text/javascript" src="{$mei_js_base}libs/wildwebmidi/074_recorder.js"><!-- MIDI library --></script>
            <script type="text/javascript" src="{$mei_js_base}midiplayer.js"><!-- MIDI player --></script>
            <script type="text/javascript" src="{$mei_js_base}midiLib.js"><!-- Custom MIDI library --></script>
            
            <!-- SVG CSS styling -->
            <link rel="stylesheet" type="text/css" href="{$mei_css_base}mei.css"/>
            
        </xsl:if>
    </xsl:template>
    
</xsl:stylesheet>