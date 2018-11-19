function out = quantize(in, type)
    global lumMat;
    global chromMat;
    if strcmp(type, 'lum')
        for i = 1:8
            for j = 1:8
                % output(i,j) = floor(double(in(i,j))./lumMat(i,j)).*lumMat(i,j);
                output(i,j) = round(in(i,j)/lumMat(i,j));
            end
        end
    elseif strcmp(type, 'chrom')
        for i = 1:8
            for j = 1:8
                % output(i,j) = floor(double(in(i,j))./chromMat(i,j)).*chromMat(i,j);
                output(i,j) = round(in(i, j)/chromMat(i,j));
            end
        end
    end     
    out = output;
end