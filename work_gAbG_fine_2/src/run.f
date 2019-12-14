      program run
      use run_star_support, only: do_read_star_job
      use run_star_extras_astero, only: do_run_star_astero
      
      implicit none
      
      integer :: ierr
      
      ierr = 0
      call do_read_star_job('inlist', ierr)
      if (ierr /= 0) stop 1
      
      call do_run_star_astero
      
      end program
