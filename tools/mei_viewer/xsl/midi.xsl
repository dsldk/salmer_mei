<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
    xmlns:m="http://www.music-encoding.org/ns/mei" 
    version="2.0" 
    exclude-result-prefixes="m xsl">

    <!-- Prepare MEI for MIDI playback -->

    <!-- Det Danske Sprog- og Litteraturselskab, 2018 -->
    <!-- http://www.dsl.dk -->

    <xsl:output xml:space="default" method="xml" encoding="UTF-8" omit-xml-declaration="no"/>

    <xsl:param name="repeat" select="true()"/>


    <!-- Add a rest before the first note to make the first note play (apparently a bug in MIDI player) -->
    <xsl:template match="m:note[not(preceding::m:note)]">
        <rest xmlns="http://www.music-encoding.org/ns/mei" dur="4"/>
        <xsl:apply-templates select="." mode="check_if_neume"/>
    </xsl:template>

    <!-- Add a rest at the end too to prevent the MIDI player from stopping too early -->
    <xsl:template match="m:note[not(following::m:note)]">
        <xsl:apply-templates select="." mode="check_if_neume"/>
        <rest xmlns="http://www.music-encoding.org/ns/mei" dur="4"/>    
    </xsl:template>
    
    <xsl:template match="m:note">
        <xsl:apply-templates select="." mode="check_if_neume"/>
    </xsl:template>
    
    <xsl:template match="m:note" mode="check_if_neume">
        <note xmlns="http://www.music-encoding.org/ns/mei">
            <xsl:copy-of select="@*[not(name()='dur')]"/>
            <xsl:choose>
                <!-- Play neumes (stemless quarters) as semibreves -->
                <xsl:when test="@type='neume' and @dur ='4'"><xsl:attribute name="dur">1</xsl:attribute></xsl:when>
                <xsl:otherwise><xsl:copy-of select="@dur"/></xsl:otherwise>
            </xsl:choose>
            <xsl:copy-of select="node()"/>
        </note>
    </xsl:template>
    
    <!-- Play repeats and endings according to <expansion> elements  -->
    <xsl:template match="m:section[m:expansion]">
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <xsl:variable name="sections" select="."/>
            <xsl:for-each select="tokenize(translate(m:expansion/@plist,'#',''),' ')">
                <xsl:variable name="this_id" select="."/>
                <xsl:apply-templates select="$sections/*[@xml:id = $this_id]"/>
            </xsl:for-each>            
        </xsl:copy>
    </xsl:template>    
    
    <!-- Play repeat unless repetitions are controlled by an <expansion> element -->
    <xsl:template match="*[@right='rptend' and not((ancestor::m:section | ancestor::m:ending)[preceding-sibling::m:expansion])]">
        <xsl:copy-of select="."/>
        <xsl:if test="$repeat">
            <xsl:choose>
                <xsl:when test="not(preceding-sibling::m:measure[@left='rptstart'] or @left='rptstart')">
                    <!-- No start repetition sign; repeat from beginning -->
                    <xsl:copy-of select="preceding-sibling::* | ."/>
                </xsl:when>
                <xsl:otherwise>
                    <!-- Between two reptition signs -->
                    <xsl:variable name="start-repeat" select="(preceding-sibling::m:measure | .)[@left='rptstart'][1]/@xml:id"/>
                    <xsl:copy-of select="preceding-sibling::*[not(following-sibling::m:measure[@xml:id=$start-repeat])] | ."/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:if>
    </xsl:template>
    
    <!-- MIDI playback tempo already set in show.xsl -->
    <!-- <xsl:template match="m:scoreDef">
        <xsl:variable name="noteValues">
            <xsl:for-each select="//m:note[not(@dur = following::m:note/@dur) and not(@type='neume')]">
                <xsl:variable name="dur" select="@dur"/>
                <xsl:variable name="val">
                    <xsl:choose>
                        <xsl:when test="contains($dur,'brev')">0.5</xsl:when>
                        <xsl:when test="contains($dur,'long')">0.25</xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="$dur"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>
                <xsl:variable name="count" select="count(//m:note[@dur = $dur and not(@type='neume')])"/>
                <value weight="{count(//m:note[@dur = $dur and not(@type='neume')]) div $val}"/>
            </xsl:for-each>
            <value weight="{count(//m:note[@type='neume'])}"/>
        </xsl:variable>
        <xsl:variable name="tempo" select="ceiling((300 * sum($noteValues//@weight)) div count(//m:note))"/>
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <xsl:attribute name="midi.bpm">
                <xsl:value-of select="$tempo"/>
            </xsl:attribute>
            <xsl:apply-templates select="node()"/>
        </xsl:copy>
    </xsl:template>-->
    
    <xsl:template match="@*|node()">
        <xsl:copy>
            <xsl:apply-templates select="@*|node()"/>
        </xsl:copy>
    </xsl:template>
</xsl:stylesheet>