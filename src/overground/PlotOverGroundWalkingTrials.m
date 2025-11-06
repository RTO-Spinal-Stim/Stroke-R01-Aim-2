%% Plot Overground EMG & Kinematics for All Subjects
clear; clc; close all;

dataDir = 'Y:\Spinal Stim_Stroke R01\AIM 2\Subject Data\MATLAB Processed Overground_EMG_Kinematics';
saveDir = fullfile(dataDir, 'Plots');
if ~exist(saveDir, 'dir'), mkdir(saveDir); end

lineWidth = 1.2;
alphaVal  = 0.6;

files = dir(fullfile(dataDir, 'SS*_Overground_EMG_Kinematics.mat'));

for f = 1:numel(files)
    filePath = fullfile(files(f).folder, files(f).name);
    [~, baseName, ~] = fileparts(filePath);
    fprintf('Processing %s...\n', baseName);

    try
        S = load(filePath, 'cycleTable');
        if ~isfield(S, 'cycleTable'), warning('No cycleTable in %s', baseName); continue; end
        cycleTable = S.cycleTable;

        subjID = regexp(baseName, 'SS\d+', 'match', 'once');
        if isempty(subjID), subjID = baseName; end
        subjSaveDir = fullfile(saveDir, subjID);
        if ~exist(subjSaveDir, 'dir'), mkdir(subjSaveDir); end

        interventions = unique(cycleTable.Intervention);
        speeds = unique(cycleTable.Speed);

        % --- Delsys fieldnames
        sampleStruct = cycleTable.Delsys_TimeNormalized(1);
        allMuscles = fieldnames(sampleStruct);
        leftMuscles  = allMuscles(startsWith(allMuscles, 'L', 'IgnoreCase', true));
        rightMuscles = allMuscles(startsWith(allMuscles, 'R', 'IgnoreCase', true));

        % --- XSENS fieldnames
        sampleStructX = cycleTable.XSENS_TimeNormalized(1);
        allJoints = fieldnames(sampleStructX);
        leftJoints  = allJoints(startsWith(allJoints, 'L', 'IgnoreCase', true));
        rightJoints = allJoints(startsWith(allJoints, 'R', 'IgnoreCase', true));
        
        % Convert Intervention and Speed from categorical to string
        % to ensure proper matching with == operator (strcmp fails on categoricals)
        intList = string(interventions);
        spdList = string(speeds);
        intCol  = string(cycleTable.Intervention);
        spdCol  = string(cycleTable.Speed);
        
        for iInt = 1:numel(intList)
            for iSpd = 1:numel(spdList)
                groupMask = intCol == intList(iInt) & spdCol == spdList(iSpd);
                groupData = cycleTable(groupMask, :);

                if isempty(groupData), continue; end

                % DELSYS
                fig = figure('Name', sprintf('%s - %s - %s - Delsys', subjID, string(interventions(iInt)), string(speeds(iSpd))), ...
                             'Color','w','Position',[100,100,1200,800]);
                tiledlayout(5,2,'TileSpacing','compact','Padding','compact');
                
                % unique trial IDs for colors
                trialList = unique(groupData.Trial);
                nTrials   = numel(trialList);
                colors    = lines(nTrials);   % distinct colors per trial
                
                % plot all muscles (left+right already combined in allMuscles)
                for m = 1:numel(allMuscles)
                    nexttile(m); hold on;
                    for t = 1:nTrials
                        trialRows = find(groupData.Trial == trialList(t));
                        for r = trialRows'
                            emgStruct = groupData.Delsys_TimeNormalized(r);
                            plot(emgStruct.(allMuscles{m}), 'LineWidth', lineWidth, ...
                                 'Color', [colors(t,:) alphaVal], 'HandleVisibility','off'); % keep real lines out of legend
                        end
                    end
                    title(allMuscles{m}); xlabel('Normalized Time (%)'); ylabel('Amplitude'); grid on;
                end
                
                % build legend using dummy (NaN) handles to guarantee 1 color per trial
                ax = gca; hold(ax,'on');
                hTrial = gobjects(nTrials,1);
                for t = 1:nTrials
                    hTrial(t) = plot(ax, nan, nan, '-', 'LineWidth', lineWidth, ...
                                     'Color', colors(t,:), 'HandleVisibility','on'); % dummy visible to legend
                end
                legend(hTrial, cellstr("Trial " + string(trialList)), 'Location','bestoutside', 'Interpreter','none');
                sgtitle(sprintf('%s | %s | %s | Delsys EMG', subjID, string(interventions(iInt)), string(speeds(iSpd))));
                saveName = sprintf('%s_%s_%s_Delsys', subjID, string(interventions(iInt)), string(speeds(iSpd)));
                savefig(fig, fullfile(subjSaveDir,[saveName '.fig']));
                exportgraphics(fig, fullfile(subjSaveDir,[saveName '.png']), 'Resolution',300);   
                close(fig);

                % XSENS
                fig2 = figure('Name', sprintf('%s - %s - %s - XSENS', subjID, string(interventions(iInt)), string(speeds(iSpd))), ...
                              'Color','w','Position',[100,100,1000,700]);
                tiledlayout(3,2,'TileSpacing','compact','Padding','compact');
                
                trialList = unique(groupData.Trial);
                nTrials   = numel(trialList);
                colors    = lines(nTrials);
                
                for j = 1:numel(allJoints)
                    nexttile(j); hold on;
                    for t = 1:nTrials
                        trialRows = find(groupData.Trial == trialList(t));
                        for r = trialRows'
                            xsStruct = groupData.XSENS_TimeNormalized(r);
                            plot(xsStruct.(allJoints{j}), 'LineWidth', lineWidth, ...
                                 'Color', [colors(t,:) alphaVal], 'HandleVisibility','off');
                        end
                    end
                    title(allJoints{j}); xlabel('Normalized Time (%)'); ylabel('Angle (°)'); grid on;
                end
                
                ax2 = gca; hold(ax2,'on');
                hTrial2 = gobjects(nTrials,1);
                for t = 1:nTrials
                    hTrial2(t) = plot(ax2, nan, nan, '-', 'LineWidth', lineWidth, ...
                                      'Color', colors(t,:), 'HandleVisibility','on');
                end
                legend(hTrial2, cellstr("Trial " + string(trialList)), 'Location','bestoutside', 'Interpreter','none');
                sgtitle(sprintf('%s | %s | %s | XSENS Kinematics', subjID, string(interventions(iInt)), string(speeds(iSpd))));
                saveNameX = sprintf('%s_%s_%s_XSENS', subjID, string(interventions(iInt)), string(speeds(iSpd)));
                savefig(fig2, fullfile(subjSaveDir,[saveNameX '.fig']));
                exportgraphics(fig2, fullfile(subjSaveDir,[saveNameX '.png']), 'Resolution',300);
                close(fig2);


            end
        end

    catch ME
        warning('Error processing %s: %s', baseName, ME.message);
    end
end

fprintf('All subjects processed. Plots saved in %s\n', saveDir);
