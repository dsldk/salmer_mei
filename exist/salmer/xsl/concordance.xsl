<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs tei" version="2.0">
 
    <!-- Generate an xml:id to chapter concordance  -->
    
    <xsl:output xml:space="default" method="xml" encoding="UTF-8" omit-xml-declaration="yes" indent="yes"/>
    
    <xsl:template match="/">
        <xsl:apply-templates select="//tei:text//*[normalize-space(@xml:id)]"/>
    </xsl:template>

    <xsl:template match="tei:front//* | tei:back//*">
        <xsl:variable name="id" select="normalize-space(@xml:id)"/>
        <ref target="{$id}" id="{@xml:id}"/>
    </xsl:template>
    
    <xsl:template match="tei:body//*">
        <xsl:variable name="id" select="string(@xml:id)"/>
        <xsl:variable name="chapter" select="ancestor-or-self::tei:div[parent::tei:body]"/>
        <xsl:variable name="chapterNo" select="count($chapter/preceding-sibling::tei:div) + 1"/>
        <xsl:variable name="section">
            <xsl:if test="$chapter/tei:div/descendant-or-self::*[@xml:id=$id]">
            <!-- was:  <xsl:if test="$chapter/tei:div[tei:head/@type='add']/descendant-or-self::*[@xml:id=$id]"> -->
                    <!-- element is a section, not a chapter -->
                <xsl:variable name="countSections" select="count($chapter//tei:div)"/>
                <!-- was: <xsl:variable name="countSections" select="count($chapter//tei:div[tei:head/@type='add'])"/> -->
                <xsl:if test="$countSections &gt; 1"><!-- don't add section number if there is only one -->
                    <xsl:variable name="sectionNo" select="count($chapter//tei:div[descendant-or-self::*[@xml:id = $id]]/preceding-sibling::tei:div) + 1"/>
                    <!-- was: <xsl:variable name="sectionNo" select="count($chapter//tei:div[descendant-or-self::*[@xml:id = $id]]/preceding-sibling::tei:div[tei:head/@type='add']) + 1"/> -->
                    <xsl:value-of select="concat('/',string($sectionNo))"/>
                </xsl:if>
            </xsl:if>
        </xsl:variable>
        <ref target="/{$chapterNo}{$section}" id="{@xml:id}"/>
    </xsl:template>
 
</xsl:stylesheet>