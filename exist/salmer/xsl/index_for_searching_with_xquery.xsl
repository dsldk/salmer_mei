<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://www.music-encoding.org/ns/mei" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:exsl="http://exslt.org/common" xmlns:math="http://exslt.org/math" xmlns:m="http://www.music-encoding.org/ns/mei" xmlns:xlink="http://www.w3.org/1999/xlink" version="1.0" extension-element-prefixes="math" exclude-result-prefixes="m exsl xlink">
    <xsl:output indent="yes"/>
    <xsl:param name="filename"/>
    
    <!-- Chromatic list of pitch names; V = C sharp/D flat, W = D sharp/E flat etc. -->
    <xsl:variable name="pitches">CVDWEFXGYAZB</xsl:variable>
    <xsl:template match="/">
        <xsl:variable name="item_list_frag">
            <xsl:call-template name="collect_items"/>
        </xsl:variable>
        <xsl:variable name="item_list" select="exsl:node-set($item_list_frag)"/>
        <xsl:variable name="abs_pitches_frag">
            <xsl:for-each select="$item_list/m:layer/*">
                <pitch>
                    <xsl:choose>
                        <xsl:when test="name()='rest'">0</xsl:when>
                        <xsl:otherwise>
                            <xsl:apply-templates select="." mode="get_absolute_pitch"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </pitch>
            </xsl:for-each>
        </xsl:variable>
        <xsl:variable name="abs_pitches" select="exsl:node-set($abs_pitches_frag)"/>
        <melody xmlns="http://dsl.dk">
            <title>
                <xsl:value-of select="//m:workStmt/m:work/titleStmt/m:title[1]"/>
            </title>
            <publ>
                <xsl:value-of select="substring($filename,1,14)"/>
            </publ>
            <file>
                <xsl:value-of select="$filename"/>
            </file>
            <xsl:variable name="pitch_names">
                <xsl:call-template name="pitch_names">
                    <xsl:with-param name="abs_pitches" select="$abs_pitches"/>
                </xsl:call-template>
            </xsl:variable>
            <pitch>
                <xsl:value-of select="translate($pitch_names,'R','')"/>
            </pitch>
            <abs_pitch>
                <xsl:for-each select="$abs_pitches/*[not(.='0')]">
                    <xsl:value-of select="."/>
                    <xsl:if test="not(position()=last())">
                        <xsl:text>,</xsl:text>
                    </xsl:if>
                </xsl:for-each>
            </abs_pitch>
            <intervals>
                <xsl:for-each select="$abs_pitches/*[preceding-sibling::* and not(.='0')]">
                    <xsl:variable name="int" select="number(.) - number(./preceding-sibling::*[not(.='0')][1])"/>
                    <xsl:if test="$int &gt; 0">
                        <xsl:text>+</xsl:text>
                    </xsl:if>
                    <xsl:value-of select="$int"/>
                    <xsl:if test="not(position()=last())">
                        <xsl:text>,</xsl:text>
                    </xsl:if>
                </xsl:for-each>
            </intervals>
            <!-- alternative index (if rests are to be taken into account) -->
            <!--
            <pitch_w_rests>
                <xsl:value-of select="$pitch_names"/>
            </pitch_w_rests>
            <abs_pitch_w_rests>
                <xsl:for-each select="$abs_pitches/*">
                    <xsl:value-of select="."/>
                    <xsl:if test="not(position()=last())">
                        <xsl:text>,</xsl:text>
                    </xsl:if>
                </xsl:for-each>
            </abs_pitch_w_rests>
            <intervals_w_rests>
                <xsl:for-each select="$abs_pitches/*[preceding-sibling::*]">
                    <xsl:variable name="int" select="number(.) - number(./preceding-sibling::*[1])"/>
                    <xsl:if test="$int > 0">
                        <xsl:text>+</xsl:text>
                    </xsl:if>
                    <xsl:value-of select="$int"/>
                    <xsl:if test="not(position()=last())">
                        <xsl:text>,</xsl:text>
                    </xsl:if>
                </xsl:for-each>
            </intervals_w_rests>
            -->
            <contour>
                <xsl:call-template name="contour">
                    <xsl:with-param name="abs_pitches" select="$abs_pitches"/>
                </xsl:call-template>
            </contour>
            <duration>
                <xsl:call-template name="durations">
                    <xsl:with-param name="items" select="$item_list"/>
                </xsl:call-template>
            </duration>
            <id>
                <xsl:call-template name="id_list">
                    <xsl:with-param name="items" select="$item_list"/>
                </xsl:call-template>
            </id>
        </melody>
    </xsl:template>
    <xsl:template name="collect_items">
        <!-- collect a sequence of timed elements (first layer top notes only) -->
        <layer>
            <!--Doesn't work for neumes: <xsl:for-each select="//m:music//m:layer[1]//*[@dur.ges and not(ancestor::*/@dur.ges)]">-->
            <xsl:for-each select="//m:music//m:layer[1]//m:note[not(ancestor::*/@dur.ges)] | //m:music//m:layer[1]//m:chord | //m:music//m:layer[1]//m:rest">
                <xsl:choose>
                    <xsl:when test="name()='chord'">
                        <xsl:variable name="top_note">
                            <xsl:call-template name="get_top_note"/>
                        </xsl:variable>
                        <xsl:apply-templates select="m:note[@xml:id=$top_note]" mode="copy_without_children"/>
                    </xsl:when>
                    <!-- to include rests, comment out the following when clause -->
                    <xsl:when test="name()='rest'"/>
                    <xsl:otherwise>
                        <xsl:apply-templates select="." mode="copy_without_children"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:for-each>
        </layer>
    </xsl:template>
    <xsl:template name="pitch_names">
        <!-- collect pitches (first layer top notes only) -->
        <xsl:param name="abs_pitches"/>
        <xsl:for-each select="$abs_pitches/*">
            <xsl:call-template name="normalize_pitch_name">
                <xsl:with-param name="abs_pitch" select="."/>
            </xsl:call-template>
        </xsl:for-each>
    </xsl:template>
    <xsl:template name="durations">
        <xsl:param name="items"/>
        <xsl:for-each select="$items/m:layer/*">
            <xsl:choose>
                <xsl:when test="@dur.ges"><xsl:value-of select="translate(@dur.ges,'p','')"/></xsl:when>
                <!-- neumes don't have encoded durations -->
                <xsl:otherwise>256</xsl:otherwise>
            </xsl:choose>
            <xsl:if test="position() != last()">
                <xsl:text>,</xsl:text>
            </xsl:if>
        </xsl:for-each>
    </xsl:template>
    
    <xsl:template name="contour">
        <!-- Generate melody contour string -->
        <xsl:param name="abs_pitches"/>
        <xsl:for-each select="$abs_pitches/*">
            <xsl:if test="position() &gt; 1">
                <xsl:variable name="preceding" select="number(./preceding-sibling::*[1])"/>
                <xsl:choose>
                    <xsl:when test="number(.) &gt; $preceding">/</xsl:when>
                    <xsl:when test="number(.) &lt; $preceding">\</xsl:when>
                    <xsl:otherwise>-</xsl:otherwise>
                </xsl:choose>
            </xsl:if>
        </xsl:for-each>
    </xsl:template>
    <xsl:template name="id_list">
        <!-- Collect list of @xml:ids for more convenient back-reference -->
        <xsl:param name="items"/>
        <xsl:for-each select="$items/m:layer/*">
            <xsl:value-of select="@xml:id"/>
            <xsl:if test="position() != last()">
                <xsl:text>,</xsl:text>
            </xsl:if>
        </xsl:for-each>
    </xsl:template>
    <xsl:template match="m:note" mode="get_absolute_pitch">
        <!-- We are assuming accidentals are encoded as attributes, not elements -->
        <xsl:variable name="modify">
            <xsl:choose>
                <xsl:when test="@accid='s' or @accid.ges='s'">1</xsl:when>
                <xsl:when test="@accid='f' or @accid.ges='f'">-1</xsl:when>
                <xsl:when test="@accid='x' or @accid.ges='x' or @accid='ss' or @accid.ges='ss'">2</xsl:when>
                <xsl:when test="@accid='ff' or @accid.ges='ff'">-2</xsl:when>
                <xsl:otherwise>0</xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="p">
            <xsl:apply-templates select="@pname" mode="uppercase"/>
        </xsl:variable>
        <!-- absolute pitch numbers follow MIDI (c4 = 60)  -->
        <xsl:value-of select="number(@oct*12 + string-length(substring-before($pitches, $p))+1 + $modify + 11)"/>
    </xsl:template>
    <xsl:template name="get_top_note">
        <!-- Select top note from chords -->
        <xsl:variable name="pitches">CDEFGAB</xsl:variable>
        <xsl:variable name="p">
            <xsl:apply-templates select="@pname" mode="uppercase"/>
        </xsl:variable>
        <xsl:value-of select="m:note[@oct = math:max(../m:note/@oct) and string-length(substring-before($pitches, $p)) = math:max(string-length(substring-before($pitches, $p)))]/@xml:id"/>
    </xsl:template>
    <xsl:template name="normalize_pitch_name">
        <xsl:param name="abs_pitch"/>
        <xsl:choose>
            <xsl:when test=".='0'">R</xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="substring($pitches, number($abs_pitch) mod 12 + 1, 1)"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="node()|@*" mode="uppercase">
        <xsl:variable name="uppercase" select="'ABCDEFGHIJKLMNOPQRSTUVWXYZ'"/>
        <xsl:variable name="lowercase" select="'abcdefghijklmnopqrstuvwxyz'"/>
        <xsl:value-of select="translate(.,$lowercase,$uppercase)"/>
    </xsl:template>
    <xsl:template match="m:*" mode="copy_without_children">
        <xsl:element name="{name()}" namespace="http://www.music-encoding.org/ns/mei">
            <xsl:apply-templates select="@*"/>
        </xsl:element>
    </xsl:template>
    <xsl:template match="*|text()|@*">
        <xsl:copy>
            <xsl:apply-templates select="node()|@*"/>
        </xsl:copy>
    </xsl:template>
</xsl:stylesheet>