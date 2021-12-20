[res1, opts] = load_and_run(0);

X = res1.features_norm;
% C = pca(X);

% Project X on PC space
[U,S,V] = svd(X);
Xproj = X * V;

varexp = diag(S).^2 / sum(diag(S).^2);

figure;
hold on
for i = 1:5
    plot(X(res1.idx == i, 1), X(res1.idx == i, 4), '.');
%     plot(Xproj(res1.idx == i,1), Xproj(res1.idx == i,2), '.');
end


%%
X = randn(1000, 2);
X2 = X * [3 0; 0 1] * [cosd(30) sind(30); -sind(30) cosd(30)];

%%
[u,s,v] = svd(X2);