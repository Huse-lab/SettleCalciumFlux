% Analysis script for reading live imaging data of Fura-2 stained cells and
% generating individual traces
% To run, add the following folders to path (included in this package):
% bfmatlab, munkres, simpletracker

%% Select Folder of interest
fprintf('Please select folder of interest containing tif files \n')
file_path = uigetdir('Select Folder of interest');
file_list = dir(file_path);

%% Loop through files in the folder

for m = 1:length(file_list)
    file = file_list(m);
    if ~contains(file.name,'.tif')
        continue
    end
    filename = file.name;
    filename
    
    data = bfopen(filename);
    metadata = data{1,4};
    
    data_table = organizeUnlabeledTIF(data);
    
    channel1_array = data_table{data_table.Channel == 1,1};
    channel2_array = data_table{data_table.Channel == 2,1};
    channel3_array = data_table{data_table.Channel == 3,1};
    
    % Process each frame of the movie, identify cells
    frameStruct = struct('Frame',[],'objectStats',{},'imageStats',{});
    disp('Processing Frames')
    parfor i = 1:length(channel3_array)
        BW = imbinarize(channel3_array{i});
        D = bwdist(~BW);
        WS = watershed(-D);
        labeledImage = double(WS).*double(BW);
        
        %filter out small stuff
        regionStats = regionprops(labeledImage);
        delete_list = [];
        for j = 1:length(regionStats)
            regionStats(j).ID = j;
            regionStats(j).Frame = i;
            if regionStats(j).Area < 50
                labeledImage(labeledImage==j) = 0;
                delete_list = [delete_list, j];
            end
        end
        regionStats(delete_list) = [];


        %get 340/380 intensity data
        for j = 1:length(regionStats)
            regionStats(j).int_340 = mean(channel2_array{i}(labeledImage==regionStats(j).ID));
            regionStats(j).int_380 = mean(channel3_array{i}(labeledImage==regionStats(j).ID));
        end
        
        %calculate background fluorescences for each frame
        background340 = prctile(channel2_array{i}(:),5);
        background380 = prctile(channel3_array{i}(:),5);
        imageStats = struct('Background_340',background340,'Background_380',background380);
    
        frameStruct(i).Frame = i;
        frameStruct(i).objectStats = regionStats;
        frameStruct(i).imageStats = imageStats;
    end
    
    %Use simpletracker to trace cells over time 
    disp('Tracing...')
    pointscellArray = {};
    for i = 1:length(frameStruct)
        
        currentObjectStats = frameStruct(i).objectStats;
        numObjectsCurrent = length(currentObjectStats);
        currentX = reshape([currentObjectStats.Centroid],2,[])';
        pointscellArray = [pointscellArray currentX];
    end
    
    [tracks, adjacency, A] = simpletracker(pointscellArray,'MaxLinkingDistance',20);
    delete_list = [];
    for i = 1:length(tracks)
        if sum(isnan(tracks{i})) > 0.60*length(tracks{i})
            delete_list = [delete_list i];
        end
    end
    
    tracks(delete_list) = [];
    
    % convert tracks to structured array for each cell with fluorescence
    % data
    f = fieldnames(frameStruct(1).objectStats)';
    f{2,1} = {};
    
    traceStats = {};
    
    for i = 1:length(tracks)
        cellTracker = struct(f{:});
        for j = 1:length(tracks{i})
            if ~isnan(tracks{i}(j))
                cellTracker(j) = frameStruct(j).objectStats(tracks{i}(j));
            end
        end
        traceStats = [traceStats;cellTracker];
    end
    
    
    
    
    
    % Do some additional computations on traceStats
    disp('Calculating Ratios')
    for i = 1:length(traceStats)
        for j = 1:length(traceStats{i})
            currentCell = traceStats{i}(j);
            if ~isempty(currentCell.Frame)
                backgroundcorrected340 = currentCell.int_340 - ...
                    frameStruct(currentCell.Frame).imageStats.Background_340;
                backgroundcorrected380 = currentCell.int_380 - ...
                    frameStruct(currentCell.Frame).imageStats.Background_380;
                traceStats{i}(j).int_340_corr = backgroundcorrected340;
                traceStats{i}(j).int_380_corr = backgroundcorrected380;
                traceStats{i}(j).Ratio340380 = double(backgroundcorrected340) / ...
                    double(backgroundcorrected380);
            end
        end
    
    end
    disp('Plotting and saving CSVs')
    %testPlots
    figure('Position',[476 124 967 742],'Units','pixels')
    maxplot = min([49 length(traceStats)]);
    for i = 1:maxplot
    subplot(7,7,i)
    plot([traceStats{i}.Ratio340380])
    xlim([0 60])
    ylim([0.1 0.7])
    end
    plotname = strrep(filename,'.tif','_testplots.png');
    saveas(gcf,plotname);
    close all
    
    
    % Make tables based on traceStats
    ratios = zeros(length(frameStruct),length(traceStats));
    for i = 1:length(traceStats)
        ratioTrace = [traceStats{i}.Ratio340380];
        ratios(1:length(ratioTrace),i) = ratioTrace;
    end
    
    csvname = strrep(filename,'.tif','_RatioTraces.csv');
    writematrix(ratios,csvname)
end
    
%% functions

function data_table = organizeUnlabeledTIF(data)
stack_size = size(data{1},1);

sz = [stack_size,4];
varTypes = ["cell","double","double","double"];
varNames = ["Image","Time","Channel","Z"];
data_table = table('Size',sz,'VariableTypes',varTypes,'VariableNames',varNames);

for k = 1:stack_size
    %image
    data_table(k,1) = data{1}(k,1);
    data_table(k,2) = {ceil(k/3)};
    data_table(k,3) = {mod(k-1,3)+1};
    data_table(k,4) = {1};
        
end
    
end