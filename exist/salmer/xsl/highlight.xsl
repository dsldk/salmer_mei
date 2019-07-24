<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:m="http://www.music-encoding.org/ns/mei" xmlns:exslt="http://exslt.org/common" exclude-result-prefixes="m exslt" version="3.0">
    
    <!-- Highlight search matches in Verovio and omit some editorial features -->
    
    <!-- Det Danske Sprog- og Litteraturselskab, 2018-2019 -->
    <!-- http://www.dsl.dk -->

    <xsl:output indent="no" xml:space="default" method="xml" encoding="UTF-8"/>

    <xsl:strip-space elements="*"/>

    <!-- A whitespace-separated list of xml:ids identifying the objects to be highlighted -->
    <xsl:param name="ids" select="''"/>
    <!-- excerpt: if true, only the <mdiv> elements containing highlighted elements are included -->
    <xsl:param name="excerpt" select="yes"/>
    
    <xsl:variable name="highlight_ids" select="concat(' ',$ids,' ')"/>

    <xsl:template match="/">
        <xsl:apply-templates/>
    </xsl:template>

    <xsl:template match="m:body">
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <mdiv xmlns="http://www.music-encoding.org/ns/mei">
                <score>
                    <xsl:variable name="mdivs_with_hits" select="count($excerpt='no' or m:mdiv[.//*[contains($highlight_ids,concat(' ',@xml:id,' '))]])"/>
                    <!-- Select only the <mdiv> elements containing matches and join them in a single mdiv for rendering (Verovio only displays one mdiv) -->
                    <xsl:for-each select="m:mdiv">
                        <xsl:if test="$excerpt='no' or .//*[contains($highlight_ids,concat(' ',@xml:id,' '))]">
                            <xsl:variable name="last">
                                <xsl:if test="position()=$mdivs_with_hits">true</xsl:if>
                            </xsl:variable>
                            <xsl:apply-templates select="m:score/*">
                                <xsl:with-param name="last" select="$last"/>
                            </xsl:apply-templates>
                        </xsl:if>
                    </xsl:for-each>
                </score>
            </mdiv>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="m:pb">
        <!-- Change page breaks between <mdiv> elements into system breaks -->
        <xsl:param name="last"/>
        <xsl:choose>
            <xsl:when test="$last='true'">
                <pb xmlns="http://www.music-encoding.org/ns/mei" n="final"/>
            </xsl:when>
            <xsl:otherwise>
                <sb xmlns="http://www.music-encoding.org/ns/mei" n="{@n}"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- Place a '[...]' marker if any <mdiv> elements have been left out -->
    <xsl:template match="m:measure[$excerpt='yes' and (count(preceding-sibling::m:measure)=0
        and ancestor::m:mdiv/preceding-sibling::m:mdiv[1][not(.//*[contains($highlight_ids,concat(' ',@xml:id,' '))])]
        or count(following-sibling::m:measure)=0
        and ancestor::m:mdiv/following-sibling::m:mdiv[1][not(.//*[contains($highlight_ids,concat(' ',@xml:id,' '))])])]">
        <xsl:copy>
            <xsl:apply-templates select="@*|node()"/>
            <xsl:if test="count(preceding-sibling::m:measure)=0 and
                ancestor::m:mdiv/preceding-sibling::m:mdiv[1][not(.//*[contains($highlight_ids,concat(' ',@xml:id,' '))])]">
                <dir xmlns="http://www.music-encoding.org/ns/mei" type="fragment above" label="Dele udeladt" tstamp="0" place="above">[...]</dir>
            </xsl:if>
            <xsl:if test="count(following-sibling::m:measure)=0 and
                ancestor::m:mdiv/following-sibling::m:mdiv[1][not(.//*[contains($highlight_ids,concat(' ',@xml:id,' '))])]">
                <dir xmlns="http://www.music-encoding.org/ns/mei" type="fragment below" label="Dele udeladt" tstamp="0" place="below">[...]</dir>
            </xsl:if>
        </xsl:copy>
    </xsl:template>
    
    <!-- Omit editorial comments etc. -->
    <xsl:template match="m:music//m:annot"/>
    <xsl:template match="m:dir"/>

    
    <xsl:template match="@*">
        <xsl:copy-of select="."/>
    </xsl:template>

    <xsl:template match="node()">
        <xsl:param name="last"/>
        <xsl:copy>
            <!-- Add class 'highlight' to @type if applicable -->
            <xsl:if test="not(@type) and contains($highlight_ids,concat(' ',@xml:id,' '))">
                <xsl:attribute name="type">highlight</xsl:attribute>
            </xsl:if>
            <xsl:if test="@type and contains($highlight_ids,concat(' ',@xml:id,' '))">
                <xsl:attribute name="type"><xsl:value-of select="concat=(@type,' highlight')"/></xsl:attribute>
            </xsl:if>
            <xsl:apply-templates select="@*[not(name()='type')]|node()">
                <xsl:with-param name="last" select="$last"/>
            </xsl:apply-templates>
        </xsl:copy>
    </xsl:template>

</xsl:stylesheet>