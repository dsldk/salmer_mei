<xsl:stylesheet xmlns="http://www.w3.org/1999/xhtml" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs tei" version="2.0">
    <xsl:template match="tei:note[@place='left']|tei:note[@place='right']|tei:note[@place='margin']">
        <!--<span class="marginal-note">
            <span class="marginal-note-mark">$</span>
            <xsl:text> </xsl:text>
            <span class="marginal-note-content">
                <xsl:apply-templates/>
            </span>
        </span>-->
    </xsl:template>
</xsl:stylesheet>