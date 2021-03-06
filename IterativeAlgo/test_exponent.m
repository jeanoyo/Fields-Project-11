%Tac simulated from Pablo model
datafulltac = dlmread('Data/TACs/pabloModel/0noise/fullTAC0sigma.tac', '\t', 1, 0);
datafulltac = datafulltac(end - 17:end, :);
% pdata = plasmafile
datarelev = datafulltac(:,[3 4 7 8 9 10]); %the 6 brain regions

n = size(datarelev,2);
k = 1; %counter
diff = zeros(18,6,6);
Cpint = zeros(18,6,6);
dim = n*(n-1)/2;
Cpintlist = zeros(18,dim); %same thing with Cpint but in 2-dim
%va = zeros(4,dim);      %the [a1i,a2i,a1j,a2j] in Fields

%ISA part

for i = 1:n
    cti = datarelev(:,i);
   
    intcti = cumtrapz(datafulltac(:,1),datarelev(:,i));
    
    %cpi = pdata(:,2);
    %cpi = cumtrapz(pdata(:,1),pdata(:,2));
    for j = i + 1:n
         ctj = datarelev(:,j);
         intctj = cumtrapz(datafulltac(:,1),datarelev(:,j));
         % find the right singular vector va corresponding to smallest
         % right singular value of c4
         c4 = [cti,intcti,ctj,intctj];
         [U,S,V] = svd(c4);
         %va(:,k) = V(:,end);
         
         %evaluate the first guesses of Cpint
         diff(:,i,j) = abs(V(1,end)*cti + V(2,end)*intcti + (V(3,end)*ctj + V(4,end)*intctj));
         Cpint(:,i,j) = abs(V(1,end))*cti +abs(V(2,end))*intcti;
         Cpintlist(:,k) = Cpint(:,i,j);
         k = k+1;
    end
    
    

       
end

%find one cpint which minimize the summation of distances
dist = zeros(1,dim);

for l = 1:dim
    for m = 1:dim
        disttemp = norm(Cpintlist(:,l)-Cpintlist(:,m));
        dist(l) = dist(l) + disttemp;
    end
end

[M,minl] = min(dist);
Cpint1 = Cpintlist(:,minl);
ISAresult = Cpint1(:);
va1 = zeros(2,n);
Cpint2 = zeros(18,n);
%%%%%begin the iterative algorithm part%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
max_err = 1;
err = 200;

while err > max_err
%regression to get new set of Vt and b
        for i = 1:n
            cti = datarelev(:,i);
            intcti = cumtrapz(datafulltac(:,1),datarelev(:,i));
            Cpint1lm = fitglm([cti,intcti],Cpint1,'linear');
            vatemp = Cpint1lm.Coefficients.Estimate;
            va1(:,i) = vatemp(2:end);
            Cpint2(:,i) = va1(1,i)*cti + va1(2,i)*intcti;
        end   

        %take averages to estimate the cpint in new iteration----no
        %va2 = [mean(va1(1,:)),mean(va1(2,:))];

        %find the distance in loop
        dist = zeros(1,n);

        for l = 1:n
            for m = 1:n
                disttemp = norm(Cpint2(:,l)-Cpint2(:,m));
                dist(l) = dist(l) + disttemp;
            end
        end

        [M,minl] = min(dist);
        err = norm(Cpint1 - Cpint2(:,minl));
        Cpint1 = Cpint2(:,minl);
        va1 = zeros(2,n);
        Cpint2 = zeros(18,n);
end

% Extraplolate
% Cpint1ep = interp1(times, Cpint1, ox, 'linear', 'extrap');

%%use Simulated Annealing to fit the CPint1%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
format short g;
times = datafulltac(:,1);

fity = @(b,x) b(1)*exp(-b(2)*x) + b(3)*exp(-b(4)*x)+b(5);

errors = zeros(1,2);
results = zeros(5,2); %the 4 can be changed 

phi1 = @(b) trapz((Cpint1 - fity(b,times)).^2);

tic;
results(:,1) = simulatedAnnealing(phi1,...
    [0.1 0.00001 0.1 0.00001 0], ...
    [-1e9 0 -1e9 0 -1e9], ...
    [1e9 0.05 1e9 0.05 1e9 ], 1000, 1e-7, 0.85);
disp(['Time elapsed in round ' num2str(1) ':']);
toc;

datap = dlmread('Data/Cps/pabloModel/pabloModel_0sigma.smpl', '\t', 1, 0);
otp = datap(:,1);
oyp = datap(:,2);
oypint = cumtrapz(otp,oyp);

yp = oyp(otp >= 1500);
tp = otp(otp >= 1500);
ypint = cumtrapz(tp, yp);

CpIntAtTimes = interp1(oypint, times);

figure;
plot(times, CpIntAtTimes, ':', times, ISAresult, 'o-', ...
    times, Cpint1, 'o-', times, fity(results(:, 1), times), 'o--');
legend('real Cp result', 'ISA result', 'It Alg result 1', 'model 1');

errors (1,1) = phi1(results(:, 1))/trapz(Cpint1.^2) ;

% Includes integral of Y squared.

disp(['variables in model ' num2str(1) ':']);
disp(results(:, 1)');
disp(['Error in model' num2str(1) ' = ' num2str(errors(1,1))]);
    
results2 = zeros(5,1); % change #variable
%real Cp data


% fitp = @(b,x) b(1)*exp(-b(2)*x) + b(3)*exp(-b(4)*x)+b(5); %#change format
% 
% phi2 = @(b) trapz((ypint - fitp(b,tp)).^2) ;%- trapz(;
% 
% tic;
% results2(:,1) = simulatedAnnealing(phi2,...
%    [0.1 0.00001 0.1 0.00001 0], ...
%     [-50000 0 -50000 0 -50000 ], ...
%     [1000 0.001 1000 0.001 50000 ], 1000, 1e-7, 0.85);
% disp(['Time elapsed in round ' num2str(2) ':']);
% toc;
% 
% figure;
% plot(otp, oyp, ':', tp, fitp(results2(:, 1), tp), '--');
% legend(['data 2' ], ['model 2' ]);
% 
% errors (1,2) = phi2(results2(:, 1))/trapz(ypint.^2) ;
% 
% 
% disp(['variables in model ' num2str(2) ':']);
% disp(results2(:, 1)');
% disp(['Error in model' num2str(2) ' = ' num2str(errors(1,2))]);

%use model fitting ISA-italgo as fix point
shift = oypint(end) - ypint(end);
%combined graph
figure;
plot(otp, oypint, ':',times, Cpint1+shift, 'bo', times, fity(results(:, 1), times)+shift, 'r-');
legend('real Cp int', 'generated Cp int', 'fit generated Cp int');
