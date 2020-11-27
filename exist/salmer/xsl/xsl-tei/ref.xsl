<xsl:stylesheet  xmlns="http://www.w3.org/1999/xhtml"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
    xmlns:tei="http://www.tei-c.org/ns/1.0" 
    xmlns:xs="http://www.w3.org/2001/XMLSchema" 
    exclude-result-prefixes="xs tei" 
    version="2.0">
    <!-- Omit textual cross references in the melody database -->
    <xsl:template match="tei:ref">
        <xsl:apply-templates/>
    </xsl:template>
</xsl:stylesheet>