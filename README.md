# Germinal center (GC) Analysis
We use Fiji to identify distinct regions within the  Germinal center (GC) using follicular dendritic cell (FDC) markers: CD23 and CD35.
## Overview
Given an image with four channels, CD23, CD35, Dapi and T cells staining, and an ROI file marking the borders of the entire GC within the image, the macro does the followin:
1. identifies distinct regions within the GC  
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
