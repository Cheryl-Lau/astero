! ***********************************************************************
!
!   Copyright (C) 2011  Bill Paxton
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
 
      module run_star_extras

      use star_lib
      use star_def
      use const_def
      use utils_lib, only: mesa_error, alloc_iounit, free_iounit 
      
      implicit none

      logical, save :: freqs_after_every_step = .false.
      logical, save :: freqs_after_final_step = .false.
      
      integer :: time0, time1, clock_rate

      
      ! these routines are called by the standard run_star check_model
      contains
      
      subroutine extras_controls(id, ierr)
         integer, intent(in) :: id
         integer, intent(out) :: ierr
         type (star_info), pointer :: s
         ierr = 0
         call star_ptr(id, s, ierr)
         if (ierr /= 0) return
         
         s% extras_startup => extras_startup
         s% extras_check_model => extras_check_model
         s% extras_finish_step => extras_finish_step
         s% extras_after_evolve => extras_after_evolve
         s% how_many_extra_history_columns => how_many_extra_history_columns
         s% data_for_extra_history_columns => data_for_extra_history_columns
         s% how_many_extra_profile_columns => how_many_extra_profile_columns
         s% data_for_extra_profile_columns => data_for_extra_profile_columns  
      end subroutine extras_controls

      
      integer function extras_startup(id, restart, ierr)
         integer, intent(in) :: id
         logical, intent(in) :: restart
         integer, intent(out) :: ierr
         type (star_info), pointer :: s
	 common/pulse_controls/ freqs_after_every_step, freqs_after_final_step
	 logical :: freqs_after_every_step, freqs_after_final_step
	 integer :: unit

	 namelist /pulse_controls/ freqs_after_every_step, freqs_after_final_step

         ierr = 0
         call star_ptr(id, s, ierr)
         if (ierr /= 0) return
         extras_startup = 0
         call system_clock(time0,clock_rate)
         if (.not. restart) then
            call alloc_extra_info(s)
         else ! it is a restart
            call unpack_extra_info(s)
         end if

	 unit = alloc_iounit(ierr)

	 write(*,*) 'reading NML pulse_controls from inlist_pulse_controls'
	 open(unit, file = 'inlist_pulse_controls', status = 'old')  
	 read(unit, NML = pulse_controls)

	 close(unit)

	 call free_iounit(unit)

      end function extras_startup
      

      integer function extras_check_model(id, id_extra)
      ! returns either keep_going, retry, backup, or terminate.

         integer, intent(in) :: id, id_extra
	 integer :: ierr
         type (star_info), pointer :: s
	 common/pulse_controls/ freqs_after_every_step, freqs_after_final_step
	 logical :: freqs_after_every_step, freqs_after_final_step, store_for_adipls, save_mode_info
!        character (len=256) :: save_mode_filename

         ierr = 0
         call star_ptr(id, s, ierr)
         if (ierr /= 0) return
         extras_check_model = keep_going
 
         store_for_adipls = .true.
         save_mode_info = .true.
!         save_mode_filename = ''

         ! get frequencies only for certain models
         if (mod(s% model_number,50) /= 0) return   ! every 50 models 

         if (freqs_after_every_step) call adipls_calculate_frequencies( &
            s, store_for_adipls, save_mode_info, ierr)

         if (ierr /= 0) extras_check_model = terminate

      end function extras_check_model



      integer function extras_finish_step(id, id_extra) 
      ! returns either keep_going or terminate.

         integer, intent(in) :: id, id_extra
         integer :: ierr
         type (star_info), pointer :: s

         extras_finish_step = keep_going
         call store_extra_info(s)
         ierr = 0
         call star_ptr(id, s, ierr)
         if (ierr /= 0) return

      end function extras_finish_step
      
      
      
      subroutine extras_after_evolve(id, id_extra, ierr)

         integer, intent(in) :: id, id_extra
         integer, intent(out) :: ierr
         type (star_info), pointer :: s
         real(dp) :: dt
	 common/pulse_controls/ freqs_after_every_step, freqs_after_final_step
	 logical :: freqs_after_every_step, freqs_after_final_step, store_for_adipls, save_mode_info
!         character (len=256) ::  save_mode_filename

         ierr = 0
         call star_ptr(id, s, ierr)
         if (ierr /= 0) return

         store_for_adipls = .true.
         save_mode_info = .true.
!         save_mode_filename = ''

         if (freqs_after_final_step .and. .not. freqs_after_every_step) call adipls_calculate_frequencies( &   
            s, store_for_adipls, save_mode_info, ierr)  

         if (ierr /= 0) stop 1

         call system_clock(time1,clock_rate)
         dt = dble(time1 - time0) / clock_rate / 60
         write(*,'(/,a50,f12.2,99i10/)') 'runtime (minutes), retries, backups, steps', &
            dt, s% num_retries, s% num_backups, s% model_number
         ierr = 0

      end subroutine extras_after_evolve
      


      ! Self-defined subroutine for calling adipls 

      subroutine adipls_calculate_frequencies( &
            s, store_for_adipls, save_mode_info, ierr) 

         use adipls_support, only: adipls_get_one_el_info
         type (star_info), pointer :: s
         logical, intent(in) :: store_for_adipls, save_mode_info
!         character (len=*), intent(in) :: save_mode_filename
         character (len=50) :: save_mode_filename
         integer, intent(out) :: ierr

         integer :: l, em, iem, iscan, i, num,  &
	    itrsig, nsel, nsig,  & 
	    irotsl, nsem, idems, iper, ivarf, irotkr, nprtkr, &
	    ispcpr, special_output
         real(dp) :: nu1, nu2, R, G, M, dels, omega0, angular_velocity
         real(dp), pointer, dimension(:) :: l_freq, l_inertia, l_beta, l_split1, l_split2, l_split3, l_splitted_freq
         integer, pointer, dimension(:) :: l_order , l_em  
         logical :: add_center_point, keep_surface_point,  &
            add_atmosphere, do_restribute_mesh,  &
            in_terms_of_omega_k,  &
	    compute_first_order_rotation, compute_second_order_rotation 
	 integer :: inunit

	 namelist /mode_controls/ l, em, nu1, nu2, iscan,  & 
	    angular_velocity, in_terms_of_omega_k,  &
	    compute_first_order_rotation, compute_second_order_rotation, &
	    special_output, save_mode_filename 

         include 'formats'

	 ! parameter values for this subroutine
         ierr = 0
         R = Rsun*s% photosphere_r
         G = s% cgrav(1)
         M = Msun*s% star_mass
         add_center_point = .true.
         keep_surface_point = .false.
         add_atmosphere = .true.
         do_restribute_mesh = .false.
         save_mode_filename = 'save_mode.data'

         nullify(l_order)
         nullify(l_em)     
         nullify(l_freq)
         nullify(l_inertia)
         nullify(l_beta)    ! added by me 
         nullify(l_split1) 
         nullify(l_split2)
         nullify(l_split3)
         nullify(l_splitted_freq)


	 ! Read inlist_pulse_controls to get scan-mode parameters
 
	 inunit = alloc_iounit(ierr)
	 if (ierr /= 0 ) return 

	 open(inunit, file = 'inlist_pulse_controls', status = 'old')
	 

	 read_loop : do   ! reading all sections of mode_controls l=0,1,2,3,...

	 ! Default values for the adipls parameters in inlist_pulse_controls
	 ! also add in g-mode negative order, em, irotsl and omega for adipls control if possible 
	 l = 1  
	 em = -1
         nu1 = 50
         nu2 = 1000
         iscan = 200

	 ! Default values for adipls parameters in inlist_pulse_controls associated with rotation settings
	 ! to be passed on to adipls_support  
	 irotsl = 1   ! turn on rotation
	 irotkr = 21  ! compute rotation second-order perturbation terms 
	 nprtkr = 70  ! print rotational kernel at 70 points
	 omega0 = 0.1  !in terms of omega_k (default true)
	 ispcpr = 6   ! special output

	 ! Parameter values to be passed on to adipls_support then to adipls
         nsel = 0      ! use el as input for l
         dels = 1.0    ! l step size control; declare as real(dp) not integer
         itrsig = 1     
         nsig = 3      ! for high-order g-modes 
	 nsem = -1
	 idems = 1 
	 iper = 0
	 ivarf = 2    ! for g-mode formulation (only if iper=1?)

	 write(*,*) 'reading inlist_pulse_controls'

	 read(inunit, NML = mode_controls, end = 100) 

	 omega0 = angular_velocity ! changing names in inlist_pulse_controls
	 ispcpr = special_output
         iem = em
         
         if (in_terms_of_omega_k) then  ! convert /omega_k to rad/s
            write(*,*) 'converting angular velocity to rad/s'
            omega0 = omega0*sqrt(G*M/(R**3))
         end if

	 if (compute_first_order_rotation) then 
	    irotsl = 1 
	    irotkr = 11
	    write(*,*) 'compute first-order rotational splitting'
	 else if (compute_second_order_rotation .AND. .NOT. compute_first_order_rotation) then
	    irotsl = 1
	    irotkr = 21 
	    write(*,*) 'compute second-order rotational splitting' 
	 else  
	    irotsl = 0
	    irotkr = 0 
	    write(*,*) 'no rotation effects added'
	 end if 

	 if (omega0 == 0.00) then
	    irotsl = 0
	    irotkr = 0
	    write(*,*) 'zero rotation'
	 end if 

	 ! Call subroutine from adipls_support.f
         call adipls_get_one_el_info( &
            s, l, iem, nu1, nu2, iscan, nsel, dels, itrsig, nsig, R, G, M, &    ! em is used for rotation controls only (?)
	    irotsl, nsem, idems, iper, ivarf, irotkr, nprtkr, ispcpr, omega0, &  ! pass arguments to adipls_support 
            add_center_point, keep_surface_point, add_atmosphere, &
            do_restribute_mesh, store_for_adipls, &
            save_mode_info, save_mode_filename, &
            num, l_order, l_em, l_freq, l_inertia, l_beta, l_split1, l_split2, &
            l_split3, l_splitted_freq, ierr)  !l_em was removed, splittings results added by me 
	 ! also pass em as an argument to rotation settings, single value input similar to l

         if (ierr /= 0) then
            write(*,*) 'failed in adipls_get_one_el_info'
            stop 1
         end if

	 ! output to shell
         write(*,*)
         write(*,'(3a8,99a17)') 'l', 'order', 'm', 'freq (uHz)', 'inertia','beta','split1','split2',  &
             'split3','split_freq (uHz)'
         do i = 1, num
            write(*,'(3i8.1,f17.5,1pe17.5,0pf17.6,1pe17.5,1pe17.5,1pe17.5,1pe17.5)') l, l_order(i), l_em(i),  &
            l_freq(i), l_inertia(i), l_beta(i), l_split1(i), l_split2(i), l_split3(i), l_splitted_freq(i)
         end do

         deallocate(l_order, l_em, l_freq, l_inertia, l_beta, l_split1, l_split2, l_split3, l_splitted_freq)
      
	 end do read_loop

100	 continue 

	 close(inunit)
 
	 call free_iounit(inunit)

      end subroutine adipls_calculate_frequencies



      integer function how_many_extra_history_columns(id, id_extra)
         integer, intent(in) :: id, id_extra
         integer :: ierr
         type (star_info), pointer :: s
         ierr = 0
         call star_ptr(id, s, ierr)
         if (ierr /= 0) return
         how_many_extra_history_columns = 0
      end function how_many_extra_history_columns
      
      
      subroutine data_for_extra_history_columns(id, id_extra, n, names, vals, ierr)
         integer, intent(in) :: id, id_extra, n
         character (len=maxlen_history_column_name) :: names(n)
         real(dp) :: vals(n)
         integer, intent(out) :: ierr
         type (star_info), pointer :: s
         ierr = 0
         call star_ptr(id, s, ierr)
         if (ierr /= 0) return
      end subroutine data_for_extra_history_columns

      
      integer function how_many_extra_profile_columns(id, id_extra)
         use star_def, only: star_info
         integer, intent(in) :: id, id_extra
         integer :: ierr
         type (star_info), pointer :: s
         ierr = 0
         call star_ptr(id, s, ierr)
         if (ierr /= 0) return
         how_many_extra_profile_columns = 0
      end function how_many_extra_profile_columns
      
      
      subroutine data_for_extra_profile_columns(id, id_extra, n, nz, names, vals, ierr)
         use star_def, only: star_info, maxlen_profile_column_name
         use const_def, only: dp
         integer, intent(in) :: id, id_extra, n, nz
         character (len=maxlen_profile_column_name) :: names(n)
         real(dp) :: vals(nz,n)
         integer, intent(out) :: ierr
         type (star_info), pointer :: s
         integer :: k
         ierr = 0
         call star_ptr(id, s, ierr)
         if (ierr /= 0) return
      end subroutine data_for_extra_profile_columns
      

      subroutine alloc_extra_info(s)
         integer, parameter :: extra_info_alloc = 1
         type (star_info), pointer :: s
         call move_extra_info(s,extra_info_alloc)
      end subroutine alloc_extra_info
      
      
      subroutine unpack_extra_info(s)
         integer, parameter :: extra_info_get = 2
         type (star_info), pointer :: s
         call move_extra_info(s,extra_info_get)
      end subroutine unpack_extra_info
      
      
      subroutine store_extra_info(s)
         integer, parameter :: extra_info_put = 3
         type (star_info), pointer :: s
         call move_extra_info(s,extra_info_put)
      end subroutine store_extra_info
      
      
      subroutine move_extra_info(s,op)
         integer, parameter :: extra_info_alloc = 1
         integer, parameter :: extra_info_get = 2
         integer, parameter :: extra_info_put = 3
         type (star_info), pointer :: s
         integer, intent(in) :: op
         
         integer :: i, j, num_ints, num_dbls, ierr
         
         i = 0
         ! call move_int or move_flg    
         num_ints = i
         
         i = 0
         ! call move_dbl       
         
         num_dbls = i
         
         if (op /= extra_info_alloc) return
         if (num_ints == 0 .and. num_dbls == 0) return
         
         ierr = 0
         call star_alloc_extras(s% id, num_ints, num_dbls, ierr)
         if (ierr /= 0) then
            write(*,*) 'failed in star_alloc_extras'
            write(*,*) 'alloc_extras num_ints', num_ints
            write(*,*) 'alloc_extras num_dbls', num_dbls
            stop 1
         end if
         
         contains
         
         subroutine move_dbl(dbl)
            real(dp) :: dbl
            i = i+1
            select case (op)
            case (extra_info_get)
               dbl = s% extra_work(i)
            case (extra_info_put)
               s% extra_work(i) = dbl
            end select
         end subroutine move_dbl
         
         subroutine move_int(int)
            integer :: int
            i = i+1
            select case (op)
            case (extra_info_get)
               int = s% extra_iwork(i)
            case (extra_info_put)
               s% extra_iwork(i) = int
            end select
         end subroutine move_int
         
         subroutine move_flg(flg)
            logical :: flg
            i = i+1
            select case (op)
            case (extra_info_get)
               flg = (s% extra_iwork(i) /= 0)
            case (extra_info_put)
               if (flg) then
                  s% extra_iwork(i) = 1
               else
                  s% extra_iwork(i) = 0
               end if
            end select
         end subroutine move_flg
      
      end subroutine move_extra_info

      end module run_star_extras
      
