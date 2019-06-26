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
    <xsl:template match="tei:cit">
        <xsl:variable name="citCount">
            <xsl:number from="tei:text" level="any"/>
        </xsl:variable>
        <!--<div class="metadata">
            <span class="caption">Citation: <xsl:value-of select="$citCount"/>/<xsl:value-of
                    select="count(//tei:cit)"/></span>
        </div>-->
        <blockquote>
            <xsl:apply-templates/>
        </blockquote>
    </xsl:template>
    <xsl:template match="tei:p/tei:cit">
        <xsl:variable name="identifier">
            <xsl:text>Cit</xsl:text>
            <xsl:choose>
                <xsl:when test="@xml:id">
                    <xsl:value-of select="@xml:id"/>
                </xsl:when>
                <xsl:when test="@n">
                    <xsl:value-of select="@n"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:number count="tei:cit" level="any"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:apply-templates select="tei:quote"/>
        <a class="notelink" href="#{$identifier}">
            <sup>
                <xsl:call-template name="citN"/>
            </sup>
        </a>
    </xsl:template>
    <xsl:template name="citN">
        <xsl:choose>
            <xsl:when test="@n">
                <xsl:value-of select="@n"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:number from="tei:text" level="any" format="a"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <!-- Template, der matcher cit og opbygger note
        som i det kritiske apparat-->
    <xsl:template match="tei:cit" mode="quotationApparatus">
        <xsl:variable name="identifier">
            <xsl:text>Cit</xsl:text>
            <xsl:choose>
                <xsl:when test="@xml:id">
                    <xsl:value-of select="@xml:id"/>
                </xsl:when>
                <xsl:when test="@n">
                    <xsl:value-of select="@n"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:number count="tei:cit" level="any"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <span class="note">
            <span class="noteLabel">
                <strong>
                    <xsl:call-template name="citN"/>
                    <xsl:text>. </xsl:text>
                </strong>
            </span>
            <span class="noteBody">
                <xsl:apply-templates select="tei:quote"/>
                <xsl:text>] </xsl:text>
                <xsl:apply-templates select="tei:bibl"/>
            </span>
        </span>
    </xsl:template>
</xsl:stylesheet>
