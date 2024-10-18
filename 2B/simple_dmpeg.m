function new_image = simple_dmpeg(huff_encoded, previous_image, Q)

  if (nargin < 3)
      Q = 80;
  end
  
  % Decode the Huffman encoded JPEG coefficients
  huff_decoded = Huff06(double(huff_encoded));
  
  % Dimensions of the image
  [rows, cols] = size(previous_image);
  block_size = 8; % Size of the 8x8 blocks
  num_blocks_row = rows / block_size;
  num_blocks_col = cols / block_size;
  
  % Initialize the new image with the previous image
  new_image = previous_image;
  
  % Reshape the coefficients
  dc_coeffs = reshape(huff_decoded{1}, [num_blocks_row, num_blocks_col]);
  ac_coeffs = reshape(huff_decoded{2}, [63, num_blocks_row * num_blocks_col]);
  
  % Iterate through each block (8x8)
  for i = 1:num_blocks_row
      for j = 1:num_blocks_col
          tile_num = (i - 1) * num_blocks_col + j; % Calculate the tile number
  
          % Retrieve the DC and AC coefficients for the current block
          dc = dc_coeffs(i, j);
          ac = ac_coeffs(:, tile_num);
          
          % Determine if the block needs updating
          if any(ac) || dc ~= 0 % This block should be updated if there are non-zero AC or a non-zero DC coefficient
              % Decompress the coefficients to get the difference block
              diff_block = decompress_block(dc, ac, Q); 
  
              % Extract the corresponding block from the previous image
              prev_block = previous_image((i-1)*block_size+1:i*block_size, (j-1)*block_size+1:j*block_size);
              
              % Add the difference to the previous block
              new_block = prev_block + diff_block;
              
              % Place the new block into the correct position in the new image
              new_image((i-1)*block_size+1:i*block_size, (j-1)*block_size+1:j*block_size) = new_block;
          end
          % If all AC and DC terms are zero, we keep the previous image data for this block
      end
  end
  
  % Enforce uint8 format and valid range
  new_image = uint8(max(0, min(255, new_image)));
  
  end
  
  function block = decompress_block(dc, ac, Q)
  % This function reconstructs the 8x8 block from the DC and AC coefficients
  % Using the inverse DCT (Discrete Cosine Transform). The quality factor Q also affects the reconstruction.
  
  % Initialize the block with zeros
  block = zeros(8, 8);
  
  % Create the zigzag order for the 8x8 coefficients
  zigzag_order = [
      1, 2, 6, 7, 15, 16, 28, 29;
      3, 5, 8, 14, 17, 27, 30, 43;
      4, 9, 13, 18, 26, 31, 42, 44;
      10, 12, 19, 25, 32, 41, 45, 54;
      11, 20, 24, 33, 40, 46, 53, 55;
      21, 23, 34, 39, 47, 52, 56, 61;
      22, 35, 38, 48, 51, 57, 60, 62;
      36, 37, 49, 50, 58, 59, 63, 64
  ];
  
  % Insert DC value
  block(1) = dc;
  
  % Insert AC values into the block using the zigzag pattern
  for k = 1:length(ac)
      if ac(k) ~= 0
          [row, col] = find(zigzag_order == k + 1);
          block(row, col) = ac(k);
      end
  end
  
  % Perform the inverse quantization (multiply by the quantization matrix)
  quantization_matrix = jpeg_quantization_matrix(Q);
  block = block .* quantization_matrix;
  
  % Perform the inverse DCT to get the 8x8 pixel values
  block = idct2(block);
  
  end
  
  function qm = jpeg_quantization_matrix(Q)
  % Generate the quantization matrix based on the quality factor Q
  if Q < 50
      S = 5000 / Q;
  else
      S = 200 - 2 * Q;
  end
  
  qm = [
      16  11  10  16  24  40  51  61;
      12  12  14  19  26  58  60  55;
      14  13  16  24  40  57  69  56;
      14  17  22  29  51  87  80  62;
      18  22  37  56  68 109 103  77;
      24  35  55  64  81 104 113  92;
      49  64  78  87 103 121 120 101;
      72  92  95  98 112 100 103  99
  ];
  
  qm = min(max(round(qm * S / 100), 1), 255);
  end