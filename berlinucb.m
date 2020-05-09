% Author: Baihan Lin (doerlbh@gmail.com)
% Date: Jan 2020

function result = berlinucb(data,opts)

ucb_alpha = 0.1;
A = {};
b = {};

if opts.oracle == 1
    nArms = opts.nOptions;
    labls = [];
    labln = [];
    for i = 1:nArms
        A{i} = eye(data.dim);
        b{i} = zeros(data.dim,1);
    end
else
    nArms = 1; % 1 for the new arm
    labls = ['new'];
    labln = [1];
    A{1} = eye(data.dim);
    b{1} = zeros(data.dim,1);
end

y = data.y;
y_true = data.full_y;
x = data.rec;

rew = 0;
r = [];
a = [];

for t = 1:data.t
    disp(strcat('berlinucb - ',num2str(t)))
    
    feat = x(:,t)';
    labl = y(t);
    labl_true = y_true(t);
    
    stillWrong = 0;
    stillCorrect = 0;
    
    ps = [];
    for i = 1:nArms
        theta = A{i}\b{i};
        p = theta'*feat'+ucb_alpha*sqrt(feat*(A{i}\feat'));
        ps = [ps, p];
    end
    
    [sps,scores] = sort(-ps);
    pred = scores(1);
    
    if opts.oracle == 1
        if ~any(labln == pred)
            if labl ~= "-1" && (isempty(labls) || ~any(labls == labl))
                labls = [labls;labl];
                labln = [labln;length(labls)];
                pred = length(labls);
            else
                stillWrong = 1;
            end
        else
            if labl ~= "-1" && (isempty(labls) || ~any(labls == labl))
                labls = [labls;labl];
                labln = [labln;length(labls)];
            end
        end
    else
        if ~any(labls == labl) && labl ~= "-1"
            nArms = nArms + 1;
            labls = [labls;labl];
            labln = [labln;nArms];
            A{nArms} = eye(data.dim);
            b{nArms} = zeros(data.dim,1);
            if pred == 1
                stillCorrect = 1;
            end
        end
    end
    
    if ~stillWrong && (stillCorrect || labls(labln == pred) == labl_true)
        rew = rew + 1;
    end
    
    r = [r;rew];
    acc = rew / t;
    a = [a;acc];
    
    if labl ~= "-1" && any(labln == pred) && labls(labln == pred) == labl
        rt = 1;
    else
        rt = 0;
    end
    A{pred} = A{pred} + feat'*feat;
    b{pred} = b{pred} + rt*feat';
    
    
end
acc = rew / data.t;

result.acc = acc;
result.rew = rew;
result.a = a;
result.r = r;

end