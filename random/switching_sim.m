%% Simulate sigmoidal transition
tvals = 1:40;
prob = 1 ./ (1+exp(-(tvals-20) * 0.8));

%generate behavior
N = 20;
nums = rand(40, N);
choices = (nums' < prob) * 2 - 1;

targets = repmat(tvals > 10, [N 1]) * 2 - 1;
sides = repmat([-1 1], [1 N/2]);
targets = targets .* sides';
choices = choices .* sides';

fb = targets .* choices;

targetsflat = reshape(targets', [], 1);
fbflat = reshape(fb', [], 1);
rewflat = fbflat == 1;
unrflat = fbflat == -1;
choicesflat = reshape(choices', [], 1);

rewcflat = rewflat .* choicesflat;
unrcflat = unrflat .* choicesflat;

y = choicesflat(6:end);
c1 = choicesflat(5:end-1);
c2 = choicesflat(4:end-2);
c3 = choicesflat(3:end-3);
c4 = choicesflat(2:end-4);
c5 = choicesflat(1:end-5);
rc1 = rewcflat(5:end-1);
rc2 = rewcflat(4:end-2);
rc3 = rewcflat(3:end-3);
rc4 = rewcflat(2:end-4);
rc5 = rewcflat(1:end-5);

urc1 = unrcflat(5:end-1);
urc2 = unrcflat(4:end-2);
urc3 = unrcflat(3:end-3);
urc4 = unrcflat(2:end-4);
urc5 = unrcflat(1:end-5);


%logistic regression
y = (y > 0) + 1;
X = [rc1 rc2 rc3 rc4 rc5 urc1 urc2 urc3 urc4 urc5 c1 c2 c3 c4 c5];
b= mnrfit(X, y);

% plot(targetsflat)


