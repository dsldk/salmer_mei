<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:tei="http://www.tei-c.org/ns/1.0"
    exclude-result-prefixes="xs tei" version="2.0">
    <xd:doc xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl" scope="stylesheet">
        <xd:desc>
            <xd:detail>Licensed by Thomas Hansen under the Creative Commons Attribution-Share Alike
                3.0 United States license. You are free to copy, distribute, transmit, and remix
                this work, provided you attribute the work to Thomas Hansen as the original author
                and reference the Society for Danish Language and Literature [http://dsl.dk] for the
                work. If you alter, transform, or build upon this work, you may distribute the
                resulting work only under the same, similar or a compatible license. Any of the
                above conditions can be waived if you get permission from the copyright holder. For
                any reuse or distribution, you must make clear to others the license terms of this
                work. The best way to do this is with a link to the license
                [http://creativecommons.org/licenses/by-sa/3.0/deed.en].</xd:detail>
            <xd:p><xd:b>Created on:</xd:b> Jan 5, 2010</xd:p>
            <xd:p><xd:b>Author:</xd:b> Thomas Hansen</xd:p>
            <xd:copyright>2010, Society for Danish Language and Literature</xd:copyright>
        </xd:desc>
    </xd:doc>
    <xsl:template match="tei:supportDesc">
        <!-- Test for declaration of manuscript material -->
        <xsl:choose>
            <xsl:when test="@material = 'empty'">
                <!-- when 'empty', leave empty-->
            </xsl:when>
            <xsl:when test="@material = 'nil'">
                <xsl:text>-- missing value @material --</xsl:text>
            </xsl:when>
            <xsl:when test="@material = 'mixed'">
                <li>
                    <span>
                        <xsl:text>Materiale: blandet. </xsl:text>
                        <xsl:if test="tei:support[tei:ab != 'empty']">
                            <xsl:apply-templates/>
                        </xsl:if>
                    </span>
                </li>
            </xsl:when>
            <xsl:when test="@material = 'paper'">
                <li>
                    <span>
                        <xsl:text>Materiale: papir. </xsl:text>
                        <xsl:if test="tei:support[tei:ab != 'empty']">
                            <xsl:apply-templates select="tei:support/tei:ab/text()"/>
                        </xsl:if>
                    </span>
                </li>
            </xsl:when>
            <xsl:when test="@material = 'parch'">
                <li>
                    <span>
                        <xsl:text>Materiale: pergament. </xsl:text>
                        <xsl:if test="tei:support[tei:ab != 'empty']">
                            <xsl:apply-templates select="tei:support/tei:ab/text()"/>
                        </xsl:if>
                    </span>
                </li>
            </xsl:when>
            <xsl:otherwise>Angiv materiale</xsl:otherwise>
        </xsl:choose>
        <!-- Test for presence of extent -->
        <xsl:if test="tei:extent/tei:dimensions/tei:width[text()!='0']">
            <xsl:apply-templates select="tei:extent"/>
        </xsl:if>
        <!-- Test for presence of condition -->
        <xsl:if test="tei:condition/tei:ab[text()!='empty']">
            <xsl:apply-templates select="tei:condition"/>
        </xsl:if>
    </xsl:template>
</xsl:stylesheet>
