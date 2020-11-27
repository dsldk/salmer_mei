<xsl:stylesheet xmlns="http://www.w3.org/1999/xhtml" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs tei" version="2.0">
    <xsl:template match="tei:choice[tei:seg[@n]]">
        <span class="alternative_text">
        <xsl:for-each select="tei:seg">
            <xsl:sort select="@n"/>
            <xsl:apply-templates/>
            <xsl:if test="not(position() = last())"><br/></xsl:if>
        </xsl:for-each>
        </span>
    </xsl:template>
</xsl:stylesheet>