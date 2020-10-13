<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs tei" version="2.0">
    <xsl:template match="tei:div">
        <xsl:apply-templates select="tei:head[not(@type='add')] | tei:div | tei:p | tei:lg | tei:epigraph | tei:sp | tei:cit"/>
    </xsl:template>
    <xsl:template match="tei:div/tei:div">
        <xsl:apply-templates select="tei:head[not(@type='add')]  | tei:p | tei:lg | tei:epigraph | tei:sp | tei:cit"/>
    </xsl:template>
    <xsl:template match="tei:div[@type = 'dedication']">
        <div class="metadata">
            <xsl:apply-templates/>
        </div>
    </xsl:template>
    <xsl:template match="tei:div[@type = 'preface']">
        <div class="metadata">
           <!-- <span class="caption">Preface: </span> -->
            <h3>
                <xsl:apply-templates select="tei:head"/>
            </h3>
            <xsl:apply-templates select="tei:p | tei:signed"/>
        </div>
    </xsl:template>
</xsl:stylesheet>