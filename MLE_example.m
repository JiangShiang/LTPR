clear


load('1');

p_vector = (0:0.2:1);

y = 7;

n = 10;

like = zeros(1,length(p_vector));

for i = 1:length(p_vector)
    p = p_vector(i);
    
    like(i) = nchoosek(n,y)*(p.^y).*((1-p).^(n-y));
        
end