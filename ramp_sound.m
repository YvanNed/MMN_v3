function y = ramp_sound(fs, ramp_dur, sig);

%--------------------------------------------------------------------------
% function y = rampsound(fs, ramp_dur, sig);
%--------------------------------------------------------------------------
% Ramps ON/OFF signal 'sig' with designated ramping duration
% defaults values are fs=44100Hz, ramp_dur=0.005 s
% 
%--------------------------------------------------------------------------
% Virginie van Wassenhove 10/2005

if nargin < 2
  fs = 44100;               % total noise duration (s)
end
if nargin < 3
  ramp_dur= 0.005;          % ramping duration (s) ON and OFF
end

y = sig;
ns = length(sig);
n = fix(fs*ramp_dur);
m = (1:n)./n;
y(1:n) = y(1:n).*m';
start = (ns-n)+1;
mm = ((ns:-1:start)-(start-1))./n;
y(start:ns) = y(start:ns).*mm';
