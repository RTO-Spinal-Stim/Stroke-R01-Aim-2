% Function to flag a signal
function flag_signal(fig, trial_name)
    global flagged_indices;
    flagged_indices{1,end+1} =  trial_name;
    close(fig);
end