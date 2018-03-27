# updateR

provides workflow for updating R packages and maintaining a miniCRAN repository in an offline server environment

# Introduction

In a corporate environment handling R and R package updates can be tricky. Usually R packages are installed into the user's `HOME` 
directory while standard library packages can be found inside the R installation's `library` directory. These paths can be accessed
via '.libPaths()'. The R isntallation itself can usually be found under `./Program Files`

When updating to a new R version only the packages inside the `library` directory of the R installation will be replaced while all 
packages inside the `HOME` directory remain unchanged. Usually after installing a new version of R we will also update all packages 
using `update.packages()`.

## Restrictions / Requirements of a corporate IT landscape 

1 We might have limited access to the `HOME` and the  `./Program Files` directories for IT security reasons
2 We can only access the local database from a server without internet access, thus cannot install packages from online sources
3 The code needs to be reproducible, thus we need to archive older versions of R and their packages.

## How to set up R for these issues

1 Do not install packages into the `HOME` directory and install R to a local drive outside `./Program Files`. You can setup up R to 
only install into the R installation's `library` directory by adding `libPaths( <path> )` to the Rprofile.site file inside the `etc` folder 
of the R installation's parent directory.
2 We can use the `miniCRAN` package to create a local CRAN repository on a machine with online connection which we can then copy
to the server
3 We can use packages like `packrat` or `checkpoint` they will save all packages for a certain analysis on disk. This approach
uses up a lot of disk space and can be quite slow. Another approach could be to use a `docker` image. What I find more practible is
to create a snapshot everytime R is updated to a new version, which is approximately 4 times a year. Before installting the new version
we simply archive the old version and the old version of the miniCRAN and note in each analysis filder which R version was used.
If R code is not running anymore on the current version we can simply spin up the old one with wich the analysis was orignally performed
this is not a 100% fool proofed like saving all packages to disk for each analysis but is more disk space friendly.

![setup](https://github.com/erblast/updateR/blob/master/miniCRAN.png)
