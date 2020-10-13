<xsl:stylesheet xmlns="http://www.w3.org/1999/xhtml" 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
    xmlns:tei="http://www.tei-c.org/ns/1.0" 
    xmlns:xs="http://www.w3.org/2001/XMLSchema" 
    version="2.0" exclude-result-prefixes="tei xsl xs">
    
    <!-- 
		Render vocal text from TEI  
		
		Author: 
		Axel Teich Geertinger
		Det Danske Sprog- og Literaturselskab, 2019-2020
	-->
    
    
    <xsl:output method="xml" encoding="UTF-8" cdata-section-elements="" omit-xml-declaration="yes" indent="no" xml:space="default"/>
    
    <xsl:strip-space elements="*"/>
    
    <xsl:param name="mdiv"/>
    
    <xsl:include href="xsl-tei/c.xsl"/>
    <xsl:include href="xsl-tei/app.xsl"/>
    <xsl:include href="xsl-tei/div.xsl"/>
    <xsl:include href="xsl-tei/ex.xsl"/>
    <xsl:include href="xsl-tei/hi.xsl"/>
    <xsl:include href="xsl-tei/l.xsl"/>
    <xsl:include href="xsl-tei/lb.xsl"/>
    <xsl:include href="xsl-tei/lg.xsl"/>
    <xsl:include href="xsl-tei/note.xsl"/>
    <xsl:include href="xsl-tei/p.xsl"/>
    
    <xsl:template match="/">
        <xsl:apply-templates/>
    </xsl:template>
    
    <xsl:template match="@type">
        <xsl:attribute name="class"><xsl:value-of select="."/></xsl:attribute>
    </xsl:template>

    <xsl:template match="tei:pb">
        <span class="page-break-mark">|</span>
    </xsl:template>
    
    <xsl:template match="text()[preceding-sibling::tei:hi]">
        <xsl:text> </xsl:text><xsl:value-of select="normalize-space()"/>
    </xsl:template>
    
    <!--<xsl:template match="tei:app">-->
        <!-- show lemma if present -->
        <!--<xsl:choose>
            <xsl:when test="tei:lem">
                <xsl:apply-templates select="tei:lem"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates/>
            </xsl:otherwise>
        </xsl:choose>
        </xsl:template>-->
    
    <xsl:template match="tei:app" priority="10">
        <xsl:choose>
            <xsl:when test="tei:lem">
                <xsl:apply-templates select="tei:lem"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates/>
            </xsl:otherwise>
        </xsl:choose>
        <xsl:variable name="appNote">
            <xsl:apply-templates select="." mode="apparatusCriticus"/>
        </xsl:variable>
        <xsl:variable name="appNo" select="substring-before($appNote/string(),'.')"/>
        <xsl:variable name="appText" select="substring-after($appNote/string(),'.')"/>
        <span class="notelink" id="{concat('notelinkApp',$appNo)}">
            <sup>[<xsl:value-of select="$appNo"/>]</sup>
        </span>
        <span class="appnotecontents" id="{concat('App',$appNo)}" style="display: none;"><xsl:value-of select="$appText"/></span>
        <!-- should generate something like this:
        <span class="notelink" id="notelinkApp1">
            <sup>[1]</sup>
        </span>
        <span class="appnotecontents" id="App1" style="display: none;">forbarme dig offuer oss.] forba rettet <em> orig.</em>, rettet </span>-->
    </xsl:template>
    
    <!-- Transfer certain TEI elements and attributes to HTML namespace. -->
    <!-- Currently handled by included templates -->
    <!--<xsl:template match="tei:p | tei:div">
        <xsl:element name="{name()}">
        <xsl:apply-templates select="@xml:id"/>
        <xsl:apply-templates select="node()"/>
        </xsl:element>        
    </xsl:template>-->    
    
    <!-- if no matching template is found, strip off TEI elements and process the contents only -->
    <xsl:template match="tei:*">
        <xsl:apply-templates select="node()"/>
    </xsl:template>
    
    <xsl:template match="@*">
        <xsl:attribute name="{name()}"><xsl:value-of select="."/></xsl:attribute>
    </xsl:template>
    
    <xsl:template match="text()">
        <xsl:copy-of select="."/>
    </xsl:template>
    
    <xsl:template match="comment()">
        <xsl:text> </xsl:text>
    </xsl:template>
    
</xsl:stylesheet>