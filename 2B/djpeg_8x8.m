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
    % Quantisation table used to dequantise DCT coeffs
    Qtable = [
        16  11  10  16  24  40  51  61;
        12  12  14  19  26  58  60  55;
        14  13  16  24  40  57  69  56;
        14  17  22  29  51  87  80  62;
        18  22  37  56  68 109 103  77;
        24  35  55  64  81 104 113  92;
        49  64  78  87 103 121 120 101;
        72  92  95  98 112 100 103  99
    ];

    % Q scale factor used in dequantisation step
    if (Q <= 50)
        qt_scale = 50/Q;
    else
        qt_scale = 2 - Q/50;
    end

    % Initialize Yq matrix with zeros
    Yq = zeros(8, 8);

    % Set DC coefficient
    Yq(1,1) = dc_coeff;

    % Reverse zig-zag to fill Yq with AC coefficients
    ac_count = 1;
    direction = 1;
    for kk = 3:16
        if (direction)
            for ll = max(1,kk-8):min(kk-1,8)
                Yq(min(8,ll), kk-min(8,ll)) = ac_coeff(ac_count);
                ac_count = ac_count + 1;
            end
        else
            for ll = max(1,kk-8):min(kk-1,8)
                Yq(kk-min(8,ll), min(8,ll)) = ac_coeff(ac_count);
                ac_count = ac_count + 1;
            end
        end
        direction = 1 - direction;
    end

    % Dequantise coefficients
    Y = Yq .* (Qtable * qt_scale);

    % Inverse DCT
    tile = idct(Y);

    % Add back 128 to shift the range back to 0-255
    tile = tile + 128;

    % Ensure pixel values are within 0-255 range
    tile = max(0, min(255, tile));

    % Convert to uint8
    tile = uint8(round(tile));
end