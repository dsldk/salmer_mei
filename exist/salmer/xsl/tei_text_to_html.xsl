<xsl:stylesheet xmlns="http://www.w3.org/1999/xhtml" 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
    xmlns:tei="http://www.tei-c.org/ns/1.0" 
    xmlns:xs="http://www.w3.org/2001/XMLSchema" 
    version="2.0" exclude-result-prefixes="tei xsl xs">
    
    <!-- 
		Render vocal text from TEI  
		
		Authors: 
		Axel Teich Geertinger
		Det Danske Sprog- og Literaturselskab, 2019-2020
	-->
    
    
    <xsl:output method="xml" encoding="UTF-8" cdata-section-elements="" omit-xml-declaration="yes" indent="no" xml:space="default"/>
    
    <xsl:strip-space elements="*"/>
    
    <xsl:param name="mdiv"/>
    
    <xsl:include href="https://raw.githubusercontent.com/dsldk/dsl-tei/master/xslt/c.xsl"/>
    <xsl:include href="https://raw.githubusercontent.com/dsldk/dsl-tei/master/xslt/div.xsl"/>
    <xsl:include href="https://raw.githubusercontent.com/dsldk/dsl-tei/master/xslt/hi.xsl"/>
    <xsl:include href="https://raw.githubusercontent.com/dsldk/dsl-tei/master/xslt/l.xsl"/>
    <xsl:include href="https://raw.githubusercontent.com/dsldk/dsl-tei/master/xslt/lb.xsl"/>
    <xsl:include href="https://raw.githubusercontent.com/dsldk/dsl-tei/master/xslt/lg.xsl"/>
    <xsl:include href="https://raw.githubusercontent.com/dsldk/dsl-tei/master/xslt/p.xsl"/>
    
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
    
    <xsl:template match="tei:app">
        <!-- show lemma if present -->
        <xsl:choose>
            <xsl:when test="tei:lem">
                <xsl:apply-templates select="tei:lem"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates/>
            </xsl:otherwise>
        </xsl:choose>
        
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