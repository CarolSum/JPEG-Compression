clear, clc;
quality = 10;
inputName = '动物卡通图片.jpg';
outputName = 'outputCartoon.jpg';
CELL_SIZE = 8;

global dc_luminance_nrcodes;
dc_luminance_nrcodes=[0 0 1 5 1 1 1 1 1 1 0 0 0 0 0 0 0];

global dc_luminance_values;
dc_luminance_values=[0 1 2 3 4 5 6 7 8 9 10 11];

global dc_chrominance_nrcodes;
dc_chrominance_nrcodes=[1 0 3 1 1 1 1 1 1 1 1 1 0 0 0 0 0];

global dc_chrominance_values;
dc_chrominance_values=[0 1 2 3 4 5 6 7 8 9 10 11];

global ac_luminance_nrcodes;
ac_luminance_nrcodes=[16 0 2 1 3 3 2 4 3 5 5 4 4 0 0 1 125];

global ac_luminance_values;
ac_luminance_values = [
      1 2 3 0 4 17 5 18 33 49 65 6 19 81 97 7 ...
      34 113 20 50 129 145 161 8 35 66 177 193 ...
      21 82 209 240 36 51 98 114 130 9 10 22 23 ...
      24 25 26 37 38 39 40 41 42 52 53 54 55 56 ...
      57 58 67 68 69 70 71 72 73 74 83 84 85 86 87 ...
      88 89 90 99 100 101 102 103 104 105 106 115 ...
      116 117 118 119 120 121 122 131 132 133 134 ...
      135 136 137 138 146 147 148 149 150 151 152 ...
      153 154 162 163 164 165 166 167 168 169 170 ...
      178 179 180 181 182 183 184 185 186 194 195 ...
      196 197 198 199 200 201 202 210 211 212 213 ...
      214 215 216 217 218 225 226 227 228 229 230 ...
      231 232 233 234 241 242 243 244 245 246 247 248 249 250 ];

global ac_chrominance_nrcodes;  
ac_chrominance_nrcodes=[17 0 2 1 2 4 4 3 4 7 5 4 4 0 1 2 119];

global ac_chrominance_values;
ac_chrominance_values = [
      0 1 2 3 17 4 5 33 49 6 18 65 81 7 97 ...
      113 19 34 50 129 8 20 66 145 161 177 ...
      193 9 35 51 82 240 21 98 114 209 10 22 ...
      36 52 225 37 241 23 24 25 26 38 39 40 ...
      41 42 53 54 55 56 57 58 67 68 69 70 71 ...
      72 73 74 83 84 85 86 87 88 89 90 99 100 ...
      101 102 103 104 105 106 115 116 117 118 ...
      119 120 121 122 130 131 132 133 134 135 ...
      136 137 138 146 147 148 149 150 151 152 ...
      153 154 162 163 164 165 166 167 168 169 ...
      170 178 179 180 181 182 183 184 185 186 ...
      194 195 196 197 198 199 200 201 202 210 ...
      211 212 213 214 215 216 217 218 226 227 ...
      228 229 230 231 232 233 234 242 243 244 ...
      245 246 247 248 249 250];

global DC_matrix;
global AC_matrix;

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
     
global bufferPutBits;
bufferPutBits = 0;

global bufferPutBuffer;
bufferPutBuffer = 0;
        
% jpeg encoder
img = imread(inputName);
[H, W, D] = size(img);
fid = fopen(outputName, 'w');

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
% ycbcr_img = rgb2ycbcr(imgExt);
ycbcr_img = myRGB2YCbCr(imgExt);
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

% 初始化哈夫曼编码表
initHuffman();
fprintf("完成初始化哈夫曼编码表\n");

% 执行huffman编码
global prevDC;
prevDC(1) = 0;
prevDC(2) = 0;
prevDC(3) = 0;
for i=1:cellNumsH
    for j=1:cellNumsH
        SubImageY{i, j} = huffman(fid, SubImageY{i, j}, 1,1,1);

        SubImageCb{i, j} = huffman(fid, SubImageCb{i, j},2,2,2);
        
        SubImageCr{i, j} = huffman(fid, SubImageCr{i, j},3,2,2);

    end
end
disp(SubImageY{1,1});
fclose(fid);

% disp(SubImageY{1,1});
% SubImageY{1,1} = zigzag(SubImageY{1,1});
% disp(SubImageY{1,1});

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
% sy = dequantize(sy, 'lum');
% disp(sy);
% sy = round(IDCT(sy));
% disp(sy);


% jpeg decoder
for i=1:cellNumsH
    for j=1:cellNumsH
        % 反量化量化
        SubImageY{i, j} = dequantize(SubImageY{i, j}, 'lum');
        % 逆DCT变换
        SubImageY{i, j} = IDCT(SubImageY{i, j});
        
        SubImageCb{i, j} = dequantize(SubImageCb{i, j}, 'chrom');
        SubImageCb{i, j} = IDCT(SubImageCb{i, j});
        
        SubImageCr{i, j} = dequantize(SubImageCr{i, j}, 'chrom');
        SubImageCr{i, j} = IDCT(SubImageCr{i, j});
    end
end

y_compressed_img = cell2mat(SubImageY);
cb_compressed_img = cell2mat(SubImageCb);
cr_compressed_img = cell2mat(SubImageCr);
decompressed_img = ycbcr_img;
decompressed_img(:, :, 1) = y_compressed_img;
decompressed_img(:, :, 2) = cb_compressed_img;
decompressed_img(:, :, 3) = cr_compressed_img; 

% YCbCr转为rgb
% decompressed_img = ycbcr2rgb(decompressed_img);
decompressed_img = myYCbCr2RGB(decompressed_img);

% 将结果转换为uint8格式
decompressed_img = uint8(decompressed_img(1:H,1:W, :));

% figure;
% subplot(2,2,1),imshow(img);title('animal.jpg');
% subplot(2,2,2),imshow(decompressed_img);title('压缩处理后的animal');
figure;imshow(img);
figure;imshow(decompressed_img);
imwrite(decompressed_img, outputName, 'jpg');

% array: 8*8小块
% prevId: 属于哪个分量的DC组
% DCcode: 1表示DC采用亮度编码；2表示DC采用色度编码
% ACcode: 1表示AC采用亮度编码；2表示AC采用色度编码
function out = huffman(fid, array, prevId, DCcode, ACcode)

    global zigZagOrder;
    global DC_matrix;
    global AC_matrix;
    global prevDC;
    % array = uint8(array);
    % The DC portion
    % DPCM编码
    curDC = array(1) - prevDC(prevId);
    temp = curDC;
    if temp < 0
        temp = -temp;
        curDC = curDC - 1;
    end
    % 求出DC值的索引,即2进制位数
    nbits = 0;
    while temp ~= 0
        nbits = nbits + 1;
        temp = bitshift(temp, -1);
    end
    % 写入SIZE编码
    % bufferIt(fid, DC_matrix(DCcode, nbits+1, 1), DC_matrix(DCcode, nbits+1, 2));
    fprintf(fid, "%x", DC_matrix(DCcode, nbits+1, 1));
    % 写入值
    if nbits ~= 0
        fprintf(fid, "%x", curDC);
        % bufferIt(fid, curDC, nbits);
    end
    
    % The AC portion
    r = 0;
    for k = 2:64 
        % zigzag扫描
        temp = array(zigZagOrder(k));
        if temp == 0
            r=r+1;
        else
            while r > 15 
                % 超过16个0 写入(15, 0)
                fprintf(fid, "%x", AC_matrix(ACcode, hex2dec('F0')+1, 1));
                % bufferIt(fid, AC_matrix(ACcode, hex2dec('F0')+1, 1), AC_matrix(ACcode, hex2dec('F0')+1, 2));
                r = r - 16;
            end
            temp2 = temp;
            if temp < 0
                temp = -temp;
                temp2 = temp2 - 1;
            end
            nbits = 1;
            temp = bitshift(temp, -1);
            while temp ~= 0
                nbits = nbits + 1;
                temp = bitshift(temp, -1);
            end
            % symbol1: RunLength + Size
            i = bitshift(r, 4) + nbits;
            % 写入symbol1的编码结果
            fprintf(fid, "%x", AC_matrix(ACcode, i+1, 1));
            % bufferIt(fid, AC_matrix(ACcode, i+1, 1), AC_matrix(ACcode, i+1, 2));
            % 写入值
            fprintf(fid, "%x",temp2);
            % bufferIt(fid, temp2, nbits);
            r = 0;
        end
    end

    % 写入EOB(0,0)
    if r > 0
        fprintf(fid, "%x",AC_matrix(ACcode, 1, 1));
        % bufferIt(fid, AC_matrix(ACcode, 1, 1), AC_matrix(ACcode, 1, 2));
    end
    
%     array = zigzag(array);
    out = array;
end


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

% 反量化
function out = dequantize(in, type)
    global lumMat;
    global chromMat;
    if strcmp(type, 'lum')
        for i = 1:8
            for j = 1:8
                % output(i,j) = floor(double(in(i,j))./lumMat(i,j)).*lumMat(i,j);
                output(i,j) = in(i,j)*lumMat(i,j);
            end
        end
    elseif strcmp(type, 'chrom')
        for i = 1:8
            for j = 1:8
                % output(i,j) = floor(double(in(i,j))./chromMat(i,j)).*chromMat(i,j);
                output(i,j) = in(i, j)*chromMat(i,j);
            end
        end
    end     
    out = output;
end

% 逆DCT
function out = IDCT(input) 
    input = double(input);
    for i = 0:7
        for j = 0:7
            sum = 0;
            for u = 0:7
                for v = 0:7
                    if u ==0
                        cU = 1/sqrt(8);
                    else
                        cU = 0.5;
                    end
                    if v ==0
                        cV = 1/sqrt(8);
                    else
                        cV = 0.5;
                    end
                    sum = sum + cU*cV*input(u+1, v+1)*cos((i+0.5)*pi*u/8)*cos((j+0.5)*pi*v/8);
                end
            end
            output(i+1, j+1) = sum;
        end
    end
    out = output;
end

function out = myRGB2YCbCr(input)
    input = double(input);
    R = input(:,:,1);
    G = input(:,:,2);
    B = input(:,:,3);
    output(:,:,1) = 0.299*R+0.5870*G+0.144*B;
    output(:,:,2) = 128-0.1687*R-0.3313*G+0.5*B;
    output(:,:,3) = 128+0.5*R-0.4187*G-0.0813*B;
    out = output;
end

function out = myYCbCr2RGB(input)
    Y = input(:,:,1);
    Cb = input(:,:,2);
    Cr = input(:,:,3);
    output(:,:,1) = Y+1.402*(Cr-128);
    output(:,:,2) = Y-0.34414*(Cb-128)-0.71414*(Cr-128);
    output(:,:,3) = Y+1.772*(Cb-128);
    out = output;
end

function initHuffman()
    global dc_chrominance_nrcodes;
    global dc_chrominance_values;
    global ac_chrominance_nrcodes;
    global ac_chrominance_values;
    global dc_luminance_nrcodes;
    global dc_luminance_values;
    global ac_luminance_nrcodes;
    global ac_luminance_values;
    global DC_matrix;
    global AC_matrix;
    
    
    %------------
    p = 0;
    for l = 1:16
        for i = 1:dc_chrominance_nrcodes(l+1)
            huffsize(p+1) = l;
            p = p + 1;
        end
    end

    huffsize(p+1) = 0;
    lastp = p;

    code = 0;
    si = huffsize(0+1);
    p = 0;
    while huffsize(p+1) ~= 0
        while huffsize(p+1) == si                
            huffcode(p+1) = code;
            p = p + 1;
            code = code + 1;
        end
        code = bitshift(code, 1);
        si = si + 1;
    end

    for p = 0:lastp-1
        DC_matrix1(dc_chrominance_values(p+1)+1, 0+1) = huffcode(p+1);
        DC_matrix1(dc_chrominance_values(p+1)+1, 1+1) = huffsize(p+1);
    end

    %--------------
    p = 0;
    for l = 1:16
        for i = 1:ac_chrominance_nrcodes(l+1)
            huffsize(p+1) = l;
            p=p+1;
        end
    end
    huffsize(p+1) = 0;
    lastp = p;

    code = 0;
    si = huffsize(0+1);
    p = 0;
    while huffsize(p+1) ~= 0
        while huffsize(p+1) == si
            huffcode(p+1) = code;
            p=p+1;
            code=code+1;
        end
        code = bitshift(code, 1);
        si=si+1;
    end 

    for p = 0:lastp-1
        AC_matrix1(ac_chrominance_values(p+1)+1, 0+1) = huffcode(p+1);
        AC_matrix1(ac_chrominance_values(p+1)+1, 1+1) = huffsize(p+1);
    end

    %--------
    p = 0;
    for l = 1:16
        for i = 1:dc_luminance_nrcodes(l+1)
            huffsize(p+1) = l;
            p = p + 1;
        end
    end
    huffsize(p+1) = 0;
    lastp = p;

    code = 0;
    si = huffsize(0+1);
    p = 0;
    while huffsize(p+1) ~= 0
        while huffsize(p+1) == si
            huffcode(p+1) = code;
            p = p + 1;
            code = code + 1;
        end
        code  = bitshift(code, 1);
        si = si + 1;
    end

    for p = 0:lastp-1
        DC_matrix0(dc_luminance_values(p+1)+1, 0+1) = huffcode(p+1);
        DC_matrix0(dc_luminance_values(p+1)+1, 1+1) = huffsize(p+1);
    end


    %-----------
    p = 0;
    for l = 1:16
        for i = 1:ac_luminance_nrcodes(l+1)
            huffsize(p+1) = l;
            p = p + 1;
        end
    end
    huffsize(p+1) = 0;
    lastp = p;

    code = 0;
    si = huffsize(0+1);
    p = 0;
    while huffsize(p+1) ~= 0
        while huffsize(p+1) == si
            huffcode(p+1) = code;
            p = p + 1;
            code = code+1;
        end
        code = bitshift(code, 1);
        si = si + 1;
    end
    for q = 0:lastp-1
        AC_matrix0(ac_luminance_values(q+1)+1, 0+1) = huffcode(q+1);
        AC_matrix0(ac_luminance_values(q+1)+1, 1+1) = huffsize(q+1);
    end

    DC_matrix(0+1, :, :) = DC_matrix0;
    DC_matrix(1+1, :, :) = DC_matrix1;
    AC_matrix(0+1, :, :) = AC_matrix0;
    AC_matrix(1+1, :, :) = AC_matrix1;
end

% DPCM

% RLC

% Huffman Encoding (Coding Tables)

