

context('update')

test_that('update'
          ,{

  temp_dir = tempdir()

  path_miniCRAN = file.path( temp_dir, 'miniCRAN' )
  path_new = path_old = Sys.getenv('R_HOME')
  libs_new = libs_old = dir( file.path(path_new, 'library') )
  R_vers_run = R_vers_new = R_vers_old = getRversion()
  can_internet = check_internet()

  op = options()

  Rprofile.site_ori = readChar( file.path( path_new, 'etc', 'Rprofile.site' )
                                , file.info( file.path( path_new, 'etc', 'Rprofile.site' ) )$size
                                )

  Rprofile.site_ori = trimws( Rprofile.site_ori, 'right' )

  undo = function(){

    options(op)
    write( Rprofile.site_ori, file.path( path_new, 'etc', 'Rprofile.site' ), append =  F )

  }

  if(! can_internet ){
    stop('internet connection required to run test')
  }

  # the R sesion run by test seems to ignore Rprofile.site therefore we have
  # to set it manually

  if( length( .libPaths() ) != 1 ){
    .libPaths( c( .libPaths()[2] , '') )
  }

  # we can only test functions that can be run inside of RStudio.

  create_miniCRAN( path = path_miniCRAN )

  expect_true( dir.exists( path_miniCRAN ) )

  # desktop ---------------------------------------------------------------

  dir_ls = list( path_new        = path_new
                 , path_old      = path_old
                 , path_miniCRAN = path_miniCRAN
                 , libs_new      = libs_new
                 , libs_old      = libs_old
                 , R_vers_run    = R_vers_run
                 , R_vers_new    = R_vers_new
                 , R_vers_old    = R_vers_old
                 , server        = F
                 , can_internet  = can_internet
                 , miniCRAN      = T )

  suppressWarnings({
    update_from_old_inst( dir_ls )
  })

  expect_false( length(Rprofile.site_ori) ==
                  file.info( file.path( path_new, 'etc', 'Rprofile.site' ) )$size
                )

  undo()

  # server ---------------------------------------------------------------


  dir_ls = list( path_new        = path_new
                   , path_old      = path_old
                   , path_miniCRAN = path_miniCRAN
                   , libs_new      = libs_new
                   , libs_old      = libs_old
                   , R_vers_run    = R_vers_run
                   , R_vers_new    = R_vers_new
                   , R_vers_old    = R_vers_old
                   , server        = T
                   , can_internet  = F
                   , miniCRAN      = T )

  suppressWarnings({
    update_from_old_inst( dir_ls )
  })


  expect_false( length(Rprofile.site_ori) ==
                  file.info( file.path( path_new, 'etc', 'Rprofile.site' ) )$size
  )

  expect_true( dir.exists( file.path( temp_dir, paste0 ('miniCRAN-',R_vers_old) ) ) )

  undo()

})







