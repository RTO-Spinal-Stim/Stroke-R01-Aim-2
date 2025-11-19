function  pick_Peaks_inPlot_callback(src,muscle_channel)

% SRC is 2 different buttons: continue or skip (since nothing was seen)

    if strcmp(src.String, 'Continue')
     % Manually click stim onset 
%         title([muscle_channel  ' - Pick STIM ONSET'])
%         [sitmIDX_picked, ~] = ginput(1);
%         sitmIDX_picked = round(sitmIDX_picked(1));
%         xline(sitmIDX_picked)
%         hold on;

        % Manually click latency 
        title([muscle_channel  ' - Pick latency (Start point of MEP)'])
        [lat_index, ~] = ginput(1);
        foundLat = round(lat_index(1));
        xline(foundLat)
        hold on;
        % Also click min and max

        % Pick first peak
        title([muscle_channel ' - Pick peak 1 (x and y must be accurate - zoom in'])
        [x_pick1, y_pick1] = ginput(1);
        hold on
        plot(x_pick1, y_pick1,'g*');

        title([muscle_channel ' - Pick peak 2 (x and y must be accurate - zoom in'])
        [x_pick2, y_pick2] = ginput(1);
        hold on
        plot(x_pick2, y_pick2,'g*');
        hold on

%         % Pick end point
%         title([muscle_channel  ' - Pick approx end point of MEP'])
%         [endIDX_picked, ~] = ginput(1);
%         endIDX_picked = round(endIDX_picked(1));
%         xline(endIDX_picked)


        % Check what index is min and which one is the max peak

        if y_pick2 > y_pick1 % if the y-val of second peak is greater, then this is the max peak
            maxIDX_picked = round(x_pick2);
            minIDX_picked = round(x_pick1);
        else
            maxIDX_picked = round(x_pick1);
            minIDX_picked = round(x_pick2);
        end

    elseif strcmp(src.String, 'Skip')

            % Did not get activation:
            % STIM INDEX - still getting stim index
            foundLat = NaN;
            %endIDX_picked = NaN;
            maxIDX_picked = NaN;
            minIDX_picked = NaN;

    end
    
    
    % Save NaN values to the base workspace
    assignin('base', 'foundLat', foundLat);
    %assignin('base', 'foundEnd', endIDX_picked);
    assignin('base', 'maxIDX_picked', maxIDX_picked);
    assignin('base', 'minIDX_picked', minIDX_picked);
    
    % Resume script execution
    uiresume(gcf);

end
