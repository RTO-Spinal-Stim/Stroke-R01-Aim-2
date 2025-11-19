%% Load the data
clearvars;
% Matched
% data_path = "Y:\LabMembers\MTillman\SavedOutcomes\StrokeSpinalStim\Overground_EMG_Kinematics\MergedTablesAffectedUnaffected\matchedCyclesPrePost.csv";
% Unmatched
data_path = "Y:\LabMembers\MTillman\SavedOutcomes\StrokeSpinalStim\Overground_EMG_Kinematics\MergedTablesAffectedUnaffected\unmatchedCycles.csv";
df = readtable(data_path);

%% Get the variable names
lastOutcomeMeasureColName = 'Side';
varNames = df.Properties.VariableNames;
outcomeVarsNames = varNames(find(ismember(varNames, lastOutcomeMeasureColName))+1:end);

%% Get the unique speed/timepoint combos
levelNames = {'Subject','Intervention','Speed','PrePost'};
% levelNames = {'Subject','Speed','PrePost'};
levelIdx = ismember(varNames, levelNames); % Column numbers to get the factor names to average within
unique_names_df = unique(df(:,levelIdx), 'rows');
df_for_rows = df(:, levelIdx); % Variable to use to get the rows from.

%% Set other column names
prePostColName = 'PrePost';
trialColName = 'Trial';
sideColName = 'Side';
trialColIdx = ismember(varNames, trialColName);
sideColIdx = ismember(varNames, sideColName);
prePostColIdx = ismember(varNames, prePostColName);

%% Plot the data
for nameRow = 1:height(unique_names_df)
    nameIdx = ismember(df_for_rows, unique_names_df(nameRow,:), 'rows');
    name = join(string(table2cell(unique_names_df(nameRow,:))),'_');
    
    for varNum = 1:length(outcomeVarsNames)
        varName = outcomeVarsNames{varNum};
        varName = 'SwingDurations';
        varColIdx = ismember(varNames, varName);        

        % Aggregate the data
        currNameDf = df(nameIdx, levelIdx | trialColIdx | sideColIdx | prePostColIdx | varColIdx);
        aggData = NaN(height(currNameDf)-1,2);
        aggVector = currNameDf.(varName);
        meanVal = abs(mean(aggVector,'omitnan') * 2);
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
        end

        nanIdx = any(isnan(aggData),2);
        aggData(nanIdx,:) = [];

        % Put it in the first quadrant
        if mean(aggData(:,1)) < 0
            aggData(:,1) = -1*aggData(:,1);
        end
        if mean(aggData(:,2)) < 0
            aggData(:,2) = -1*aggData(:,2);
        end

        % Determine UCM & ORT vectors
        demeanedAggData = aggData - mean(aggData);
        g = ones(1,size(demeanedAggData,2)); % Jacobian
        [~,~,d]=svd(g);
        o = d(:,1); % ORT
        u = d(:,2); % UCM

        % Find length of projections of de-meaned data onto UCM and ORT
        % planes
        m = size(aggData,1);
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

        % Compute DVz
        % DVz = 0.5*log(((2+DV)/(2/(1-DV)));

        % Plot        
        fig = figure('Name',[char(name) ' ' varName]);
        line([0 meanVal],[meanVal, 0],'Color','black','LineStyle','-');
        hold on;
        line([0 meanVal], [0 meanVal],'Color','black','LineStyle','--');    
        scatter(aggData(:,1), aggData(:,2), 'k', 'filled');
        xlabel('Affected');
        ylabel('Unaffected');
        title({[varName ' Mean: ' num2str(meanVal / 2) ' DV: ' num2str(DV)], ...
            ['Vucm: ' num2str(Vucm) ' Vort: ' num2str(Vort)]},'Interpreter','None');         
        xlim([0 meanVal]);
        ylim([0 meanVal]); 
        axis equal;
        close(fig);
    end
end