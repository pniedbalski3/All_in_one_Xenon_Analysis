function newind = Halton_rand(ind,base)

    
    f = 1;
    newind = 0;
    
    while ind > 0 
        f = f/base;
        newind = newind + f*mod(ind,base);
        ind = floor(ind/base);
    end
    