% fits a plane to the given set (pointlist) of 3D points
function [plane,fit] = tar_fitplane(pointlist)

  [L,W] = size(pointlist);  % input list of L points
  plane = zeros(4,1);
  D = zeros(L,4);           % working array

  com = mean(pointlist);    % compute centre of mass
  for k = 1 : L
    % subtract centre of mass to improve numerics
    % use a scale factor of 100 internally to balance value sizes
    D(k,:) = [pointlist(k,4)-com(4),pointlist(k,5)-com(5),pointlist(k,6)-com(6),100];
  end
  S = D'*D;                 % compute scatter matrix
  [U,DG,V] = svd(S);        % find eigenvectors
  N = V(1:3,4);             % plane normal is eivenvector with smallest eigenvalue
  plane(1:3) = N' / norm(N); % make to unit normal
  plane(4) = 100*V(4,4) / norm(N) - com(4:6)*plane(1:3); % recompute d in N*x+d=0 fit
  if plane(3) < 0       % all normals face sensor
    plane = -plane;
  end
  fit = DG(4,4);        % least square fitting error

     
