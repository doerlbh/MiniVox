% Author: Baihan Lin (doerlbh@gmail.com)
% Date: Jan 2020

function data = minivox(opts)


idlist = 'idlist.txt';
wavlist = 'wavlist.txt';

FID = fopen(fullfile(opts.dataDir,idlist));
tID = textscan(FID,'%s');
fclose(FID);
idL = string(tID{:});

if length(idL) < opts.nOptions
    opts.nOptions = length(idL);
end

ids = string(datasample(idL,opts.nOptions,'Replace',false));

rcs = [];
ycs = [];
for i = 1:length(ids)
%     disp(fullfile(opts.dataDir,ids(i),wavlist))
    FID = fopen(string(fullfile(opts.dataDir,ids(i),wavlist)));
    tID = textscan(FID,'%s');
    fclose(FID);
    rcs = [rcs; ids(i)+'/'+string(tID{:})];
    for t = 1:length(string(tID{:}))
        ycs = [ycs; ids(i)];
    end
end

[pcs,idx] = datasample(rcs,opts.nPiece,'Replace',false);
pcy = ycs(idx);

mfcc = [];
ymfcc = [];
for j = 1:length(pcs)
    pc = pcs(j);
    
    inpPath = fullfile(opts.dataDir,pc);
    %     disp(inpPath);
    
    % Load or download the VGGVox model for Verification
    modelName = 'vggvox_ver_net.mat' ;
    paths = {opts.modelPath, ...
        modelName, ...
        fullfile(vl_rootnn, 'data', 'models-import', modelName)} ;
    ok = find(cellfun(@(x) exist(x, 'file'), paths), 1) ;
    
    if isempty(ok)
        fprintf('Downloading the VGGVox model for Verification ... this may take a while\n') ;
        opts.modelPath = fullfile(vl_rootnn, 'data/models-import', modelName) ;
        mkdir(fileparts(opts.modelPath)) ; base = 'http://www.robots.ox.ac.uk' ;
        url = sprintf('%s/~vgg/data/voxceleb/models/%s', base, modelName) ;
        urlwrite(url, opts.modelPath) ;
    else
        opts.modelPath = paths{ok} ;
    end
    load(opts.modelPath); net = dagnn.DagNN.loadobj(netStruct);
    
    % Remove loss layers and add distance layer
    names = {'loss'} ;
    for i = 1:numel(names)
        layer = net.layers(net.getLayerIndex(names{i})) ;
        net.removeLayer(names{i}) ;
        net.renameVar(layer.outputs{1}, layer.inputs{1}, 'quiet', true) ;
    end
    net.addLayer('dist', dagnn.PDist('p',2), {'x1_s1', 'x1_s2'}, 'distance');
    
    % Evaluate network on GPU and set up network to be in test mode
    % net.move('gpu');
    net.conserveMemory = 0;
    net.mode = 'test' ;
    
    % Setup buckets
    buckets.pool 	= [2 5 8 11 14 17 20 23 27 30];
    buckets.width 	= [100 200 300 400 500 600 700 800 900 1000];
    
    % Load input pair and do a forward pass
    inp = getmfcc(inpPath, net.meta, buckets);
    
    mfcc = [mfcc, inp];
    for t = 1:size(inp,2)
        ymfcc = [ymfcc; pcy(j)];
    end
end

if opts.useNN == 0
    rec = mfcc;
    y = ymfcc;
else
    s_full = size(mfcc,2);
    sw = 500;
    
    rec = [];
    y = [];
    for t = 1:s_full-sw
        disp(t)
        
        seg1 = mfcc(:,t:t+500-1);
        seg2 = mfcc(:,t+1:t+500);
        
        yseg = ymfcc(t:t+500-1);
        
        s1 = sw;
        s2 = sw;
        
        p1 = buckets.pool(s1==buckets.width);
        p2 = buckets.pool(s2==buckets.width);
        
        net.layers(22).block.poolSize=[1 p1];
        net.layers(47).block.poolSize=[1 p2];
        % net.eval({ 'input_b1', gpuArray(inp1) ,'input_b2', gpuArray(inp2) });
        net.eval({ 'input_b1', seg1,'input_b2', seg2 });
        
        %         featid = structfind(net.vars,'name','distance');
        %         dist = gather(squeeze(net.vars(featid).value));
        
        featid1 = structfind(net.vars,'name','x1_s1');
        feat1 = gather(squeeze(net.vars(featid1).value));
        %         featid2 = structfind(net.vars,'name','x1_s2');
        %         feat2 = gather(squeeze(net.vars(featid2).value));
        
        rec = [rec, feat1];
        y = [y; string(mode(categorical(yseg)))];
    end
end

y_epi = y;
if opts.epiReward ~= 1
    yidx = randperm(length(y));
    yidx = yidx(1:floor(length(y)*(1-opts.epiReward)));
    y_epi(yidx) = -1;
end

data.rec = rec;
data.dim = size(rec,1);
data.dim = size(rec,1);
data.t = size(rec,2);
data.full_y = y;
data.y = y_epi;

end