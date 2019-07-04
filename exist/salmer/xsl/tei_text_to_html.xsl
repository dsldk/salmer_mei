<xsl:stylesheet xmlns="http://www.w3.org/1999/xhtml" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:xs="http://www.w3.org/2001/XMLSchema" version="2.0" exclude-result-prefixes="tei xsl xs">
    
    <!-- 
		Prepare MEI 4.0.0 <mdiv> elements for rendering 
		
		Authors: 
		Axel Teich Geertinger
		Det Danske Sprog- og Literaturselskab, 2019
	-->
    
    
<!-- TO DO: include relevant xslt stylesheets from dsl-tei -->    
    
    <xsl:output method="xml" encoding="UTF-8" cdata-section-elements="" omit-xml-declaration="yes" indent="no" xml:space="default"/>
    
    <xsl:strip-space elements="*"/>
    
    <xsl:param name="mdiv"/>
    
    <xsl:include href="https://raw.githubusercontent.com/dsldk/dsl-tei/master/xslt/c.xsl"/>
    <xsl:include href="https://raw.githubusercontent.com/dsldk/dsl-tei/master/xslt/hi.xsl"/>
    <xsl:include href="https://raw.githubusercontent.com/dsldk/dsl-tei/master/xslt/l.xsl"/>
    <xsl:include href="https://raw.githubusercontent.com/dsldk/dsl-tei/master/xslt/lg.xsl"/>
    
    <xsl:template match="/">
        <xsl:apply-templates/>
    </xsl:template>
    
    <xsl:template match="@type">
        <xsl:attribute name="class"><xsl:value-of select="."/></xsl:attribute>
    </xsl:template>
    
    <xsl:template match="tei:lb | tei:pb | tei:ptr">
        <xsl:text> </xsl:text>
    </xsl:template>
    
    <xsl:template match="text()[preceding-sibling::tei:hi]">
        <xsl:text> </xsl:text><xsl:value-of select="normalize-space()"/>
    </xsl:template>
    
    <!-- if no matching template is found, just transfer TEI elements and attributes to HTML namespace -->
    <xsl:template match="tei:*">
        <xsl:element name="{name()}">
            <xsl:apply-templates select="@xml:id"/>
            <xsl:apply-templates select="node()"/>
        </xsl:element>        
    </xsl:template>    
    
    <xsl:template match="@*">
        <xsl:attribute name="{name()}"><xsl:value-of select="."/></xsl:attribute>
    </xsl:template>
    
    <xsl:template match="text()">
        <xsl:value-of select="normalize-space()"/>
    </xsl:template>
    
</xsl:stylesheet>