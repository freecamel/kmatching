\name{plotmirror}
\alias{plotmirror}
\title{Plots 3-d mirror output in readable format}
\usage{
  plotmirror(m)
}
\arguments{
  \item{m}{A matrix with 3 rows, corresponding to the
  output of a call to mirror with includeInfeasible =
  TRUE.}
}
\value{
  A ggplot object gives the arrow plot
}
\description{
  Plot the steps of a random walk on the simplex in 3
  varibles, using arrows to direct
}
\examples{
A <- matrix(1, ncol = 3)
x0 <- c(.2, -.2, 1)

m <- mirror(A, x0, n = 1, includeInfeasible = TRUE)
plotmirror(m)
}

