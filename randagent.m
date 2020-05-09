% Author: Baihan Lin (doerlbh@gmail.com)
% Date: Jan 2020

function result = randagent(data,opts)

if opts.oracle == 1
    nArms = opts.nOptions;
    labls = [];
    labln = [];
else
    nArms = 1; % 1 for the new arm
    labls = ['new'];
    labln = [1];
end

y = data.y;
y_true = data.full_y;
x = data.rec;

rew = 0;
r = [];
a = [];

for t = 1:data.t
    disp(strcat('random - ',num2str(t)))

    feat = x(:,t)';
    labl = y(t);
    labl_true = y_true(t);

    stillWrong = 0;
    stillCorrect = 0;
    
    scores = randperm(nArms);
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
    
end
acc = rew / data.t;

result.acc = acc;
result.rew = rew;
result.a = a;
result.r = r;

end