<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:xs="http://www.w3.org/2001/XMLSchema" 
	xmlns:tei="http://www.tei-c.org/ns/1.0" 
	xmlns="http://www.tei-c.org/ns/1.0"
    exclude-result-prefixes="xs tei" version="2.0">
    <xsl:output method="xml" encoding="UTF-8" indent="yes" omit-xml-declaration="yes"/>
    <xsl:strip-space elements="*"/>
    <xsl:preserve-space elements="tei:p"/>
    <!-- Create identity template -->
    <xsl:template match="node()|@*">
        <xsl:copy>
            <xsl:apply-templates select="node()|@*"/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="processing-instruction()"/>
    <xsl:template match="tei:facsimile"/>
    <!--Filters for teiHeader -->
    <xsl:template match="tei:availability">
      <availability status="restricted"><ab>Copyright © 2017, Det Danske Sprog- og Litteraturselskab</ab></availability>
    </xsl:template>
    <xsl:template match="tei:encodingDesc"/>
    <xsl:template match="tei:extent"/>
    <xsl:template match="tei:idno[@type='isbn']"/>
    <xsl:template match="tei:sourceDesc">
      <sourceDesc><p>Source description goes here</p></sourceDesc>
    </xsl:template>
    <xsl:template match="tei:revisionDesc"/>
    <xsl:template match="tei:textClass"/>
    <!--Filters for text level -->
    <xsl:template match="tei:app">
	    <xsl:apply-templates select="tei:lem"/>
    </xsl:template>
    <xsl:template match="tei:lem">
      <xsl:apply-templates/>
    </xsl:template>
    <xsl:template match="tei:cit">
      <xsl:apply-templates select="tei:quote/text()"/>
    </xsl:template>
    <!-- Strip figure descs -->
    <xsl:template match="//tei:figure"/>
    <!-- damage: apply whatever templates are within -->
    <xsl:template match="//tei:damage">
      <xsl:apply-templates/>
    </xsl:template>
    <xsl:template match="//tei:hi"><xsl:apply-templates/></xsl:template>
    <xsl:template match="//tei:ref | //tei:ex">
      <xsl:apply-templates select="text()"/>
    </xsl:template>
    <xsl:template match="tei:note"/>
    <xsl:template match="//tei:text//tei:persName"><xsl:apply-templates/></xsl:template>
    <xsl:template match="//tei:text//tei:placeName"><xsl:apply-templates/></xsl:template>
    <xsl:template match="//tei:supplied">
      <xsl:apply-templates/>
    </xsl:template>
    <!--Strip some unnecessary attributes -->
    <xsl:template match="@n|@type"/>
</xsl:stylesheet>
