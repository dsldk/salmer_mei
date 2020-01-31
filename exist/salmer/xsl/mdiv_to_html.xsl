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
<!--	<xsl:param name="include_data" as="xs:boolean"/>  -->

	
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
				<div id="{$id}{$mdivId}" class="mei">
					Henter noder...<br/>
					<p class="loading"><img src="style/img/loading.gif" width="128" height="128" alt="Henter noder..." title="Henter noder..."/></p>
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
			</div>
	</xsl:template>
	
	
</xsl:stylesheet>