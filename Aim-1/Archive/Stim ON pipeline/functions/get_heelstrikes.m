function [L_hs, R_hs, Pos_Rf, Pos_Lf] = get_heelstrikes(pel_ori_segment, pel_pos, rightFoot_pos, leftFoot_pos, select_range)
    % OUT:
    % Pos_Rf, Pos_Lf: are the postions of Left and right in the specified
    % range
    % L_hs, R_hs - heelstrikes of left and right, each row is a stride

    % Set default value for select_range if not provided
    if nargin < 5
        select_range = false;
    end
        
        % this are needed for the heelstrike function later:
    Hz      = 100;  
    Ts      = 1/Hz;
    Tw      = 0.3;

    for k = 1:length(pel_ori_segment)
        %     q_PE_init = quaternion(mean(ori(:,1:4)));
        q_PE_init   = quaternion((pel_ori_segment(1,1:4)));         % Pelvis quaternion at start - get 4 coordinates and gets back complex quat
        % Real and complex numbers
        q_PE        = quaternion(pel_ori_segment(k,1:4));           % Pelvis quaternion at instant k
        q_Pel(k,:)  = times(conj(q_PE_init),q_PE);      % Projection of the pelvis on the init one
        Pel(k,:)    = EulerAngles(q_Pel(k,:),'123')';   % Euler angles for orientation of pelvis
        % Would this be the same as the given Euler?

        Ro  = RotationMatrix(q_PE);             % Matrix of rotation
        To  = [Ro pel_pos(k,1:3)'; 0 0 0 1];   % Traslo-rotation matrix # Ro should be a 1 column?
        F_R = [rightFoot_pos(k,1:3) 1]';
        F_L = [leftFoot_pos(k,1:3) 1]';
        F_R = inv(To)*F_R;  % Right Foot
        F_L = inv(To)*F_L;  % Left Foot

        RF(k,:) = F_R(1:3)'; % Right Foot
        LF(k,:) = F_L(1:3)'; % Left Foot
    end
    % Correct discontinuous signal near -+180 degree in pelvis rotation
    Pel(:,3) = pelvis_correct(Pel(:,3));

    % Depending of select_range - could plot and manually select range 
    if select_range == false
        f_1 = 1;
        f_2 = length(pel_pos);
        rangeofinterest = (f_1:f_2);
    else
        figure()
        subplot(3,1,1), hold on
        plot(LF(:,1),'b'),plot(RF(:,1),'r')
        title('Select Start and Stop, avoid with ENTER')
        ylabel('Foot Traj x(m)')
        subplot(3,1,2), hold on
        plot(LF(:,2),'b'),plot(RF(:,2),'r')
        ylabel('Foot Traj y(m)')
        subplot(3,1,3), hold on
        plot(LF(:,3),'b'),plot(RF(:,3),'r')
        ylabel('Foot Traj z(m)')
        xlabel('Frames')
        legend('left','right')
        % Gait range
        [f,range] = ginput(2);
       
        f = round(f);
        if strcmp(testlist{testidx},'WTm2')
            f(2) = f(1) + 12000;
            f(2) = min(size(Pel,1),f(2));
        end
        close all
        
        rangeofinterest = (f(1):f(2));
    end 

    % Positions - replace with range of interest:
    Pos_Pel(:,1:3) = pel_pos(rangeofinterest,1:3);	% Pelvis
    Pos_Rf(:,1:3) = RF(rangeofinterest,:);        	% Right Foot
    Pos_Lf(:,1:3) = LF(rangeofinterest,:);        	% Left Foot

    % Joint Angles
    JA(:,1:3)   = Pel(rangeofinterest,:)*180/pi;

    
    L_hs    = heelstrike(Pos_Lf(:,1),JA(:,3),Ts,Tw); 	% Left Heel Strike (HS) to Left HS
    R_hs    = heelstrike(Pos_Rf(:,1),JA(:,3),Ts,Tw); 	% Right HS to HS








end