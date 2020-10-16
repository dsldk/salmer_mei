<xsl:stylesheet xmlns="http://www.w3.org/1999/xhtml"  
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
    xmlns:tei="http://www.tei-c.org/ns/1.0" 
    xmlns:xs="http://www.w3.org/2001/XMLSchema" 
    exclude-result-prefixes="xs tei" 
    version="2.0">
    
    <xsl:template match="tei:rdg">
        <xsl:apply-templates/>
        <xsl:if test="@wit">
            <xsl:text> </xsl:text>
            <em>
                <xsl:value-of select="@wit"/>
            </em>
        </xsl:if>
    </xsl:template>
    
    <xsl:template match="tei:app[tei:lem]">
        <!--<xsl:variable name="identifier">
            <xsl:text>App</xsl:text>
            <xsl:number count="tei:app[tei:lem]" level="any" from="tei:div" format="A"/>
        </xsl:variable>-->
        <!-- numbering is not safe if there is more than one MDIV; generate a random id instead -->
        <xsl:variable name="identifier" select="generate-id(.)"/>
        <xsl:apply-templates select="tei:lem"/>
        <span class="textcriticalnote annotation-marker" id="appnotelink{$identifier}">†</span>
        <xsl:text> </xsl:text>
        <span class="appnotecontents" id="{$identifier}" style="display: none;">
            <xsl:choose>
                <xsl:when test="tei:lem">
                    <xsl:apply-templates select="tei:lem"/>
                    <xsl:text>]</xsl:text>
                    <xsl:text>  </xsl:text>
                    <xsl:if test="tei:lem/@wit">
                        <em>
                            <!-- Since values in the must be prefixed with a #
                                we use tokenize() to obtain the substring after # -->
                            <xsl:value-of select="tei:lem/@wit/tokenize(., '#')"/>
                        </em>
                        <xsl:text>, </xsl:text>
                    </xsl:if>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates select="tei:lem"/>
                    <xsl:text>]</xsl:text>
                    <xsl:text>  </xsl:text>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:for-each select="tei:rdg">
                <xsl:apply-templates select="."/>
                <xsl:if test="position() != last()">; </xsl:if>
                <!--<xsl:if test="position() = last()">. </xsl:if>-->
            </xsl:for-each>
            <xsl:text> </xsl:text>
            <!--<xsl:apply-templates select="tei:rdg"/>
                <xsl:text> </xsl:text>-->
        </span>
    </xsl:template>
    
    <xsl:template name="appN">
        <xsl:number count="tei:app[tei:lem]" level="any" from="tei:div" format="A"/>
    </xsl:template>
    
    <xsl:template match="tei:rdg/text()">
        <em><xsl:value-of select="."/></em>
    </xsl:template>
</xsl:stylesheet>