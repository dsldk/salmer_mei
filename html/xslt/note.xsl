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

    <!--<xsl:template match="tei:body//tei:note">
        <xsl:variable name="identifier">
            <xsl:text>Note</xsl:text>
            <xsl:choose>
                <xsl:when test="@xml:id">
                    <xsl:value-of select="@xml:id"/>
                </xsl:when>
                <xsl:when test="@n">
                    <xsl:value-of select="@n"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:number level="single"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <a class="notelink" href="#{$identifier}">
            <sup>
                <xsl:call-template name="noteN"/>
            </sup>
        </a>
    </xsl:template>
    <xsl:template name="noteN">
        <xsl:choose>
            <xsl:when test="@n">
                <xsl:value-of select="@n"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:number from="tei:text" level="any" format="1"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>-->
    <!-- Template, der matcher note og opbygger note
        i det kritiske apparat-->
    <!--<xsl:template match="tei:note" mode="footnoteApparatus">
        <xsl:variable name="identifier">
            <xsl:text>Note</xsl:text>
            <xsl:choose>
                <xsl:when test="@xml:id">
                    <xsl:value-of select="@xml:id"/>
                </xsl:when>
                <xsl:when test="@n">
                    <xsl:value-of select="@n"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:number count="tei:note" from="tei:body" level="any"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <span class="note">
            <span class="noteLabel">
                <strong>
                    <xsl:call-template name="noteN"/>
                    <xsl:text>. </xsl:text>
                </strong>
            </span>
            <span class="noteBody">
                <xsl:apply-templates/>
            </span>
            <xsl:text>
			</xsl:text>
        </span>
    </xsl:template>-->

    <!-- Handle marginal notes -->
    <xsl:template match="tei:note[@place = 'right'] | tei:note[@place = 'left']">
        <span class="marginal-note">
            <span class="marginal-note-mark">$<!--<xsl:value-of select="@n"/>|--></span>
            <span class="marginal-note-content">
                <xsl:apply-templates/>
            </span>
        </span>
    </xsl:template>
    <xsl:template match="tei:note[@place = 'bottom']">
        <xsl:choose>
            <xsl:when test="@type = 'add'"/>
            <xsl:otherwise>
                <xsl:variable name="identifier">
                    <xsl:text>Note</xsl:text>
                    <xsl:choose>
                        <xsl:when test="@xml:id">
                            <xsl:value-of select="@xml:id"/>
                        </xsl:when>
                        <xsl:when test="@n">
                            <xsl:value-of select="@n"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:number count="tei:note[@place = 'bottom']" from="tei:body"
                                level="any"/>
                            <!--<xsl:number/>-->
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>
                <a class="notelink" href="#{$identifier}" id="back{$identifier}">
                    <sup>*<!--<xsl:call-template name="noteN"/>--></sup>
                </a>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template name="noteN">
        <xsl:choose>
            <xsl:when test="@n">
                <xsl:value-of select="@n"/>
            </xsl:when>
            <xsl:otherwise>
                <!--<xsl:number count="tei:note[not(@type)]" from="tei:body" level="any"/>-->
                <xsl:number count="tei:note[@place = 'bottom']" from="tei:body" level="any"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="tei:note[@place = 'bottom']" mode="footnoteApparatus">
        <xsl:choose>
            <xsl:when test="@type = 'add'"/>
            <xsl:otherwise>
                <xsl:variable name="identifier">
                    <xsl:text>Note</xsl:text>
                    <xsl:choose>
                        <xsl:when test="@xml:id">
                            <xsl:value-of select="@xml:id"/>
                        </xsl:when>
                        <xsl:when test="@n">
                            <xsl:value-of select="@n"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <!--<xsl:number count="tei:note[not(@type)]" from="tei:body" level="any"/>-->
                            <xsl:number count="tei:note[@place = 'bottom']" from="tei:body"
                                level="any"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>
                <p class="note">
                    <span class="noteLabel" id="{$identifier}">
                        <strong>
                            <a href="#back{$identifier}">
                                <xsl:call-template name="noteN"/>
                            </a>
                            <xsl:text>. </xsl:text>
                        </strong>
                    </span>
                    <span class="noteBody">
                        <xsl:apply-templates/>
                    </span>
                </p>
            </xsl:otherwise>
        </xsl:choose>

    </xsl:template>

    <!--Notes in rdg elements should be rendered in italics-->
    <xsl:template match="tei:rdg/tei:note">
        <em>
            <xsl:apply-templates/>
        </em>
    </xsl:template>
</xsl:stylesheet>
