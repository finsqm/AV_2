function [target_pxls, sphere_params_all, target_images] = get_objects(pcl_cell)

target_pxls = cell(16);
target_images = cell(16);
sphere_params_all = cell(16);
%sphere_pxls_all = cell(16);
old_sphere_hists = cell(3);

for k = 1:16
    
    %figure
    
    I = pcl_cell{k};
    I = I(20:460,20:620,:);
    
    R = I(:,:,1);
    G = I(:,:,2);
    B = I(:,:,3);
    
    r = R ./ sqrt(R.^2 + G.^2 + B.^2);
    g = G ./ sqrt(R.^2 + G.^2 + B.^2);
    b = B ./ sqrt(R.^2 + G.^2 + B.^2);
    
    %norm(:,:,1) = r;
    %norm(:,:,2) = g;
    %norm(:,:,3) = b;
    
    %imshow(norm)
    
    R2 = imgaussfilt(R,3);
    bw_r = edge(R2,'canny',0.35);
    G2 = imgaussfilt(G,3);
    bw_g = edge(G2,'canny',0.35);
    B2 = imgaussfilt(B,3);
    bw_b = edge(B2,'canny',0.35);
    
    bw = bw_r | bw_g | bw_b;
    %bw2 = bwmorph(bw,'close');
    se90 = strel('line', 4, 90);
    se0 = strel('line', 4, 0);
    seD = strel('diamond',1);
    bw2 = imdilate(bw, [se90 se0]);
    %bw3 = bwmorph(bw,'dilate',5);
    bw3 = imfill(bw2,'holes');
    bw4 = imclearborder(bw3, 4);
    BW = imerode(bw4,seD);
    %imshow(BW)
    
    stats = regionprops(BW,'all');
    [N,~] = size(stats);
    
    id = zeros(N);
    for i = 1 : N
        id(i) = i;
    end
    for i = 1 : N-1
        for j = i+1 : N
            if stats(i).Area < stats(j).Area
                tmp = stats(i);
                stats(i) = stats(j);
                stats(j) = tmp;
                tmp = id(i);
                id(i) = id(j);
                id(j) = tmp;
            end
        end
    end
    
    STATS = stats(1:4);
    
    % Get target object
    target_idxs = STATS(1).PixelList;
    target_pxls{k} = get_pixels(target_idxs,I);
    target_images{k} = get_pixels2(target_idxs,I);
    %[R,C,D] = size(I);
    %I2 = reshape(I,[R*C,D]);
    %target_pxls{k} = I2;
    %figure
    %plot3(target_pxls{k}(:,4),target_pxls{k}(:,5),target_pxls{k}(:,6),'r.')
    
    
    sphere_pxls = cell(3);
    sphere_params = cell(3);
    sphere_hists = cell(3);
    sphere_idxs = cell(3);
    for i = 1:3
        sphere_idxs{i} = STATS(i+1).PixelList;
        sphere_pxls{i} = get_pixels(sphere_idxs{i},I);
        %target_pxls{k} = [target_pxls{k};sphere_pxls{i}];
        [c,~] = sphereFit(sphere_pxls{i}(:,4:6));
        sphere_params{i} = c;
        norm_pxls = normRGB(sphere_pxls{i});
        rhist = dohist(norm_pxls(:,1),0);
        ghist = dohist(norm_pxls(:,2),0);
        bhist = dohist(norm_pxls(:,3),0);
        hist = cat(1, rhist, ghist, bhist);
        norm_hist = hist ./ sum(hist);
        sphere_hists{i} = norm_hist;
    end
    
    if k == 1
        old_sphere_params = sphere_params;
        old_sphere_hists = sphere_hists;
        old_sphere_pxls = sphere_pxls;
        old_sphere_idxs = sphere_idxs;
    else
        % For all current spheres
        dists = zeros(3,3);
        for i = 1:3
            hi = sphere_hists{i};
            % Get distance with all previous spheres
            for j = 1:3
                hj = old_sphere_hists{j};
                dists(i,j) = 1 - sum(sqrt(hi).*sqrt(hj));
            end
        end
        [~, argmindists] = min(dists,[],2);
        for i = 1:3
            j = argmindists(i);
            old_sphere_params{j} = sphere_params{i};
            old_sphere_hists{j} = sphere_hists{i};
            old_sphere_pxls{j} = sphere_pxls{i};
            old_sphere_idxs{j} = sphere_idxs{i};
        end
    end
    
    sphere_params_all{k} = old_sphere_params;
    %sphere_pxls_all{k} = old_sphere_pxls;
    
    %figure
    %imshow(I(:,:,1:3)/255)
    %[R,C,D] = size(I);
    %I2 = reshape(I,[R*C,D]);
    %plot3(I2(:,4),I2(:,5),I2(:,6),'r.');
    %figure
    %imshow(I(:,:,1:3)/255)
    %hold on
    %colours = ['r.','g.','b.'];
    %for i = 1:3
    %    plot(old_sphere_idxs{i}(:,1),old_sphere_idxs{i}(:,2),colours(i))
    %end
    %hold off
end