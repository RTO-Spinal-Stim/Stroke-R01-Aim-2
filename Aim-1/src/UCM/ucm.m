%% Load the data
clearvars;
root_save_path = 'Y:\LabMembers\MTillman\GitRepos\Stroke-R01\plots\UCM';
% Color by intervention
% colors.SHAM1 = 'k';
% colors.SHAM2 = 'b';
% colors.RMT30 = 'g';
% colors.RMT50 = 'r';
% colors.TOL30 = 'm';
% colors.TOL50 = 'c';
% Color by session order
% colors.x1 = 'k';
% colors.x2 = 'b';
% colors.x3 = 'g';
% colors.x4 = 'r';
% colors.x5 = 'm';
% colors.x6 = 'c';
shapes.SSV = 'o';
shapes.FV = '^';
speedsToPlot.PRE = true; % Dummy variable
speedsToPlot.POST = true;
% Unmatched
data_path = 'Y:\LabMembers\MTillman\SavedOutcomes\StrokeSpinalStim\Overground_EMG_Kinematics\MergedTablesAffectedUnaffected10MWT\unmatchedCycles.csv';
df = readtable(data_path);

%% Set column names
% Factors to possibly facet by
subjectColName = 'Subject';
interventionColName = 'Intervention';
prePostColName = 'PrePost';
speedColName = 'Speed';
sessionOrderColName = 'SessionOrder';
% Factors to help organize data to plot
sideColName = 'Side';
trialColName = 'Trial';

%% Get the variable names
lastOutcomeMeasureColName = sideColName;
varNames = df.Properties.VariableNames;
outcomeVarsNames = varNames(find(ismember(varNames, lastOutcomeMeasureColName))+1:end);

%% Set plotting configuration
facetFactors = {'Subject','PrePost','Speed'};
% facetFactors = {'Subject'};
color_factor = {'Intervention'};
% color_factor = {'SessionOrder'};

saveFolder = color_factor{1};
if ~exist('colors','var')
    saveFolder = 'Speed';
end

% Get the columns that have all of the factors
allFactorNames = {subjectColName,interventionColName,speedColName,prePostColName,sessionOrderColName};
allFactorsIdx = ismember(varNames, allFactorNames);

%% Get the list of plot facets
dfToFilterBy = df(:, ismember(varNames, facetFactors));
unique_facets = unique(dfToFilterBy,'rows','stable');
color_factors_idx = ismember(varNames, color_factor);

subFolder = char(string(join(facetFactors,'_')));

%% Plot the data
fig = figure;
fig.WindowState = 'maximized';
subFolderPath = fullfile(root_save_path, subFolder, saveFolder);
if ~isfolder(subFolderPath)
    mkdir(subFolderPath);
end
th = 45;
R = [cosd(th), -1*sind(th); sind(th), cosd(th)];
for varNum = 1:length(outcomeVarsNames)
    varName = outcomeVarsNames{varNum};
    varColIdx = ismember(varNames, varName);
    varFolderPath = fullfile(subFolderPath, varName);
    if ~isfolder(varFolderPath)
        mkdir(varFolderPath);
    end        

    % Get the min & max of the unaffected and affected sides separately
    aIdx = ismember(df.(sideColName), 'A');
    uIdx = ismember(df.(sideColName), 'U');
    aExtremaRaw = [min(abs(df.(varName)(aIdx)),[],1,'omitnan'), max(abs(df.(varName)(aIdx)),[],1,'omitnan')];
    aExtrema = aExtremaRaw;
    aExtrema(1) = min([0 aExtremaRaw(1)]);
    uExtremaRaw = [min(abs(df.(varName)(uIdx)),[],1,'omitnan'), max(abs(df.(varName)(uIdx)),[],1,'omitnan')];
    uExtrema = uExtremaRaw;
    uExtrema(1) = min([0 uExtremaRaw(1)]);
    tmpFig = figure;
    tmpAx = axes(tmpFig);
    scatter(tmpAx,aExtrema, uExtrema);
    xlims1 = tmpAx.XLim;
    ylims1 = tmpAx.YLim;  
    cla(tmpFig);

    % Get the min & max of the rotated unaffected and affected sides
    allPlotData = NaN(height(df)-1,2);
    for i = 1:height(df)-1
        if df.(trialColName)(i) ~= df.(trialColName)(i+1)
            continue; % End of trial
        end        
        currSide = df.(sideColName)(i);
        currData = df.(varName)(i);
        nextData = df.(varName)(i+1);
        if strcmp(currSide, 'A')
            allPlotData(i,1) = currData;
            allPlotData(i,2) = nextData;
        elseif strcmp(currSide, 'U')
            allPlotData(i,1) = nextData;
            allPlotData(i,2) = currData;
        end
    end
    nanIdx = any(isnan(allPlotData),2);
    allPlotData(nanIdx,:) = [];
    rotDataAll = (R*abs(allPlotData)')';

    xRotExtremaRaw = [min(rotDataAll(:,1),[],1,'omitnan'), max(rotDataAll(:,1),[],1,'omitnan')];
    yRotExtremaRaw = [min(rotDataAll(:,2),[],1,'omitnan'), max(rotDataAll(:,2),[],1,'omitnan')];    
    xRotExtrema = xRotExtremaRaw;
    xRotExtrema(1) = min([0, xRotExtremaRaw(1)]);
    yRotExtrema = yRotExtremaRaw;
    yRotExtrema(1) = min([0, yRotExtremaRaw(1)]);
    scatter(tmpAx,xRotExtrema, yRotExtrema);
    xlims2 = tmpAx.XLim;
    ylims2 = tmpAx.YLim;
    close(tmpFig);
    figure(fig);    

    for facetRowNum = 1:height(unique_facets) 
        clf;        
        ax1 = subplot(1,2,1);
        hold on;
        ax2 = subplot(1,2,2);
        hold on;
        curr_facet = unique_facets(facetRowNum,:);
        facet_idx = ismember(dfToFilterBy, curr_facet, 'rows');
        facet_df = df(facet_idx,:);
        unique_names_curr_df = unique(facet_df(:,allFactorsIdx), 'rows');
        currDfToFilterBy = facet_df(:, allFactorsIdx); % Variable to use to get the rows from.        
        
        figName = char(join(string(table2cell(curr_facet)),' '));
        fig.Name = [figName ' ' varName];   
        colorGroupNames = {};
        prePostNames = {'PRE'; 'POST'};
        if exist('colors','var')
            prePostNames = {};
            colorGroupNames = fieldnames(colors);
            h = gobjects(length(colorGroupNames)+4,1);
            for intNum = 1:length(colorGroupNames)
                h(intNum) = scatter(ax1,NaN, NaN, colors.(colorGroupNames{intNum}));
            end
        end
        h(length(colorGroupNames)+1) = scatter(ax1,NaN, NaN,'o','k');
        h(length(colorGroupNames)+2) = scatter(ax1,NaN, NaN,'^','k');
        if exist('colors','var')
            h(length(colorGroupNames)+3) = scatter(ax1,NaN, NaN,'sq','k');
            h(length(colorGroupNames)+4) = scatter(ax1,NaN, NaN,'sq','k','filled');        
        end
        legend(ax1,[colorGroupNames; fieldnames(shapes); prePostNames],'AutoUpdate','off','Location','northoutside','NumColumns',5);
        allAggData = [];
        % Set the color limits        
        if ismember({'TenMWT'}, df.Properties.VariableNames)
            unique_names_curr_df_with_speed = unique(facet_df(:,allFactorsIdx | ismember(facet_df.Properties.VariableNames,{'TenMWT'})), 'rows');
            speeds = 10 ./ unique_names_curr_df_with_speed.TenMWT;
            minSpeed = min(speeds);
            maxSpeed = max(speeds);
            colormap(turbo);
            clim([minSpeed maxSpeed]);
        end
        for nameRow = 1:height(unique_names_curr_df)
            currComb = unique_names_curr_df(nameRow,:);
            nameIdx = ismember(currDfToFilterBy, unique_names_curr_df(nameRow,:), 'rows');
            currCombFacetCols = currComb(:,facetFactors);
            name = join(string(table2cell(currCombFacetCols)),'_');              

            % Aggregate the data
            currNameDf = facet_df(nameIdx, ismember(varNames, [allFactorNames, {trialColName, sideColName, prePostColName, varName, 'TenMWT'}]));
            aggData = NaN(height(currNameDf)-1,2);
            speedsToPlot = NaN(size(aggData,1),1);
            for rowNum = 1:height(currNameDf)-1
                if currNameDf.(trialColName)(rowNum) ~= currNameDf.(trialColName)(rowNum+1)
                    continue; % End of trial
                end
                currSide = currNameDf.(sideColName)(rowNum);
                currData = currNameDf.(varName)(rowNum);
                nextData = currNameDf.(varName)(rowNum+1);
                if strcmp(currSide, 'A')
                    aggData(rowNum,1) = currData;
                    aggData(rowNum,2) = nextData;
                elseif strcmp(currSide, 'U')
                    aggData(rowNum,1) = nextData;
                    aggData(rowNum,2) = currData;
                end
                if ismember({'TenMWT'}, currNameDf.Properties.VariableNames)
                    speed = 10 / currNameDf.TenMWT(rowNum);
                    speedsToPlot(rowNum) = speed;
                end
            end
    
            nanIdx = any(isnan(aggData),2);
            aggData(nanIdx,:) = [];
            speedsToPlot(nanIdx) = [];

            % Put it in the first quadrant
            if mean(aggData(:,1)) < 0
                aggData(:,1) = -1*aggData(:,1);
            end
            if mean(aggData(:,2)) < 0
                aggData(:,2) = -1*aggData(:,2);
            end                                        

            colorFactor = currComb.(color_factor{1});
            if iscell(colorFactor)
                colorFactor = colorFactor{1};
            end
            if isnumeric(colorFactor)
                colorFactor = num2str(colorFactor);
            end
            colorFactorVarName = genvarname(colorFactor);
            if exist('colors','var')
                color = colors.(colorFactorVarName);
            else
                color = speedsToPlot;
            end
            shape = shapes.(currComb.Speed{1});

            if length(color) ~= size(aggData,1)
                disp('a');
            end
   
            % Plot            
            if isequal(currComb.PrePost{1},'PRE') && exist('colors','var')
                scatter(ax1,aggData(:,1), aggData(:,2), [], color,shape);
            else
                scatter(ax1,aggData(:,1), aggData(:,2), [], color, 'filled', shape);
            end  
            allAggData = [allAggData; aggData];            
            rotData = (R*aggData')';
            if isequal(currComb.PrePost{1},'PRE') && exist('colors','var')
                scatter(ax2,rotData(:,1), rotData(:,2), [], color,shape);
            else
                scatter(ax2,rotData(:,1), rotData(:,2), [], color,'filled',shape);
            end            
        end
        c = colorbar(ax1);
        c.Label.String = "Speed (m/s)";
        aggVector = facet_df.(varName);
        meanVal = abs(mean(aggVector,'omitnan') * 2);
        % Determine UCM & ORT vectors
        demeanedAggData = allAggData - mean(allAggData);
        g = ones(1,size(demeanedAggData,2)); % Jacobian
        [~,~,d]=svd(g);
        o = d(:,1); % ORT
        u = d(:,2); % UCM

        % Find length of projections of de-meaned data onto UCM and ORT
        % planes
        m = size(allAggData,1);
        distORT = NaN(m,1);
        distUCM = NaN(m,1);
        distTOT = NaN(m,1);
        for i=1:m
            distORT(i) = dot(demeanedAggData(i,:),o);
            distUCM(i) = dot(demeanedAggData(i,:),u);
            distTOT(i) = norm(demeanedAggData(i,:));
        end

        % Find variances of each
        Vucm = sum(diag(distUCM'*distUCM)/length(distUCM));
        Vort = sum(diag(distORT'*distORT)/length(distORT));
        Vtot = sum(diag(distTOT'*distTOT)/length(distTOT));

        % Calculate index of symmetry
        DV = (Vucm-Vort)/(Vtot/2);
        xlabel(ax1,'Affected');
        ylabel(ax1,'Unaffected');
        sgtitle({[char(name) ' ' varName ' Mean: ' num2str(meanVal / 2) ' DV: ' num2str(-1*DV)], ...
            ['Vsym: ' num2str(Vort) ' Vmean: ' num2str(Vucm)]},'Interpreter','None');         
        axis(ax1,'equal');
        xlim(ax1,xlims1);
        ylim(ax1,ylims1);
        line(ax1,[0 meanVal],[meanVal, 0],'Color','black','LineStyle','-');        
        line(ax1,[0 meanVal], [0 meanVal],'Color','black','LineStyle','--'); 
        xlabel(ax2,'Symmetry');
        ylabel(ax2,'Rotated Magnitude');
        axis(ax2,'equal');
        xlim(ax2,xlims2);
        ylim(ax2,ylims2);       
        xline(ax2,0,'k','LineStyle','--');
        filePath = fullfile(varFolderPath, figName);
        saveas(fig, [filePath '.fig']);
        saveas(fig, [filePath '.png']);
        saveas(fig, [filePath '.svg']);
    end
end
close(fig);