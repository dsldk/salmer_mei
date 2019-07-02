<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:m="http://www.music-encoding.org/ns/mei" xmlns:exslt="http://exslt.org/common" exclude-result-prefixes="m exslt" version="3.0">
    
    <!-- Highlight search matches in Verovio and omit some editorial features -->
    
    <!-- Det Danske Sprog- og Litteraturselskab, 2018-2019 -->
    <!-- http://www.dsl.dk -->

    <xsl:output indent="yes" xml:space="default" method="xml" encoding="UTF-8"/>

    <xsl:strip-space elements="*"/>

    <xsl:param name="highlight" select="''"/>

    <xsl:variable name="highlight_ids" select="concat(' ',$highlight,' ')"/>

    <xsl:include href="show.xsl"/>

    <xsl:template match="/">
        <!-- For eXist 4.4 / Saxon: -->
        <xsl:variable name="transformed" as="node()">
            <xsl:apply-templates/>
        </xsl:variable>
        <!-- For eXist 2.2: -->
        <!--<xsl:variable name="transformed_fragm">
            <xsl:apply-templates/>
        </xsl:variable>
        <xsl:variable name="transformed" select="exslt:node-set($transformed_fragm)"/>-->
        <xsl:apply-templates mode="highlight" select="$transformed"/>
    </xsl:template>

    <xsl:template match="m:body" mode="highlight">
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <mdiv xmlns="http://www.music-encoding.org/ns/mei">
                <score>
                    <xsl:variable name="mdivs_with_hits" select="count(m:mdiv[.//*[contains($highlight_ids,concat(' ',@xml:id,' '))]])"/>
                    <!-- Select only the <mdiv> elements containing matches and join them in a single mdiv for rendering -->
                    <xsl:for-each select="m:mdiv">
                        <xsl:if test=".//*[contains($highlight_ids,concat(' ',@xml:id,' '))]">
                            <xsl:variable name="last">
                                <xsl:if test="position()=$mdivs_with_hits">true</xsl:if>
                            </xsl:variable>
                            <xsl:apply-templates select="m:score/*" mode="highlight">
                                <xsl:with-param name="last" select="$last"/>
                            </xsl:apply-templates>
                        </xsl:if>
                    </xsl:for-each>
                </score>
            </mdiv>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="m:pb" mode="highlight">
        <xsl:param name="last"/>
        <xsl:choose>
            <xsl:when test="$last='true'">
                <pb xmlns="http://www.music-encoding.org/ns/mei" n="{$last}"/>
            </xsl:when>
            <xsl:otherwise>
                <sb xmlns="http://www.music-encoding.org/ns/mei" n="{$last}"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!--<xsl:template match="m:measure[1][ancestor::m:mdiv/preceding-sibling::m:mdiv[1]//*[contains($highlight_ids,concat(' ',@xml:id,' '))]]" mode="highlight">-->
    <xsl:template match="m:measure[count(preceding-sibling::m:measure)=0  
        and ancestor::m:mdiv/preceding-sibling::m:mdiv[1][not(.//*[contains($highlight_ids,concat(' ',@xml:id,' '))])]
        or count(following-sibling::m:measure)=0
        and ancestor::m:mdiv/following-sibling::m:mdiv[1][not(.//*[contains($highlight_ids,concat(' ',@xml:id,' '))])]]"
        mode="highlight">
        <xsl:copy>
            <xsl:apply-templates select="@*|node()" mode="highlight"/>
            <xsl:if test="count(preceding-sibling::m:measure)=0 and
                ancestor::m:mdiv/preceding-sibling::m:mdiv[1][not(.//*[contains($highlight_ids,concat(' ',@xml:id,' '))])]">
                <dir xmlns="http://www.music-encoding.org/ns/mei" type="fragment above" tstamp="0" place="above">[...]</dir>
            </xsl:if>
            <xsl:if test="count(following-sibling::m:measure)=0 and
                ancestor::m:mdiv/following-sibling::m:mdiv[1][not(.//*[contains($highlight_ids,concat(' ',@xml:id,' '))])]">
                <dir xmlns="http://www.music-encoding.org/ns/mei" type="fragment below" tstamp="0" place="below">[...]</dir>
            </xsl:if>
        </xsl:copy>
    </xsl:template>
    
    <!-- Override default handling defined in show.xsl -->
    <xsl:template match="m:music//m:annot" mode="add_comment" priority="1"/>

    <xsl:template match="m:dir"/>
    
    
    <xsl:template match="@*|node()" mode="highlight">
        <xsl:param name="last"/>
        <xsl:copy>
            <xsl:if test="contains($highlight_ids,concat(' ',@xml:id,' '))">
                <xsl:attribute name="type">highlight</xsl:attribute>
            </xsl:if>
            <xsl:apply-templates select="@*|node()" mode="highlight">
                <xsl:with-param name="last" select="$last"/>
            </xsl:apply-templates>
        </xsl:copy>
    </xsl:template>
</xsl:stylesheet>