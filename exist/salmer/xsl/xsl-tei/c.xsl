<xsl:stylesheet  xmlns="http://www.w3.org/1999/xhtml"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
    xmlns:tei="http://www.tei-c.org/ns/1.0" 
    xmlns:xs="http://www.w3.org/2001/XMLSchema" 
    exclude-result-prefixes="xs tei" 
    version="2.0">
    <xsl:template match="tei:c">
        <xsl:choose>
            <xsl:when test="@type = 's'">
                <xsl:text> </xsl:text>
            </xsl:when>
            <xsl:when test="@type = 'p'">
                <xsl:value-of select="."/>
            </xsl:when>
            <xsl:when test="@function">
                <xsl:apply-templates/>
            </xsl:when>
        </xsl:choose>
    </xsl:template>
</xsl:stylesheet>