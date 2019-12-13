! ***********************************************************************
!
!   Copyright (C) 2013  Bill Paxton
!
!   this file is part of mesa.
!
!   mesa is free software; you can redistribute it and/or modify
!   it under the terms of the gnu general library public license as published
!   by the free software foundation; either version 2 of the license, or
!   (at your option) any later version.
!
!   mesa is distributed in the hope that it will be useful, 
!   but without any warranty; without even the implied warranty of
!   merchantability or fitness for a particular purpose.  see the
!   gnu library general public license for more details.
!
!   you should have received a copy of the gnu library general public license
!   along with this software; if not, write to the free software
!   foundation, inc., 59 temple place, suite 330, boston, ma 02111-1307 usa
!
! ***********************************************************************
 
      
      

      ! output routine called by adipls   
      ! uses adipls_support, so must compile work directory after that   
      
      subroutine spcout_adi(x,y,aa,data,nn,iy,iaa,ispcpr)

         ! must set ispcpr > 0 to get this called, settings moved to run_star_extras

!         use astero_data, only: store_new_oscillation_results, &
!            el, order, em, cyclic_freq, inertia, num_results
         use astero_data, only: store_new_oscillation_results, &
            el, order, em, cyclic_freq, inertia, beta, split1,  &
	    split2, split3, splitted_freq, num_results    ! added by me 
         use adipls_support, only: adipls_mode_info
         use utils_lib
         use const_def, only: dp
         use utils_lib, only: mesa_error

         ! Note: naming splitting split1 instead of split(1), avoid confusion with 
         ! original split(1) from rotker, now stored as obs_st(7,nobs_st)

         implicit none
         
         real(dp) :: x(1:nn), y(1:iy,1:nn), aa(1:iaa,1:nn), data(8)
         integer :: nn, iy, iaa, ispcpr

         !  common for storage of model parameters 
         !  degree, order, cyclic frequency (microHz), inertia
         common/cobs_param/ icobs_st, nobs_st, obs_st
         real(dp) :: csummm(50)
         common/csumma/ csummm
                  
         integer :: icobs_st, nobs_st, i
         real(dp) :: obs_st(10,100000) ! huge 2nd dimension to satisfy bounds checking

         integer :: ierr, new_el, new_order, new_em, n
         real(dp) :: new_cyclic_freq, new_inertia, new_beta,  &
	    new_split1, new_split2, new_split3, new_splitted_freq
         
         include 'formats'

	 write(*,*) 'Subroutine spcout_adi called'

         write(*,*) 'Show me obs_st(3,nobs_st) [em] in spcout_adi'
         write(*,*) obs_st(3,nobs_st)

         write(*,*) 'Show me obs_st(6,nobs_st) [beta] in spcout_adi'
         write(*,*) obs_st(6,nobs_st)         

         write(*,*) 'Show me obs_st(7,nobs_st) [split1] in spcout_adi'
         write(*,*) obs_st(7,nobs_st)
         
!         new_el = int(obs_st(1,nobs_st)+0.5) ! converted to integer, why +0.5
         new_el = int(obs_st(1,nobs_st))
!         new_order = int(obs_st(2,nobs_st)+0.5)
         new_order = int(obs_st(2,nobs_st))
!         new_em = csummm(38)
	 new_em = int(obs_st(3,nobs_st)) 
         new_cyclic_freq = obs_st(4,nobs_st)
	 new_inertia = obs_st(5,nobs_st)

	 new_beta = obs_st(6,nobs_st)        ! added by me 
	 new_split1 = obs_st(7,nobs_st)
	 new_split2 = obs_st(8,nobs_st)
	 new_split3 = obs_st(9,nobs_st) 
	 
!        Frequency including rotational splittings 
!        omega = cyclic_freq +m*split(1) + split(2) + m^2*split(3)
         new_splitted_freq = obs_st(4,nobs_st) + obs_st(3,nobs_st)*  &
         obs_st(7,nobs_st) + obs_st(8,nobs_st) + (obs_st(3,nobs_st))**2*  &
         obs_st(9,nobs_st)
 
         write(*,*) 'Show me new_em, new_split1 in adipls_support_procs'
         write(*,*) new_em, new_split1
         
         write(*,*) 'Show me new_splitted_freq in adipls_support_procs'
         write(*,*) new_splitted_freq
         
!         call store_new_oscillation_results( &
!            new_el, new_order, new_em, new_inertia, new_cyclic_freq, 0._dp, ierr)
!         if (ierr /= 0) call mesa_error(__FILE__,__LINE__)

	 write(*,*) 'calling store_new_oscillation_results from astero_data'
 
         call store_new_oscillation_results( &   ! from astero_data
            new_el, new_order, new_em, new_cyclic_freq, new_inertia, &
	    new_beta, new_split1, new_split2, new_split3, new_splitted_freq, &
	    0._dp, ierr)
         if (ierr /= 0) call mesa_error(__FILE__,__LINE__)
         
         n = num_results

         write(*,*) 'Show me em(n),split1(n) in adipls_support_procs after calling store_new_oscillation_results'
         write(*,*) em(n), split1(n)
         write(*,*) 'Show me splitted_freq(n) in adipls_support_procs'
         write(*,*) splitted_freq(n)

!         call adipls_mode_info( &
!            el(n), order(n), em(n), cyclic_freq(n), inertia(n), &
!            x, y, aa, data, nn, iy, iaa, ispcpr)

	 write(*,*) 'calling adipls_mode_info from adipls_support'

         call adipls_mode_info( &   ! from adipls_support 
            el(n), order(n), em(n), cyclic_freq(n), inertia(n), &
	    beta(n), split1(n), split2(n), split3(n), splitted_freq(n), &
            x, y, aa, data, nn, iy, iaa, ispcpr)

      end subroutine spcout_adi      
      
      
      subroutine modmod(x,aa,data,nn,ivarmd,iaa,imdmod)
         use const_def, only: dp
         integer :: nn, ivarmd, iaa, imdmod
         real(dp) :: x(nn), aa(iaa,nn), data(8)
      end subroutine modmod
      
      
      subroutine resdif
      return
      end subroutine resdif
