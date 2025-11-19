function [] = expandMuscleYLabels(fig, muscleNamesStruct)

%% PURPOSE: EXPAND MUSCLE NAMES FROM THEIR ABBREVIATIONS TO THEIR FULL NAMES
% Inputs:
% fig: The figure to manipulate
% muscleNamesStruct: Config struct where fields are the muscle
% abbreviations, and their values are the full muscle names.

axHandlesFiltered = findobj(fig, 'Type', 'Axes');
for axNum = 1:length(axHandlesFiltered)
    ax = axHandlesFiltered(axNum);
    muscleName = ax.Tag;
    if isfield(muscleNamesStruct, muscleName)
        muscleFullName = muscleNamesStruct.(muscleName);
    end
    muscleFullNameCellArray = strsplit(muscleFullName,' ');
    ax.YLabel.String = muscleFullNameCellArray;
end