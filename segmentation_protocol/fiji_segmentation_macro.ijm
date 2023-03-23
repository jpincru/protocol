
/*
 * SCRIPT PARA SEGMENTAR CROMOSOMAS
 * Macro template to process multiple images in a folder
 */

#@ File (label = "Input directory", style = "directory") input
#@ File (label = "Output directory", style = "directory") output
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
			processFile(input, output, list[i]);
	}
}

function processFile(input, output, file) {
close("*");
print("Processing: " + input + File.separator + file);
open(file);
title = getTitle();
path = "C:/Users/admin/Desktop/Proyectos/script_segmentacion_2023/script_segmentacion_2023/";
minSize = 12.5;
//minSize = getNumber("Enter size area filter in microns", 12.5);
//minSize = getNumber("Enter size area filter in pixels", 5000);
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
//variable for changing area of particles ( meter dialog por si estamos midiendo SPB's en vez de cromosomas)
//minSize = getNumber("Enter size area filter in pixels", 5000);
run("Analyze Particles...", "size=" + minSize + "-Infinity exclude clear add");
roiManager("Show All");
roiManager("Show All with labels");
roiNumber = roiManager("count");
print("Nº de Rois =" + " " + roiNumber);

if (roiNumber < 1){
	print("No particles detected");
	
	}


outputfolder3 = path +"/Rois/";
filename = "RoiSet";

roiManager("Save", outputfolder3 + filename + ".zip");


//bucle for para varios ROI
for (m = 0; m < roiManager("count"); m++){
roiManager("Reset");
open(path + "/Rois/RoiSet.zip");
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
run("Median...", "radius=2 stack");
run("Mean...", "radius=3 stack");
run("Duplicate...", "duplicate");

/* test
 * setAutoThreshold("Otsu dark");
setAutoThreshold("Otsu dark stack");
run("Convert to Mask", "method=Otsu background=Dark black");
 */

//run("Threshold...");
setAutoThreshold("MaxEntropy dark");
//run("Threshold...");
setOption("BlackBackground", true);
run("Convert to Mask", "method=MaxEntropy background=Dark calculate black");
//poner ruta con variable

P_Image = path + "temptif.tif";
saveAs(".tif", P_Image);

}

else {
open(P_Image);
}

//roiManager("Select", m);
roimask_output = path + "RoiMasks/" +"/RoiMask_" + m + "_" + title.replace("(Z_projection_)","");
saveAs(".tiff", roimask_output);
print("Roi image generated in" + path +"/RoiMask_"+ title.replace("(Z_projection_)","") + m);
size_particle = 2;    //PARTICULAS MENORES DE ESTE TAMAÑO SE VAN A QUITAR
//size_particle = getNumber("Enter size area filter in pixels", 2);
run("Analyze Particles...", "size="+ size_particle +"-Infinity exclude clear add stack");
//run("Analyze Particles...", "size="+ size_particle +"-Infinity clear add stack"); //No excluimos las celulas de borde
//prueba sacar tabla ROI
roiManager("Save", outputfolder3 + "Roi_table_" + i+1 + ".zip");
//run("Set Measurements...", "area centroid center perimeter fit shape feret's area_fraction stack redirect=None decimal=4");
run("Set Measurements...", "area centroid center perimeter fit shape stack display redirect=None decimal=4");
run("Input/Output...", "jpeg=85 gif=-1 file=.csv use_file save_column save_row");
roiManager("Measure");
//cambiar rutas 

ruta_output = path + "CSV/" + "/Results_"+ title.replace("(Z_projection_)","") +"_" + m + ".csv";

saveAs("results", ruta_output);
print("Results saved in"+ ruta_output);
close("\\Others");
// END

print("Particle nº" + " " + m + " " + "analized.");
}
}
//close("*");
//close("Roi Manager");
//close("Results");
print("COMPLETED");
print("");

}

