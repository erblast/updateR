#' @importFrom utils choose.dir compareVersion install.packages installed.packages update.packages

#' @title get R version from path
#' @description R isntallation folder needs to have standard annotation R-X.X.X
#' @param path, Default Sys.getenv('R_HOME')
#' @return character vector 'X.X.X'
#' @examples
#' \dontrun{
#' get_Rversion_from_path()
#'}
#' @rdname get_Rversion_from_path
#' @export
get_Rversion_from_path = function( path = Sys.getenv('R_HOME') ){

  pos = regexec( 'R-\\d+\\.\\d+\\.\\d+', path )[[1]]

  start = pos[[1]] + 2

  end = attributes(pos)$match.length + start

  R_vers = substr(path, start = start, stop = end )

  if( R_vers == '' ){
    stop( paste('could not extract R version from', path,'. Make sure folder name has standard annotation R-X.X.X') )
  }

  is_program_files_folder_in_path = grepl( 'Program Files', path )

  if( is_program_files_folder_in_path ){
    stop( paste( path, ', R seems to be installed in System folder "Program Files". Please install R outside system folders to avoid access rights conflicts') )
  }

  return(R_vers)
}


#' @title get user input necessary for update
#' @description used by update_from_old_inst() and update_new()
#' @return dir_ls list()
#' \describe{
#'   \item{path_new}{path of new R installation}
#'   \item{path_old}{path of old R installation}
#'   \item{path_miniCRAN}{path to miniCRAN repository}
#'   \item{libs_new}{packages in new R installation}
#'   \item{libs_old}{packages in old R installation}
#'   \item{R_vers_run}{R version currently running}
#'   \item{R_vers_new}{R version of new installation}
#'   \item{R_vers_old}{R version of old installation}
#'   \item{server}{ logical, is server environment}
#'   \item{can_internet}{logical, has internet connection}
#'   \item{miniCRAN}{logical, is miniCRAN supposed to be used}
#' }
#' @details DETAILS
#' @examples
#' \dontrun{
#' if(interactive()){
#'  #EXAMPLE1
#'  }
#' }
#' @rdname get_user_input
get_user_input = function(){

  # check internet ---------------------------------------------------------
  can_internet = check_internet()

  #get paths ---------------------------------------------------------------
  path_new = choose.dir(caption = 'pick directory of new R installation'
                        , default = Sys.getenv('R_HOME'))

  path_new = normalizePath(path_new)

  path_old = choose.dir(caption = 'pick directory of old R installation'
                        , default = path_new)

  path_old = normalizePath(path_old)

  print( 'Enter `D` if unsure about environment' )
  input = readline( prompt = 'Server or Desktop environment ( S | D ):' )

  # server or desktop ------------------------------------------------------
  if( (input == 's' | input == 'S') ){

    if( can_internet ) stop('internet connection detected cannot be a server environment')

    server = T
    miniCRAN = T

  }else if(input == 'd' | input == 'D'){
    server = F
    miniCRAN = F
  }else{
    stop( paste0('input: "', input, '" is invalid') )
  }

  # miniCRAN------------------------------------------------------------------

  if( ! server ){

    print( 'if unsure select `N` ' )

    input = readline( prompt = 'Are you using miniCRAN ( Y | N ):' )

    if( (input == 'y' | input == 'Y') ){
      miniCRAN = T
    }else if(input == 'n' | input == 'N'){
      miniCRAN = F
    }else{
      stop( paste0('input: "', input, '" is invalid') )
    }

  }


  if( miniCRAN ){

    path_miniCRAN = choose.dir( caption = 'pick miniCRAN directory')

    if( any( ! dir(path_miniCRAN) %in% c('bin','src')  ) ){
      stop( paste( path_miniCRAN, 'does not appear to be a valid miniCRAN repository') )
    }

  }else{
    path_miniCRAN = NULL
  }

  # get libraries and R versions----------------------------------------

  libs_new = dir( file.path( path_new, 'library' ) )

  libs_old = dir( file.path( path_old, 'library' ) )

  R_vers_run = paste( getRversion(), collapse = '.' )

  R_vers_new = get_Rversion_from_path( path_new )

  R_vers_old = get_Rversion_from_path( path_old )

  # print----------------------------------------------------------------

  print( paste('new R version:', R_vers_new) )
  print( paste('old R version:', R_vers_old) )
  print( paste('running R version:', R_vers_run) )
  print( paste('server environment:', server) )
  print( paste('internet connection:', can_internet) )
  print( paste('using miniCRAN:', miniCRAN) )

  # checks ------------------------------------------------------------------------

  if( compareVersion( R_vers_new, R_vers_old) < 0 ){
    stop( paste( 'new R version', R_vers_new,' is lower than old R version', R_vers_old ) )
  }

  if( length(libs_old) < length(libs_new) ){

    diff_pkgs = paste( libs_new[ ! libs_new %in% libs_old ], collapse = ', ' )

    print( 'more packages found in new installation than in old installation' )

    print( paste( diff_pkgs, 'only found in new installation' ) )

    abort = readline( 'Abort ( Y | N ) ')

    if( abort == 'y' | abort == 'Y' ){
      stop( 'aborted' )
    }

  }


  # returns ------------------------------------------------------------------------

  dir_ls = list( path_new        = path_new
                 , path_old      = path_old
                 , path_miniCRAN = path_miniCRAN
                 , libs_new      = libs_new
                 , libs_old      = libs_old
                 , R_vers_run    = R_vers_run
                 , R_vers_new    = R_vers_new
                 , R_vers_old    = R_vers_old
                 , server        = server
                 , can_internet  = can_internet
                 , miniCRAN      = miniCRAN )

  return( dir_ls )

}

#' @title update new R installation based on old installation
#' @description needs to run on old R version, copies all packages from old
#'   installation, updates Rprofile.site and archives miniCRAN if run on server
#'   environment.
#' @param dir_ls list, Default: get_user_input()
#' @rdname update_from_old_inst
#' @export
update_from_old_inst = function( dir_ls = get_user_input() ){

  path_new      = dir_ls$path_new
  path_old      = dir_ls$path_old
  path_miniCRAN = dir_ls$path_miniCRAN
  libs_new      = dir_ls$libs_new
  libs_old      = dir_ls$libs_old
  R_vers_run    = dir_ls$R_vers_run
  R_vers_new    = dir_ls$R_vers_new
  R_vers_old    = dir_ls$R_vers_old
  server        = dir_ls$server
  can_internet  = dir_ls$can_internet
  miniCRAN      = dir_ls$miniCRAN

  # checks ------------------------------------------------------------------------

  if( R_vers_run != R_vers_old ){
    stop( 'run update_from_old_inst() on old R version' )
  }

  # copy libraries ----------------------------------------------------------------

  copy = function( folder ){

    print( paste('copying', folder) )

    file.copy( from = file.path( path_old, 'library', folder )
               , to = file.path( path_new, 'library' )
               , recursive = T
               )

  }

  folders = libs_old[ ! libs_old %in% libs_new ]

  if( length(folders) > 0 ){

    apply( data.frame( folders = folders ), 1, copy )

    print('all libraries copied')

  }

  # correct .libPaths---------------------------------------------------------------

  print( 'correcting .libPaths() in Rprofile.site' )

  rprofile_new = file.path( path_new, 'etc', 'Rprofile.site')
  rprofile_new = normalizePath(rprofile_new)

  append_string = paste0( '.libPaths( "'
                          , normalizePath( file.path( path_new, 'library'),winslash = '/' )
                          , '" )'  )


  write( x = append_string
         , file = rprofile_new
         , append = T )

  # miniCRAN ------------------------------------------------------------------------

  if( can_internet == F & server == F ){

    warning( 'no internet connection detected' )

  }

  if( can_internet == F & server == T ){

    print( paste('setting', path_miniCRAN, 'as only CRAN repository in Rprofile.site') )

    append_string = paste0( 'options( repos = c( miniCRAN = "'
                           ,  paste0('file:///', normalizePath( path_miniCRAN, winslash = '/') )
                           , '" ) )' )

    write( x = append_string
           , file = rprofile_new
           , append = T )


    print( paste('archiving miniCRAN') )

    path_miniCRAN_archive = file.path( dirname(path_miniCRAN), paste0( 'miniCRAN-',R_vers_old ) )

    if( ! dir.exists(path_miniCRAN_archive) ){

      dir.create( path_miniCRAN_archive )

      file.copy( from = path_miniCRAN
                 , to = path_miniCRAN_archive
                 , recursive = T)

      print( paste('miniCRAN archived at', path_miniCRAN_archive) )

    }else{

      warning('miniCRAN archive for R-', R_vers_old , 'already exists')

    }


  }

}


#' @title update new R installation
#' @description update new R installation, update all packages from either CRAN
#'   or miniCRAN. On desktop environment all packages not yet in miniCRAN are
#'   added. On server environment all missing packages from miniCRAN which are
#'   not yet installed will be installed.
#' @param dir_ls PARAM_DESCRIPTION, Default: get_user_input()
#' @return OUTPUT_DESCRIPTION
#' @details DETAILS
#' @examples
#' \dontrun{
#' if(interactive()){
#'  #EXAMPLE1
#'  }
#' }
#' @seealso \code{\link[miniCRAN]{pkgAvail}},\code{\link[miniCRAN]{addPackage}}
#' @rdname update_new_inst
#' @export
update_new_inst = function( dir_ls = get_user_input()
                            , CRAN_repos = 'https://cran.rstudio.com' ){

  path_new      = dir_ls$path_new
  path_old      = dir_ls$path_old
  path_miniCRAN = dir_ls$path_miniCRAN
  libs_new      = dir_ls$libs_new
  libs_old      = dir_ls$libs_old
  R_vers_run    = dir_ls$R_vers_run
  R_vers_new    = dir_ls$R_vers_new
  R_vers_old    = dir_ls$R_vers_old
  server        = dir_ls$server
  can_internet  = dir_ls$can_internet
  miniCRAN      = dir_ls$miniCRAN


  # checks ------------------------------------------------------------------------

  check_libPaths()

  if( check_RStudio() ){
    stop('do not run update_new_inst() from inside RStudio')
  }

  no_running_R_tasks = check_no_of_tasks()

  if( no_running_R_tasks > 1 ){
    stop( paste( no_running_R_tasks, 'Rsessions are currently running. You can only have on Rsession running.') )
  }

  # in vanilla R no CRAN mirror is loaded it is set to @CRAN@ which results in
  # a user prompt for selecting a mirror. Rstudio overwrites this behaviour.
  # Here we have to overwrite ourselves

  repos = getOption('repos')
  no_repos = length(repos)
  miniCRAN_in_repos = grepl( 'miniCRAN', names(repos) )[1]

  if( '@CRAN@' %in% repos ){
    repos[ repos == '@CRAN@' ] = CRAN_repos
  }

  if( server & ( no_repos > 1 | miniCRAN_in_repos == F ) ){
    stop( paste('miniCRAN has to be only CRAN repository. repos:', repos ) )
  }

  if( server == F & miniCRAN_in_repos == T ){
    stop( paste('miniCRAN should not be a registered CRAN repository. repos:', repos ) )
  }

  if( R_vers_new != R_vers_run ){
    stop('update_new_inst() has to be called from new R installation')
  }

  # update packages -------------------------------------------------------------------------

  print( paste( 'updating packages from', repos[1] ))

  libs_new_before = libs_new

  update.packages( ask = F, repos = repos[1] )

  libs_new_after = dir( file.path(path_new, 'library') )

  libs_diff = libs_new_before[ ! libs_new_before %in% libs_new_after ]

  if( length(libs_diff) > 0 ){

    libs_diff_str = paste( libs_diff, collapse = ', ')

    print( paste( 'packages', libs_diff_str, 'seem to have been deleted during the update process attempt to reinstall') )

    install.packages( libs_diff, repos =  repos[1] )

    libs_new_after = dir( file.path(path_new, 'library') )

    libs_diff = libs_new_before[ ! libs_new_before %in% libs_new_after ]

    if( length( libs_diff ) ){

      libs_diff_str = paste( libs_diff, collapse = ', ')

      stop( paste( 'reinstallation of', libs_diff_str, 'failed' ) )
    }

  }else{
    print( paste( 'update from', repos[1], 'successfull' ))
  }

  # miniCRAN ----------------------------------------------------------------------------------

  if( miniCRAN ){

    # updateR does not import miniCRAN because it loads igraph by default
    # therefore we specifically load miniCRAN here and then unload it when
    # we are done.

    require(miniCRAN)

    miniCRAN_repos = c( miniCRAN = paste0('file:///', normalizePath( path_miniCRAN, winslash = '/') ) )
    CRAN_repos = repos[[1]]

    pkg_loc  = installed.packages()[,c(1,3)]
    pkg_loc  = as.data.frame(pkg_loc)

    pkg_miniCRAN = miniCRAN::pkgAvail( repos = miniCRAN_repos)[,c(1,2)]
    pkg_miniCRAN = as.data.frame(pkg_miniCRAN)
    row.names(pkg_miniCRAN) <- NULL

    pkg_CRAN = miniCRAN::pkgAvail( repos = CRAN_repos)[,c(1,2)]
    pkg_CRAN = as.data.frame(pkg_CRAN)
    row.names(pkg_CRAN) <- NULL

    if( server == F ){

      # get local packages not in miniCRAN (standard library packages + none CRAN packages + new packages)
      pkg_add = pkg_loc[ ! pkg_loc$Package %in% pkg_miniCRAN$Package,  ]

      # only add packages available on CRAN (new packages)
      pkg_add = pkg_add[ pkg_add$Package %in% pkg_CRAN$Package, ]

      if( nrow(pkg_add) > 0 ){

        print( paste('Adding', paste( pkg_add$Package, collapse = ', ' ),'to miniCRAN') )

        miniCRAN::addPackage( pkg_add$Package, path_miniCRAN, CRAN_repos, type = 'win.binary', deps = F)
        miniCRAN::addPackage( pkg_add$Package, path_miniCRAN, CRAN_repos, type = 'source', deps = F)

        package_str = paste( pkg_add$Package, collapse = ', ')

        print( paste(package_str, 'have been added to miniCRAN') )

      }else{
        print('no packages have been added to miniCRAN')
      }

      miniCRAN::updatePackages( path = path_miniCRAN, repos = CRAN_repos, ask = F )

      print('miniCRAN updated, consider pasting miniCRAN to server, make sure to archive miniCRAN
            when switching to new R version by running updateR::update_from_old_inst() first')

    }else{

      # when adding missing packages ignore package version
      pkg_add = pkg_miniCRAN$Package[ ! pkg_miniCRAN$Package %in% pkg_loc$Package ]
      pkg_add = as.vector(pkg_add)

      print( 'installing missing packages from miniCRAN' )

      print( pkg_add )

      install.packages(pkg_add)

      print( paste(  paste(pkg_add, collapse = ', '), 'installed') )

    }

    detach('package:miniCRAN', unload = T)

  }

}


#' @title create fresh miniCRAN from scratch
#' @description creates a fresh miniCRAN repository, usually not needed because
#'   a miniCRAN is already in place
#' @param overwrite Default: F
#' @param path path to miniCRAN repository
#' @rdname miniCRAN_create
#' @export
create_miniCRAN = function( overwrite = F
                            , path = 'c:/miniCRAN'
                            , CRAN_repos = 'https://cran.rstudio.com' ){


  if( check_internet() == F ){
    stop( 'internet connection needed to create miniCRAN repository')
  }

  if( dir.exists(path) & overwrite == F){
    stop('miniCRAN already exists, set overwrite = TRUE')
  }else{
    dir.create( path )
  }

  op = options()

  if( ! startsWith(CRAN_repos, prefix = 'http')  ){
    stop( paste( options('repos')[[1]], "no online CRAN repository found" ) )
  }

  pkg_inst = installed.packages()[,1]

  pkg_CRAN = miniCRAN::pkgAvail( repos = CRAN_repos)[,c(1,2)]
  pkg_CRAN = as.data.frame(pkg_CRAN)
  row.names(pkg_CRAN) <- NULL

  pkg_add = pkg_inst[ pkg_inst %in% pkg_CRAN$Package ]

  miniCRAN::makeRepo( pkg_add, path, CRAN_repos, type = 'source')
  miniCRAN::makeRepo( pkg_add, path, CRAN_repos, type = 'win.binary')

  options(op)

}

