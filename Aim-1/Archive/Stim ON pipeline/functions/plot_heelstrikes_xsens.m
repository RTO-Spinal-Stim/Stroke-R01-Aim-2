function plot_heelstrikes_xsens(Pos_Lf, L_hs,Pos_Rf, R_hs  )
    % Display the segmentation
    figure()
    % Left Foot
    pl(1) = plot(Pos_Lf(:,1),'b');
    hold on
    plot(L_hs(:,1),Pos_Lf(L_hs(:,1),1),'bx')
    plot(L_hs(:,2),Pos_Lf(L_hs(:,2),1),'bo')
    % Right Foot
    pl(2) = plot(Pos_Rf(:,1),'r');
    plot(R_hs(:,1),Pos_Rf(R_hs(:,1),1),'rx')
    plot(R_hs(:,2),Pos_Rf(R_hs(:,2),1),'ro')
    %     xlim([0 frames(end)])
    ylabel('x- displacement (m)')
    legend(pl,'Left','Right')
end 