function out = DCT(input) 
    input = double(input);
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
            sum = 0;
            for i = 0:7
                for j = 0:7
                    sum = sum + input(i+1, j+1)*cos((i+0.5)*pi*u/8)*cos((j+0.5)*pi*v/8);
                end
            end
            output(u+1, v+1) = cU*cV*sum;
        end
    end
    out = output;
end