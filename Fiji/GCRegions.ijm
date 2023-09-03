//#@ String(label="Process Mode", choices=("singleFile", "wholeFolder", "AllSubFolders"), style="list") iProcessMode
var iProcessMode = "singleFile";
#@ String(label="File Extension",value=".tif", persist=true, description="eg .tif, .h5") iFileExtension
#@ String(label="CD35 Smooth factor (microns)",value="15", persist=true, description="Gaussian smooth factor to generate CD35 area") iCD35SmoothFactor
#@ String(label="CD23 Smooth factor (microns)",value="15", persist=true, description="Gaussian smooth factor to generate CD23 area") iCD23SmoothFactor
#@ String(label="CD35 Threshold Intensity (0-64K)",value="5000", persist=true, description="Threshold to mark CD35 region") iCD35Threshold
#@ String(label="CD23 Threshold Intensity (0-64K)",value="4000", persist=true, description="Threshold to mark CD35 region") iCD23Threshold
#@ String(label="CD35 Area min size (microns^2)",value="1000", persist=true, description="Used to identify main region") iCD35MinSize
#@ String(label="CD23 Area min size (microns^2)",value="500", persist=true, description="Used to identify main region") iCD23MinSize
#@ String(label="CD35 max pixel display value (0-64K)",value="20000", persist=true, description="Used to generate CD35 image") iCD35MaxPixelDisplayValue
#@ String(label="CD23 max pixel display value (0-64K)",value="10000", persist=true, description="Used to generate CD23 image") iCD23MaxPixelDisplayValue
//#@ String(label="Smoothed CD35 max pixel display value (0-64K)",value="5000", persist=true, description="Used to generate smooth CD35 image") iSmoothedCD35MaxPixelDisplayValue
//#@ String(label="Smoothed CD23 max pixel display value (0-64K)",value="7000", persist=true, description="Used to generate smooth CD23 image") iSmoothedCD23MaxPixelDisplayValue
#@ String(label="CD35 roi color",value="yellow", persist=true, description="Used to generate CD35 roi image") iCD35Color
#@ String(label="CD23 roi color",value="blue", persist=true, description="Used to generate CD23 roi image") iCD23Color
#@ String(label="Line margin (% of GC)",value="20", persist=true, description="The margins added to the line before and after GC ") iLineMargin
#@ String(label="Line width (% of GC)",value="70", persist=true, description="The width of the Line relative to the width of GC") iLineWidth
#@ String(label="T Cell nucleic area min size (microns^2)",value="10", persist=true, description="Used to filter noise") iMinTCellSize
#@ String(label="T Cell nucleic area max size (microns^2)",value="100", persist=true, description="Used to filter noise") iMaxTCellSize
#@ String(label="T Cell nucleic min intensity (0-64K)",value="3000", persist=true, description="Used to filter noise") iTCellMinIntensity
#@ String(label="GC roi color",value="pink", persist=true, description="Used to generate GC roi image") iGCColor
#@ String(label="ROI Line width",value=10, persist=true, description="Used to generate rois") iROILineWidth
#@ String(label="Spot artifact CD35 thresold",value=100000, persist=true, description="remove high intensity spots 0-64K") i35SpotThreshold
#@ String(label="Spot artifact CD23 thresold",value=20000, persist=true, description="remove high intensity spots 0-64K") i23SpotThreshold

#@ boolean(label="Use labeld dapi previous info",value=false, persist=true, description="for quicker runs, use previous dapi labeling") iUseStoredLabeledImage
#@ boolean(label="Skip T Cells analysis altogether",value=false, persist=true, description="for quicker runs without T Cells info") iSkipTCellsAnalysis


//CGRegions
//Input: a file with 4 channels:
//Ch. 1: Dapi
//Ch. 2: CD23 staining
//Ch. 3: T cell staining
//CH. 4: CD35 staining
// 0. DETECT T-CELLS: SEGMENT NUCLEI, MEASURE MEAN T-CELLS INTENSITY (CD4), DISCARD NUC WITH LOW INTENSITY (PARAMETER) 
// 1. Get The ROI of the GC (Input for now)
// 2. Generate a fitting ellipse for that ROI
// 3. Generate an ROI for CD35 staining within the ellipse
// 4. Generate an ROI for CD23 staining within the ellipse
// 6. Find the hemisphere where CD35 ROI is mainly located
// 7. Draw a line of iWidthPercentage (of vertical diagonal) along the dagonal of the elipse starting from that hemisphere
//    that starts iLineMargin (of horizontal diagonal) before the ellipse and ends iLineMargin after it
// 8. Generate a histogram of the line on top of CD35 and CD23 channels and save it to file
// 10. Calculate the number of T cells and their density in CD35 and CD23 ROIs
// 11. generate an image with GC,CD23,CD35 on top of CD23 and CD35 channels



//----- global variables-----------
var	gCompositeTable = "CompositeResults.xls";
var	gAllCompositeTable = "allCompositeTable.xls";
var gResultsSubFolder = "uninitialized";
var gImagesResultsSubFolder = "uninitialized";
var gMainDirectory = "uninitialized";
var gSubFolderName = "";
var gFileFullPath = "uninitialized"
var gFileNameNoExt = "uninitialized"
var gH5OpenParms = "datasetname=[/data: (1, 1, 1024, 1024, 1) uint8] axisorder=tzyxc";
var gImsOpenParms = "autoscale color_mode=Default view=Hyperstack stack_order=XYCZT series_"; //bioImage importer auto-selection
var gRoisSuffix = "_RoiSet"
var gROIMeasurment = "area centroid perimeter fit integrated display";
//------ constants--------
var GAUSSIAN_BLUR = 0;

var CD35_CHANNEL = 4
var CD23_CHANNEL = 2
var DAPI_CHANNEL = 1
var TCELLS_CHANNEL = 3
var	gHemiNames = newArray("Left","Top","Right","Bottom");
var gChannels = newArray("None","Dapi","CD23","T Cells","CD35");
//-------macro specific global variables
var gCD35ImgId = 0;
var gCD23ImgId = 0;
var gTCellsImgId = 0;
var gDapiImgId = 0;
var gTCellsBitmapImgId = 0;
var gCD35SmoothImgId = 0;

var hHorizontal = -1;
var hVertical = -1;
var gLineWidth = -1;
var rAngle = -1;
var sinAngle = -1;
var cosAngle = -1;
var cX = -1;
var cY = -1;
var switch;
var width, height, channels, slices, frames;
var unit,pixelWidth, pixelHeight;
//-----debug variables--------
var gDebugFlag = false;
var gBatchModeFlag = false;
//------------Main------------
Initialization();
SetProcessMode();
if(LoopFiles())
	print("Macro ended successfully");
else
	print("Macro failed");
CleanUp(true);
waitForUser("=================== Done ! ===================");


// Run analysis of single file
//Input: a file with 4 channels:
//Ch. 1: Dapi
//Ch. 2: CD23 staining
//Ch. 3: T cell staining
//CH. 4: CD35 staining
// 1. DETECT T-CELLS: SEGMENT NUCLEI, MEASURE MEAN T-CELLS INTENSITY (CD4), DISCARD NUC WITH LOW INTENSITY (PARAMETER) 
// 2. Generate a fitting ellipse for that ROI
// 3. Generate an ROI for CD35 staining within the ellipse
// 4. Generate an ROI for CD23 staining within the ellipse
// 6. Find the hemisphere where CD35 ROI is mainly located
// 7. Draw a line of iWidthPercentage (of vertical diagonal) along the dagonal of the elipse starting from that hemisphere
//    that starts iLineMargin (of horizontal diagonal) before the ellipse and ends iLineMargin after it
// 8. Generate a histogram of the line on top of CD35 and CD23 channels and save it to file
// 10. Calculate the number of T cells and their density in CD35 and CD23 ROIs
//11. generate an image with GC,CD23,CD35 on top of CD23 and CD35 channels
	
function ProcessFile(directory) 
{
	
	setBatchMode(gBatchModeFlag);	
	
	if(!openFile(gFileFullPath))
		return false;
		
	imageId = getImageID();	
	getDimensions(width, height, channels, slices, frames);
	getPixelSize(unit,pixelWidth, pixelHeight);	

	//remove artifacts (spots)
	RemoveArtifacts(imageId,i23SpotThreshold, CD23_CHANNEL);
	RemoveArtifacts(imageId,i35SpotThreshold,CD35_CHANNEL);
		
	gFileNameNoExt = File.getNameWithoutExtension(gFileFullPath);
	gImagesResultsSubFolder = gResultsSubFolder + "/" + gFileNameNoExt;	
	File.makeDirectory(gImagesResultsSubFolder);
	run("Select None");

	// duplicate all channels

	gCD35ImgId = dupChannel(imageId, CD35_CHANNEL, "CD35");
	gCD23ImgId = dupChannel(imageId, CD23_CHANNEL, "CD23");
	gTCellsImgId = dupChannel(imageId, TCELLS_CHANNEL, "T Cells");
	gDapiImgId = dupChannel(imageId, DAPI_CHANNEL, "Dapi");

	//RemoveArtifacts(gCD35ImgId,i35SpotThreshold);
	//RemoveArtifacts(gCD23ImgId,i23SpotThreshold);

	
	// smooth CD35 and CD23
	gCD35SmoothImgId = generateSmoothImage(gCD35ImgId,GAUSSIAN_BLUR,(iCD35SmoothFactor)/pixelWidth,-1,true);
	gCD23SmoothImgId = generateSmoothImage(gCD23ImgId,GAUSSIAN_BLUR,(iCD23SmoothFactor)/pixelWidth,-1,true);
	
	// 1. DETECT T-CELLS: SEGMENT NUCLEI, MEASURE MEAN T-CELLS INTENSITY (CD4), DISCARD NUC WITH LOW INTENSITY (PARAMETER) 
	if(!iSkipTCellsAnalysis)
		gTCellsBitmapImgId = markTCells();

	// get GC ROI
	if(!AddGC_roi())
		return false;
	
	//2. Generate a fitting ellipse for that ROI		
	selectImage(imageId);
	GenerateFittingElipse();
	//3-4. Generate an ROI for CD35 and CD23 staining within the ellipse
	CD35Area = GenerateRoiWithinGC(gCD35SmoothImgId,iCD35Threshold,(iCD35MinSize)/(pixelWidth*pixelHeight),"CD35");
	CD23Area = GenerateRoiWithinGC(gCD23SmoothImgId,iCD23Threshold,(iCD23MinSize)/(pixelWidth*pixelHeight),"CD23");
	//5. GENRATE ROI FOR DARK ZONE = GC ROI - CD 35 ROI
	//GenerateDarkRoi();
	//11. generate an image with GC,CD23,CD35 on top of CD23 and CD35 channels
	compositeImageId = compositeAreas(imageId);
	//6. Find the hemisphere where CD35 ROI is mainly located
	hemiId = FindGCOrientation();
	//7. Draw a line of iWidthPercentage (of vertical diagonal) along the dagonal of the elipse starting from that hemisphere
	//    that starts iLineMargin (of horizontal diagonal) before the ellipse and ends iLineMargin after it
	drawAutoLine(hemiId, iLineWidth/100, iLineMargin/100);
	drawUserLine(compositeImageId, iLineMargin/100);
	//8. Generate a histogram of the line on top of CD35 and CD23 channels and save it to file
	generateLineImageAndHistogram(gCD35SmoothImgId, 0);//iSmoothedCD35MaxPixelDisplayValue);
	generateLineImageAndHistogram(gCD23SmoothImgId, 0);//iSmoothedCD23MaxPixelDisplayValue);
	// 9. Generate a histogram of the number of T cells along that line
	//if(!iSkipTCellsAnalysis)
	//		generateHistogram(gTCellsBitmapImgId);
	// 10. Calculate the number of T cells and their density in CD35 and CD23 ROIs
	if(!iSkipTCellsAnalysis)
		StroeTCellsInfo(CD35Area, CD23Area);
	//store generated ROIs
	storeROIs(gImagesResultsSubFolder, "RoiSet");

	return true;
}
function RemoveArtifacts(imgId,spotThreshold,channel)
{
	roiManager("Deselect");
	run("Clear Results");
	run("Select None");
	
	selectImage(imgId);	
	Stack.setChannel(channel);
	run("Set Measurements...", "mean min display redirect=None decimal=3");
	run("Measure");
	meanIntensity = Table.get("Mean",0, "Results");
	run("Macro...", "code=if(v>" + spotThreshold + ")v=" + meanIntensity); //Notice: no spaces allowed in macro
	run("Clear Results");
}
/*
function RemoveArtifacts(imgId,spotThreshold)
{
	selectImage(imgId);	
	title = getTitle();
	
	maskWindow = "tempMaskWindow";
	roiManager("Deselect");
	run("Clear Results");

	maskImgId = dupChannel(imgId, 1, maskWindow);
	selectImage(maskImgId);	
	run("Set Measurements...", "mean min display redirect=None decimal=3");
	run("Measure");
	meanIntensity = Table.get("Mean",0, "Results");
	setThreshold(0,spotThreshold);
	setOption("BlackBackground", false);
	run("Convert to Mask");	
	run("Create Selection");
	run("Select None");
	run("Divide...", "value=255");

	run("Image Calculator...", "image1="+title+" operation=Multiply image2="+ maskWindow);	
	selectImage(maskImgId);
	run("HiLo");
	run("Macro...", "code=v=1-v");
	run("16-bit");
	run("Multiply...", meanIntensity);
	imageCalculator("Add", title, maskWindow);

	
	
	selectImage(maskImgId);
	close();
	run("Clear Results");
	waitForUser("mean: "+meanIntensity);
}
*/
function storeROIs(path,fileName)
{
	roiManager("Deselect");
	roiManager("Save", path +"/" + fileName+".zip");
}
function compositeAreas(imageId)
{
	selectImage(imageId);

	// set the B/C of CD35 and CD25 channels
	Stack.setChannel(CD35_CHANNEL);
	setMinAndMax(0, iCD35MaxPixelDisplayValue);
	Stack.setChannel(CD23_CHANNEL);
	setMinAndMax(0, iCD23MaxPixelDisplayValue);
	
	//make a composite image of the two channels
	channels = newArray(4);
	channels[CD35_CHANNEL-1] = 1;
	channels[CD23_CHANNEL-1] = 1;	
	Stack.setDisplayMode("composite");
	Stack.setActiveChannels(String.join(channels,""));

	
	run("Select None");
	roiManager("Show None");
	
	// show CD23, CD35 and GC on the composite image and flatten them on it
	rois = newArray(SelectRoiByName("GC"),SelectRoiByName("CD35"),SelectRoiByName("CD23"));
	colors = newArray(iGCColor,iCD35Color,iCD23Color);

	prevImgId = 0;
	for(i=0;i<rois.length;i++)
	{
		roiManager("Select", rois[i]);
		RoiManager.setGroup(0);
		RoiManager.setPosition(0);	
		roiManager("Set Color", colors[i]);
		roiManager("Set Line Width", iROILineWidth);
		prevImgId = imageId;
		run("Flatten");	
		imageId = getImageID();
		if(i > 0)
		{
			selectImage(prevImgId);
			close();
			selectImage(imageId);						
		}
	}
	saveAs("Jpeg", gImagesResultsSubFolder+"/"+"CD35nCD23."+"jpeg");
	return imageId;
}

function StroeTCellsInfo(CD35Area, CD23Area)
{
	GenerateLineHistogram(gTCellsBitmapImgId,"T Cells Count", false,true);
	tableName = "T Cells info";
	TCellsInCD35 = CountWhitePixelsInROI(gTCellsBitmapImgId, SelectRoiByName("CD35"));
	TCellsInCD23 = CountWhitePixelsInROI(gTCellsBitmapImgId, SelectRoiByName("CD23"));
	Table.create(tableName);
	Table.set("CD35 Count", 0,TCellsInCD35,tableName);
	Table.set("CD35 Density", 0,d2s(TCellsInCD35/CD35Area,5),tableName);
	Table.set("CD23 Count", 0,TCellsInCD23,tableName);
	Table.set("CD23 Density", 0,d2s(TCellsInCD23/CD23Area,5),tableName);
	Table.set("CD35 Basal Count", 0,(TCellsInCD35 - TCellsInCD23),tableName);
	Table.set("CD35 Basal Density", 0,d2s((TCellsInCD35 - TCellsInCD23)/(CD35Area- CD23Area),5),tableName);
  	Table.save(gImagesResultsSubFolder + "/"+tableName+".csv", tableName);
}

function GenerateLineHistogram(imageId,title, normalizeY, convertToMicrons)
{

	selectImage(imageId);
	SelectRoiByName("Line");
	run("Plot Profile");	
	saveAs("Jpeg", gImagesResultsSubFolder+"/"+title+"_LineHistogram.jpg");
	//now save as csv file as well
  	Plot.getValues(x, y);
  	if(convertToMicrons)
  	{
		for(i=0;i<x.length;i++)
			x[i] *= pixelWidth;
  	}
  	run("Close") ;
  	tableName = title+"_Histogram_values";
  	Array.show(tableName, x, y);
  	//Table.save(gResultsSubFolder+"/"+tableName+".csv", tableName);
  	Table.save(gImagesResultsSubFolder + "/"+tableName+".csv", tableName);
  	run("Close") ;
  	//save normalized table as well
  	normalizeXArray(x,iLineMargin);
  	if(normalizeY)
 		normealizeYArray(y,title);
   	//Table.save(gResultsSubFolder+"/"+tableName+".csv", tableName);
  	tableName = title+"_Histogram_values_normalized";
  	Array.show(tableName, x, y);
  	Table.save(gImagesResultsSubFolder + "/"+tableName+".csv", tableName);
	run("Close") ;
}


function CountWhitePixelsInROI(BitmapImgId,RoiId)
{
	selectImage(BitmapImgId);
	run("Set Measurements...", "area limit display redirect=None decimal=3");
	roiManager("Select", RoiId);
	setAutoThreshold("Default dark no-reset");
	setThreshold(1, 255);
	run("Measure");
	run("Clear Results");
	roiManager("Measure");
	count = Table.get("Area",0, "Results");
	return count;
}

function generateLineImageAndHistogram(imageId, maxPixelValue)
{
	selectImage(imageId);
	title = getTitle();
	run("Select None");
//	setMinAndMax(0, maxPixelValue);	
//	run("Flatten");
	tempId = getImageID();
	SelectRoiByName("Line");
//	run("Flatten");
	saveAs("Tiff", gImagesResultsSubFolder+"/"+title+"_Line.tif");
//	close();
//	selectImage(tempId);
//	close();
	GenerateLineHistogram(imageId, title, true,false);
//	selectImage(imageId);
//	SelectRoiByName("Line");

//	run("Plot Profile");	
//	saveAs("Jpeg", gImagesResultsSubFolder+"/"+title+"_LineHistogram.jpg");
	//now save as csv file as well
// 	Plot.getValues(x, y);
//  	run("Close") ;
//  	tableName = title+"_Histogram_values";
//  	Array.show(tableName, x, y);
  	//Table.save(gResultsSubFolder+"/"+tableName+".csv", tableName);
//  	Table.save(gImagesResultsSubFolder + "/"+tableName+".csv", tableName);
//  	run("Close") ;
  	//save normalized table as well
//  	normalizeXArray(x,iLineMargin);
// 	normealizeYArray(y,title);
   	//Table.save(gResultsSubFolder+"/"+tableName+".csv", tableName);
//  	tableName = title+"_Histogram_values_normalized";
// 	Array.show(tableName, x, y);
//  	Table.save(gImagesResultsSubFolder + "/"+tableName+".csv", tableName);
//	run("Close") ;
}
function normealizeYArray(y,title)
{
	max = y[0];
	for(i=1;i<y.length;i++)
	{
		if(y[i] > max)
			max = y[i];
	}
	print("Normalizing " + title + ": Dividing all values by ("+max+")/100");
	v = max/100;
	for(i=0;i<y.length;i++)
		y[i] /= v;
}
//input:
//1. x: array of increasing numbers
//2. margin: a number between 0 and 100 specifing the precentage of the numbers 
//        of the array at the begining and end that belong to the margins
//returns: the array x where the values are normalized betwin -margin and +margin
function normalizeXArray(x,margin)
{
	shift = x[0];
	Xmax = x[x.length-1];
	for(i=0;i<x.length;i++)
	{
		x[i] = (x[i]-shift)	* (2*margin + 100)/Xmax - margin;	
	}
}
//2.	Run stardist on dapi to create label image of all nuclei  WITH ROI 
//3.	Measure the mean intensity of each roi in T Cells image
//4.	Assign mean measure to each label
//5.	Remove labels with intensity lower than iTCellMinIntensity (3000) – WITH CLIJ
//6.	Filtter out very small or very big nuclei – WITH MorpholibJ / CLIJ 
//If something doesn’t work well – maybe you’ll need Remap labels from MorphoLibJ
//7.	reGenerate ROI for each remaining label
//8.	Show ROIs on top of T Cells channel and save to disk
//9.	Reduce each Label to a point and 
//  	Create a binary map of T cells points (0 or 255) for later use

function markTCells()
{
	StarDistWindowTitle = "Label Image";
	labeledImageFullPath = gImagesResultsSubFolder + "/" + StarDistWindowTitle +".tif";
	labeledImageRoisFullPath = gImagesResultsSubFolder + "/" + StarDistWindowTitle +"_RoiSet.zip";

	// 2. Run stardist on dapi to create label image of all nuclei  WITH ROI 

	if(iUseStoredLabeledImage && File.exists(labeledImageFullPath) && File.exists(labeledImageRoisFullPath))
	{
		open(labeledImageFullPath);
		rename(StarDistWindowTitle);
		openRois(labeledImageRoisFullPath);
		print("Using stored Dapi labeled image");
	}
	else 
	{
		print("Progress Report: Identifying " + gFileNameNoExt + "'s nuclei. That might take a few minutes");	
		selectImage(gDapiImgId);		
		run("Command From Macro", "command=[de.csbdresden.stardist.StarDist2D], args=['input':'Dapi', 'modelChoice':'Versatile (fluorescent nuclei)', 'normalizeInput':'true', 'percentileBottom':'1.0', 'percentileTop':'99.8', 'probThresh':'0.5', 'nmsThresh':'0.4', 'outputType':'Both', 'nTiles':'1', 'excludeBoundary':'2', 'roiPosition':'Automatic', 'verbose':'false', 'showCsbdeepProgress':'false', 'showProbAndDist':'false'], process=[false]");
		selectWindow(StarDistWindowTitle);
		saveAs("Tiff", labeledImageFullPath);
		rename(StarDistWindowTitle);
		roiManager("save", labeledImageRoisFullPath);
		print("Progress Report: Identifying nuclei ended.");	
	}
	//3.	Measure the mean intensity of each roi in T Cells image
	run("Set Measurements...", "mean integrated display redirect=None decimal=3");
	selectImage(gTCellsImgId);
	roiManager("Measure");
	//4.	Assign mean measure to each label
	selectWindow(StarDistWindowTitle);
	run("Assign Measure to Label", "results="+"Results"+" column="+"Mean"+" min="+0+" max="+7000);
	//5.	Remove labels with intensity lower than iTCellMinIntensity (3000) – WITH CLIJ
	removeLabelsInFeatureValueRange(StarDistWindowTitle,"Label-Mean",0,iTCellMinIntensity,"Filtered labels by Mean Intensity");
	//6.	Filtter out very small or very big nuclei – WITH MorpholibJ / CLIJ 
	lowerLimit = (iMinTCellSize) / (pixelWidth*pixelHeight);
	upperLimit = (iMaxTCellSize) / (pixelWidth*pixelHeight);
	run("Label Size Filtering", "operation=Lower_Than size="+upperLimit);
	run("Label Size Filtering", "operation=Greater_Than size="+lowerLimit);
	rename("Labeled T Cells");
	//7.	reGenerate ROI for each remaining label
	roiManager("Deselect");
	roiManager("Delete");
	run("Label image to ROIs");
	//8.	Show ROIs on top of T Cells channel and save to disk
	selectImage(gTCellsImgId);
	run("Enhance Contrast", "saturated=0.35");	
	FlattenRois(gTCellsImgId, "T Cells", "Yellow", 1, "Jpeg",false);
	storeROIs(gImagesResultsSubFolder, "T Cells RoiSet");
	roiManager("Delete");
	//9.	Reduce each Label to a point and 
	//  	Create a binary map of T cells points (0 or 255) for later use
	return reduceLabelsToPoint("Labeled T Cells","T Cells Binary map",true);
}
function openRois(fullPath)
{
	if(roiManager("count") > 0)
	{
		roiManager("deselect");
		roiManager("delete");
	}
	roiManager("Open", labeledImageRoisFullPath);	
}


function reduceLabelsToPoint(labeldImage,resultImageTitle,createBinaryMap)
{
	//run("CLIJ2 Macro Extensions", "cl_device=[Quadro P5000]");

	// reduce labels to centroids
	//image1 = "LabeldTCells.tif";
	Ext.CLIJ2_push(labeldImage);
	//image2 = "reduce_labels_to_centroids1949713628";
	Ext.CLIJ2_reduceLabelsToCentroids(labeldImage, resultImageTitle);
	Ext.CLIJ2_pull(resultImageTitle);
	if(createBinaryMap)
	{
		setAutoThreshold("Default dark no-reset");
		//run("Threshold...");
		setThreshold(1, 65535);
		setOption("BlackBackground", true);
		run("Convert to Mask");
		return getImageID();
	}
	return 0; // no image
}
function removeLabelsInFeatureValueRange(labelImage, featureValuesImage, minimum_value_range, maximum_value_range, resultImage)
{
//	run("CLIJ2 Macro Extensions", "cl_device=[Quadro P5000]");
//	
	// exclude labels with values out of range
	Ext.CLIJ2_push(featureValuesImage);
	Ext.CLIJ2_push(labelImage);
	Ext.CLIJ2_excludeLabelsWithValuesWithinRange(featureValuesImage, labelImage, resultImage, minimum_value_range, maximum_value_range);
	Ext.CLIJ2_pull(resultImage);
}
function drawAutoLine(hemiId, widthP, marginP)
{
	//Left or Right
	if(hemiId%2 == 0)
	{
		gLineWidth = 2*hVertical*widthP/pixelHeight;
		margin = 2*hHorizontal*marginP;
		if(hemiId == 2) // line right to left
			switch *= -1;
		//find start and end points
		fromX = (cX - switch*sinAngle*(hHorizontal+margin))/pixelWidth;
		fromY = (cY - switch*cosAngle*(hHorizontal+margin))/pixelHeight;
		toX = (cX + switch*sinAngle*(hHorizontal+margin))/pixelWidth;
		toY = (cY + switch*cosAngle*(hHorizontal+margin))/pixelHeight;
	}
	else // Top or bottom
	{
		gLineWidth = 2*hHorizontal*widthP/pixelWidth;
		margin = 2*hVertical*marginP;
		//updateDisplay();		
		if(hemiId == 3) // line Bottom to Top
			switch *= -1;
		//find start and end points
		fromX = (cX - switch*cosAngle*(hVertical+margin))/pixelWidth;
		fromY = (cY + switch*sinAngle*(hVertical+margin))/pixelHeight;
		toX = (cX + switch*cosAngle*(hVertical+margin))/pixelWidth;
		toY = (cY - switch*sinAngle*(hVertical+margin))/pixelHeight;
	}

	makeLine(fromX, fromY, toX, toY,gLineWidth);
	updateDisplay();
	roiManager("Add");
	selectLastROI();
	roiManager("Rename", "Line");

	
}
function drawUserLine(imageId, marginP)
{
	selectImage(imageId);
	roiManager("select", SelectRoiByName("Line"));
	waitForUser("If you want to change the Line:\n"+
			"Draw a new line from the side of the GC where CD23 is located to the other side using the 'Straight Line' icon.\n"+
			"Notice: Margins and width will be generated automaticaly.\n"+
			"Then, add the new line to the ROI manger (By pressing 't')\n"+
			"and rename it there to 'NewLine'.\n"+
			"Once done (even if you choose to do nothing), press the OK button");

	run("Set Measurements...", "centroid perimeter fit integrated display redirect=None decimal=3");
	run("Clear Results");
	if(SelectRoiByName("NewLine") != -1)
	{
		switch = 1;

		roiManager("measure");
		angle = Table.get("Angle",0, "Results");
		cX = Table.get("X",0, "Results");
		cY = Table.get("Y",0, "Results");
		hPerimeter = Table.get("Perim.",0, "Results")/2;
		
		margin = 2*hPerimeter*marginP;
		rAngle = toRadians(angle);
		cosAngle = Math.cos(rAngle);
		sinAngle = Math.sin(rAngle);
		
		fromX = (cX - switch*cosAngle*(hPerimeter+margin))/pixelWidth;
		fromY = (cY + switch*sinAngle*(hPerimeter+margin))/pixelHeight;
		toX = (cX + switch*cosAngle*(hPerimeter+margin))/pixelWidth;
		toY = (cY - switch*sinAngle*(hPerimeter+margin))/pixelHeight;
	
		makeLine(fromX, fromY, toX, toY, gLineWidth);
		roiManager("Add");
		SelectRoiByName("Line");
		roiManager("Rename", "AutoLine");
		selectLastROI();
		roiManager("Rename", "Line");
	}
}
function GenerateDarkRoi()
{
	SelectRoiByName("GC");
	run("Create Mask");
	rename("CD Mask");
	mask1 = getImageID();
	SelectRoiByName("CD35");
	run("Create Mask");
	rename("CD35 Mask");
	mask2 = getImageID();
	imageCalculator("subtract", mask1, mask2);
	run("Create Selection");	
	roiManager("Add");
	selectLastROI();
	roiManager("Rename", "Dark");
}
function drawLine(hemiId, widthP, marginP)
{
	//Left or Right
	if(hemiId%2 == 0)
	{
		lineWidth = 2*hVertical*widthP/pixelHeight;
		margin = 2*hHorizontal*marginP;
		if(hemiId == 2) // line right to left
			switch *= -1;
		//find start and end points
		fromX = (cX - switch*sinAngle*(hHorizontal+margin))/pixelWidth;
		fromY = (cY - switch*cosAngle*(hHorizontal+margin))/pixelHeight;
		toX = (cX + switch*sinAngle*(hHorizontal+margin))/pixelWidth;
		toY = (cY + switch*cosAngle*(hHorizontal+margin))/pixelHeight;
	}
	else // Top or bottom
	{
		lineWidth = 2*hHorizontal*widthP/pixelWidth;
		margin = 2*hVertical*marginP;
		//updateDisplay();		
		if(hemiId == 3) // line Bottom to Top
			switch *= -1;
		//find start and end points
		fromX = (cX - switch*cosAngle*(hVertical+margin))/pixelWidth;
		fromY = (cY + switch*sinAngle*(hVertical+margin))/pixelHeight;
		toX = (cX + switch*cosAngle*(hVertical+margin))/pixelWidth;
		toY = (cY - switch*sinAngle*(hVertical+margin))/pixelHeight;
	}

	makeLine(fromX, fromY, toX, toY,lineWidth);
	updateDisplay();
}
function FindGCOrientation()
{
	// intersect  CD35 ROI with each of the hemiSpheres to find orientation
	maxArea = 0;
	hemiID = -1;

	SelectRoiByName("CD35");
	run("Create Mask");
	rename("CD35 Mask");
	mask1 = getImageID();
	for(i=0;i<4;i++)
	{
		SelectRoiByName(gHemiNames[i]);
		run("Create Mask");	
		mask2 = getImageID();	
		rename(gHemiNames[i]+" Mask");
		imageCalculator("AND", mask2, mask1);
		run("Create Selection");	
		roiManager("Add");
		selectLastROI();
		roiManager("Rename", gHemiNames[i]+" Intersection");
		run("Clear Results");
		roiManager("Measure");
		roiManager("delete");
		hemiArea = Table.get("Area",0, "Results");
		if(hemiArea > maxArea)
		{
			maxArea = hemiArea;
			hemiID = i;
		}
		SelectRoiByName(gHemiNames[i]);
		roiManager("delete");
	}
//	print("hemiID = " + hemiID + ", area = " + maxArea);
	return hemiID;
}

function GenerateRoiWithinGC(imageId,minThreshold,ROIMinSize,roiName)
{
	nBefore = roiManager("Count");

	tempImageId = dupChannel(imageId,1,"temp_GenerateRoiWithinGC");
	SelectRoiByName("GC");
	run("Clear Outside");
	run("Manual Threshold...", "min="+minThreshold+" max=100000");
	run("Convert to Mask");
	run("Analyze Particles...", "size="+ROIMinSize+"-Infinity display exclude summarize add");
	nAfter = roiManager("Count");
	if (nBefore + 1 != nAfter)
	{
		print("ERROR: Could not identify a single " + roiName + " Region but " + (nAfter - nBefore) + 
			"\n\tConsider cahnging " + roiName + "'s min-intensity-threshold or its roi-min-size\nSelecting largest one");
		LeaveLargestRoi(nAfter - nBefore);
	}
	close();
	
	selectLastROI();
	roiManager("Rename", roiName);
	return GetRoiArea(roiManager("count")-1)
}
function GetRoiArea(roiIndex)
{
	roiManager("Select", roiIndex);
	run("Clear Results");
	run("Set Measurements...", "area integrated display redirect=None decimal=3");
	run("Measure");
	area = Table.get("Area",0, "Results");
	return area;	
}
function LeaveLargestRoi(numRois)
{
	// go over last ROIs and leave the one with largest area
	n = roiManager("count");
	maxIndex = n - 1;
	maxArea = GetRoiArea(maxIndex);
	for(i=1; i < numRois; i++)
	{
		area = GetRoiArea(n-1-i);
		if(area > maxArea)
		{
			maxArea = area;
			maxIndex = n - 1 - i;
		}
	}
	// now remove all rois but the one with max area
	for(i=n-1;i>maxIndex;i--)
	{
		roiManager("Select", i);
		roiManager("delete");
	}
	for(i=0;i<n-maxIndex;i++)
	{
		roiManager("Select", maxIndex-i-1);
		roiManager("delete");
	}
}
function generateSmoothImage(imageId, smoothType, parm1, parm2, duplicateImage)
{
	selectImage(imageId);
	if(duplicateImage)
	{		
		smoothImageId = dupChannel(imageId, 1, getTitle()+"_Smoothed");
	}
	else 
		smoothImageId = imageId;
	if(smoothType == GAUSSIAN_BLUR)
	{
		run("Gaussian Blur...", "sigma="+parm1);
	}
	else 
	{
		print("FATAL ERROR: Unknown smoothing operation");
	}
	return smoothImageId;
}
function dupChannel(imageId,channel,newTitle)
{
	selectImage(imageId);
	run("Select None");
	roiManager("deselect");
	run("Duplicate...", "title=["+newTitle+"] duplicate channels="+channel);
	return getImageID();
}

function SelectRoiByName(roiName) { 
	nR = roiManager("Count"); 
	roiIdx = newArray(nR); 
	 
	for (i=0; i<nR; i++) { 
		roiManager("Select", i); 
		rName = Roi.getName(); 
		if (matches(rName, roiName) ) { 
			roiManager("Select", i);	
			return i;
		} 
	} 
	print("Fatal Error: Roi " + roiName + " not found");
	return -1; 
} 
function selectLastROI()
{
	n = roiManager("count");
	roiManager("Select", n-1);
}
// GenerateFittingElipse
// generates an ellipse fitting to the GC and its 4 hemisphers (left, up, right, bottom)
function GenerateFittingElipse()
{
	run("Set Measurements...", gROIMeasurment + " redirect=None decimal=3");
	imageXBorders = newArray(0,width,0,width);
	imageYBorders = newArray(0,0,height,height);
	// generate "Ellipse" roi and measure it 
	SelectRoiByName("GC");
	run("Fit Ellipse");
	roiManager("Add");
	selectLastROI();
	roiManager("Rename", "Ellipse");
	run("Clear Results");
	roiManager("Measure");
	
	// given the ellipse dimensions generae the 4 hemisperes
	hemiNames = newArray("Left","Top","Right","Bottom");
	switch = 1;
	cX = Table.get("X",0, "Results");
	cY = Table.get("Y",0, "Results");
	hVertical = Table.get("Major",0, "Results")/2;
	hHorizontal = Table.get("Minor",0, "Results")/2;
	angle = Table.get("Angle",0, "Results");
	if (angle <= 45 || angle > 135)
	{
		temp = hVertical;
		hVertical = hHorizontal;
		hHorizontal = temp;
		if(angle <= 45)
			switch = -1;
		angle = 270 + angle;
	}
	//waitForUser(angle);
	rAngle = toRadians(angle);
	cosAngle = Math.cos(rAngle);
	sinAngle = Math.sin(rAngle);
	// handle "standing" ellipses
	//if (angle > 45 && angle <= 135)
	//{
		//GenerateROIFromPoints(hemiNames[(0+nameShift)%4],newArray(cX - cosAngle*hVertical, cX - sinAngle*hHorizontal, cX + cosAngle*hVertical), newArray(cY + sinAngle*hVertical, cY - cosAngle*hHorizontal, cY - sinAngle*hVertical));
		//GenerateROIFromPoints(hemiNames[(1+nameShift)%4],newArray(cX - sinAngle*hHorizontal, cX + cosAngle*hVertical, cX + sinAngle*hHorizontal), newArray(cY - cosAngle*hHorizontal, cY - sinAngle*hVertical, cY + cosAngle*hHorizontal));
		//GenerateROIFromPoints(hemiNames[(2+nameShift)%4],newArray(cX - cosAngle*hVertical, cX + sinAngle*hHorizontal, cX + cosAngle*hVertical), newArray(cY + sinAngle*hVertical, cY + cosAngle*hHorizontal, cY - sinAngle*hVertical));
		//GenerateROIFromPoints(hemiNames[(3+nameShift)%4],newArray(cX - sinAngle*hHorizontal, cX - cosAngle*hVertical, cX + sinAngle*hHorizontal), newArray(cY - cosAngle*hHorizontal, cY + sinAngle*hVertical, cY + cosAngle*hHorizontal));
		
		GenerateROIFromPoints(hemiNames[0],newArray((cX - switch*cosAngle*hVertical)/pixelWidth, imageXBorders[2], imageXBorders[0], (cX + switch*cosAngle*hVertical)/pixelWidth), newArray((cY + switch*sinAngle*hVertical)/pixelHeight, imageYBorders[2], imageYBorders[0], (cY - switch*sinAngle*hVertical)/pixelHeight));
		GenerateROIFromPoints(hemiNames[1],newArray((cX - switch*sinAngle*hHorizontal)/pixelWidth, imageXBorders[0], imageXBorders[1],(cX + switch*sinAngle*hHorizontal)/pixelWidth), newArray((cY - switch*cosAngle*hHorizontal)/pixelHeight, imageYBorders[0], imageYBorders[1], (cY + switch*cosAngle*hHorizontal)/pixelHeight));
		GenerateROIFromPoints(hemiNames[2],newArray((cX + switch*cosAngle*hVertical)/pixelWidth, imageXBorders[1], imageXBorders[3], (cX - switch*cosAngle*hVertical)/pixelWidth), newArray((cY - switch*sinAngle*hVertical)/pixelHeight, imageYBorders[1], imageYBorders[3], (cY + switch*sinAngle*hVertical)/pixelHeight));
		GenerateROIFromPoints(hemiNames[3],newArray((cX - switch*sinAngle*hHorizontal)/pixelWidth, imageXBorders[2], imageXBorders[3], (cX + switch*sinAngle*hHorizontal)/pixelWidth), newArray((cY - switch*cosAngle*hHorizontal)/pixelHeight, imageYBorders[2], imageYBorders[3], (cY + switch*cosAngle*hHorizontal)/pixelHeight));
	//}
}
function GenerateROIFromPoints(name, xPoints, yPoints)
{
	makeSelection("polygon", xPoints, yPoints);	
	roiManager("Add");
	n = roiManager("count");
	roiManager("Select", n-1);
	roiManager("Rename", name);
}


function toRadians(angle)
{
	return angle*PI/180;
}


function AddGC_roi()
{
	roiPath = File.getDirectory(gFileFullPath)+gFileNameNoExt+gRoisSuffix;
	if(!openROIsFile(roiPath))
	{
		print("Fatal Error: could not find ROI file " + roiPath + ".roi");
		return false;
	}
	// rename ROI to GC
	selectLastROI();
	roiManager("Rename", "GC");
	return true;
}

/*function ProcessFile(directory) 

	axonCh1 = 2;
	axonCh2 = 3;
	if(!openFile(gFileFullPath))
		return false;	
	setBatchMode(gBatchModeFlag);	
	//run("Brightness/Contrast...");
	run("Enhance Contrast", "saturated=0.35");			
	originalWindow = getTitle();
	gFileNameNoExt = File.getNameWithoutExtension(gFileFullPath);
	gImagesResultsSubFolder = gResultsSubFolder + "/" + gFileNameNoExt;
	File.makeDirectory(gImagesResultsSubFolder);
	run("Select None");
	run("Duplicate...", "title="+gAxonCh1Name+" duplicate channels="+axonCh1);
	run("Enhance Contrast", "saturated=0.35");		
	selectWindow(originalWindow);
	run("Duplicate...", "title="+gAxonCh2Name+" duplicate channels="+axonCh2);
	run("Enhance Contrast", "saturated=0.35");	
	

	
	axonCh1DansityMapTitle = CreateSegmentationAndDensityMap(gAxonCh1Name, iMinThresholdCh1, iMinAxonCh1);
	axonCh2DansityMapTitle = CreateSegmentationAndDensityMap(gAxonCh2Name, iMinThresholdCh2, iMinAxonCh2);
	if(openROIsFile(File.getDirectory(gFileFullPath)+gFileNameNoExt+gRoisSuffix))
	{
		windows = newArray(axonCh1DansityMapTitle,axonCh2DansityMapTitle); 
		GenerateCompositeResultTable(windows, originalWindow);
	}
	else
		print(File.getDirectory(gFileFullPath)+gFileNameNoExt+" has no ROIs");
	return true;
}*/

//GenerateCompositeResultTable:
// 1. for each window in a given list of windows (channels) it:
// 1.1 rum measurements on all rois
// 1.2 for each roi in the list of rois
// 1.2.1 for each meaasurment taken
// 1.2.1.1 it adds it to a single row per roi in a single table for all channels
// 1.2.1.2 if the macro runs on all files in a directory it will also add these row to a comulative table 
/*function GenerateCompositeResultTable(windows, originalWindow)
{	
	selectImage(originalWindow);
	run("Duplicate...", "duplicate channels=1");
	FlattenRois(getTitle(),gFileNameNoExt, "Yellow",10,"Jpeg", true);
	
	Table.create("Results");	
	selectImage(windows[0]);
	roiManager("Deselect");
	roiManager("Measure");
	selectWindow("Results");

	columns_names = split(Table.headings,"\t");
	Table.create(gCompositeTable);
	for(w=0;w<lengthOf(windows);w++)
	{	
		roiManager("Associate", "true");
		roiManager("Centered", "false");
		roiManager("UseNames", "true");
		FlattenRois(windows[w],File.getNameWithoutExtension(windows[w]), "Yellow",10,"Jpeg",true);	
		Table.create("Results");	
		selectImage(windows[w]);
		roiManager("Measure");
		for(r=0;r<nResults;r++)
		{
			for(c=1;c<lengthOf(columns_names);c++)
			{
				column_name = columns_names[c]+"_"+w;
				value = Table.getString(columns_names[c],r, "Results");
				Table.set(column_name,r,value,gCompositeTable);
				if(!matches(iProcessMode, "singleFile"))
					Table.set(column_name,gAllCompositeResults+r,value,gAllCompositeTable);
			}
		}	
		roiManager("Deselect");
	}
	gAllCompositeResults += nResults;
	fullPath = gResultsSubFolder+"/"+gFileNameNoExt+".csv";
	Table.save(fullPath,gCompositeTable);
}*/
//FlattenRois:
//to a given image it flattens all rois onto it and stroes it as Jpeg
function FlattenRois(imageId, name, color, width, extention,withLabels)
{
	selectImage(imageId);
	
	//RoiManager.setPosition(3);
	roiManager("Deselect");
	roiManager("Set Color", color);
	roiManager("Set Line Width", width);
	//n = roiManager("count");
	//arr = Array.getSequence(n);
	//roiManager("select", arr);
	//Roi.setFontSize(5)
	if(withLabels)
		roiManager("Show All with labels");
	else 
		roiManager("Show All without labels");
	//	Overlay.setLabelFontSize(5, 'sacle')
	run("Flatten");
	saveAs(extention, gImagesResultsSubFolder+"/"+name+"_rois."+extention);
}

// CreateSegmentationAndDensityMap:
// 1. on a given channel, run Tubeness filter + Threshold to generate Mask
// 2. run mean intensisty on the result to get density map
// 3. store it to disk 
// 4. stroe to disk the original channel with the threshold mask
function CreateSegmentationAndDensityMap(window, minThreshold, minAxonSize)
{
	selectWindow(window);
	getPixelSize(unit,pixelWidth, pixelHeight);
	pixelDensityRadius = Math.round((iDensityRadius)/pixelWidth);
	//print("pixelDensityRadius: " + pixelDensityRadius);
	run("Tubeness", "sigma="+iTubenessSigma+" use");
	setThreshold(minThreshold, 1000000000000000000000000000000.0000);
	setOption("BlackBackground", false);
	run("Analyze Particles...", "size="+minAxonSize+"-Infinity show=Masks exclude");
	run("Convert to Mask");	
	run("Create Selection");
	run("Select None");
	
	run("Divide...", "value=2.55");
	//run("Brightness/Contrast...");
	//setMinAndMax(0, iMaxDensity);

	run("Mean...", "radius="+pixelDensityRadius);
	run("Fire");
	setMinAndMax(0, iMaxDensity);	
	run("Calibration Bar...", "location=[Upper Right] fill=White label=Black number=5 decimal=0 font=12 zoom="+iZoomLevel+" overlay");
	dansityMapTitle = gFileNameNoExt + "_" + window + "_DensityMap_R"+pixelDensityRadius;
	rename(dansityMapTitle);
	//saveAs("Tiff", gImagesResultsSubFolder+"/"+title+".tif");
	saveAs("Tiff", gImagesResultsSubFolder+"/"+window+".tif");
	dansityMapTitle = getTitle();
	
	selectWindow(window);
	run("Grays");
	run("Restore Selection");
	//saveAs("Tiff", gImagesResultsSubFolder+"/"+gFileNameNoExt + "_"+window+"_Segmentation_T"+iMinThreshold+".tif");
	saveAs("Tiff", gImagesResultsSubFolder+"/"+window+"_Segmentation_T"+minThreshold+".tif");
	return dansityMapTitle;
}

function FinalActions()
{
//	if(gAllCompositeResults > 0) // stroe allCompositeTable table
//		Table.save(gResultsSubFolder+"/"+gAllCompositeTable+".csv", gAllCompositeTable);
}
// end of single file analysis

//--------Helper functions-------------

function Initialization()
{
	requires("1.53c");
	run("Check Required Update Sites");
	// for CLIJ
	run("CLIJ2 Macro Extensions", "cl_device=");
	Ext.CLIJ2_clear();
	
	setBatchMode(false);
	run("Close All");
	close("\\Others");
	print("\\Clear");
	run("Options...", "iterations=1 count=1 black");
	roiManager("Reset");

	CloseTable("Results");
	//CloseTable(gCompositeTable);	
	//CloseTable(gAllCompositeTable);

	run("Collect Garbage");

	if (gBatchModeFlag)
	{
		print("Working in Batch Mode, processing without opening images");
		setBatchMode(gBatchModeFlag);
	}	

}

function checkInput()
{
	getDimensions (ImageWidth, ImageHeight, ImageChannels, ImageSlices, ImageFrames);

	if(ImageChannels != 4)
	{
		print("Fatal error: input file must include 4 channels: Dapi, CD23, T-Cells and CD35");
		return false;
	}
	getPixelSize(unit,pixelWidth, pixelHeight);
	if(!matches(unit, "microns") && !matches(unit, "um"))
	{
		print("Fatal error. File " + gFileFullPath + " units are "+ unit+ " and not microns");
		return false;
	}
	return true;
}
//------openROIsFile----------
//open ROI file with 
function openROIsFile(ROIsFileNameNoExt)
{
	// first delete all ROIs from ROI manager
	roiManager("deselect");
	if(roiManager("count") > 0)
		roiManager("delete");

	// ROIs are stored in "roi" suffix in case of a single roi and in "zip" suffix in case of multiple ROIs
	RoiFileName = ROIsFileNameNoExt+".roi";
	ZipRoiFileName = ROIsFileNameNoExt+".zip";
	if (File.exists(RoiFileName) && File.exists(ZipRoiFileName))
	{
		if(File.dateLastModified(RoiFileName) > File.dateLastModified(ZipRoiFileName))
			roiManager("Open", RoiFileName);
		else
			roiManager("Open", ZipRoiFileName);
		return true;
	}
	if (File.exists(RoiFileName))
	{
		roiManager("Open", RoiFileName);
		return true;
	}
	if (File.exists(ZipRoiFileName))
	{
		roiManager("Open", ZipRoiFileName);
		return true;
	}
	return false;
}

function openFile(fileName)
{
	// ===== Open File ========================
	// later on, replace with a stack and do here Z-Project, change the message above
	if ( endsWith(gFileFullPath, "h5") )
		run("Import HDF5", "select=["+gFileFullPath+"] "+ gH5OpenParms);
	if ( endsWith(gFileFullPath, "ims") )
		run("Bio-Formats Importer", "open=["+gFileFullPath+"] "+ gImsOpenParms);
	else
		open(gFileFullPath);
	

	return checkInput();
	
}


//----------LoopFiles-------------
// according to iProcessMode analyzes a single file, or loops over a directory or sub-directories
function LoopFiles()
{
	if (matches(iProcessMode, "wholeFolder") || matches(iProcessMode, "singleFile")) {
		print("directory: "+ gMainDirectory);
		gResultsSubFolder = gMainDirectory + File.separator + "Results" + File.separator; 
		File.makeDirectory(gResultsSubFolder);
		
		if (matches(iProcessMode, "singleFile")) {
			return ProcessFile(gMainDirectory); 
		}
		else if (matches(iProcessMode, "wholeFolder")) {
			return ProcessFiles(gMainDirectory); 
		}
	}
	
	else if (matches(iProcessMode, "AllSubFolders")) {
		list = getFileList(gMainDirectory);
		for (i = 0; i < list.length; i++) {
			if(File.isDirectory(gMainDirectory + list[i])) {
				gSubFolderName = list[i];
				gSubFolderName = substring(gSubFolderName, 0,lengthOf(gSubFolderName)-1);
	
				//directory = gMainDirectory + list[i];
				directory = gMainDirectory + gSubFolderName + File.separator;
				gResultsSubFolder = directory + File.separator + "Results" + File.separator; 
				File.makeDirectory(gResultsSubFolder);
				//resFolder = directory + gResultsSubFolder + File.separator; 
				//print(gMainDirectory, directory, resFolder);
				//File.makeDirectory(resFolder);
				print("inDir=",directory," outDir=",gResultsSubFolder);
				if(!ProcessFiles(directory))
					return false;
				print("Processing ",gSubFolderName, " Done");
			}
		}
	}
	return true;
}
//===============================================================================================================
// Loop on all files in the folder and Run analysis on each of them
function ProcessFiles(directory) 
{
	Table.create(gAllCompositeTable);		
	gAllCompositeResults = 0;

	setBatchMode(gBatchModeFlag);
	dir1=substring(directory, 0,lengthOf(directory)-1);
	idx=lastIndexOf(dir1,File.separator);
	subdir=substring(dir1, idx+1,lengthOf(dir1));

	// Get the files in the folder 
	fileListArray = getFileList(directory);
	
	// Loop over files
	for (fileIndex = 0; fileIndex < lengthOf(fileListArray); fileIndex++) {
		if (endsWith(fileListArray[fileIndex], iFileExtension) ) {
			gFileFullPath = directory+File.separator+fileListArray[fileIndex];
			print("\nProcessing:",fileListArray[fileIndex]);
			showProgress(fileIndex/lengthOf(fileListArray));
			if(!ProcessFile(directory))
				return false;
		} // end of if 
	} // end of for loop
	FinalActions();
	CleanUp(false);
	return true;
} // end of ProcessFiles

function CleanUp(finalCleanUp)
{
	run("Close All");
	close("\\Others");
	run("Collect Garbage");
	if (finalCleanUp) 
	{
//		CloseTable(gAllCompositeTable);	
		setBatchMode(false);
	}
}
function SetProcessMode()
{
		// Choose image file or folder
	if (matches(iProcessMode, "singleFile")) {
		gFileFullPath=File.openDialog("Please select an image file to analyze");
		gMainDirectory = File.getParent(gFileFullPath);
	}
	else if (matches(iProcessMode, "wholeFolder")) {
		gMainDirectory = getDirectory("Please select a folder of images to analyze"); }
	
	else if (matches(iProcessMode, "AllSubFolders")) {
		gMainDirectory = getDirectory("Please select a Parent Folder of subfolders to analyze"); }
}

//===============================================================================================================
function CloseTable(TableName)
{
	if (isOpen(TableName))
	{
		selectWindow(TableName);
		run("Close");
	}
}
