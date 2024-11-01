<?xml version="1.0" encoding="UTF-8" ?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:x="anything">
	<xsl:namespace-alias stylesheet-prefix="x" result-prefix="xsl" />
	<xsl:output encoding="UTF-8" indent="yes" method="xml" />
	<xsl:include href="../utils.xsl" />

	<xsl:template match="/Paytable">
		<x:stylesheet version="1.0" xmlns:java="http://xml.apache.org/xslt/java" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
			exclude-result-prefixes="java" xmlns:lxslt="http://xml.apache.org/xslt" xmlns:my-ext="ext1" extension-element-prefixes="my-ext">
			<x:import href="HTML-CCFR.xsl" />
			<x:output indent="no" method="xml" omit-xml-declaration="yes" />

			<!-- TEMPLATE Match: -->
			<x:template match="/">
				<x:apply-templates select="*" />
				<x:apply-templates select="/output/root[position()=last()]" mode="last" />
				<br />
			</x:template>

			<!--The component and its script are in the lxslt namespace and define the implementation of the extension. -->
			<lxslt:component prefix="my-ext" functions="formatJson,retrievePrizeTable,getType">
				<lxslt:script lang="javascript">
					<![CDATA[
var debugFeed = [];
var debugFlag = false;
// Format instant win JSON results.
// @param jsonContext String JSON results to parse and display.
// @param translation Set of Translations for the game.
function formatJson(jsonContext, translations, prizeTable, prizeValues, prizeNamesDesc) {
    var scenario = getScenario(jsonContext);
    var scenarioWinNums = scenario.split('|')[0].split(',');
    var scenarioBonusNums = scenario.split('|').slice(1, 3);
    var scenarioYourNums = scenario.split('|')[3].split(',');
    var convertedPrizeValues = (prizeValues.substring(1)).split('|').map(function (item) { return item.replace(/\t|\r|\n/gm, "") });
    var prizeNames = (prizeNamesDesc.substring(1)).split(',');

    ////////////////////
    // Parse scenario //
    ////////////////////

    var arrBonusNums = [];
    var arrSetYourNums = [];
    var arrWinNums = [];
    var arrYourNumParts = [];
    var arrYourNums = [];
    var indexNum = -1;
    var objBonusNum = {};
    var objWinNum = {};
    var objYourNum = {};

    for (var indexYourNum = 0; indexYourNum < scenarioYourNums.length; indexYourNum++) {
        objYourNum = { sValue: '', sPrize: '', bIW: false, bMatched: false };

        arrYourNumParts = scenarioYourNums[indexYourNum].split(':');

        objYourNum.sValue = arrYourNumParts[0];
        objYourNum.sPrize = arrYourNumParts[1];
        objYourNum.bIW = (objYourNum.sValue.indexOf('X') != -1);

        arrYourNums.push(objYourNum);
        arrSetYourNums.push(objYourNum.sValue);
    }

    for (var indexWinNum = 0; indexWinNum < scenarioWinNums.length; indexWinNum++) {
        objWinNum = { sValue: '', bMatched: false };
        indexNum = arrSetYourNums.indexOf(scenarioWinNums[indexWinNum]);

        objWinNum.sValue = scenarioWinNums[indexWinNum];
        objWinNum.bMatched = (indexNum != -1);

        arrWinNums.push(objWinNum);

        if (objWinNum.bMatched) {
            arrYourNums[indexNum].bMatched = true;
        }
    }

    for (var indexBonusNum = 0; indexBonusNum < scenarioBonusNums.length; indexBonusNum++) {
        objBonusNum = { sValue: '', bMatched: false };
        indexNum = arrSetYourNums.indexOf(scenarioBonusNums[indexBonusNum]);

        objBonusNum.sValue = scenarioBonusNums[indexBonusNum];
        objBonusNum.bMatched = (indexNum != -1);

        arrBonusNums.push(objBonusNum);

        if (objBonusNum.bMatched) {
            arrYourNums[indexNum].bMatched = true;
        }
    }

    /////////////////////////
    // Currency formatting //
    /////////////////////////

    var bCurrSymbAtFront = false;
    var strCurrSymb = '';
    var strDecSymb = '';
    var strThouSymb = '';

    function getCurrencyInfoFromTopPrize() {
        var topPrize = convertedPrizeValues[0];
        var strPrizeAsDigits = topPrize.replace(new RegExp('[^0-9]', 'g'), '');
        var iPosFirstDigit = topPrize.indexOf(strPrizeAsDigits[0]);
        var iPosLastDigit = topPrize.lastIndexOf(strPrizeAsDigits.substr(-1));
        bCurrSymbAtFront = (iPosFirstDigit != 0);
        strCurrSymb = (bCurrSymbAtFront) ? topPrize.substr(0, iPosFirstDigit) : topPrize.substr(iPosLastDigit + 1);
        var strPrizeNoCurrency = topPrize.replace(new RegExp('[' + strCurrSymb + ']', 'g'), '');
        var strPrizeNoDigitsOrCurr = strPrizeNoCurrency.replace(new RegExp('[0-9]', 'g'), '');
        strDecSymb = strPrizeNoDigitsOrCurr.substr(-1);
        strThouSymb = (strPrizeNoDigitsOrCurr.length > 1) ? strPrizeNoDigitsOrCurr[0] : strThouSymb;
    }

    function getPrizeInCents(AA_strPrize) {
        return parseInt(AA_strPrize.replace(new RegExp('[^0-9]', 'g'), ''), 10);
    }

    function getCentsInCurr(AA_iPrize) {
        var strValue = AA_iPrize.toString();

        strValue = (strValue.length < 3) ? ('00' + strValue).substr(-3) : strValue;
        strValue = strValue.substr(0, strValue.length - 2) + strDecSymb + strValue.substr(-2);
        strValue = (strValue.length > 6) ? strValue.substr(0, strValue.length - 6) + strThouSymb + strValue.substr(-6) : strValue;
        strValue = (bCurrSymbAtFront) ? strCurrSymb + strValue : strValue + strCurrSymb;

        return strValue;
    }

    getCurrencyInfoFromTopPrize();

    ///////////////
    // UI Config //
    ///////////////

    const colourBlack = '#000000';
    const colourBlue = '#99ccff';
    const colourBrown = '#990000';
    const colourGreen = '#00cc00';
    const colourLemon = '#ffff99';
    const colourLilac = '#ccccff';
    const colourLime = '#ccff99';
    const colourNavy = '#0000ff';
    const colourOrange = '#ffcc99';
    const colourPink = '#ffccff';
    const colourPurple = '#cc99ff';
    const colourRed = '#ff9999';
    const colourScarlet = '#ff0000';
    const colourWhite = '#ffffff';
    const colourYellow = '#ffff00';

    const boxWidth = 120;
    const boxMargin = 1;

    var boxColourStr = '';
    var canvasIdStr = '';
    var elementStr = '';
    var textStr1 = '';
    var textStr2 = '';

    var r = [];

    function showBox(A_strCanvasId, A_strCanvasElement, A_iWidth, A_strBoxColour, A_strTextColour, A_strText1, A_strText2) {
        const boxHeightStd = 24;
        const boxTextY2 = 40;

        var canvasCtxStr = 'canvasContext' + A_strCanvasElement;
        var canvasWidth = A_iWidth + 2 * boxMargin;
        var boxHeight = (A_strText2 == '') ? boxHeightStd : 2 * boxHeightStd;
        var canvasHeight = boxHeight + 2 * boxMargin;
        var boxTextY = (A_strText2 == '') ? boxHeight / 2 + 3 : boxHeight / 2 - 6;
        var textSize1 = (A_strText2 == '') ? ((A_strBoxColour == colourBlack) ? '14' : '16') : '24';

        r.push('<canvas id="' + A_strCanvasId + '" width="' + canvasWidth.toString() + '" height="' + canvasHeight.toString() + '"></canvas>');
        r.push('<script>');
        r.push('var ' + A_strCanvasElement + ' = document.getElementById("' + A_strCanvasId + '");');
        r.push('var ' + canvasCtxStr + ' = ' + A_strCanvasElement + '.getContext("2d");');
        r.push(canvasCtxStr + '.font = "bold ' + textSize1 + 'px Arial";');
        r.push(canvasCtxStr + '.textAlign = "center";');
        r.push(canvasCtxStr + '.textBaseline = "middle";');
        r.push(canvasCtxStr + '.strokeRect(' + (boxMargin + 0.5).toString() + ', ' + (boxMargin + 0.5).toString() + ', ' + A_iWidth.toString() + ', ' + boxHeight.toString() + ');');
        r.push(canvasCtxStr + '.fillStyle = "' + A_strBoxColour + '";');
        r.push(canvasCtxStr + '.fillRect(' + (boxMargin + 1.5).toString() + ', ' + (boxMargin + 1.5).toString() + ', ' + (A_iWidth - 2).toString() + ', ' + (boxHeight - 2).toString() + ');');
        r.push(canvasCtxStr + '.fillStyle = "' + A_strTextColour + '";');
        r.push(canvasCtxStr + '.fillText("' + A_strText1 + '", ' + (A_iWidth / 2 + boxMargin).toString() + ', ' + boxTextY.toString() + ');');

        if (A_strText2 != '') {
            r.push(canvasCtxStr + '.font = "bold 12px Arial";');
            r.push(canvasCtxStr + '.fillText("' + A_strText2 + '", ' + (A_iWidth / 2 + boxMargin).toString() + ', ' + boxTextY2.toString() + ');');
        }

        r.push('</script>');
    }

    function showCircle(A_strCanvasId, A_strCanvasElement, A_strBoxColour, A_strText) {
        const circleSize = 60;

        var canvasCtxStr = 'canvasContext' + A_strCanvasElement;
        var canvasSize = circleSize + 2 * boxMargin;
        var circleOrigin = canvasSize / 2;
        var circleRadius = circleSize / 2;

        r.push('<canvas id="' + A_strCanvasId + '" width="' + canvasSize.toString() + '" height="' + canvasSize.toString() + '"></canvas>');
        r.push('<script>');
        r.push('var ' + A_strCanvasElement + ' = document.getElementById("' + A_strCanvasId + '");');
        r.push('var ' + canvasCtxStr + ' = ' + A_strCanvasElement + '.getContext("2d");');
        r.push(canvasCtxStr + '.font = "bold 16px Arial";');
        r.push(canvasCtxStr + '.textAlign = "center";');
        r.push(canvasCtxStr + '.textBaseline = "middle";');
        r.push(canvasCtxStr + '.beginPath();');
        r.push(canvasCtxStr + '.arc(' + circleOrigin.toString() + ', ' + circleOrigin.toString() + ', ' + circleRadius.toString() + ', 0, 2*Math.PI);');
        r.push(canvasCtxStr + '.stroke();');
        r.push(canvasCtxStr + '.arc(' + circleOrigin.toString() + ', ' + circleOrigin.toString() + ', ' + (circleRadius - 1).toString() + ', 0, 2*Math.PI);');
        r.push(canvasCtxStr + '.fillStyle = "' + A_strBoxColour + '";');
        r.push(canvasCtxStr + '.fill();');
        r.push(canvasCtxStr + '.fillStyle = "' + colourBlack + '";');
        r.push(canvasCtxStr + '.fillText("' + A_strText + '", ' + (circleRadius + boxMargin).toString() + ', ' + (circleRadius + 3).toString() + ');');

        r.push('</script>');
    }

    r.push('<p>' + getTranslationByName("gameDetails", translations) + '</p>');

    r.push('<div style="float:left; margin-right:50px">');
    r.push('<table border="0" cellpadding="2" cellspacing="1" class="gameDetailsTable">');
    r.push('<tr class="tableheader">');
    r.push('<td colspan="' + arrWinNums.length.toString() + '" align="center">');

    canvasIdStr = 'cvsWinNumsTitle';
    elementStr = 'eleWinNumsTitle';
    textStr1 = getTranslationByName("titleWinNums", translations);

    showBox(canvasIdStr, elementStr, arrWinNums.length * boxWidth, colourBlack, colourWhite, textStr1, '');

    r.push('</td>');
    r.push('</tr>');
    r.push('<tr class="tablebody">');

    for (var indexWinNum = 0; indexWinNum < arrWinNums.length; indexWinNum++) {
        r.push('<td align="center">');

        canvasIdStr = 'cvsWinNumData' + indexWinNum.toString();
        elementStr = 'eleWinNumData' + indexWinNum.toString();
        boxColourStr = (arrWinNums[indexWinNum].bMatched) ? colourLime : colourWhite;
        textStr1 = arrWinNums[indexWinNum].sValue;

        showCircle(canvasIdStr, elementStr, boxColourStr, textStr1);

        r.push('</td>');
    }

    r.push('</tr>');
    r.push('</table>');
    r.push('</div>');

    ///////////////
    // Bonus Num //
    ///////////////

    r.push('<div style="float:left">');
    r.push('<table border="0" cellpadding="2" cellspacing="1" class="gameDetailsTable">');
    r.push('<tr class="tableheader">');

    for (indexBonusNum = 0; indexBonusNum < arrBonusNums.length; indexBonusNum++) {
        r.push('<td align="center">');

        canvasIdStr = 'cvsBonusNumTitle' + indexBonusNum.toString();
        elementStr = 'eleBonusNumTitle' + indexBonusNum.toString();
        textStr1 = getTranslationByName("titleBonus" + (indexBonusNum + 1).toString(), translations);

        showBox(canvasIdStr, elementStr, boxWidth, colourBlack, colourWhite, textStr1, '');

        r.push('</td>');
    }

    r.push('</tr>');
    r.push('<tr class="tablebody">');

    for (indexBonusNum = 0; indexBonusNum < arrBonusNums.length; indexBonusNum++) {
        r.push('<td align="center">');

        canvasIdStr = 'cvsBonusNumData' + indexBonusNum.toString();
        elementStr = 'eleBonusNumData' + indexBonusNum.toString();
        boxColourStr = (arrBonusNums[indexBonusNum].bMatched) ? colourLime : colourWhite;
        textStr1 = arrBonusNums[indexBonusNum].sValue;

        showCircle(canvasIdStr, elementStr, boxColourStr, textStr1);

        r.push('</td>');
    }

    r.push('</tr>');
    r.push('</table>');
    r.push('</div>');

    ///////////////
    // Your Nums //
    ///////////////

    const yourNumRows = 4;
    const yourNumsPerRow = 5;

    var indexYourNum = 0;

    r.push('<div style="clear:both"></div>');
    r.push('<p>&nbsp;</p>');

    r.push('<div style="float:left">');
    r.push('<table border="0" cellpadding="2" cellspacing="1" class="gameDetailsTable">');
    r.push('<tr class="tableheader">');
    r.push('<td colspan="' + yourNumsPerRow.toString() + '" align="center">');

    canvasIdStr = 'cvsYourNumsTitle';
    elementStr = 'eleYourNumsTitle';
    textStr1 = getTranslationByName("titleYourNums", translations);

    showBox(canvasIdStr, elementStr, yourNumsPerRow * boxWidth, colourBlack, colourWhite, textStr1, '');

    r.push('</td>');
    r.push('</tr>');

    for (var indexYourNumRow = 0; indexYourNumRow < yourNumRows; indexYourNumRow++) {
        r.push('<tr class="tablebody">');

        for (var indexYourNumCol = 0; indexYourNumCol < yourNumsPerRow; indexYourNumCol++) {
            r.push('<td align="center">');

            indexYourNum = indexYourNumRow * yourNumsPerRow + indexYourNumCol;

            canvasIdStr = 'cvsYourNumData' + indexYourNum.toString();
            elementStr = 'eleYourNumData' + indexYourNum.toString();
            boxColourStr = (arrYourNums[indexYourNum].bMatched) ? colourLime : ((arrYourNums[indexYourNum].bIW) ? colourRed : colourWhite);
            textStr1 = arrYourNums[indexYourNum].sValue;
            textStr2 = convertedPrizeValues[getPrizeNameIndex(prizeNames, arrYourNums[indexYourNum].sPrize)];

            showBox(canvasIdStr, elementStr, boxWidth, boxColourStr, colourBlack, textStr1, textStr2);

            r.push('</td>');
        }

        r.push('</tr>');
    }

    r.push('</table>');
    r.push('</div>');

    r.push('<p>&nbsp;</p>');

						////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
						// !DEBUG OUTPUT TABLE
						////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
						if(debugFlag)
						{
							//////////////////////////////////////
							// DEBUG TABLE
							//////////////////////////////////////
							r.push('<table border="0" cellpadding="2" cellspacing="1" width="100%" class="gameDetailsTable" style="table-layout:fixed">');
							for(var idx = 0; idx < debugFeed.length; ++idx)
 							{
								if(debugFeed[idx] == "")
									continue;
								r.push('<tr>');
 								r.push('<td class="tablebody">');
								r.push(debugFeed[idx]);
 								r.push('</td>');
	 							r.push('</tr>');
							}
							r.push('</table>');
						}
						return r.join('');
					}

					function getScenario(jsonContext)
					{
						var jsObj = JSON.parse(jsonContext);
						var scenario = jsObj.scenario;

						scenario = scenario.replace(/\0/g, '');

						return scenario;
					}

					// Input: A list of Price Points and the available Prize Structures for the game as well as the wagered price point
					// Output: A string of the specific prize structure for the wagered price point
					function retrievePrizeTable(pricePoints, prizeStructures, wageredPricePoint)
					{
						var pricePointList = pricePoints.split(",");
						var prizeStructStrings = prizeStructures.split("|");

						for(var i = 0; i < pricePoints.length; ++i)
						{
							if(wageredPricePoint == pricePointList[i])
							{
								return prizeStructStrings[i];
							}
						}

						return "";
					}

					// Input: Json document string containing 'amount' at root level.
					// Output: Price Point value.
					function getPricePoint(jsonContext)
					{
						// Parse json and retrieve price point amount
						var jsObj = JSON.parse(jsonContext);
						var pricePoint = jsObj.amount;

						return pricePoint;
					}

					// Input: "A,B,C,D,..." and "A"
					// Output: index number
					function getPrizeNameIndex(prizeNames, currPrize)
					{
						for(var i = 0; i < prizeNames.length; ++i)
						{
							if(prizeNames[i] == currPrize)
							{
								return i;
							}
						}
					}

					////////////////////////////////////////////////////////////////////////////////////////
					function registerDebugText(debugText)
					{
						debugFeed.push(debugText);
					}

					/////////////////////////////////////////////////////////////////////////////////////////
					function getTranslationByName(keyName, translationNodeSet)
					{
						var index = 1;
						while(index < translationNodeSet.item(0).getChildNodes().getLength())
						{
							var childNode = translationNodeSet.item(0).getChildNodes().item(index);
							
							if(childNode.name == "phrase" && childNode.getAttribute("key") == keyName)
							{
								registerDebugText("Child Node: " + childNode.name);
								return childNode.getAttribute("value");
							}
							
							index += 1;
						}
					}

					// Grab Wager Type
					// @param jsonContext String JSON results to parse and display.
					// @param translation Set of Translations for the game.
					function getType(jsonContext, translations)
					{
						// Parse json and retrieve wagerType string.
						var jsObj = JSON.parse(jsonContext);
						var wagerType = jsObj.wagerType;

						return getTranslationByName(wagerType, translations);
					}
					]]>
				</lxslt:script>
			</lxslt:component>

			<x:template match="root" mode="last">
				<table border="0" cellpadding="1" cellspacing="1" width="100%" class="gameDetailsTable">
					<tr>
						<td valign="top" class="subheader">
							<x:value-of select="//translation/phrase[@key='totalWager']/@value" />
							<x:value-of select="': '" />
							<x:call-template name="Utils.ApplyConversionByLocale">
								<x:with-param name="multi" select="/output/denom/percredit" />
								<x:with-param name="value" select="//ResultData/WagerOutcome[@name='Game.Total']/@amount" />
								<x:with-param name="code" select="/output/denom/currencycode" />
								<x:with-param name="locale" select="//translation/@language" />
							</x:call-template>
						</td>
					</tr>
					<tr>
						<td valign="top" class="subheader">
							<x:value-of select="//translation/phrase[@key='totalWins']/@value" />
							<x:value-of select="': '" />
							<x:call-template name="Utils.ApplyConversionByLocale">
								<x:with-param name="multi" select="/output/denom/percredit" />
								<x:with-param name="value" select="//ResultData/PrizeOutcome[@name='Game.Total']/@totalPay" />
								<x:with-param name="code" select="/output/denom/currencycode" />
								<x:with-param name="locale" select="//translation/@language" />
							</x:call-template>
						</td>
					</tr>
				</table>
			</x:template>

			<!-- TEMPLATE Match: digested/game -->
			<x:template match="//Outcome">
				<x:if test="OutcomeDetail/Stage = 'Scenario'">
					<x:call-template name="Scenario.Detail" />
				</x:if>
			</x:template>

			<!-- TEMPLATE Name: Scenario.Detail (base game) -->
			<x:template name="Scenario.Detail">
				<x:variable name="odeResponseJson" select="string(//ResultData/JSONOutcome[@name='ODEResponse']/text())" />
				<x:variable name="translations" select="lxslt:nodeset(//translation)" />
				<x:variable name="wageredPricePoint" select="string(//ResultData/WagerOutcome[@name='Game.Total']/@amount)" />
				<x:variable name="prizeTable" select="lxslt:nodeset(//lottery)" />

				<table border="0" cellpadding="0" cellspacing="0" width="100%" class="gameDetailsTable">
					<tr>
						<td class="tablebold" background="">
							<x:value-of select="//translation/phrase[@key='wagerType']/@value" />
							<x:value-of select="': '" />
							<x:value-of select="my-ext:getType($odeResponseJson, $translations)" disable-output-escaping="yes" />
						</td>
					</tr>
					<tr>
						<td class="tablebold" background="">
							<x:value-of select="//translation/phrase[@key='transactionId']/@value" />
							<x:value-of select="': '" />
							<x:value-of select="OutcomeDetail/RngTxnId" />
						</td>
					</tr>
				</table>
				<br />			
				
				<x:variable name="convertedPrizeValues">
					<x:apply-templates select="//lottery/prizetable/prize" mode="PrizeValue"/>
				</x:variable>

				<x:variable name="prizeNames">
					<x:apply-templates select="//lottery/prizetable/description" mode="PrizeDescriptions"/>
				</x:variable>


				<x:value-of select="my-ext:formatJson($odeResponseJson, $translations, $prizeTable, string($convertedPrizeValues), string($prizeNames))" disable-output-escaping="yes" />
			</x:template>

			<x:template match="prize" mode="PrizeValue">
					<x:text>|</x:text>
					<x:call-template name="Utils.ApplyConversionByLocale">
						<x:with-param name="multi" select="/output/denom/percredit" />
					<x:with-param name="value" select="text()" />
						<x:with-param name="code" select="/output/denom/currencycode" />
						<x:with-param name="locale" select="//translation/@language" />
					</x:call-template>
			</x:template>
			<x:template match="description" mode="PrizeDescriptions">
				<x:text>,</x:text>
				<x:value-of select="text()" />
			</x:template>

			<x:template match="text()" />
		</x:stylesheet>
	</xsl:template>

	<xsl:template name="TemplatesForResultXSL">
		<x:template match="@aClickCount">
			<clickcount>
				<x:value-of select="." />
			</clickcount>
		</x:template>
		<x:template match="*|@*|text()">
			<x:apply-templates />
		</x:template>
	</xsl:template>
</xsl:stylesheet>
