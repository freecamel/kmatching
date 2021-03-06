#' Generates weights using mirror algorithm.

#' Fulfills equality constraints while maintaining randomness by using a random
#' walk reflecting at the boundaries. Based on \code{xsample} function in
#' limSolve package. Given a set of constraints: \eqn{Ex = Ex_0, x \ge 0} mirror
#' starts at \eqn{x_0} and repeatedly jumps from the point in a random direction
#' in the k-plane that defines \eqn{Ax=b}. It then checks against \eqn{x\ge 0}.
#' If it has violated this constraint, it projects onto the violating components
#' and projects the resulting vector back into the plane. This final vector is
#' subtracted from the violating jump, with the length scaled by a random number
#' that is calculated to maximally reduce the distance from the walls (helps it
#' converge faster). This process is repeated until there are no components 
#' violating the constraints. In practice this process generates points in time
#' that is exponential in $n$, the number of components of $x$.
#' 
#' To project a vector u onto vector v we use the operation proj(u)_v = v *
#' frac{u*v}{v*v}. We do this several times with an operation that looks like
#' u * u%*%v/(u%*%u).
#' 
#' @param Amat This is the matrix of the equality constraint coefficients
#' @param x0 An original solution to the constraints
#' @param n Number of random solutions to output
#' @param verbose Give verbose output describing the progress of the function
#' @param numjump The number of jumps to scatter around the direction given by 
#' the difference from zero
#' @param includeInfeasible TRUE to include all "bad" points in the output
#' @return Gives back a matrix with 'n' columns corresponding to 'n' positive
#' solutions to Ax = b. If includeInfeasible is TRUE then infeasible points will also
#' be included in the output, so there will be some negatives. This is to be able to track
#' the walk of mirror. 
#' 
#' @author Mike Flynn \email{<mflynn210@@gmail.com>}
#' @export
#' 
#' @references Van Den Meershe, Karel, Karline Soetaert, and Dick Van Oevelen.
#'   "Xsample(): An R Function for Sampling Linear Inverse Problems." Journal of
#'   Statistical Software 30 (2009): 1--15.
#'   \url{http://cran.cermin.lipi.go.id/web/packages/limSolve/vignettes/xsample.pdf}
#'   
#'   
#' @examples
#' Amat <- matrix(1, ncol = 3, nrow = 1)
#' x0 <- c(.3, .3, .4)
#' mirror(Amat, x0, 1)

mirror <- function(Amat, x0, n, verbose = FALSE, numjump= 20, includeInfeasible = FALSE) {
  
  if(any(is.na(Amat))) 
    stop(paste("'Amat' cannot have NA's in it. It currently has ", sum(is.na(Amat)), sep = ""))
  
  
  if(any(is.na(x0)))
    stop(paste("'x0' cannot have NA's in it. It currently has ", sum(is.na(x0)), sep = ""))
  
  ## overdetermined, more constraints than degrees of freedom
  dimen = dim(Amat)
  if(dimen[1] > dimen[2]) {  
    stop("Problem is overdetermined, more constraints than degrees of freedom")
  }
  
    ## set number at which to set components to zero
    smallnegnumber = -10e-100
    ## columns of Z are orthogonal, unit basis of null space of Amat
    ## a.k.a. vectors in the plane defined by Ax=b
    Z <- Null(t(Amat))
    
    ## initialize return matrix
    ret <- matrix(0, nrow = length(x0), ncol = n + 1)
    ## initialize return list
    retlist <- list()
    
    ## number of cols in Z and mean of x0 used to normalize jumps else
    ## the convergence time grows much faster for higher n
    nc <- ncol(Z)
    mn <- mean(x0)
    ## jump from initial point, distance normally distributed
    ## Z %*% r = r1*v1 + r2*v2 + ... + rn*vn where the v's are orthogonal
    ## vectors in the solution plane and r's are random vectors
    ## for example: if n = 3 and  v1 = x, v2 = y, v4 = z and we have a random point
    ## [r1, r2, r3].
    index<- 1
    ret[, 1] <- x0
    retlist[[index]] <- ret[,1]
    index <- index + 1
    
    ## bestjump will eventually be used to store the optimal length to scale the
    ## reflection
    bestjump <- 0
    for (i in 2:(n + 1)) {
        ## jump
        ret[, i] <- ret[, i - 1] + Z %*% rnorm(nc, 0, abs(mn))/sqrt(nc)
        retlist[[index]] <- ret[,i]
        index <- index + 1
        
        ## we will compare olddist to dist, if olddist < dist, then we have
        ## moved away from feasible space with a jump, and are not converging
        olddist <- Inf
        ## if any of the components is negative, mirror component back
        ## Steps:
        ## -Project onto negative components
        ## -Project resulting vector onto solution plane
        ## -generate random lengths of the resulting vector to subtract from the current
        ## -pick the length to subtract that results in a vector closest to the interior
        ## -repeat until back in interior of solution
        while(any(ret[, i] < 0)) {
            ## intialize the reflection
            reflection <- rep(0, ncol(Amat))
            
            ## overdist will be a vector of all zeros except for the negative components
            ## of ret[,i], this is to isolate the "bad" part of the current vector
            ## We will get rid of this "bad" part by projecting it back on to the solution space
            ## (It is no longer in the solution space because we set all the "good" components to zero, 
            ## changing it)
            overdist <- rep(0, ncol(Amat))
            j <- which.min(ret[,i])
            overdist[j] <- ret[, i][j]
            ## measure distance of negative components from x ==0, this is to
            ## help debug and give verbose output
            dist <- overdist[j]
            
            ## if the only violators are very small members of ret[,i]
            ## override this step, prepare to output zeros
            if(all(abs(ret[,i]) > smallnegnumber)) overdist[j] == 0
            
            if(verbose) str <- paste("Distance from walls: ", dist, "\n", sep = "" )
            if(verbose) cat(str)
            ## project the bad vector back into feasible space, each column
            ## of z constitutes a basis vector in the plane we want to project into, to
            ## project we do the standard projection calculation onto each basis vector (each column) and 
            ## subtract the result from overdist in order to not count twice for a component.
            for (j in 1:ncol(Z)) {
                ## projection = u * (u*v)/(v*V)
                proj <-  Z[, j] * (overdist %*% Z[, j])/(Z[,j] %*% Z[, j])
                ## add projection to reflection
                reflection <- reflection  - proj
                ## remove component from "overdist"
                overdist <- overdist - proj
            }
            ret[,i] <- ret[,i] + 2*reflection
            
            ## if only violators are very small negative numbers, set to zero
            if(all(ret[,i] > smallnegnumber)) {
              ret[which(ret[,i] < 0),i] = 0
              warning("mirror set some components to zero because they were very small. Could cause hitandrun to fail.")
            }
            
            newdist <- ret[,i][j]
            retlist[[index]] <- ret[,i]
            index <- index + 1
            if(verbose) for(j in 1:nchar(str))  cat("\b")
        }
    }
    ret <- ret[, 2:(n + 1)]
    if(includeInfeasible) {
      return(do.call("cbind", retlist))  
    } else {
      return(ret)
    }
}
