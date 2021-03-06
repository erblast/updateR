

#' @title check number of running tasks
#' @description searches a sstring returned by the system command tasklist for a
#'   task regex pattern. Returns the number of occurrences.
#' @param task_regex regex pattern for task, Default: 'rsession\.exe'
#' @return integer, number of tasks
#' @examples
#' \dontrun{
#' check_no_of_tasks()
#'}
#' @rdname check_no_of_tasks
#' @export
check_no_of_tasks = function( task_regex = c( 'rsession\\.exe'
                                              , 'Rgui\\.exe'
                                              , 'R\\.exe'
                                              , 'Rscript\\.exe'
                                              , 'Rcmd\\.exe' ) ){

  print( paste('checking number of running tasks', task_regex) )

  tasks = system('tasklist', intern = T )

  tasks = paste( tasks, collapse = '')

  results = c()

  for( regex in task_regex){

    splits = strsplit(tasks, regex)[[1]]

    no_tasks = length( splits ) - 1

    results = c( results, no_tasks )
  }

  return( sum(results) )

}


#' @title check for an internet connection
#' @description checks for an internet connection by reading the first line of a
#'   given url
#' @param url character vector, Default: 'http://www.google.com'
#' @return logical
#' @examples
#' check_internet()
#' @rdname check_internet
#' @export
check_internet <- function(url = "http://www.google.com") {

  print('checking for internet connection')

  # test the http capabilities of the current R build
  if (!capabilities(what = "http/ftp")) return(FALSE)

  # test connection by trying to read first line of url
  test <- try(suppressWarnings(readLines(url, n = 1)), silent = TRUE)

  # return FALSE if test inherits 'try-error' class
  return( !inherits(test, "try-error") )

}

#' @title check if RStudio is running
#' @description checks Sys.getenv("RSTUDIO") == "1"
#' @return logical
#' @examples
#' check_RStudio()
#' @rdname check_RStudio
#' @export
check_RStudio = function(){

  print('check if Rstudio is running')

  return( Sys.getenv("RSTUDIO") == "1" )

}

#' @title check .libPaths()
#' @description checks if .libPaths only points to one folder inside running R
#'   installation. Will throw an error if this is not the case.
#' @return logical
#' @examples
#' \dontrun{
#' check_libPaths()
#' }
#' @rdname check_libPaths
#' @export
check_libPaths = function(){

  if( length( .libPaths() ) > 1 ){

    stop( paste( 'found more than one package installation folder, run update_from_old_inst(), .libPaths():', .libPaths() ) )
  }

  if( .libPaths() != file.path( Sys.getenv( 'R_HoME'), 'library' ) ){
    stop( paste( .libPaths(), 'should be inside R installation folder', Sys.getenv( 'R_HoME'), 'library' ) )
  }

  check = TRUE

}
