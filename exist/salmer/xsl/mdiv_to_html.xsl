<xsl:stylesheet xmlns="http://www.w3.org/1999/xhtml" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:m="http://www.music-encoding.org/ns/mei" version="2.0" exclude-result-prefixes="m xsl xs">

	<!-- 
		Prepare MEI 4.0.0 <mdiv> elements for rendering 
		
		Authors: 
		Axel Teich Geertinger
		Det Danske Sprog- og Literaturselskab, 2019
	-->
	

	<xsl:output method="xml" encoding="UTF-8" cdata-section-elements="" omit-xml-declaration="yes" indent="no" xml:space="default"/>

	<xsl:strip-space elements="*"/>

	<xsl:param name="mdiv"/>
	<xsl:param name="doc" select="//m:music[1]/@xml:id"/>
	<xsl:param name="linewise" select="false()"/>
	<xsl:param name="language"/>
	<xsl:param name="hostname"/>
	<!--	<xsl:param name="include_data" as="xs:boolean"/>  -->

	<xsl:param name="base_uri" select="concat('https://',$hostname)"/>

	<!-- Default language for labels etc. Default is overridden if the calling script provides a language parameter -->
	<xsl:variable name="default_language">da</xsl:variable>

	<xsl:variable name="language_pack_file_name">
		<xsl:choose>
			<xsl:when test="$language!=''">
				<xsl:value-of select="string(concat($base_uri,'/library/language/',$language,'.xml'))"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="string(concat($base_uri,'/library/language/',$default_language,'.xml'))"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:variable>
	<xsl:variable name="l" select="document($language_pack_file_name)/language"/>
	
	
	<!-- MAIN TEMPLATE -->
	<xsl:template match="m:mei" xml:space="default">
	    <xsl:apply-templates select="m:music/m:body/m:mdiv[@xml:id=$mdiv]"/>
	</xsl:template>
	
	<!-- SUB-TEMPLATES -->

    <!-- Display score -->
	<xsl:template match="m:mdiv">
		<xsl:variable name="id" select="substring-before($doc,'.xml')"/>
			<xsl:variable name="mdivId">
				<xsl:if test="count(//m:music//m:mdiv) &gt; 1">
                    <xsl:value-of select="concat('MDIV',$mdiv)"/>
                </xsl:if>
			</xsl:variable>
			<div class="score">
				<xsl:choose>
					<xsl:when test="not($linewise)">
						<div id="{$id}{$mdivId}" class="mei">
						    <p class="loading"><xsl:value-of select="$l/retrieving_score"/></p>
						</div>
						<div id="{$id}{$mdivId}_options" class="mei_options">
							<xsl:comment>MEI options menu will be inserted here</xsl:comment>
						</div>
						<!--				<xsl:if test="$include_data">
							<script id="{$id}_data" type="text/xml">
							<xsl:comment>Commented out</xsl:comment>
							<xsl:copy-of select="/"/>  
							</script>
							</xsl:if>-->
					</xsl:when>
					<xsl:otherwise>
						<!-- split up the score into single-system chunks -->
					</xsl:otherwise>
				</xsl:choose>
			</div>
	</xsl:template>
	
	
</xsl:stylesheet>