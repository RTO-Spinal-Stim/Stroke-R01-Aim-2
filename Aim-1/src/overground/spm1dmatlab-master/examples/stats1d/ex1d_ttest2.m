%  YA = load('RVL.mat');
%  YB = load('LVL.mat');

 YA = RRF;
 YB = LRF;

% YA = YA.RVL;
% YB = YB.LVL;

%(0) Load data:
% dataset = spm1d.data.uv1d.t2.PlantarArchAngle();
% dataset = spm1d.data.uv1d.t2.SimulatedTwoLocalMax();
% [YA,YB] = deal(YA, dataset.YB);






%(1) Conduct SPM analysis:
spm       = spm1d.stats.ttest2(YA, YB);
spmi      = spm.inference(0.05, 'two_tailed',true, 'interp',true);
disp(spmi)




close all
figure('position', [0 0 1000 300])
%%% plot mean and SD:
subplot(121)
spm1d.plot.plot_meanSD(YA, 'color','k');
hold on
spm1d.plot.plot_meanSD(YB, 'color','r');
title('Mean and SD')
%%% plot SPM results:
subplot(122)
spmi.plot();
spmi.plot_threshold_label();
spmi.plot_p_values();
title('Hypothesis test')













