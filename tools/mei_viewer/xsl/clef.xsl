<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:m="http://www.music-encoding.org/ns/mei"
    version="1.0" exclude-result-prefixes="m xsl">

    <!-- Change any clef to transposing G clef -->
    
    <!-- Det Danske Sprog- og Litteraturselskab, 2018 -->
    <!-- http://www.dsl.dk -->
    
    <xsl:output xml:space="default" method="xml" encoding="UTF-8" omit-xml-declaration="no"/>
    
    <!-- The clefs to use: 'G', 'G8', 'F', or 'original' (default) -->
    <xsl:param name="clef" select="'original'"/>
    
    <xsl:template match="m:staffDef">
        <xsl:element name="staffDef" namespace="http://www.music-encoding.org/ns/mei">
            <xsl:choose>
                <xsl:when test="$clef='G8'">
                        <xsl:apply-templates select="@*[name()!='clef.shape' and name()!='clef.line']"/>
                        <xsl:attribute name="clef.shape">G</xsl:attribute>
                        <xsl:attribute name="clef.line">2</xsl:attribute>
                        <xsl:attribute name="clef.dis">8</xsl:attribute>
                        <xsl:attribute name="clef.dis.place">below</xsl:attribute>
                        <xsl:apply-templates select="node()"/>
                </xsl:when>
                <xsl:when test="$clef='G'">
                    <xsl:apply-templates select="@*[name()!='clef.shape' and name()!='clef.line']"/>
                    <xsl:attribute name="clef.shape">G</xsl:attribute>
                    <xsl:attribute name="clef.line">2</xsl:attribute>
                    <xsl:apply-templates select="node()"/>
                </xsl:when>
                <xsl:when test="$clef='F'">
                    <xsl:apply-templates select="@*[name()!='clef.shape' and name()!='clef.line']"/>
                    <xsl:attribute name="clef.shape">F</xsl:attribute>
                    <xsl:attribute name="clef.line">4</xsl:attribute>
                    <xsl:apply-templates select="node()"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates select="@*|node()"/>
            </xsl:otherwise>
        </xsl:choose>
        </xsl:element>
    </xsl:template>    
    
    <xsl:template match="m:clef">
        <xsl:choose>
            <xsl:when test="$clef='original'">
                <clef xmlns="http://www.music-encoding.org/ns/mei">
                    <xsl:apply-templates select="@*|node()"/>
                </clef>
            </xsl:when>
        </xsl:choose>
        
    </xsl:template>
    
    <xsl:template match="@*|node()">
        <xsl:copy>
            <xsl:apply-templates select="@*|node()"/>
        </xsl:copy>
    </xsl:template>
    
</xsl:stylesheet>