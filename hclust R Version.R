# A basic (and wasteful) way to compute a full Euclidean distance matrix for
# the input matrix x. The output[i,j] position is the Euclidean distance
# between rows x[i,] and x[j,].
dis = function(x)
{
  x = as.matrix(x)
  u = apply(x*x,1,sum) %*% matrix(1.0,1,nrow(x))
  sqrt(abs(u + t(u) - 2 * x %*% t(x)))
}

# The following ordering function for the hclust plot is translated from the
# original Fortran code used by R in hclust.f. It's only needed by the plotting
# routine to avoid crossing connections. This translation is really really slow.
iorder = function(m)
{
  N = nrow(m) + 1
  iorder = rep(0,N)
  iorder[1] = m[N-1,1]
  iorder[2] = m[N-1,2]
  loc = 2
  for(i in seq(N-2,1))
  {
    for(j in seq(1,loc))
    {
      if(iorder[j] == i)
      {
        iorder[j] = m[i,1]
        if(j==loc)
        {
          loc = loc + 1
          iorder[loc] = m[i,2]
        } else
        {
          loc = loc + 1
          for(k in seq(loc, j+2)) iorder[k] = iorder[k-1]
          iorder[j+1] = m[i,2]
        }
      }
    }
  }
  -iorder
}

# A really simple pure-R hierarchical clustering implementation. Can
# be used like hclust(d, method).
hc = function(d, method=c("single","complete","average","median"))
{
  if(!is.matrix(d)) d = as.matrix(d)
  # Pick a clustering function:
  method_fn = switch(match.arg(method),
                     single   = min,
                     complete = max,
                     average  = mean,
                     median  = median)
  N = nrow(d)
  diag(d)=Inf
  n = -(1:N)                       # Tracks group membership
  m = matrix(0,nrow=N-1, ncol=2)   # hclust merge output
  h = rep(0,N-1)                   # hclust height output
  for(j in seq(1,N-1))
  {
    # Find smallest distance and corresponding indices
    h[j] = min(d)
    
    # if(is.infinite(h[j])){
    #   break()
    # }
    
    # We can use == here (I think) because we know we'll get exactly a 0 value.
    i = which(d - h[j] == 0, arr.ind=TRUE)
    # We could get more than one, but we just want to merge one pair, so take 1st.
    i = i[1,,drop=FALSE]
    p = n[i]
    # R's convention is to order each m[j,] pair as follows:
    p = p[order(p)]
    m[j,] = p
    # Agglomerate this pair and all previous groups they belong to
    # into the current jth group:
    grp = c(i, which(n %in% n[i[1,n[i]>0]]))
    n[grp] = j
    # Concoct replacement distances that consolidate our pair using `method`:
    r = apply(d[i,],2,method_fn)
    # Move on to the next minimum distance, excluding current one by modifying
    # the distance matrix:
    d[min(i),] = d[,min(i)] = r
    d[min(i),min(i)]        = Inf
    d[max(i),] = d[,max(i)] = Inf
  }
  # Return something similar to the output from hclust.
  
  
  # cut height and merge
  
  # m = m [1:j-1,]
  # h = h [1:j-1]
  
  structure(list(merge = m, height = h, order = iorder(m),
                 labels = rownames(d), method = method, 
                 call = match.call(), dist.method = "euclidean"), 
            class = "hclust")
}

# Compare!
#h = hclust(dist(USArrests),method="single")
#h1 = hc(dis(USArrests), method="single")
#plot(h)
#plot(h1)

# A more numerically challenging example
# i=seq(1,by=3,length.out=50)
# x=as.matrix(iris[i,1:4])
# h=hclust(dist(x),method="single")
# h1=hc(dist(x),method="single")
# print(cbind(h$merge[1:22,],h1$merge[1:22,]))