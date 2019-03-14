<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:m="http://www.music-encoding.org/ns/mei"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    version="1.0" exclude-result-prefixes="m xsl">
    
    <!-- Transpose MEI score n semitones. -->
    <!-- Works with simple scores. Assumptions made: No key changes; simple alterations only; no cautionary accidentals. -->

    <!-- Det Danske Sprog- og Litteraturselskab, 2018 -->
    <!-- http://www.dsl.dk -->
    
   
    <xsl:output xml:space="default" method="xml" encoding="UTF-8" omit-xml-declaration="no"/>
    
    <!-- The number of semitones to transpose. Range is -11 to 11 -->
    <xsl:param name="interval" select="0" as="xs:double"/>
    <!-- Direction of transposition. Values are 'up' or 'down' -->
    <xsl:param name="direction" select="'up'"/>
        
    <xsl:variable name="dir" as="xs:integer">
        <xsl:choose>
            <xsl:when test="$direction='up'">1</xsl:when>
            <xsl:otherwise>-1</xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    
    <xsl:variable name="keysig">
        <xsl:choose>
            <xsl:when test="/m:mei/m:music//m:staffDef[1]/@key.sig!=''">
                <xsl:value-of select="/m:mei/m:music//m:staffDef[1]/@key.sig"/>
            </xsl:when>
            <xsl:otherwise>0</xsl:otherwise>
        </xsl:choose>
    </xsl:variable>

    <xsl:variable name="pitchNames">
        <!-- sequence of pitch names in upwards or downwards direction depending on direction of transposition -->
        <xsl:choose>
            <xsl:when test="$dir = 1">cdefgabcdefgab</xsl:when>
            <xsl:otherwise>cbagfedcbagfed</xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    
    <xsl:variable name="keys" as="node()">
        <!-- Key signatures' major scale equivalents and the name of their tonic stem tone. -->
        <!-- Two octaves needed to allow room for all transpositions within an octave's range. -->
        <keys>
            <key>
                <!-- C natural -->
                <pitchName>c</pitchName>
                <accid>0</accid>
            </key>
            <key>
                <!-- D flat -->
                <pitchName>d</pitchName>
                <accid>5f</accid>
            </key>
            <key>
                <!-- D natural -->
                <pitchName>d</pitchName>
                <accid>2s</accid>
            </key>
            <key>
                <!-- E flat -->
                <pitchName>e</pitchName>
                <accid>3f</accid>
            </key>
            <key>
                <!-- E natural -->
                <pitchName>e</pitchName>
                <accid>4s</accid>
            </key>
            <key>
                <!-- F natural -->
                <pitchName>f</pitchName>
                <accid>1f</accid>
            </key>
            <key>
                <!-- F sharp -->
                <pitchName>f</pitchName>
                <accid>6s</accid>
            </key>
            <key>
                <!-- G natural -->
                <pitchName>g</pitchName>
                <accid>1s</accid>
            </key>
            <key>
                <!-- A flat -->
                <pitchName>a</pitchName>
                <accid>4f</accid>
            </key>
            <key>
                <!-- A natural -->
                <pitchName>a</pitchName>
                <accid>3s</accid>
            </key>
            <key>
                <!-- B flat -->
                <pitchName>b</pitchName>
                <accid>2f</accid>
            </key>
            <key>
                <!-- B natural -->
                <pitchName>b</pitchName>
                <accid>5s</accid>
            </key>
            <key>
                <!-- C natural -->
                <pitchName>c</pitchName>
                <accid>0</accid>
            </key>
            <key>
                <!-- D flat -->
                <pitchName>d</pitchName>
                <accid>5f</accid>
            </key>
            <key>
                <!-- D natural -->
                <pitchName>d</pitchName>
                <accid>2s</accid>
            </key>
            <key>
                <!-- E flat -->
                <pitchName>e</pitchName>
                <accid>3f</accid>
            </key>
            <key>
                <!-- E natural -->
                <pitchName>e</pitchName>
                <accid>4s</accid>
            </key>
            <key>
                <!-- F natural -->
                <pitchName>f</pitchName>
                <accid>1f</accid>
            </key>
            <key>
                <!-- F sharp -->
                <pitchName>f</pitchName>
                <accid>6s</accid>
            </key>
            <key>
                <!-- G natural -->
                <pitchName>g</pitchName>
                <accid>1s</accid>
            </key>
            <key>
                <!-- A flat -->
                <pitchName>a</pitchName>
                <accid>4f</accid>
            </key>
            <key>
                <!-- A natural -->
                <pitchName>a</pitchName>
                <accid>3s</accid>
            </key>
            <key>
                <!-- B flat -->
                <pitchName>b</pitchName>
                <accid>2f</accid>
            </key>
            <key>
                <!-- B natural -->
                <pitchName>b</pitchName>
                <accid>5s</accid>
            </key>
        </keys>
    </xsl:variable>
    
    <xsl:variable name="oldKey">
        <xsl:copy-of select="$keys/key[accid=$keysig][1]"/>
    </xsl:variable>
    
    <xsl:variable name="newKey">
        <!-- Determine the transposed key -->
        <xsl:choose>
            <xsl:when test="$dir=1 and $interval &gt; 0">
                <xsl:copy-of select="$keys/key[accid=$keysig][1]/following-sibling::key[$interval]"/>
            </xsl:when>
            <xsl:when test="$dir=-1 and $interval &gt; 0">
                <xsl:copy-of select="$keys/key[accid=$keysig][2]/preceding-sibling::key[$interval]"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:copy-of select="$oldKey"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    
    <xsl:variable name="pitchNameDistance" as="xs:integer">
        <!-- Calculate amount of pitch name displacement -->
        <xsl:variable name="fromTo">
            <xsl:call-template name="calculatePitchNamesFromTo">
                <xsl:with-param name="from" select="$oldKey/key/pitchName"/>
                <xsl:with-param name="to" select="$newKey/key/pitchName"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:value-of select="string-length($fromTo)-1"/>
    </xsl:variable>
    
    <xsl:template match="m:note">
        <!-- Changing pitch names. @pnum ignored for the time being -->
        <xsl:element name="note" namespace="http://www.music-encoding.org/ns/mei">
            <xsl:choose>
                <xsl:when test="$interval != 0">
                    <xsl:variable name="newPitch"
                        select="substring(substring-after($pitchNames,@pname), $pitchNameDistance, 1)"/>
                    <xsl:apply-templates select="@*[name()!='pname' and name()!='oct']"/>
                    <xsl:attribute name="pname">
                        <xsl:value-of select="$newPitch"/>
                    </xsl:attribute>
                    <!-- calculate octave -->
                    <xsl:variable name="pitchSpan">
                        <xsl:call-template name="calculatePitchNamesFromTo">
                            <xsl:with-param name="from" select="@pname"/>
                            <xsl:with-param name="to" select="$newPitch"/>
                        </xsl:call-template>
                    </xsl:variable>
                    <xsl:attribute name="oct">
                        <xsl:choose>
                            <xsl:when test="contains($pitchSpan,'c') and ((@pname!='c' and $dir=1) or ($newPitch!='c' and $dir=-1))">
                                <!-- transposed pitch is in the next octave -->
                                <xsl:value-of select="@oct + $dir"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:value-of select="@oct"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:attribute>
                    <xsl:apply-templates select="node()"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:element>
    </xsl:template>
    
    <xsl:template match="m:staffDef[@key.sig]">
        <xsl:element name="staffDef" namespace="http://www.music-encoding.org/ns/mei">
            <xsl:choose>
                <xsl:when test="$interval != 0">
                    <xsl:apply-templates select="@*[name()!='key.sig']"/>
                    <xsl:attribute name="key.sig" select="$newKey/key/accid"/>
                    <xsl:apply-templates select="node()"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates select="@* | *"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:element>
    </xsl:template>
    
    <xsl:template match="@accid | @accid.ges">
        <!-- For simplicity, all @accid values are regarded as actual alterations (no cautionary accidentals!) -->
        <!-- Also no double alterations assumed. -->
        <xsl:attribute name="{name()}">
            <xsl:choose>
                <xsl:when test="$interval != 0">
                    <xsl:choose>
                        <xsl:when test="contains($oldKey/key/accid,'s') and contains($newKey/key/accid,'f')">
                            <!-- translate naturals to flats, sharps to naturals -->
                            <xsl:choose>
                                <xsl:when test=".='n'">f</xsl:when>
                                <xsl:when test=".='s'">n</xsl:when>
                                <xsl:otherwise><xsl:value-of select="."/></xsl:otherwise>
                            </xsl:choose>
                        </xsl:when>
                        <xsl:when test="contains($oldKey/key/accid,'f') and contains($newKey/key/accid,'s')">
                            <!-- translate naturals to sharps, flats to naturals -->
                            <xsl:choose>
                                <xsl:when test=".='n'">s</xsl:when>
                                <xsl:when test=".='f'">n</xsl:when>
                                <xsl:otherwise><xsl:value-of select="."/></xsl:otherwise>
                            </xsl:choose>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="."/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="."/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:attribute>
    </xsl:template>

    <xsl:template name="calculatePitchNamesFromTo" as="xs:string">
        <!-- Calculate a string including the range of pitch names between two pitches  -->
        <xsl:param name="from"/>
        <xsl:param name="to"/>
        <xsl:variable name="str1" select="substring($pitchNames, string-length(substring-before($pitchNames,$from))+1)"/>
        <xsl:value-of select="substring($str1, 1, string-length(substring-before($str1, $to))+1)"/>
    </xsl:template>
    

    <xsl:template match="@*|node()">
        <xsl:copy>
            <xsl:apply-templates select="@*|node()"/>
        </xsl:copy>
    </xsl:template>
    
</xsl:stylesheet>