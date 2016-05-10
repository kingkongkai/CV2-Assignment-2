function [x, y] = point_view_matrix(image_dir, threshold, n_epoch)

files = dir(strcat(image_dir, '*.png'));
files = {files.name};
main_view = [];

[~, coordinates] = compute_fundamental_matrix(single(rgb2gray(imread(strcat(image_dir, files{1})))), single(rgb2gray(imread(strcat(image_dir, files{2})))), threshold, n_epoch);
x = coordinates(3, :);
y = coordinates(4, :);

for i = 3:length(files)
    
    tmp_x = zeros(1, size(x, 2));
    tmp_y = zeros(1, size(y, 2));
    
    [~, coordinates] = compute_fundamental_matrix(single(rgb2gray(imread(strcat(image_dir, files{i - 1})))), single(rgb2gray(imread(strcat(image_dir, files{i})))), threshold, n_epoch);
    %tmp_x(ismember(x(size(x, 1), :), coordinates(1, :))) = coordinates(3, ismember(coordinates(1, :), x(size(x, 1), :)));
    %tmp_y(ismember(y(size(y, 1), :), coordinates(2, :))) = coordinates(4, ismember(coordinates(2, :), y(size(y, 1), :)));
    
    for j = 1:size(coordinates, 2)
        if any(x == coordinates(1, j))
            if any(y(x == coordinates(1, j)) == coordinates(2, j))
                tmp_x(j) = coordinates(3, j);
                tmp_y(j) = coordinates(4, j);
            end
        end
    end
    
    new_x = unique(coordinates(3, ~ismember(coordinates(1, :), x(size(x, 1), :))));        
    new_y = unique(coordinates(4, ~ismember(coordinates(2, :), y(size(y, 1), :))));
    
    x = horzcat(x, zeros(size(x, 1), length(new_x)));
    y = horzcat(y, zeros(size(y, 1), length(new_y)));
    x = vertcat(x, horzcat(tmp_x, new_x));
    y = vertcat(y, horzcat(tmp_y, new_y));
    
    if mod(i, 5) == 0
        structure = SFM(vertcat(x(i-4:i-1, :), y(i-4:i-1, :)));
        if isempty(main_view)
            main_view = structure;
        else
            [~, structure] = procrustes(main_view, structure);
            main_view = horzcat(main_view, structure);
        end
        figure(1);
        scatter3(main_view(1,:),main_view(2,:),main_view(3,:), 2);
    end
end
figure(1);
scatter3(main_view(1,:),main_view(2,:),main_view(3,:), 2);
    
end

% o we have Ax pointview--matrix and Ay matrix for x/y coordinates
% 
% 1) from mathces for frame1-frame2 we got x1, y1, x2, y2 - coordinates of matches.
% 
% we ignore x1, y1 and set first row of Ax as x2, first row of Ay as y2
% 
% 2) for frame2-frame3 (and all following) we got x1, y1, x2, y2
% 
% we create new_rowx/y - of size of prev row of Ax/Ay
% 
% then for each point in x1/y1
% we check previous row of Ax/Ay
% if we found the same point - we set that index of new_rowx/y to corresponfing point in x2/y2
% 
% if we don't find it - add new value to  new_rowx/y  - to corresponfing point in x2/y2
% 
% after looking at all points in x1/y1:
% add new_rowx/y below Ax/Ay