function new_image = simple_dmpeg(huff_encoded, previous_image, Q)

  if (nargin < 3)
      Q = 80;
  end
  
  % Decode the Huffman encoded jpeg coefficients
  huff_decoded = Huff06(double(huff_encoded));
  dc_coeffs = reshape(huff_decoded{1}, floor(size(previous_image) / 8));
  ac_coeffs = reshape(huff_decoded{2}, [63, prod(floor(size(previous_image) / 8))]);
  
  % By default, the new output image is initialized as the previous image
  new_image = previous_image;
  
  tile_num = 0;
  % Process each 8x8 block of the image
  for ii = 1:8:size(previous_image, 1)
      for jj = 1:8:size(previous_image, 2)
          tile_num = tile_num + 1;
  
          % Retrieve DC and AC coefficients for this block
          dc_iijj = dc_coeffs((ii-1)/8 + 1, (jj-1)/8 + 1);
          ac_iijj = ac_coeffs(:, tile_num);
  
          % Check if the block needs to be updated (non-zero coefficients)
          if dc_iijj ~= 0 || any(ac_iijj ~= 0)
              % Block needs updating, so decompress the block
              decompressed_tile = djpeg_8x8(dc_iijj, ac_iijj, Q);

              % figure;
              % imshow(uint8(decompressed_tile));
              % title(['Tile number: ', num2str(tile_num)]);
              % pause(0.5);

              % Replace the corresponding 8x8 block in the new image
              new_image(ii:ii+7, jj:jj+7) = decompressed_tile;
          end
          % Else, do nothing - the block remains unchanged from previous_image
      end
  end
  
  % Enforce uint8 format
  new_image = uint8(new_image);
  
  return
  
  end