function [v_filtered] = ACSR_filter(v_rest,v_target,Ws)
% function [v_filtered] = ACSR_filter(v_rest,v_target,Ws)
% Inputs:  v_rest - The raw signal to train filter parameters
%          v_target - The raw signal to filter
%          Ws - Window length 
% Output: v_filtered - The ASCR filtered signal 

%% Information
% This function provides an implementation of the ACSR filter, described in the following paper:
% Title: A Novel Technique to Reject Artifact Components 
%        for Surface EMG Signals Recorded During Walking 
%        with Transcutaneous Spinal Cord Stimulation: A Pilot Study
% Authors: Minjae Kim, Yaejin Moon, Jasmine Hunt, Kelly A. McKenzie, 
%          Adam Horin, Matt McGuire, Keehoon Kim, Levi J. Hargrove, and Arun Jayaraman
% This manuscript has been submitted for publication in Frontiers in Human Neuroscience.

% <ACSR filter for sEMG signals>
% Copyright (C) 2021, Minjae Kim <mjkim@northwestern.edu>
% Shirley Ryan AbilityLab, Chicago, IL, USA
% Feinberg School of Medicine, Northwestern University, Chicago, IL, USA
% 
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
% 
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with this program. If not, see <https://www.gnu.org/licenses/>.
%--------------------------------------------------------------------------

[mmags,~] = ACSR_init(v_rest,Ws);
overlap=round(Ws/2);
ev=Window_division(v_target,Ws,overlap);
fv=[];
for tt=1:size(ev,2)
    comp=Artifact_removal(ev(:,tt),'ind_app',mmags);    
    if overlap>0
        fv(:,tt)=comp(overlap+1:end);
    else
        fv(:,tt)=comp';
    end
end
    fv=reshape(fv,1,[]);
    fv=[zeros(1,overlap),fv];    
    if length(fv)<length(v_target)
       fv=[fv, zeros(1,length(v_target)-length(fv))];
    end
    v_filtered=reshape(fv,size(v_target));
    
end

function [varargout] = ACSR_init(v,windows)
rv=Window_division(v,windows,windows-1);
[mmags,mags]=Artifact_removal(rv,'init');
varargout{1}=mmags;
varargout{2}=mags;

end

function [ output ] = Window_division( data,windows,overlap)
[m,n]=size(data);
if min([m,n])==1
   data=reshape(data,1,[]); 
end
    N_ch=size(data,1);
    output=cell(N_ch,1);
    End=[windows:(windows-overlap):length(data)];

     for fi=1:N_ch
         sig=data(fi,:);
         Sig=[];
         for fj=1:length(End)
            Sig=[Sig sig(:,End(fj)-windows+1:End(fj))'];
         end             
         output{fi}=Sig;
     end
     if N_ch==1
         output=output{1};
     end
end

function [varargout] = Artifact_removal(input,statev,params)
switch statev
    case 'init' % input= windows by trials
        target_fft=zeros(size(input));        
        for ii=1:size(input,2)
            target=input(:,ii);
            target_fft(:,ii)=fft(target);
        end
        mags=abs(target_fft);
        if size(mags,2)==1
            mmags=mags;
        else        
            mmags=max(mags')';    
        end
        varargout{1}=mmags;
        varargout{2}=mags;

    case 'ind_app' % windows by 1 
        mmags=params;        
        target=input;
        freq=fft(target);
        comp_freq=zeros(size(freq));
        for ii=1:length(freq)
            [a,b]=ACSR_computation(freq(ii),mmags(ii));
            comp_freq(ii)=a+b*1i;
        end
        comp=(ifft(comp_freq,'symmetric'));
        varargout{1}=comp;
end

end

function [a1,b1] = ACSR_computation(in,mag)
    a0=real(in);
    b0=imag(in);
    s_a=sign(a0);

    p0=atan2(b0,a0);
    m0=sqrt(a0.^2+b0.^2);
    ratio=tan(p0);

    m1=m0-mag;
    if m1<0        
        m1=0; 
    end

    a1=s_a*sqrt((m1.^2)/(1+ratio.^2));
    b1=a1*ratio;

end