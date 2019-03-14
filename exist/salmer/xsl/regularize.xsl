<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:m="http://www.music-encoding.org/ns/mei" version="1.0" exclude-result-prefixes="m xsl">
    <!-- Change any clef to transposing G clef -->
    
    <!-- Det Danske Sprog- og Litteraturselskab, 2018 -->
    <!-- http://www.dsl.dk --><xsl:output xml:space="default" method="xml" encoding="UTF-8" omit-xml-declaration="no"/>
    
    <!-- The readings to use: 'reg' (regularized) or 'orig' (original; default) --><xsl:param name="reg" select="'orig'"/><xsl:template match="m:choice"><xsl:apply-templates select="*[name()=$reg]"/></xsl:template><xsl:template match="@*|node()"><xsl:copy><xsl:apply-templates select="@*|node()"/></xsl:copy></xsl:template></xsl:stylesheet>