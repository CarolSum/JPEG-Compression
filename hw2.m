clear, clc;
quality = 10;
inputName = 'animal.jpg';
outputName = 'outputAnimal.jpg';
CELL_SIZE = 8;

% 标准亮度量化表
global lumMat;  
lumMat = [
             16 11 10 16 24 40 51 61;
             12 12 14 19 26 58 60 55;
             14 13 16 24 40 57 69 56;
             14 17 22 29 51 87 80 62;
             18 22 37 56 68 109 103 77;
             24 35 55 64 81 104 113 92 ;
             49 64 78 87 103 121 120 101;
             72 92 95 98 112 100 103 99];
         
% 标准色差量化表
global chromMat;
chromMat = [
         17 18 24 47 99 99 99 99;
         18 21 26 66 99 99 99 99;
         24 26 56 99 99 99 99 99;
         47 66 99 99 99 99 99 99;
         99 99 99 99 99 99 99 99;
         99 99 99 99 99 99 99 99;
         99 99 99 99 99 99 99 99;
         99 99 99 99 99 99 99 99];

% ZigZag扫描顺序
global zigZagOrder;
zigZagOrder = [ 1 2 9 17 10 3 4 11;
            18 25 33 26 19 12 5 6;
            13 20 27 34 41 49 42 35;
            28 21 14 7 8 15 22 29;
            36 43 50 57 58 51 44 37;
            30 23 16 24 31 38 45 52;
            59 60 53 46 39 32 40 47;
            54 61 62 55 48 56 63 64];
     
% jpeg encoder
img = imread(inputName);
[H, W, D] = size(img);
remainderH = mod(H,8);
remainderW = mod(W,8);
% 如果图像尺寸不是8的倍数，则需要补齐
if remainderH == 0
    paddingH = H;
else
    paddingH = H+(8-mod(H,8));
end
if remainderW == 0
    paddingW = W;
else
    paddingW = W+(8-mod(W,8));
end
imgExt = zeros(paddingH, paddingW, 3);
imgExt(1:H,1:W, :) = img;


% 色彩空间转换 RGB -> YCbCr
ycbcr_img = rgb2ycbcr(imgExt);
imageY = ycbcr_img(:, :, 1);    % Y分量
imageCb = ycbcr_img(:, :, 2);   % Cb分量
imageCr = ycbcr_img(:, :, 3);   % Cr分量

% Image Split 将各个分量图像分成8*8小块
cellNumsH = size(imageY, 1)/CELL_SIZE;
cellNumsW = size(imageY, 2)/CELL_SIZE;

repeat_height_mat = repmat(CELL_SIZE, [1 cellNumsH]);
repeat_width_mat = repmat(CELL_SIZE, [1 cellNumsW]);

SubImageY = mat2cell(imageY, repeat_height_mat, repeat_width_mat);
SubImageCb = mat2cell(imageCb, repeat_height_mat, repeat_width_mat);
SubImageCr = mat2cell(imageCr, repeat_height_mat, repeat_width_mat);

disp(SubImageY{1,1});


for i=1:cellNumsH
    for j=1:cellNumsH
        % DCT变换
        SubImageY{i, j} = DCT(SubImageY{i, j});
        % Quantization 量化
        SubImageY{i, j} = quantize(SubImageY{i, j}, 'lum');
        
        SubImageCb{i, j} = DCT(SubImageCb{i, j});
        SubImageCb{i, j} = quantize(SubImageCb{i, j}, 'chrom');
        
        SubImageCr{i, j} = DCT(SubImageCr{i, j});
        SubImageCr{i, j} = quantize(SubImageCr{i, j}, 'chrom');
    end
end

disp(SubImageY{1,1});
SubImageY{1,1} = zigzag(SubImageY{1,1});
disp(SubImageY{1,1});

% 校正dct变换的值
% sy = [118  118  120  122  122  121  125  128;
%   117  118  120  122  123  123  128  132;
%   121  121  121  121  121  121  125  130;
%   124  123  120  118  116  117  122  126;
%   124  122  118  114  113  116  123  127;
%   130  127  122  117  114  117  124  128;
%   138  135  129  122  117  119  123  126;
%   141  138  133  125  120  121  124  126;]
% 
% sy = DCT(sy);
% disp(sy);
% sy = quantize(sy, 'lum');
% disp(sy);

% Zig Zag 扫描
function out = zigzag(input)
    global zigZagOrder;
    index = 1;
    for i = 1:8
        for j = 1:8
            temp = zigZagOrder(i,j);
            m = mod(temp, 8);
            if m == 0
                n = floor(temp/8);
                m = 8;
            else
                n = floor(temp/8)+1;
            end
            outputData(index) = input(n,m);
            index=index+1;
        end
    end
    out = outputData;
end
% DPCM

% RLC

% Huffman Encoding (Coding Tables)
