function I_deblur = wiener_deblur(I,B,k)
 
if ( isa(I,'uint8') || isa(B,'uint8') )
  error('deblur: Image and blur data should be of type double.');
end

% imshow(I);
I = edgetaper(I,B);
Fi = fft2(I);

% modify the code below ------------------------------------------------

% this section is just dummy code - delete it

% 1. zero pad B and compute its FFT
B_padded = padarray(B, size(I) - size(B), 'post');
FB = fft2(B_padded);

% 2. compute and apply the inverse filter
H_conj = conj(FB);
H_abs2 = abs(FB).^2;
Wiener_filter = H_conj ./ (H_abs2 + k);

% 3. convert back to a real image
F_deblur = Fi .* Wiener_filter;
I_deblur = real(ifft2(F_deblur));

% 4. handle any spatial delay caused by zero padding of B
I_deblur = circshift(I_deblur, -floor(size(B)/2));

% you may need to deal with values near zero in the FFT of B etc
% to avoid division by zero's etc.

% modify the code above ------------------------------------------------

return

