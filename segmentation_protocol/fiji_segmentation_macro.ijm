//Segmentation and CSV data extraction macro

#@ File (label = "Input directory", style = "directory") input
//#@ File (label = "Output directory", style = "directory") output
#@ String (label = "File suffix", value = ".tif") suffix

processFolder(input);

// function to scan folders/subfolders/files to find files with correct suffix
function processFolder(input) {
	list = getFileList(input);
	list = Array.sort(list);
	for (i = 0; i < list.length; i++) {
		if(File.isDirectory(input + File.separator + list[i]))
			processFolder(input + File.separator + list[i]);
		if(endsWith(list[i], suffix))
			processFile(input, list[i]);
	}
}

function processFile(input, file) {
	// closing of active images to prevent errors
	close("*");
	//optional log output 
	//print("Processing: " + input + File.separator + file);
	open(file);
	title = getTitle();
	
	//pathing format change to prevent errors
	path = replace(input,"\\","/");
	path = path.replace("Z_Projections/batchmacro","");
	
	//Setting of area size detected by the "Analize particles" command
	size_value = 12.5;
	
	//Optional code asking for user input to select desired area size:
	//size_value = getNumber("Enter size area filter in microns", 12.5);
	//size_value = getNumber("Enter size area filter in pixels", 5000);
	
	selectWindow(title);
	run("Median...", "radius=2 stack");
	run("Mean...", "radius=2 stack");
	run("Z Project...", "projection=[Max Intensity]");
	run("Enhance Contrast", "saturated=0.35");
	//testing LUT, change if no particles detected and check source image
	run("Apply LUT");
	setAutoThreshold("Otsu dark");
	//run("Threshold...");
	run("Convert to Mask");
	run("Morphological Filters", "operation=Erosion element=Disk radius=4");
	run("Morphological Filters", "operation=Closing element=Disk radius=6");
	
	mask_output = path +"/Mask/Mask_" + title.replace("(Z_projection_)","");
	saveAs(".tif", mask_output);
	
	print("Image .tiff generated in " + mask_output);
	//variable for changing area of particles 
	//size_value = getNumber("Enter size area filter in pixels", 5000);
	run("Analyze Particles...", "size=" + size_value + "-Infinity exclude clear add");
	roiManager("Show All");
	roiManager("Show All with labels");
	roiNumber = roiManager("count");
	print("Nº de ROIs =" + " " + roiNumber);
	
	if (roiNumber < 1){
		print("No particles detected");
		}
		
	outputfolder3 = path +"/ROIS/";
	filename = "ROISet";
	
	roiManager("Save", outputfolder3 + filename + ".zip");
		
	//"for" loop for multiple ROI
	for (m = 0; m < roiManager("count"); m++){
		roiManager("Reset");
		open(path + "/ROIS/ROISet.zip");
		if(m < roiManager("count")){
			roiManager("Select", m);
			run("Enlarge...", "enlarge=40 pixel");
			roiManager("Update");
			roiManager("Deselect");
			close("\\Others");
		
		
		if(m == 0){
			open(file);
			roiManager("Select", m);
			run("Clear Outside", "stack");
			run("Duplicate...", "duplicate");
			//run("Subtract Background...", "rolling=80 stack");
			run("Median...", "radius=1 stack");
			run("Mean...", "radius=2 stack");
			run("Duplicate...", "duplicate");
		
		
			//run("Threshold...");
			setAutoThreshold("MaxEntropy dark");
			//run("Threshold...");
			setOption("BlackBackground", true);
			run("Convert to Mask", "method=MaxEntropy background=Dark calculate black");
			
			
			P_Image = path + "temptif.tif";
			saveAs(".tif", P_Image);
	
		}
	
		else {
			open(P_Image);
		}
	
		//roiManager("Select", m);
		roimask_output = path + "ROIMasks/" +"/ROIMask_" + m + "_" + title.replace("(Z_projection_)","");
		saveAs(".tiff", roimask_output);
		print("ROI image generated in" + path +"/ROIMask_"+ title.replace("(Z_projection_)","") + m);
		size_particle = 2;    //particles with less than this size will not be selected
		//size_particle = getNumber("Enter size area filter in microns", 2);
		run("Analyze Particles...", "size="+ size_particle +"-Infinity exclude clear add stack");
		//run("Analyze Particles...", "size="+ size_particle +"-Infinity clear add stack"); //No excluimos las celulas de borde
		
		roiManager("Save", outputfolder3 + "ROI_table_" + i+1 + ".zip");
		//run("Set Measurements...", "area centroid center perimeter fit shape feret's area_fraction stack redirect=None decimal=4");
		run("Set Measurements...", "area centroid center perimeter fit shape stack display redirect=None decimal=4");
		run("Input/Output...", "jpeg=85 gif=-1 file=.csv use_file save_column save_row");
		roiManager("Measure");
		
		
		ruta_output = path + "CSV/" + "/Results_"+ title.replace("(Z_projection_)","") +"_" + m + ".csv";
		
		saveAs("results", ruta_output);
		print("Results saved in "+ ruta_output);
		close("\\Others");
	
		// END
	
		print("Particle nº" + " " + m + " " + "analized.");
		}
	}
		//Optional code for closing images and tables after analysis
		//close("*");
		//close("ROI Manager");
		//close("Results");
		print("COMPLETED");
		print("");

}

