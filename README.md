# SettleCalciumFlux
A repository for the code used to analyze Fura-2 tracing data from the Huse Lab Nikon Microscope

Requires MATLAB 2022b. Add the contents of Dependencies to your MATLAB path before beginning.

The primary script is CalciumFluxTracing_v1.m, to analyze data:
1. Place .tif files to be analyzed in a directory of your choice. Add that directory to the MATLAB path. This code was written to analyze tif files exported through Nikon Elements, with three channels: Channel1 = Fura 340 excitation channel, Channel2 = Fura 380 excitation channel, Channel3 = Brightfield.
2. Run each step in CalciumFluxTracing in sequence. For each .tif file analyzed, this will generate a .csv and a .png.
   - The CSV file contains columns indiciating 340/380 ratios over time as individual cell traces. Each column represents one cell and each row represents one frame in the timelapse
   - The .png is a QC check that plots the first 50 traces over time, for manual inspectino to see if the code has run properly. See examples of these in the folders contained.
