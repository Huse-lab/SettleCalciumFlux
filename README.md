# SettleCalciumFlux
Published 9/4/2024

A repository for the code used to analyze Fura-2 tracing data from the Huse Lab Nikon Microscope, Memorial Sloan Kettering Cancer Center, Zuckerman Research Center

Requires MATLAB 2022b. Add the contents of Dependencies to your MATLAB path before beginning.

Note that this is not a well-tested software package, rather it is a code resource that can be used as a scaffold to analyze similar data sets. Adjustments to the data loading and organization steps may be required to work for your specific analysis needs.

The primary script is CalciumFluxTracing_v1.m, to analyze data:
1. Place .tif files to be analyzed in a directory of your choice. Add that directory to the MATLAB path. This code was written to analyze tif files exported through Nikon Elements, with three channels: Channel1 = Fura 340 excitation channel, Channel2 = Fura 380 excitation channel, Channel3 = Brightfield.
2. Run each step in CalciumFluxTracing in sequence. For each .tif file analyzed, this will generate a .csv and a .png.
   - The CSV file contains columns indiciating 340/380 ratios over time as individual cell traces. Each column represents one cell and each row represents one frame in the timelapse
   - The .png is a QC check that plots the first 50 traces over time, for manual inspectino to see if the code has run properly. See examples of these in the folders contained.


## Summary of Method
1. Read tif files into memory and organize them according to the channel identiy and time.
2. Process each frame independently to identify each cell's location and attributions
   - uses built-in matlab functions imbinarize, bwdist and watershed to segment cells
   - uses built-in matlab function bwlabel and regionprops to gather the size and location of each cell in each frame
   - Compute a background fluoresence for each channel
   - Using each individual cell mask, obtain the mean fluoresence intensity (subtracting the background) of the 340 and 380 channel for each cell and calculate the ratio
4. Use simpletracker.m (https://www.mathworks.com/matlabcentral/fileexchange/34040-simpletracker) trace individual cells overtime through each frame.
5. Reorganize the data to generate individual tracks of 340/380 ratio values over time for each cell.
   - Remove any discontinous tracks or tracks shorter than 60% of the timelapse length
7. Output these as a csv and plot the first 50 traces overtime, export as a png
