function [ cpat] = makeRandchecker( checkercolor,checkersize,ncheckers,radius, seed, numFrames)
% generate a random checker pattern from binary distribution with alpha
% channels
diat=2;
sz=floor(checkersize/diat)*ncheckers;
cpat=ones(sz,sz);
% cpat=cat(3,ones(sz,sz,1), zeros(sz,sz,1));
center=[floor(sz/2) floor(sz/2)];

s = RandStream('mt19937ar','Seed',seed);
RandStream.setGlobalStream(s);
pattern=randi(s,[0 1],ncheckers,ncheckers,numFrames)*checkercolor;

for x=1:sz
    for y=1:sz
        if sqrt((x-center(1))^2+(y-center(2))^2)>=radius/diat
            cpat(x,y)=0;
        end
    end
end
cpat=repmat(cpat,1,1,numFrames);

for k=1: numFrames
    for i=1:ncheckers
        for j=1:ncheckers
            cpat((i-1)*floor(checkersize/diat)+1:i*floor(checkersize/diat),(j-1)*floor(checkersize/diat)+1:j*floor(checkersize/diat),k)= ...,
                cpat((i-1)*floor(checkersize/diat)+1:i*floor(checkersize/diat),(j-1)*floor(checkersize/diat)+1:j*floor(checkersize/diat))*pattern(i,j,k);
        end
    end
end
