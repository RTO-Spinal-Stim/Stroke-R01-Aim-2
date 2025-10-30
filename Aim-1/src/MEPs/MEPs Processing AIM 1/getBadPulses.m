function delete_in = getBadPulses(pulsestodelete)
    if ischar(pulsestodelete) 
        % This cell says 'N/A'
        if isequal(pulsestodelete,'N/A')
            delete_in = [];
        else % multiple pulses to delete, delimited by commas
            % parse out the individual pulse numbers
            pulsestodelete_split = strsplit(pulsestodelete,',');
            delete_in = str2double(pulsestodelete_split);
        end

    else % This cell has one pulse
        % In case the cell was left empty
        if isnan(pulsestodelete)
            delete_in = [];
        else
            delete_in = pulsestodelete;
        end
    end

end