<?xml version="1.0" encoding="UTF-8"?>
<!--<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:tei="http://www.tei-c.org/ns/1.0"
    exclude-result-prefixes="xs tei" version="2.0">-->
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <xsl:output omit-xml-declaration="yes" indent="yes"/>

    <xsl:strip-space elements="*"/>

    <xsl:template match="node() | @*">
        <xsl:copy>
            <xsl:apply-templates select="node() | @*"/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="
            *[not(node())]
            | *[not(child::node()/child::node())]
            | *[not(child::node()/child::node()/child::node())]    
            | *[not(child::node()/child::node()/child::node()/child::node())]"/>

    <!--<xsl:template match="
            *[not(node()) and not(attribute())] 
            |
            *[child::text() = 'empty']
            
            
            "/>-->
    <!--<xsl:template match="
         
        *[node()/self::text()='nil']
        ">FEJL</xsl:template>-->
</xsl:stylesheet>
