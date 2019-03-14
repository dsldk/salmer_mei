<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:m="http://www.music-encoding.org/ns/mei" version="1.0" exclude-result-prefixes="m xsl">
    
    <!-- Add beams to reduced note values. No metric grouping. -->
    
    <!-- Det Danske Sprog- og Litteraturselskab, 2018 -->
    <!-- http://www.dsl.dk --><xsl:output xml:space="default" method="xml" encoding="UTF-8" omit-xml-declaration="no"/><xsl:template name="add_notes"><xsl:param name="note"/><xsl:copy><xsl:apply-templates select="@*|node()"/></xsl:copy>
        <!-- add subsequent flagged-value notes as long as no (new) syllable is attached to them  --><xsl:for-each select="following-sibling::m:*[1][name()='note' and @dur &gt; 4 and not(m:verse//text())]"><xsl:call-template name="add_notes"><xsl:with-param name="note" select="following-sibling::m:*[1][name()='note' and @dur &gt; 4 and not(m:verse//text())]"/></xsl:call-template></xsl:for-each></xsl:template>    
    
    <!-- start a beam if this is the first note in a sequence of flagged note values and there is no (new) syllable attached to it --><xsl:template match="m:note[not(@stem.len=0) and @dur &gt; 4 and          (m:verse//text() or preceding-sibling::m:*[1][name()='note' and @dur &lt; 8] or preceding-sibling::m:*[1][name()='rest'] or          not(preceding-sibling::m:*[1][name()='note' or name()='rest']))          and following-sibling::m:*[1][name()='note' and @dur &gt; 4 and not(m:verse//text())]]"><beam xmlns="http://www.music-encoding.org/ns/mei"><xsl:call-template name="add_notes"><xsl:with-param name="note" select="."/></xsl:call-template></beam></xsl:template>    

    <!-- skip notes already added inside the beam --><xsl:template match="m:note[@dur &gt; 4 and not(m:verse//text()) and preceding-sibling::m:*[1][name()='note' and @dur &gt; 4]]"/><xsl:template match="@*|node()"><xsl:copy><xsl:apply-templates select="@*|node()"/></xsl:copy></xsl:template></xsl:stylesheet>