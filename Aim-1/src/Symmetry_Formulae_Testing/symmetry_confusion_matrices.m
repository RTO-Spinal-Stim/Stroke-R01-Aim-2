L = -1:0.1:1;
R = L;
nRows = length(L) * length(R);
close all;

%% Equation 1: 2|R-L|/(R+L)
% Initialize table with zeros
tbl = table('Size', [nRows, 3], 'VariableNames', {'L', 'R', 'Sym'}, ...
    'VariableTypes', {'double', 'double', 'double'});

row = 0;
for lCount = 1:length(L)
    l = L(lCount);
    for rCount = 1:length(R)  % Fixed the loop range
        r = R(rCount);
        row = row + 1;
        tbl.L(row) = l;
        tbl.R(row) = r;

        if l<0 && r<0
            tbl.Sym(row) = NaN;
            continue;
        end
                       
        tbl.Sym(row) = (2*abs(r - l)) / (r + l);                
    end
end

f = figure;
h = heatmap(tbl, 'L', 'R', 'ColorVariable', 'Sym');
h.YDisplayData = flip(h.YDisplayData);
title(h, 'Current Symmetry Equation: 2|R-L|/(R+L)');
colormap(turbo);
f.WindowState = 'maximized'; drawnow;
saveas(f, 'Equation1.fig');
saveas(f, 'Equation1.png');

%% Equation 2: (R-L)/(L+R)
% Initialize table with zeros
tbl = table('Size', [nRows, 3], 'VariableNames', {'L', 'R', 'Sym'}, ...
    'VariableTypes', {'double', 'double', 'double'});

row = 0;
for lCount = 1:length(L)
    l = L(lCount);
    for rCount = 1:length(R)  % Fixed the loop range
        r = R(rCount);
        row = row + 1;
        tbl.L(row) = l;
        tbl.R(row) = r;

        if l<0 && r<0
            tbl.Sym(row) = NaN;
            continue;
        end
                       
        % tbl.Sym(row) = abs((r - l) / (r + l));
        tbl.Sym(row) = (r - l) / (r + l);
    end
end

f = figure;
h = heatmap(tbl, 'L', 'R', 'ColorVariable', 'Sym');
h.YDisplayData = flip(h.YDisplayData);
title(h, 'Alternative Symmetry Equation: (R-L)/(L+R)');
colormap(turbo);
f.WindowState = 'maximized'; drawnow;
saveas(f, 'Equation2.fig');
saveas(f, 'Equation2.png');

%% Equation 3: 1-abs(1-L/R)
% Initialize table with zeros
tbl = table('Size', [nRows, 3], 'VariableNames', {'L', 'R', 'Sym'}, ...
    'VariableTypes', {'double', 'double', 'double'});

row = 0;
for lCount = 1:length(L)
    l = L(lCount);
    for rCount = 1:length(R)  % Fixed the loop range
        r = R(rCount);
        row = row + 1;
        tbl.L(row) = l;
        tbl.R(row) = r;

        if l<0 && r<0
            tbl.Sym(row) = NaN;
            continue;
        end
                       
        tbl.Sym(row) = 100*(1-abs(1-l/r));
    end
end

f = figure;
h = heatmap(tbl, 'L', 'R', 'ColorVariable', 'Sym');
h.YDisplayData = flip(h.YDisplayData);
title(h, 'Grant Symmetry Equation: 1-abs(1-L/R)');
colormap(turbo);
f.WindowState = 'maximized'; drawnow;
saveas(f, 'Equation3.fig');
saveas(f, 'Equation3.png');

%% Equation 4: -1*(|R-L|/(R+L)) + 1
% Initialize table with zeros
tbl = table('Size', [nRows, 3], 'VariableNames', {'L', 'R', 'Sym'}, ...
    'VariableTypes', {'double', 'double', 'double'});

row = 0;
for lCount = 1:length(L)
    l = L(lCount);
    for rCount = 1:length(R)  % Fixed the loop range
        r = R(rCount);
        row = row + 1;
        tbl.L(row) = l;
        tbl.R(row) = r;

        if l<0 && r<0
            tbl.Sym(row) = NaN;
            continue;
        end
                       
        tbl.Sym(row) = -1*((abs(r - l)) / (r + l)) + 1;
    end
end

f = figure;
h = heatmap(tbl, 'L', 'R', 'ColorVariable', 'Sym');
h.YDisplayData = flip(h.YDisplayData);
title(h, 'Modified Current Symmetry Equation: -1*(|R-L|/(R+L)) + 1');
colormap(turbo);
f.WindowState = 'maximized'; drawnow;
saveas(f, 'Equation4.fig');
saveas(f, 'Equation4.png');

%% Equation 5: L/R
% Initialize table with zeros
tbl = table('Size', [nRows, 3], 'VariableNames', {'L', 'R', 'Sym'}, ...
    'VariableTypes', {'double', 'double', 'double'});

row = 0;
for lCount = 1:length(L)
    l = L(lCount);
    for rCount = 1:length(R)  % Fixed the loop range
        r = R(rCount);
        row = row + 1;
        tbl.L(row) = l;
        tbl.R(row) = r;

        if l<0 && r<0
            tbl.Sym(row) = NaN;
            continue;
        end
                       
        tbl.Sym(row) = l/r;
    end
end

f = figure;
h = heatmap(tbl, 'L', 'R', 'ColorVariable', 'Sym');
h.YDisplayData = flip(h.YDisplayData);
title(h, 'Simple Ratio: L/R');
colormap(turbo);
f.WindowState = 'maximized'; drawnow;
saveas(f, 'Equation5.fig');
saveas(f, 'Equation5.png');