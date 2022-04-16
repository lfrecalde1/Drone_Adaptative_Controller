function [xp] = Adaptation_law(Y,ve)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here
K = 0.3*eye(27);
xp = inv(K)*Y'*ve;
end

