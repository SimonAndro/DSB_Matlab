function y = interp_zero(x,I)
    m = length (x);
    y = [x;zeros(I-1,m)];
    y = y(:)';
end
