%
% Compute the quantised coefficients for a given 8x8 jpeg region
%
% tile - 8x8 greyscale region (0..255)
% Q - quality factor 1..100 (eg. 80).
%
% dc_coeff  - quantised dc coefficient  of DCT
% ac_coeff - quantised ac coefficients (63) of DCT in zig-zag order
%
function tile = djpeg_8x8(dc_coeff, ac_coeff, Q)
    % Decompresses 8x8 JPEG region
    %
    % dc_coeff - quantized DC coefficient (top left of DCT)
    % ac_coeff - quantized AC coefficients (1x63 array in zig-zag order)
    % Q - quality factor (1..100)
    %
    % tile - reconstructed 8x8 grayscale region (0..255)

    % Quantization table used to reconstruct DCT coefficients
    Qtable = [ 16  11  10  16  24  40  51  61 ; ...
               12  12  14  19  26  58  60  55 ; ...
               14  13  16  24  40  57  69  56 ; ...
               14  17  22  29  51  87  80  62 ; ...
               18  22  37  56  68 109 103  77 ; ...
               24  35  55  64  81 104 113  92 ; ...
               49  64  78  87 103 121 120 101 ; ...
               72  92  95  98 112 100 103  99 ];

    % Scale factor used in the reconstruction step
    if (Q <= 50)
        qt_scale = 50 / Q;
    else
        qt_scale = 2 - Q / 50;
    end

    % Initialize the DCT coefficients matrix
    Yq = zeros(8, 8);

    % Set the DC coefficient
    Yq(1, 1) = dc_coeff;

    % Fill in the AC coefficients in zig-zag order
    idx = 1;  % Index for AC coefficients in the array
    direction = 1;  % Direction flag for zig-zag manner
    
    for kk = 3:16
        if (direction)
            for ll = max(1, kk-8):min(kk-1, 8)
                Yq(min(8, ll), kk - min(8, ll)) = ac_coeff(idx) * (Qtable(min(8, ll), kk - min(8, ll)) * qt_scale);
                idx = idx + 1;
            end
        else
            for ll = max(1, kk-8):min(kk-1, 8)
                Yq(kk - min(8, ll), min(8, ll) ) = ac_coeff(idx) * (Qtable(min(8, ll), kk - min(8, ll)) * qt_scale);
                idx = idx + 1;
            end
        end
        direction = 1 - direction;
    end

    % Perform the Inverse DCT
    tile = idct(Yq);

    % Center the data to restore to 0-255 range
    tile = uint8(tile + 128);
    
    % Ensure values are within the valid grayscale range
    tile(tile < 0) = 0;
    tile(tile > 255) = 255;
end