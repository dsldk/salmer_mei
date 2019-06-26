<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:tei="http://www.tei-c.org/ns/1.0"
    exclude-result-prefixes="xs tei" version="2.0">
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
            <xd:p><xd:b>Created on:</xd:b> Jan 5, 2010</xd:p>
            <xd:p><xd:b>Author:</xd:b> Thomas Hansen</xd:p>
            <xd:copyright>2010, Society for Danish Language and Literature</xd:copyright>
        </xd:desc>
    </xd:doc>
    <xsl:template match="tei:text">
        <xsl:choose>
            <xsl:when test="tei:front">
                <xsl:apply-templates select="tei:front"/>
            </xsl:when>
            <!--<xsl:otherwise>
                <h4>Front: n/a</h4>
            </xsl:otherwise>-->
        </xsl:choose>
        <xsl:choose>
            <xsl:when test="tei:body">
                <xsl:apply-templates select="tei:body"/>
            </xsl:when>
            <xsl:otherwise>
                <h4>Text body: n/a</h4>
            </xsl:otherwise>
        </xsl:choose>
        <xsl:choose>
            <xsl:when test="tei:back">
                <xsl:apply-templates select="tei:back"/>
            </xsl:when>
            <!--<xsl:otherwise>
                <h4>Back matter: n/a</h4>
            </xsl:otherwise>-->
        </xsl:choose>
    </xsl:template>
</xsl:stylesheet>
