<xsl:stylesheet xmlns="http://www.w3.org/1999/xhtml" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:xs="http://www.w3.org/2001/XMLSchema" version="2.0" exclude-result-prefixes="tei xsl xs">
    
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
    <xsl:include href="xsl-tei/choice.xsl"/>
    <xsl:include href="xsl-tei/app.xsl"/>
    <xsl:include href="xsl-tei/div.xsl"/>
    <xsl:include href="xsl-tei/ex.xsl"/>
    <xsl:include href="xsl-tei/hi.xsl"/>
    <xsl:include href="xsl-tei/l.xsl"/>
    <xsl:include href="xsl-tei/lb.xsl"/>
    <xsl:include href="xsl-tei/lg.xsl"/>
    <xsl:include href="xsl-tei/q.xsl"/>
    
    <xsl:template match="/">
        <xsl:apply-templates/>
    </xsl:template>
    
    <xsl:template match="@type">
        <xsl:attribute name="class"><xsl:value-of select="."/></xsl:attribute>
    </xsl:template>

    <!-- omit prose text -->
    <xsl:template match="tei:p"/>

    <xsl:template match="tei:pb">
        <span class="page-break-mark">|</span>
    </xsl:template>
    
    <xsl:template match="text()[preceding-sibling::tei:hi]">
        <xsl:text> </xsl:text><xsl:value-of select="normalize-space()"/>
    </xsl:template>
       
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
        
</xsl:stylesheet>