function h = OTF( m, n, off_x, off_y, fc )
h=zeros(m,n);
for k=1:m
    for l=1:n
        q = sqrt((k-m/2-1-off_y)^2+(l-n/2-1-off_x)^2);
        if q>fc
            h(k,l)=0;
        else
            b = acos( q/fc );
            h(k,l)=(2*b-sin(2*b))/pi;
            %h(k,l)=1;
        end
    end
end
return