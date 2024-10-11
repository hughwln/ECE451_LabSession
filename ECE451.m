% ====================================================
% author: Yi Hu (yhu28@ncsu.edu)
% date: 10/11/2024
% ECE451 Lab Session
% ====================================================

clear all
close all

opt = mpoption('VERBOSE',0, 'OUT_ALL',0);

initial_case = case5;
results = runpf(initial_case);

% =====================================================

% modify Load
load = 1530;
max_load = [100; 830; 200; 300; 100];
initial_case.bus(:, 3) = max_load;

% modify generation
max_gen = [40; 170; 520; 200; 600];
initial_case.gen(:, 2) = max_gen;

results_1 = runpf(initial_case);

% remove branch
initial_case.branch(4, :) = [];

T = 10;
load_profile = [0.1, 0.32, 0.29, 0.46, 0.74, 0.93, 0.68, 0.49, 0.63, 0.71];
violation_list = zeros(T);
for t = 1:T
    % modify load
    initial_case.bus(:, 3) = max_load * load_profile(t);
    % modify gen
    initial_case.gen(:, 2) = max_gen * load_profile(t);
    
    results_t = runpf(initial_case, opt);
    
    isViolation = checkResults(results_t, 0, 1);
    violation_list(t) = isViolation;
end

plot(violation_list);


% remove branch
initial_case.branch(4, :) = [];
results_2 = runpf(initial_case);

function isViolation = checkResults(results, flow, voltage)
    isViolation = 0;
    % check power flow on branches
    if flow
        branch = results.branch;
        for n_branch = 1:size(branch, 1)
            p = max(abs(branch(n_branch, 14)), abs(branch(n_branch, 16)));
            rate = branch(n_branch, 6);
            if p > rate
               % fprintf("Over heat on branch %d \n", n_branch);
               isViolation = 2;
               break;
            end
        end
    end

    % check voltage violation
    if voltage
        V_mag = results.bus(:, 8);
        [V_max, i_max] = max(V_mag);
        [V_min, i_min] = min(V_mag);
        if V_max > 1.05
            fprintf("High voltage at bus %d, %f. \n", i_max, V_max);
            isViolation = isViolation + 1;
        end

        if V_min < 0.95
            fprintf("Low voltage at bus %d, %f. \n", i_min, V_min);
            isViolation = isViolation + 1;
        end
    end
end

