

check_no_of_tasks = function( task_regex = 'rsession\\.exe'){

  print( paste('checking number of running tasks', task_regex) )

  tasks = system('tasklist', intern = T )

  tasks = paste( tasks, collapse = '')

  splits = strsplit(tasks, task_regex)[[1]]

  no_tasks = length( splits ) - 1

  return( no_tasks )

}


check_internet <- function(url = "http://www.google.com") {

  print('checking for internet connection')

  # test the http capabilities of the current R build
  if (!capabilities(what = "http/ftp")) return(FALSE)

  # test connection by trying to read first line of url
  test <- try(suppressWarnings(readLines(url, n = 1)), silent = TRUE)

  # return FALSE if test inherits 'try-error' class
  return( !inherits(test, "try-error") )

}

check_RStudio = function(){

  print('check if Rstudio is running')

  return( Sys.getenv("RSTUDIO") == "1" )

}

check_libPaths = function(){

  if( length( .libPaths() ) > 1 ){
    stop( 'found more than one package installation folder, run update_from_old_inst()' )
  }

  if( .libPaths() != file.path( Sys.getenv( 'R_HoME'), 'library' ) ){
    stop( paste( .libPaths(), 'should be inside R installation folder', Sys.getenv( 'R_HoME'), 'library' ) )
  }

  check = TRUE

}
