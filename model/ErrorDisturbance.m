
function out = ErrorDisturbance(t,i)
%%% Renewable production (wind and solar) error follows AR model;
%%% Error =Production -forecast
%%%

if t == 1
    out = 1;
else
    %out = norminv(i/10-0.05,1,0.0376);
    out = norminv(i/10-0.05,1,0.015);
end

end











