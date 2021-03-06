\name{mirror}
\alias{mirror}
\title{Generates weights using mirror algorithm.
Fulfills equality constraints while maintaining randomness by using a random
walk reflecting at the boundaries. Based on \code{xsample} function in
limSolve package. Given a set of constraints: \eqn{Ex = Ex_0, x \ge 0} mirror
starts at \eqn{x_0} and repeatedly jumps from the point in a random direction
in the k-plane that defines \eqn{Ax=b}. It then checks against \eqn{x\ge 0}.
If it has violated this constraint, it projects onto the violating components
and projects the resulting vector back into the plane. This final vector is
subtracted from the violating jump, with the length scaled by a random number
that is calculated to maximally reduce the distance from the walls (helps it
converge faster). This process is repeated until there are no components
violating the constraints. In practice this process generates points in time
that is exponential in $n$, the number of components of $x$.}
\usage{
  mirror(Amat, x0, n, verbose = FALSE, numjump = 20,
    includeInfeasible = FALSE)
}
\arguments{
  \item{Amat}{This is the matrix of the equality constraint
  coefficients}

  \item{x0}{An original solution to the constraints}

  \item{n}{Number of random solutions to output}

  \item{verbose}{Give verbose output describing the
  progress of the function}

  \item{numjump}{The number of jumps to scatter around the
  direction given by the difference from zero}

  \item{includeInfeasible}{TRUE to include all "bad" points
  in the output}
}
\value{
  Gives back a matrix with 'n' columns corresponding to 'n'
  positive solutions to Ax = b. If includeInfeasible is
  TRUE then infeasible points will also be included in the
  output, so there will be some negatives. This is to be
  able to track the walk of mirror.
}
\description{
  To project a vector u onto vector v we use the operation
  proj(u)_v = v * frac{u*v}{v*v}. We do this several times
  with an operation that looks like u * u%*%v/(u%*%u).
}
\examples{
Amat <- matrix(1, ncol = 3, nrow = 1)
x0 <- c(.3, .3, .4)
mirror(Amat, x0, 1)
}
\author{
  Mike Flynn \email{<mflynn210@gmail.com>}
}
\references{
  Van Den Meershe, Karel, Karline Soetaert, and Dick Van
  Oevelen.  "Xsample(): An R Function for Sampling Linear
  Inverse Problems." Journal of Statistical Software 30
  (2009): 1--15.
  \url{http://cran.cermin.lipi.go.id/web/packages/limSolve/vignettes/xsample.pdf}
}

