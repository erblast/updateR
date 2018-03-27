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

1. We might have limited access to the `HOME` and the  `./Program Files` directories for IT security reasons
2. We can only access the local database from a server without internet access, thus cannot install packages from online sources
3. The code needs to be reproducible, thus we need to archive older versions of R and their packages.

## How to set up R to be compliant

1. Do not install packages into the `HOME` directory and install R to a local drive outside `./Program Files`. You can setup up R to 
only install into the R installation's `library` directory by adding `libPaths( <path> )` to the Rprofile.site file inside the `etc` folder 
of the R installation's parent directory.
2. We can use the `miniCRAN` package to create a local CRAN repository on a machine with online connection which we can then copy
to the server
3. We can use packages like `packrat` or `checkpoint` they will save all packages for a certain analysis on disk. This approach
uses up a lot of disk space and can be quite slow. Another approach could be to use a `docker` image. What I find more practible is
to create a snapshot everytime R is updated to a new version, which is approximately 4 times a year. Before installting the new version
we simply archive the old R version and the old version of the miniCRAN and note in each analysis folder which R version was used.
If R code is not running anymore on the current version we can simply spin up the old one with which the analysis was orignally performed
this is not a 100% fool-proofed like saving all packages to disk for each analysis but is more disk space friendly.

![setup](https://github.com/erblast/updateR/blob/master/miniCRAN.png)

## Callenges of the proposed workflow

This workflow requires a lot of copy and pasting of files and it is easy to make mistakes. 

- running `update.packages()`, packages that are explicitly or implicitly loaded will fail to update and then be removed from the current library. There are anumber of important packages which are always loaded when Rstudio is running like `Rccp`, `rlang` to just name a few. Also another R Session running will cause problems.

- Each of the steps that are needed to update to a new version takes quite a long time which makes it easy to forget on which step of the sequence one currently is.

# How to use `updateR`

- `updateR` is **MS Windows** only
- make sure no packages are installed in `HOME` directory
- install updateR for **old Rversion**
- download and install new R version on Desktop and Server
- do not use `Rstudio` to run any of the `updateR` functions
- for example run `<R installation path>/bin/<x64 or i386>/Rgui.exe`

## Create miniCRAN

**run in old R Version**

if you do not have a miniCRAN yet make one

`updateR::create_miniCRAN( path = "c:/miniCRAN" )`

## Update new installation from old installation *on desktop*

**run in old R Version**

`updateR::update_from_old_inst()`

- copies all libraries from old to new version
- updates Rprofile.site


## Update new installation from old installation *on server*

**run in old R Version**

`updateR::update_from_old_inst()`

- copies all libraries from old to new version
- updates Rprofile.site
- *archives miniCRAN*

## Update new installation from CRAN repository *on desktop*

**run in new R Version**

`updateR::update_new_inst()`

- this will update all R packages
- will add any local packages available on CRAN to miniCRAN
- update miniCRAN

## Transfer miniCRAN from desktop to server

Before you transfer make sure that you ran `updateR::update_new_inst()` on server first and check if you can find the archived minicRAN version on disk.

**Note this is the only step where you can make a mistake and end up not haveing this version archived**

this is important for updating the packages on the server and installing new packages


## Update new installation from CRAN repository *on server*

**run in new R Version**

`updateR::update_new_inst()`

- this will install all packages found on miniCRAN which are not yet installed locally
- will update all packages from miniCRAN


## Install new CRAN packages on the server

- install them on *desktop* via `install.packages`
- run `updateR::update_new_inst()` on *desktop*
- transfer miniCRAN from *desktop* to *server*
- run `updateR::update_new_inst()` on *server*

Note I would not archive the miniCRAN between R releases, you can however do so manually `updateR::update_from_old_inst()` will not work if there is alrady an archive named using the current R Version.




