<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:math="http://exslt.org/math" xmlns:m="http://www.music-encoding.org/ns/mei" xmlns:xlink="http://www.w3.org/1999/xlink" version="2.0" extension-element-prefixes="math" exclude-result-prefixes="m xlink">
    
    <!--
        
        Create an index file to upload into Solr
        
        Axel Teich Geertinger
        Det Danske Sprog- og Litteraturselskab, 2018–19
    -->
    
    
    <xsl:output indent="yes"/>
    <xsl:param name="filename"/>
    <xsl:param name="collection"/>
    
    <!-- Chromatic list of pitch names; V = C sharp/D flat, W = D sharp/E flat etc. -->
    <xsl:variable name="pitches">CVDWEFXGYAZB</xsl:variable>
    <!-- String of 100 characters to use as substitution codes for numbers. Pitches: X = c4 (= MIDI pitch no. 60) ; Intervals: Z = unison (repeated note) -->
    <xsl:variable name="chars">ÙÚÛÜÝÞßàáâãäåæçèéêëìíîïðABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyzÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖØ</xsl:variable>
    <xsl:template match="/">
        <xsl:variable name="item_list">
            <xsl:call-template name="collect_items"/>
        </xsl:variable>
        <xsl:variable name="abs_pitches">
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
        <doc>
            <field name="id">
                <xsl:value-of select="substring-before($filename,'.xml')"/>
            </field>
            <xsl:for-each select="//m:workList/m:work/m:title[text()]">
                <field name="title">
                    <xsl:value-of select="."/>
                </field>
            </xsl:for-each>
            <!-- If no work titles are given, try fileDesc title instead -->
            <xsl:if test="//m:fileDesc/m:titleStmt/m:title[text()] and not(//m:workList/m:work/m:title[text()])">
                <field name="title">
                    <xsl:value-of select="//m:fileDesc/m:titleStmt/m:title[1]"/>
                </field>
            </xsl:if>
            <field name="publ">
                <xsl:value-of select="substring($filename,1,14)"/>
            </field>
            <field name="collection">
                <xsl:value-of select="$collection"/>
            </field>
            <field name="file">
                <xsl:value-of select="$filename"/>
            </field>
            <xsl:variable name="pitch_names">
                <xsl:call-template name="pitch_names">
                    <xsl:with-param name="abs_pitches" select="$abs_pitches"/>
                </xsl:call-template>
            </xsl:variable>
            <field name="pitch">
                <xsl:value-of select="translate($pitch_names,'R','')"/>
            </field>
            <xsl:variable name="abs_pitch_chars">
                <!-- translate absolute pitches to unicode characters  -->
                <xsl:for-each select="$abs_pitches/*[not(.='0')]">
                    <xsl:value-of select="substring($chars,number(.),1)"/>
                </xsl:for-each>
            </xsl:variable>
            <field name="abs_pitch_chars">
                <xsl:value-of select="$abs_pitch_chars"/>
            </field>
            <field name="transposition">
                <!-- first transposition is just a copy of the non-transposed pitch string -->
                <xsl:value-of select="$abs_pitch_chars"/>
            </field>
            <xsl:call-template name="transpositions">
                <!-- remaining transpositions (between 1 and 11 semitones up) -->
                <xsl:with-param name="i" select="number(11)"/>
                <xsl:with-param name="abs_pitches" select="$abs_pitches"/>
            </xsl:call-template>
            <field name="intervals_chars">
                <!-- translate intervals to unicode characters with offset 50 (Z = unison) -->
                <xsl:for-each select="$abs_pitches/*[preceding-sibling::* and not(.='0')]">
                    <xsl:variable name="int" select="50 + number(.) - number(./preceding-sibling::*[not(.='0')][1])"/>
                    <xsl:value-of select="substring($chars,number($int),1)"/>
                </xsl:for-each>
            </field>
            
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
            <field name="contour">
                <xsl:call-template name="contour">
                    <xsl:with-param name="abs_pitches" select="$abs_pitches"/>
                </xsl:call-template>
            </field>
            <field name="duration">
                <xsl:call-template name="durations">
                    <xsl:with-param name="items" select="$item_list"/>
                </xsl:call-template>
            </field>
            <field name="ids">
                <xsl:call-template name="id_list">
                    <xsl:with-param name="items" select="$item_list"/>
                </xsl:call-template>
            </field>
        </doc>
    </xsl:template>
    
    <xsl:template name="transpositions">
        <!-- generate a pitch string for each transposition within one octave -->
        <xsl:param name="i"/>
        <xsl:param name="abs_pitches"/>
        <xsl:if test="$i > 1">
            <!-- count down the interval and call recursively to iterate through the octave -->
            <xsl:call-template name="transpositions">
                <xsl:with-param name="i" select="number($i - 1)"/>
                <xsl:with-param name="abs_pitches" select="$abs_pitches"/>
            </xsl:call-template>
        </xsl:if>
        <field name="transposition">
            <xsl:for-each select="$abs_pitches/*[not(.='0')]">
                <xsl:value-of select="substring($chars,number(.) + $i,1)"/>
            </xsl:for-each>
        </field>
    </xsl:template>
    
    
    <xsl:template name="collect_items">
        <!-- collect a sequence of timed elements (first layer top notes only) -->
        <layer xmlns="http://www.music-encoding.org/ns/mei">
            <!--Doesn't work for neumes: <xsl:for-each select="//m:music//m:layer[1]//*[@dur.ges and not(ancestor::*/@dur.ges)]">-->
            <!--<xsl:for-each select="//m:music//m:layer[1]//m:note[not(ancestor::*/@dur.ges)] | //m:music//m:layer[1]//m:chord | //m:music//m:layer[1]//m:rest">-->
            <xsl:for-each select="//m:music//m:layer[1]//*[(@dur.ppq or @pnum) and not(ancestor::*/@dur.ppq)]">
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
                <xsl:when test="@dur.ppq">
                    <xsl:value-of select="translate(@dur.ppq,'p','')"/>
                </xsl:when>
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
                    <xsl:when test="number(.) &gt; $preceding">u</xsl:when>
                    <xsl:when test="number(.) &lt; $preceding">d</xsl:when>
                    <xsl:otherwise>r</xsl:otherwise>
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
    <xsl:template match="m:note | m:nc" mode="get_absolute_pitch">
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
        <xsl:value-of select="m:note[@oct = max(../m:note/@oct) and string-length(substring-before($pitches, $p)) = max(string-length(substring-before($pitches, $p)))]/@xml:id"/>
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