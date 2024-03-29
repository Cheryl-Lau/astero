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
 

      module astero_data

      use star_lib
      use star_def
      use const_def
      use crlibm_lib
      use utils_lib
      
      implicit none
      
      
      ! oscillation code results
      
      integer :: num_results
      integer, pointer, dimension(:) :: el, order, em
      real(dp), pointer, dimension(:) :: inertia, cyclic_freq, growth_rate, beta, split1, split2, split3, splitted_freq
      real(dp) :: total_time_in_oscillation_code 

         
      ! interfaces for procedure pointers
      abstract interface
      
         subroutine other_proc_interface(id, ierr)   ! can ignore?
            integer, intent(in) :: id
            integer, intent(out) :: ierr
         end subroutine other_proc_interface

         subroutine other_adipls_mode_info_interface( &     ! can ignore?
               l, order, freq, inertia, x, y, aa, data, nn, iy, iaa, ispcpr, ierr)
            use const_def, only: dp
            integer, intent(in) :: l, order
            real(dp), intent(in) :: freq, inertia
            real(dp), intent(in) :: x(1:nn), y(1:iy,1:nn), aa(1:iaa,1:nn), data(8)
            integer, intent(in) :: nn, iy, iaa, ispcpr
            integer, intent(out) :: ierr
         end subroutine other_adipls_mode_info_interface
         
      end interface
      
      type astero_info
      
         procedure(other_proc_interface), pointer, nopass :: &
            other_after_get_chi2 => null()
            
         procedure(other_adipls_mode_info_interface), pointer, nopass :: &
            other_adipls_mode_info => null()
            
      end type astero_info
      
      type (astero_info), save :: astero_other_procs
      
      logical :: use_other_after_get_chi2 = .false.
      logical :: use_other_adipls_mode_info = .false.
      

      ! chi2 = chi2_seismo*chi2_seismo_fraction &
      !      + chi2_spectroscopic_and_photometric*(1 - chi2_seismo_fraction)
      real(dp) :: chi2_seismo_fraction

      real(dp) :: chi2_seismo_delta_nu_fraction
      real(dp) :: chi2_seismo_nu_max_fraction
      real(dp) :: chi2_seismo_r_010_fraction
      real(dp) :: chi2_seismo_r_02_fraction
      
      logical :: &
         trace_chi2_seismo_delta_nu_info, &
         trace_chi2_seismo_nu_max_info, &
         trace_chi2_seismo_ratios_info, &
         trace_chi2_seismo_frequencies_info, &
         trace_chi2_spectro_info

      real(dp) :: delta_nu, delta_nu_sigma
      real(dp) :: nu_max, nu_max_sigma

      logical :: include_logg_in_chi2_spectro
      real(dp) :: logg_target, logg_sigma
      
      logical :: include_logL_in_chi2_spectro
      real(dp) :: logL_target, logL_sigma

      logical :: include_Teff_in_chi2_spectro
      real(dp) :: Teff_target, Teff_sigma

      logical :: include_FeH_in_chi2_spectro
      real(dp) :: FeH_target, FeH_sigma
         
      logical :: include_logR_in_chi2_spectro
      real(dp) :: logR_target, logR_sigma
         
      logical :: include_age_in_chi2_spectro
      real(dp) :: age_target, age_sigma
      integer :: num_smaller_steps_before_age_target
      real(dp) :: dt_for_smaller_steps_before_age_target
         
      logical :: include_surface_Z_div_X_in_chi2_spectro
      real(dp) :: surface_Z_div_X_target, surface_Z_div_X_sigma
         
      logical :: include_surface_He_in_chi2_spectro
      real(dp) :: surface_He_target, surface_He_sigma
         
      logical :: include_Rcz_in_chi2_spectro
      real(dp) :: Rcz_target, Rcz_sigma
         
      logical :: include_csound_rms_in_chi2_spectro, &
         report_csound_rms
      real(dp) :: csound_rms_target, csound_rms_sigma

      logical :: include_my_var1_in_chi2_spectro
      real(dp) :: my_var1_target, my_var1_sigma
      character (len=32) :: my_var1_name

      logical :: include_my_var2_in_chi2_spectro
      real(dp) :: my_var2_target, my_var2_sigma
      character (len=32) :: my_var2_name

      logical :: include_my_var3_in_chi2_spectro
      real(dp) :: my_var3_target, my_var3_sigma
      character (len=32) :: my_var3_name
      
      real(dp) :: Z_div_X_solar

      integer, parameter :: & ! increase these if necessary
         max_nl0 = 1000, &
         max_nl1 = 1000, &
         max_nl2 = 1000, &
         max_nl3 = 1000

      ! observed l=0 modes to match to model
      integer :: nl0
      real(dp) :: l0_obs(max_nl0), l0_obs_sigma(max_nl0)
      
      ! observed l=1 modes to match to model
      integer :: nl1
      real(dp) :: l1_obs(max_nl1), l1_obs_sigma(max_nl1)
      
      ! observed l=2 modes to match to model
      integer :: nl2
      real(dp) :: l2_obs(max_nl2), l2_obs_sigma(max_nl2)
      
      ! observed l=3 modes to match to model
      integer :: nl3
      real(dp) :: l3_obs(max_nl3), l3_obs_sigma(max_nl3)
            
      character (len=100) :: search_type
      
      logical :: eval_chi2_at_target_age_only
      real(dp) :: min_age_for_chi2, max_age_for_chi2

      character (len=256) :: newuoa_output_filename
      real(dp) :: newuoa_rhoend ! search control for newuoa

      character (len=256) :: bobyqa_output_filename
      real(dp) :: bobyqa_rhoend ! search control for bobyqa
      
      character (len=256) :: simplex_output_filename
      integer :: simplex_itermax, &
         simplex_fcn_calls_max, simplex_seed
      logical :: &
         simplex_enforce_bounds, &
         simplex_adaptive_random_search, &
         restart_simplex_from_file
      real(dp) :: &
         simplex_x_atol, &
         simplex_x_rtol, &
         simplex_chi2_tol, &
         simplex_centroid_weight_power
      
      character (len=256) :: scan_grid_output_filename
      logical :: restart_scan_grid_from_file
      character (len=256) :: filename_for_parameters
      integer :: max_num_from_file
      integer :: &
         file_column_for_FeH, file_column_for_Y, file_column_for_f_ov, &
         file_column_for_alpha, file_column_for_mass
      character (len=256) :: from_file_output_filename
      
      logical :: Y_depends_on_Z
      real(dp) :: Y0, dYdZ

      logical :: vary_FeH, vary_Y, vary_mass, vary_alpha, vary_f_ov
      real(dp) :: first_FeH, first_Y, first_mass, first_alpha, first_f_ov
      real(dp) :: min_FeH, min_Y, min_mass, min_alpha, min_f_ov
      real(dp) :: max_FeH, max_Y, max_mass, max_alpha, max_f_ov
      real(dp) :: delta_Y, delta_FeH, delta_mass, delta_alpha, delta_f_ov
      
      real(dp) :: f0_ov_div_f_ov, Lnuc_div_L_limit, &
         chi2_spectroscopic_limit, chi2_radial_limit, chi2_delta_nu_limit
      
      real(dp) :: max_yrs_dt_when_cold, max_yrs_dt_when_warm, max_yrs_dt_when_hot, &
         max_yrs_dt_chi2_small_limit, chi2_limit_for_small_timesteps, &
         max_yrs_dt_chi2_smaller_limit, chi2_limit_for_smaller_timesteps, &
         max_yrs_dt_chi2_smallest_limit, chi2_limit_for_smallest_timesteps, &
         chi2_search_limit1, chi2_search_limit2, chi2_relative_increase_limit, &
         avg_age_sigma_limit, avg_model_number_sigma_limit
         
      integer :: min_num_samples_for_avg, max_num_samples_for_avg, &
         limit_num_chi2_too_big
      
      real(dp) :: min_age_limit
      
      real(dp) :: &
         sigmas_coeff_for_logg_limit, &
         sigmas_coeff_for_logL_limit, &
         sigmas_coeff_for_Teff_limit, &
         sigmas_coeff_for_logR_limit, &
         sigmas_coeff_for_surface_Z_div_X_limit, &
         sigmas_coeff_for_surface_He_limit, &
         sigmas_coeff_for_Rcz_limit, &
         sigmas_coeff_for_csound_rms_limit, &
         sigmas_coeff_for_delta_nu_limit, &
         sigmas_coeff_for_my_var1_limit, &
         sigmas_coeff_for_my_var2_limit, &
         sigmas_coeff_for_my_var3_limit
      
      character(len=32) :: correction_scheme
      real(dp) :: correction_b, correction_factor
      integer :: l0_n_obs(max_nl0)
      
      ! frequency ratios for observations
      integer :: ratios_n, ratios_l0_first, ratios_l1_first
      real(dp), dimension(max_nl0) :: &
         ratios_r01, sigmas_r01, &
         ratios_r10, sigmas_r10, &
         ratios_r02, sigmas_r02
      
      ! output controls
      logical :: write_best_model_data_for_each_sample
      integer :: num_digits
      character (len=256) :: sample_results_prefix, sample_results_postfix
      
      integer :: model_num_digits

      logical :: write_fgong_for_each_model
      character (len=256) :: fgong_prefix, fgong_postfix      
      logical :: write_fgong_for_best_model
      character (len=256) :: best_model_fgong_filename
      
      logical :: write_gyre_for_each_model
      character (len=256) :: gyre_prefix, gyre_postfix     
      logical :: write_gyre_for_best_model
      character (len=256) :: best_model_gyre_filename
      integer :: max_num_gyre_points
      
      logical :: write_profile_for_best_model
      character (len=256) :: best_model_profile_filename
      
      logical :: save_model_for_best_model
      character (len=256) :: best_model_save_model_filename
      
      logical :: save_info_for_last_model
      character (len=256) :: last_model_save_info_filename

      character (len=1024) :: shell_script_for_each_sample
      character (len=1) :: shell_script_num_string_char
      
      
      ! miscellaneous

      logical :: save_next_best_at_higher_frequency, &
         save_next_best_at_lower_frequency

      logical :: trace_limits

      logical :: save_controls
      character (len=256) :: save_controls_filename
      
      real(dp) :: Y_frac_he3
      
      integer :: save_mode_model_number = -1
      character (len=256) :: save_mode_filename
      integer :: el_to_save = -1
      integer :: order_to_save = -1
      integer :: em_to_save = -1
      
      character (len=256) :: &
         oscillation_code, &
         gyre_input_file
      logical :: gyre_non_ad
      
      logical :: trace_time_in_oscillation_code 
      
      logical :: add_atmosphere     
      logical :: keep_surface_point      
      logical :: add_center_point

      logical :: do_redistribute_mesh
      ! note: number of zones for redistribute is set in the redistrb.c input file
               
      integer :: & ! iscan for adipls = this factor times expected number of modes
         iscan_factor_l0, iscan_factor_l1, iscan_factor_l2, iscan_factor_l3
      real(dp) :: nu_lower_factor, nu_upper_factor
         ! frequency range for adipls is set from observed frequencies times these            
      integer :: & ! misc adipls parameters
         adipls_irotkr, adipls_nprtkr, adipls_igm1kr, adipls_npgmkr

      
      logical :: read_extra_astero_search_inlist1
      character (len=256) :: extra_astero_search_inlist1_name 
      
      logical :: read_extra_astero_search_inlist2
      character (len=256) :: extra_astero_search_inlist2_name 
      
      logical :: read_extra_astero_search_inlist3
      character (len=256) :: extra_astero_search_inlist3_name 
      
      logical :: read_extra_astero_search_inlist4
      character (len=256) :: extra_astero_search_inlist4_name 
      
      logical :: read_extra_astero_search_inlist5
      character (len=256) :: extra_astero_search_inlist5_name 


      namelist /astero_search_controls/ &
         chi2_seismo_fraction, &
         chi2_seismo_delta_nu_fraction, &
         chi2_seismo_nu_max_fraction, &
         chi2_seismo_r_010_fraction, &
         chi2_seismo_r_02_fraction, &
         trace_chi2_seismo_ratios_info, &
         trace_chi2_seismo_frequencies_info, &
         trace_chi2_spectro_info, &
         trace_chi2_seismo_delta_nu_info, &
         trace_chi2_seismo_nu_max_info, &
         delta_nu, delta_nu_sigma, &
         nu_max, nu_max_sigma, &
         
         include_logg_in_chi2_spectro, &
         logg_target, logg_sigma, &
         
         include_logL_in_chi2_spectro, &
         logL_target, logL_sigma, &
         
         include_Teff_in_chi2_spectro, &
         Teff_target, Teff_sigma, &
         
         include_FeH_in_chi2_spectro, &
         FeH_target, FeH_sigma, &
         
         include_logR_in_chi2_spectro, &
         logR_target, logR_sigma, &
         
         include_age_in_chi2_spectro, &
         age_target, age_sigma, &
         num_smaller_steps_before_age_target, &
         dt_for_smaller_steps_before_age_target, &
         
         include_surface_Z_div_X_in_chi2_spectro, &
         surface_Z_div_X_target, surface_Z_div_X_sigma, &
         
         include_surface_He_in_chi2_spectro, &
         surface_He_target, surface_He_sigma, &
         
         include_Rcz_in_chi2_spectro, &
         Rcz_target, Rcz_sigma, &
         
         include_csound_rms_in_chi2_spectro, &
         csound_rms_target, csound_rms_sigma, &
         report_csound_rms, &
         
         include_my_var1_in_chi2_spectro, &
         my_var1_target, my_var1_sigma, my_var1_name, &
         
         include_my_var2_in_chi2_spectro, &
         my_var2_target, my_var2_sigma, my_var2_name, &
         
         include_my_var3_in_chi2_spectro, &
         my_var3_target, my_var3_sigma, my_var3_name, &
         
         Z_div_X_solar, &
         nl0, &
         l0_obs, l0_obs_sigma, &
         nl1, &
         l1_obs, l1_obs_sigma, &
         nl2, &
         l2_obs, l2_obs_sigma, &
         nl3, &
         l3_obs, l3_obs_sigma, &
         
         search_type, &
         
         eval_chi2_at_target_age_only, &
         min_age_for_chi2, &
         max_age_for_chi2, &
         
         simplex_output_filename, &
         simplex_itermax, &
         simplex_fcn_calls_max, simplex_seed, &
         simplex_enforce_bounds, &
         simplex_adaptive_random_search, &
         restart_simplex_from_file, &
         simplex_x_atol, &
         simplex_x_rtol, &
         simplex_chi2_tol, &
         simplex_centroid_weight_power, &

         newuoa_output_filename, &
         newuoa_rhoend, &
         bobyqa_output_filename, &
         bobyqa_rhoend, &
         
         scan_grid_output_filename, &
         restart_scan_grid_from_file, &
         filename_for_parameters, &
         max_num_from_file, &
         file_column_for_FeH, file_column_for_Y, file_column_for_f_ov, &
         file_column_for_alpha, file_column_for_mass, &
         from_file_output_filename, &
         Y_depends_on_Z, Y0, dYdZ, &
         vary_FeH, vary_Y, vary_mass, vary_alpha, vary_f_ov, &
         first_FeH, first_Y, first_mass, first_alpha, first_f_ov, &
         min_FeH, min_Y, min_mass, min_alpha, min_f_ov, &
         max_FeH, max_Y, max_mass, max_alpha, max_f_ov, &
         delta_Y, delta_FeH, delta_mass, delta_alpha, delta_f_ov, &
         f0_ov_div_f_ov, &
         Lnuc_div_L_limit, chi2_spectroscopic_limit, &
         chi2_radial_limit, chi2_delta_nu_limit, &
         max_yrs_dt_when_cold, max_yrs_dt_when_warm, max_yrs_dt_when_hot, &
         max_yrs_dt_chi2_small_limit, chi2_limit_for_small_timesteps, &
         max_yrs_dt_chi2_smaller_limit, chi2_limit_for_smaller_timesteps, &
         max_yrs_dt_chi2_smallest_limit, chi2_limit_for_smallest_timesteps, &
         chi2_search_limit1, chi2_search_limit2, &
         limit_num_chi2_too_big, chi2_relative_increase_limit, &
         avg_age_sigma_limit, avg_model_number_sigma_limit, &
         min_num_samples_for_avg, max_num_samples_for_avg, &
         sigmas_coeff_for_logg_limit, &
         sigmas_coeff_for_logL_limit, &
         sigmas_coeff_for_Teff_limit, &
         
         sigmas_coeff_for_logR_limit, &
         sigmas_coeff_for_surface_Z_div_X_limit, &
         sigmas_coeff_for_surface_He_limit, &
         sigmas_coeff_for_Rcz_limit, &
         sigmas_coeff_for_csound_rms_limit, &
         sigmas_coeff_for_my_var1_limit, &
         sigmas_coeff_for_my_var2_limit, &
         sigmas_coeff_for_my_var3_limit, &
         
         sigmas_coeff_for_delta_nu_limit, &
         min_age_limit, &
         correction_scheme, correction_b, correction_factor, &
         l0_n_obs, &
         write_best_model_data_for_each_sample, &
         num_digits, &
         sample_results_prefix, sample_results_postfix, &
         model_num_digits, &
         
         write_fgong_for_each_model, &
         fgong_prefix, fgong_postfix, &
         write_fgong_for_best_model, best_model_fgong_filename, &
         
         write_gyre_for_each_model, &
         gyre_prefix, gyre_postfix, &
         write_gyre_for_best_model, best_model_gyre_filename, &
         max_num_gyre_points, &
         
         write_profile_for_best_model, best_model_profile_filename, &
         save_model_for_best_model, best_model_save_model_filename, &
         save_info_for_last_model, last_model_save_info_filename, &
         shell_script_for_each_sample, shell_script_num_string_char, &
         trace_limits, save_controls, save_controls_filename, &
         Y_frac_he3, &
         save_mode_model_number, save_mode_filename, &
         save_next_best_at_higher_frequency, &
         save_next_best_at_lower_frequency, &
         
         oscillation_code, &
         gyre_input_file, &
         gyre_non_ad, &
         
         el_to_save, &
         order_to_save, &
         em_to_save, &
         add_atmosphere, &
         keep_surface_point, &
         add_center_point, &
         do_redistribute_mesh, &
         trace_time_in_oscillation_code, &
         iscan_factor_l0, iscan_factor_l1, iscan_factor_l2, iscan_factor_l3, &
         adipls_irotkr, adipls_nprtkr, adipls_igm1kr, adipls_npgmkr, &
         nu_lower_factor, nu_upper_factor, &
         read_extra_astero_search_inlist1, &
         extra_astero_search_inlist1_name, &
         read_extra_astero_search_inlist2, &
         extra_astero_search_inlist2_name, &
         read_extra_astero_search_inlist3, &
         extra_astero_search_inlist3_name, &
         read_extra_astero_search_inlist4, &
         extra_astero_search_inlist4_name, &
         read_extra_astero_search_inlist5, &
         extra_astero_search_inlist5_name
            
      
      ! pgstar plots

      logical :: echelle_win_flag, echelle_file_flag
      integer :: echelle_file_interval
      character (len=256) :: echelle_file_dir, echelle_file_prefix, &
         echelle_best_model_file_prefix, echelle_title
      real :: &
         echelle_win_width, echelle_win_aspect_ratio, &
         echelle_file_width, echelle_file_aspect_ratio, &
         echelle_xleft, echelle_xright, echelle_ybot, echelle_ytop, &
         echelle_txt_scale, echelle_delta_nu, echelle_model_alt_y_shift
      logical :: &
         show_echelle_next_best_at_higher_frequency, &
         show_echelle_next_best_at_lower_frequency, &
         show_echelle_annotation1, &
         show_echelle_annotation2, &
         show_echelle_annotation3      

      logical :: ratios_win_flag, ratios_file_flag
      integer :: ratios_file_interval
      character (len=256) :: ratios_file_dir, ratios_file_prefix, &
         ratios_best_model_file_prefix, ratios_title
      real :: &
         ratios_win_width, ratios_win_aspect_ratio, &
         ratios_file_width, ratios_file_aspect_ratio, &
         ratios_xleft, ratios_xright, ratios_ybot, &
         ratios_ytop, ratios_txt_scale, ratios_margin_sig_factor
      logical :: &
         show_ratios_annotation1, &
         show_ratios_annotation2, &
         show_ratios_annotation3      
      
      logical :: read_extra_astero_pgstar_inlist1
      character (len=256) :: extra_astero_pgstar_inlist1_name 
      
      logical :: read_extra_astero_pgstar_inlist2
      character (len=256) :: extra_astero_pgstar_inlist2_name 
      
      logical :: read_extra_astero_pgstar_inlist3
      character (len=256) :: extra_astero_pgstar_inlist3_name 
      
      logical :: read_extra_astero_pgstar_inlist4
      character (len=256) :: extra_astero_pgstar_inlist4_name 
      
      logical :: read_extra_astero_pgstar_inlist5
      character (len=256) :: extra_astero_pgstar_inlist5_name 
         
      namelist /astero_pgstar_controls/ &
         echelle_win_flag, echelle_file_flag, &
         echelle_file_interval, &
         echelle_file_dir, echelle_file_prefix, echelle_best_model_file_prefix, &
         echelle_win_width, echelle_win_aspect_ratio, &
         echelle_file_width, echelle_file_aspect_ratio, &
         echelle_xleft, echelle_xright, echelle_ybot, echelle_ytop, &
         echelle_txt_scale, echelle_delta_nu, echelle_title, &
         echelle_model_alt_y_shift, &
         show_echelle_next_best_at_higher_frequency, &
         show_echelle_next_best_at_lower_frequency, &
         show_echelle_annotation1, &
         show_echelle_annotation2, &
         show_echelle_annotation3, &
         ratios_win_flag, ratios_file_flag, &
         ratios_file_interval, ratios_title, &
         ratios_file_dir, ratios_file_prefix, ratios_best_model_file_prefix, &
         ratios_win_width, ratios_win_aspect_ratio, &
         ratios_file_width, ratios_file_aspect_ratio, &
         ratios_xleft, ratios_xright, ratios_ybot, &
         ratios_ytop, ratios_txt_scale, ratios_margin_sig_factor, &
         show_ratios_annotation1, &
         show_ratios_annotation2, &
         show_ratios_annotation3, &
         read_extra_astero_pgstar_inlist1, extra_astero_pgstar_inlist1_name, &
         read_extra_astero_pgstar_inlist2, extra_astero_pgstar_inlist2_name, &
         read_extra_astero_pgstar_inlist3, extra_astero_pgstar_inlist3_name, &
         read_extra_astero_pgstar_inlist4, extra_astero_pgstar_inlist4_name, &
         read_extra_astero_pgstar_inlist5, extra_astero_pgstar_inlist5_name



      ! private data
      
      
      ! working storage for models and search results
      real(dp) :: l0_freq(max_nl0), l0_freq_corr(max_nl0), &
         l0_inertia(max_nl0)
      real(dp) :: l1_freq(max_nl1), l1_freq_corr(max_nl1), &
         l1_inertia(max_nl1)
      real(dp) :: l2_freq(max_nl2), l2_freq_corr(max_nl2), &
         l2_inertia(max_nl2)
      real(dp) :: l3_freq(max_nl3), l3_freq_corr(max_nl3), &
         l3_inertia(max_nl3)
      integer :: l0_order(max_nl0), l1_order(max_nl1), &
         l2_order(max_nl2), l3_order(max_nl3)
         
      ! next best fit at higher frequency
      real(dp) :: l1_freq_alt_up(max_nl1), l1_freq_corr_alt_up(max_nl1), &
         l1_inertia_alt_up(max_nl1)
      real(dp) :: l2_freq_alt_up(max_nl2), l2_freq_corr_alt_up(max_nl2), &
         l2_inertia_alt_up(max_nl2)
      real(dp) :: l3_freq_alt_up(max_nl3), l3_freq_corr_alt_up(max_nl3), &
         l3_inertia_alt_up(max_nl3)
      integer :: l1_order_alt_up(max_nl1), l2_order_alt_up(max_nl2), &
         l3_order_alt_up(max_nl3)
         
      ! next best fit at lower frequency
      real(dp) :: l1_freq_alt_down(max_nl1), l1_freq_corr_alt_down(max_nl1), &
         l1_inertia_alt_down(max_nl1)
      real(dp) :: l2_freq_alt_down(max_nl2), l2_freq_corr_alt_down(max_nl2), &
         l2_inertia_alt_down(max_nl2)
      real(dp) :: l3_freq_alt_down(max_nl3), l3_freq_corr_alt_down(max_nl3), &
         l3_inertia_alt_down(max_nl3)
      integer :: l1_order_alt_down(max_nl1), l2_order_alt_down(max_nl2), &
         l3_order_alt_down(max_nl3)

      integer, dimension(max_nl0) :: i2_for_r02
      
      ! frequency ratios for model
      integer :: model_ratios_n, model_ratios_l0_first, model_ratios_l1_first
      real(dp), dimension(max_nl0) :: &
         model_ratios_r01, &
         model_ratios_r10, &
         model_ratios_r02
      
      logical :: have_radial, have_nonradial
      
      real(dp) :: min_sample_chi2_so_far = -1
      integer :: sample_number, nvar, num_chi2_too_big
      
      integer :: &
         i_Y, i_FeH, &
         i_mass, i_alpha, i_f_ov
      real(dp) :: &
         final_Y, final_FeH, &
         final_mass, final_alpha, final_f_ov
      
      real(dp) :: initial_max_years_for_timestep
      logical :: okay_to_restart
      real(dp) :: nu_max_sun, delta_nu_sun

      real(dp) :: &
         next_FeH_to_try, next_Y_to_try, &
         next_initial_h1_to_try, next_initial_he3_to_try, &
         next_initial_he4_to_try, &
         next_mass_to_try, next_alpha_to_try, next_f_ov_to_try

      real(dp) :: avg_nu_obs, avg_radial_n
      real(dp) :: chi2_seismo_freq_fraction

      character (len=256) :: inlist_astero_fname

      real(dp) :: &
         best_chi2, &
         best_chi2_seismo, &
         best_chi2_spectro, &
         best_init_h1, &
         best_init_he3, &
         best_init_he4, &
         best_init_Z, &
         best_age, &
         best_radius, &
         best_logL, &
         best_Teff, &
         best_logg, &
         best_FeH, &
         best_logR, &
         best_surface_Z_div_X, &
         best_surface_He, &
         best_Rcz, &
         best_csound_rms, &
         best_my_var1, &
         best_my_var2, &
         best_my_var3, &
         best_delta_nu, &
         best_nu_max, &
         best_a_div_r, &
         best_correction_r
         
      integer :: &
         best_model_number
         
      integer :: &
         best_l0_order(max_nl0), &
         best_l1_order(max_nl1), &
         best_l2_order(max_nl2), &
         best_l3_order(max_nl3)
      real(dp), dimension (max_nl0) :: &
         best_l0_freq, &
         best_l0_freq_corr, &
         best_l0_inertia
      real(dp), dimension (max_nl1) :: &
         best_l1_freq, &
         best_l1_freq_corr, &
         best_l1_inertia
      real(dp), dimension (max_nl2) :: &
         best_l2_freq, &
         best_l2_freq_corr, &
         best_l2_inertia
      real(dp), dimension (max_nl3) :: &
         best_l3_freq, &
         best_l3_freq_corr, &
         best_l3_inertia
      
      real(dp), dimension(max_nl0) :: &
         best_ratios_r01, &
         best_ratios_r10, &
         best_ratios_r02
         
      integer :: max_num_samples
      integer :: scan_grid_skip_number
             
      real(dp), pointer, dimension(:) :: &
         sample_chi2, &
         sample_chi2_seismo, &
         sample_chi2_spectro, &
         sample_age, &
         sample_init_Y, &
         sample_init_FeH, &
         sample_init_h1, &
         sample_init_he3, &
         sample_init_he4, &
         sample_init_Z, &
         sample_mass, &
         sample_alpha, &
         sample_f_ov, &
         sample_radius, &
         sample_logL, &
         sample_Teff, &
         sample_logg, &
         sample_FeH, &
         sample_logR, &
         sample_surface_Z_div_X, &
         sample_surface_He, &
         sample_Rcz, &
         sample_csound_rms, &
         sample_my_var1, &
         sample_my_var2, &
         sample_my_var3, &
         sample_delta_nu, &
         sample_nu_max, &
         sample_a_div_r, &
         sample_correction_r
         
      integer, pointer, dimension(:) :: &
         sample_index_by_chi2, &
         sample_model_number, &
         sample_op_code
         
      integer, pointer, dimension(:,:) :: &
         sample_l0_order, &
         sample_l1_order, &
         sample_l2_order, &
         sample_l3_order
         
      real(dp), pointer, dimension(:,:) :: &
         sample_l0_freq, &
         sample_l0_freq_corr, &
         sample_l0_inertia, &
         sample_l1_freq, &
         sample_l1_freq_corr, &
         sample_l1_inertia, &
         sample_l2_freq, &
         sample_l2_freq_corr, &
         sample_l2_inertia, &
         sample_l3_freq, &
         sample_l3_freq_corr, &
         sample_l3_inertia

      real(dp), pointer, dimension(:,:) :: &
         sample_ratios_r01, &
         sample_ratios_r10, &
         sample_ratios_r02

      real(dp) :: astero_max_dt_next
            
      real(dp) :: avg_age_top_samples, avg_age_sigma, &
         avg_model_number_top_samples, avg_model_number_sigma

      real(dp) :: a_div_r, correction_a, correction_r, &
         nu_max_model, delta_nu_model, avg_nu_model, chi2, &
         chi2_seismo, chi2_spectro, chi2_radial, chi2_delta_nu, chi2_nu_max, &
         chi2_r_010_ratios, chi2_r_02_ratios, chi2_frequencies, &
         initial_Y, initial_FeH, initial_Z_div_X, &
         logg, FeH, logR, surface_Z_div_X, surface_He, Rcz, csound_rms, &
         my_var1, my_var2, my_var3

      integer :: star_id, star_model_number
      integer :: num_chi2_seismo_terms, num_chi2_spectro_terms
      
      ! current values for parameters set by adipls_extras_controls
      real(dp) :: &
         current_Y, &
         current_FeH, &
         current_mass, &
         current_alpha, &
         current_f_ov, &
         current_h1, &
         current_he3, &
         current_he4, &
         current_Z

      integer, parameter :: num_extra_history_columns = 5

      type (pgstar_win_file_data), pointer :: p_echelle, p_ratios
      

      ! solar sound speed data
      logical :: have_sound_speed_data = .false.
      integer, parameter :: npts = 79
      real(dp), dimension(npts) :: data_r, data_csound, data_width

      
      contains
      

      ! called from adipls_support_procs/ spcout_adi

      subroutine store_new_oscillation_results( &
            new_el, new_order, new_em, new_cyclic_freq, new_inertia,  &
	    new_beta, new_split1, new_split2, new_split3, new_splitted_freq, &     ! added by me 
	    new_growth_rate, ierr)

         integer, intent(in) :: new_el, new_order, new_em
         real(dp), intent(in) :: new_cyclic_freq, new_inertia, new_beta,  &
	    new_split1, new_split2, new_split3, new_splitted_freq, new_growth_rate
         integer, intent(out) :: ierr
         
         integer :: n
         
         include 'formats'

         write(*,*) 'Subroutine store_new_oscillation_results called'
         
         ierr = 0
         n = num_results*3/2 + 50
         if (.not. associated(el)) allocate(el(n))
         if (.not. associated(order)) allocate(order(n))
         if (.not. associated(em)) allocate(em(n))
         if (.not. associated(cyclic_freq)) allocate(cyclic_freq(n))
         if (.not. associated(inertia)) allocate(inertia(n))
	 if (.not. associated(beta)) allocate(beta(n))       ! added by me 
	 if (.not. associated(split1)) allocate(split1(n))
	 if (.not. associated(split2)) allocate(split2(n))
	 if (.not. associated(split3)) allocate(split3(n))
	 if (.not. associated(splitted_freq)) allocate(splitted_freq(n))
         if (.not. associated(growth_rate)) allocate(growth_rate(n))

         
         if (num_results >= size(el,dim=1)) then ! enlarge
            call realloc_integer(el,n,ierr)
            if (ierr /= 0) call mesa_error(__FILE__,__LINE__)
            call realloc_integer(order,n,ierr)
            if (ierr /= 0) call mesa_error(__FILE__,__LINE__)
            call realloc_integer(em,n,ierr)
            if (ierr /= 0) call mesa_error(__FILE__,__LINE__)
            call realloc_double(cyclic_freq,n,ierr)
            if (ierr /= 0) call mesa_error(__FILE__,__LINE__)
            call realloc_double(inertia,n,ierr)
            if (ierr /= 0) call mesa_error(__FILE__,__LINE__)
            call realloc_double(beta,n,ierr)                    ! added by me 
            if (ierr /= 0) call mesa_error(__FILE__,__LINE__)
            call realloc_double(split1,n,ierr)
            if (ierr /= 0) call mesa_error(__FILE__,__LINE__)
            call realloc_double(split2,n,ierr)
            if (ierr /= 0) call mesa_error(__FILE__,__LINE__)
            call realloc_double(split3,n,ierr)
            if (ierr /= 0) call mesa_error(__FILE__,__LINE__)
            call realloc_double(splitted_freq,n,ierr)
            if (ierr /= 0) call mesa_error(__FILE__,__LINE__)
            call realloc_double(growth_rate,n,ierr)
            if (ierr /= 0) call mesa_error(__FILE__,__LINE__)

         end if

         num_results = num_results+1
         
         n = num_results
         el(n) = new_el
         order(n) = new_order
         em(n) = new_em
         cyclic_freq(n) = new_cyclic_freq
         inertia(n) = new_inertia
	 beta(n) = new_beta        ! added by me 
	 split1(n) = new_split1 
	 split2(n) = new_split2 
	 split3(n) = new_split3
	 splitted_freq(n) = new_splitted_freq
         growth_rate(n) = new_growth_rate

         write(*,*) 'Show me em(n),split1(n) in astero_data store_new_oscillation_results'
         write(*,*) em(n), split1(n)
         write(*,*) 'Show me splitted_freq(n) in astero_data store_new_oscillation_results'
         write(*,*) splitted_freq(n)  
         
      end subroutine store_new_oscillation_results

         
      subroutine init_sample_ptrs
         nullify( &
            sample_chi2, &
            sample_chi2_seismo, &
            sample_chi2_spectro, &
            sample_age, &
            sample_init_Y, &
            sample_init_FeH, &
            sample_init_h1, &
            sample_init_he3, &
            sample_init_he4, &
            sample_init_Z, &
            sample_mass, &
            sample_alpha, &
            sample_f_ov, &
            sample_radius, &
            sample_logL, &
            sample_Teff, &
            sample_logg, &
            sample_FeH, &
            sample_logR, &
            sample_surface_Z_div_X, &
            sample_surface_He, &
            sample_Rcz, &
            sample_csound_rms, &
            sample_my_var1, &
            sample_my_var2, &
            sample_my_var3, &
            sample_delta_nu, &
            sample_nu_max, &
            sample_a_div_r, &
            sample_correction_r, &
            sample_op_code, &
            sample_model_number, &
            sample_index_by_chi2, &
            sample_l0_order, &
            sample_l1_order, &
            sample_l2_order, &
            sample_l3_order, &
            sample_l0_freq, &
            sample_l0_freq_corr, &
            sample_l0_inertia, &
            sample_l1_freq, &
            sample_l1_freq_corr, &
            sample_l1_inertia, &
            sample_l2_freq, &
            sample_l2_freq_corr, &
            sample_l2_inertia, &
            sample_l3_freq, &
            sample_l3_freq_corr, &
            sample_l3_inertia, &
            sample_ratios_r01, &
            sample_ratios_r10, &
            sample_ratios_r02)
      end subroutine init_sample_ptrs
      
      
      subroutine alloc_sample_ptrs(ierr)
         use utils_lib
         integer, intent(out) :: ierr
         ierr = 0
         max_num_samples = 1.5*max_num_samples + 200
         
         call realloc_double(sample_chi2,max_num_samples,ierr); if (ierr /= 0) return
         call realloc_double(sample_chi2_seismo,max_num_samples,ierr); if (ierr /= 0) return
         call realloc_double(sample_chi2_spectro,max_num_samples,ierr); if (ierr /= 0) return
         call realloc_double(sample_age,max_num_samples,ierr); if (ierr /= 0) return
         call realloc_double(sample_init_Y,max_num_samples,ierr); if (ierr /= 0) return
         call realloc_double(sample_init_FeH,max_num_samples,ierr); if (ierr /= 0) return
         call realloc_double(sample_init_h1,max_num_samples,ierr); if (ierr /= 0) return
         call realloc_double(sample_init_he3,max_num_samples,ierr); if (ierr /= 0) return
         call realloc_double(sample_init_he4,max_num_samples,ierr); if (ierr /= 0) return
         call realloc_double(sample_init_Z,max_num_samples,ierr); if (ierr /= 0) return
         call realloc_double(sample_mass,max_num_samples,ierr); if (ierr /= 0) return
         call realloc_double(sample_alpha,max_num_samples,ierr); if (ierr /= 0) return
         call realloc_double(sample_f_ov,max_num_samples,ierr); if (ierr /= 0) return
         call realloc_double(sample_radius,max_num_samples,ierr); if (ierr /= 0) return
         call realloc_double(sample_logL,max_num_samples,ierr); if (ierr /= 0) return
         call realloc_double(sample_Teff,max_num_samples,ierr); if (ierr /= 0) return
         call realloc_double(sample_logg,max_num_samples,ierr); if (ierr /= 0) return
         call realloc_double(sample_FeH,max_num_samples,ierr); if (ierr /= 0) return
         
         call realloc_double(sample_logR,max_num_samples,ierr); if (ierr /= 0) return
         call realloc_double(sample_surface_Z_div_X,max_num_samples,ierr); if (ierr /= 0) return
         call realloc_double(sample_surface_He,max_num_samples,ierr); if (ierr /= 0) return
         call realloc_double(sample_Rcz,max_num_samples,ierr); if (ierr /= 0) return
         call realloc_double(sample_csound_rms,max_num_samples,ierr); if (ierr /= 0) return
         call realloc_double(sample_my_var1,max_num_samples,ierr); if (ierr /= 0) return
         call realloc_double(sample_my_var2,max_num_samples,ierr); if (ierr /= 0) return
         call realloc_double(sample_my_var3,max_num_samples,ierr); if (ierr /= 0) return
         
         call realloc_double(sample_delta_nu,max_num_samples,ierr); if (ierr /= 0) return
         call realloc_double(sample_nu_max,max_num_samples,ierr); if (ierr /= 0) return
         call realloc_double(sample_a_div_r,max_num_samples,ierr); if (ierr /= 0) return
         call realloc_double(sample_correction_r,max_num_samples,ierr); if (ierr /= 0) return

         call realloc_integer(sample_index_by_chi2,max_num_samples,ierr); if (ierr /= 0) return
            
         call realloc_integer(sample_op_code,max_num_samples,ierr); if (ierr /= 0) return
         call realloc_integer(sample_model_number,max_num_samples,ierr); if (ierr /= 0) return
         call realloc_integer2(sample_l0_order,max_nl0,max_num_samples,ierr); if (ierr /= 0) return
         call realloc_integer2(sample_l1_order,max_nl1,max_num_samples,ierr); if (ierr /= 0) return
         call realloc_integer2(sample_l2_order,max_nl2,max_num_samples,ierr); if (ierr /= 0) return
         call realloc_integer2(sample_l3_order,max_nl2,max_num_samples,ierr); if (ierr /= 0) return
            
         call realloc_double2(sample_l0_freq,max_nl0,max_num_samples,ierr); if (ierr /= 0) return
         call realloc_double2(sample_l0_freq_corr,max_nl0,max_num_samples,ierr); if (ierr /= 0) return
         call realloc_double2(sample_l0_inertia,max_nl0,max_num_samples,ierr); if (ierr /= 0) return
         
         call realloc_double2(sample_l1_freq,max_nl1,max_num_samples,ierr); if (ierr /= 0) return
         call realloc_double2(sample_l1_freq_corr,max_nl1,max_num_samples,ierr); if (ierr /= 0) return
         call realloc_double2(sample_l1_inertia,max_nl1,max_num_samples,ierr); if (ierr /= 0) return
         
         call realloc_double2(sample_l2_freq,max_nl2,max_num_samples,ierr); if (ierr /= 0) return
         call realloc_double2(sample_l2_freq_corr,max_nl2,max_num_samples,ierr); if (ierr /= 0) return
         call realloc_double2(sample_l2_inertia,max_nl2,max_num_samples,ierr); if (ierr /= 0) return
         
         call realloc_double2(sample_l3_freq,max_nl3,max_num_samples,ierr); if (ierr /= 0) return
         call realloc_double2(sample_l3_freq_corr,max_nl3,max_num_samples,ierr); if (ierr /= 0) return
         call realloc_double2(sample_l3_inertia,max_nl3,max_num_samples,ierr); if (ierr /= 0) return

         call realloc_double2(sample_ratios_r01,max_nl0,max_num_samples,ierr); if (ierr /= 0) return
         call realloc_double2(sample_ratios_r10,max_nl0,max_num_samples,ierr); if (ierr /= 0) return
         call realloc_double2(sample_ratios_r02,max_nl0,max_num_samples,ierr); if (ierr /= 0) return

      end subroutine alloc_sample_ptrs
   
   
      subroutine read_astero_search_controls(filename, ierr)
         character (len=*), intent(in) :: filename
         integer, intent(out) :: ierr
         ! initialize controls to default values
         include 'astero_search.defaults'
         ierr = 0
         call read1_astero_search_inlist(filename, 1, ierr)
      end subroutine read_astero_search_controls
         
         
      recursive subroutine read1_astero_search_inlist(filename, level, ierr)
         character (len=*), intent(in) :: filename
         integer, intent(in) :: level  
         integer, intent(out) :: ierr
         
         logical :: read_extra1, read_extra2, read_extra3, read_extra4, read_extra5
         character (len=256) :: message, extra1, extra2, extra3, extra4, extra5
         integer :: unit
         
         if (level >= 10) then
            write(*,*) 'ERROR: too many levels of nested extra star_job inlist files'
            ierr = -1
            return
         end if
         
         ierr = 0
         unit=alloc_iounit(ierr)
         if (ierr /= 0) return
         
         open(unit=unit, file=trim(filename), action='read', delim='quote', iostat=ierr)
         if (ierr /= 0) then
            write(*, *) 'Failed to open astero search inlist file ', trim(filename)
         else
            read(unit, nml=astero_search_controls, iostat=ierr)  
            close(unit)
            if (ierr /= 0) then
               write(*, *) &
                  'Failed while trying to read astero search inlist file ', trim(filename)
               write(*, '(a)') trim(message)
               write(*, '(a)') &
                  'The following runtime error message might help you find the problem'
               write(*, *) 
               open(unit=unit, file=trim(filename), &
                  action='read', delim='quote', status='old', iostat=ierr)
               read(unit, nml=astero_search_controls)
               close(unit)
            end if  
         end if
         call free_iounit(unit)
         if (ierr /= 0) return
         
         ! recursive calls to read other inlists
         
         read_extra1 = read_extra_astero_search_inlist1
         read_extra_astero_search_inlist1 = .false.
         extra1 = extra_astero_search_inlist1_name
         extra_astero_search_inlist1_name = 'undefined'
         
         read_extra2 = read_extra_astero_search_inlist2
         read_extra_astero_search_inlist2 = .false.
         extra2 = extra_astero_search_inlist2_name
         extra_astero_search_inlist2_name = 'undefined'
         
         read_extra3 = read_extra_astero_search_inlist3
         read_extra_astero_search_inlist3 = .false.
         extra3 = extra_astero_search_inlist3_name
         extra_astero_search_inlist3_name = 'undefined'
         
         read_extra4 = read_extra_astero_search_inlist4
         read_extra_astero_search_inlist4 = .false.
         extra4 = extra_astero_search_inlist4_name
         extra_astero_search_inlist4_name = 'undefined'
         
         read_extra5 = read_extra_astero_search_inlist5
         read_extra_astero_search_inlist5 = .false.
         extra5 = extra_astero_search_inlist5_name
         extra_astero_search_inlist5_name = 'undefined'
         
         if (read_extra1) then
            !write(*,*) 'read extra astero_search inlist1 from ' // trim(extra1)
            call read1_astero_search_inlist(extra1, level+1, ierr)
            if (ierr /= 0) return
         end if
         
         if (read_extra2) then
            !write(*,*) 'read extra astero_search inlist2 from ' // trim(extra2)
            call read1_astero_search_inlist(extra2, level+1, ierr)
            if (ierr /= 0) return
         end if
         
         if (read_extra3) then
            !write(*,*) 'read extra astero_search inlist3 from ' // trim(extra3)
            call read1_astero_search_inlist(extra3, level+1, ierr)
            if (ierr /= 0) return
         end if
         
         if (read_extra4) then
            !write(*,*) 'read extra astero_search inlist4 from ' // trim(extra4)
            call read1_astero_search_inlist(extra4, level+1, ierr)
            if (ierr /= 0) return
         end if
         
         if (read_extra5) then
            write(*,*) 'read extra astero_search inlist5 from ' // trim(extra5)
            call read1_astero_search_inlist(extra5, level+1, ierr)
            if (ierr /= 0) return
         end if
         
      end subroutine read1_astero_search_inlist


      subroutine write_astero_search_controls(filename_in, ierr)
         use utils_lib
         character(*), intent(in) :: filename_in
         integer, intent(out) :: ierr
         character (len=256) :: filename
         integer :: unit
         ierr = 0
         filename = trim(filename_in)
         if (len_trim(filename) == 0) filename = 'astero_search_controls.out'
         unit=alloc_iounit(ierr)
         if (ierr /= 0) then
            write(*,*) 'failed to alloc iounit in write_astero_search_controls'
            return
         end if
         ! NOTE: when open namelist file, must include delim='APOSTROPHE'
         open(unit=unit, file=trim(filename), action='write', delim='APOSTROPHE', iostat=ierr)
         if (ierr /= 0) then
            write(*, *) 'Failed to open ', trim(filename)
         else
            write(unit, nml=astero_search_controls)
            close(unit)
         end if
         call free_iounit(unit)
         
         write(*,*)
         write(*,*) 'saved initial &astero_search_controls to ' // trim(filename)
         write(*,*)
         write(*,*)

      end subroutine write_astero_search_controls
   
   
      subroutine read_astero_pgstar_controls(filename, ierr)
         character (len=*), intent(in) :: filename
         integer, intent(out) :: ierr
         
         ! initialize controls to default values
         include 'astero_pgstar.defaults'
         
         ierr = 0
         call read1_astero_pgstar_inlist(filename, 1, ierr)
         
      end subroutine read_astero_pgstar_controls
      
   
      recursive subroutine read1_astero_pgstar_inlist(filename, level, ierr)
         character (len=*), intent(in) :: filename
         integer, intent(in) :: level  
         integer, intent(out) :: ierr
         
         logical :: read_extra1, read_extra2, read_extra3, read_extra4, read_extra5
         character (len=256) :: message, extra1, extra2, extra3, extra4, extra5
         integer :: unit
         
         if (level >= 10) then
            write(*,*) 'ERROR: too many levels of nested extra star_job inlist files'
            ierr = -1
            return
         end if
         
         ierr = 0
         unit=alloc_iounit(ierr)
         if (ierr /= 0) return
         
         open(unit=unit, file=trim(filename), action='read', delim='quote', iostat=ierr)
         if (ierr /= 0) then
            write(*, *) 'Failed to open astero pgstar inlist file ', trim(filename)
         else
            read(unit, nml=astero_pgstar_controls, iostat=ierr)  
            close(unit)
            if (ierr /= 0) then
               write(*, *) &
                  'Failed while trying to read astero pgstar inlist file ', trim(filename)
               write(*, '(a)') &
                  'The following runtime error message might help you find the problem'
               write(*, *) 
               open(unit=unit, file=trim(filename), &
                  action='read', delim='quote', status='old', iostat=ierr)
               read(unit, nml=astero_pgstar_controls)
               close(unit)
            end if  
         end if
         call free_iounit(unit)
         if (ierr /= 0) return
         
         ! recursive calls to read other inlists
         
         read_extra1 = read_extra_astero_pgstar_inlist1
         read_extra_astero_pgstar_inlist1 = .false.
         extra1 = extra_astero_pgstar_inlist1_name
         extra_astero_pgstar_inlist1_name = 'undefined'
         
         read_extra2 = read_extra_astero_pgstar_inlist2
         read_extra_astero_pgstar_inlist2 = .false.
         extra2 = extra_astero_pgstar_inlist2_name
         extra_astero_pgstar_inlist2_name = 'undefined'
         
         read_extra3 = read_extra_astero_pgstar_inlist3
         read_extra_astero_pgstar_inlist3 = .false.
         extra3 = extra_astero_pgstar_inlist3_name
         extra_astero_pgstar_inlist3_name = 'undefined'
         
         read_extra4 = read_extra_astero_pgstar_inlist4
         read_extra_astero_pgstar_inlist4 = .false.
         extra4 = extra_astero_pgstar_inlist4_name
         extra_astero_pgstar_inlist4_name = 'undefined'
         
         read_extra5 = read_extra_astero_pgstar_inlist5
         read_extra_astero_pgstar_inlist5 = .false.
         extra5 = extra_astero_pgstar_inlist5_name
         extra_astero_pgstar_inlist5_name = 'undefined'
         
         if (read_extra1) then
            !write(*,*) 'read extra astero_pgstar inlist1 from ' // trim(extra1)
            call read1_astero_pgstar_inlist(extra1, level+1, ierr)
            if (ierr /= 0) return
         end if
         
         if (read_extra2) then
            !write(*,*) 'read extra astero_pgstar inlist2 from ' // trim(extra2)
            call read1_astero_pgstar_inlist(extra2, level+1, ierr)
            if (ierr /= 0) return
         end if
         
         if (read_extra3) then
            !write(*,*) 'read extra astero_pgstar inlist3 from ' // trim(extra3)
            call read1_astero_pgstar_inlist(extra3, level+1, ierr)
            if (ierr /= 0) return
         end if
         
         if (read_extra4) then
            !write(*,*) 'read extra astero_pgstar inlist4 from ' // trim(extra4)
            call read1_astero_pgstar_inlist(extra4, level+1, ierr)
            if (ierr /= 0) return
         end if
         
         if (read_extra5) then
            write(*,*) 'read extra astero_pgstar inlist5 from ' // trim(extra5)
            call read1_astero_pgstar_inlist(extra5, level+1, ierr)
            if (ierr /= 0) return
         end if
         
      end subroutine read1_astero_pgstar_inlist


      subroutine save_sample_results_to_file(i_total, results_fname, ierr)
         use utils_lib
         integer, intent(in) :: i_total
         character (len=*), intent(in) :: results_fname
         integer, intent(out) :: ierr
         integer :: iounit
         write(*,*) 'save_sample_results_to_file ' // trim(results_fname)
         iounit = alloc_iounit(ierr)
         if (ierr /= 0) stop 'alloc_iounit failed'
         open(unit=iounit, file=trim(results_fname), action='write', iostat=ierr)
         if (ierr /= 0) return
         call show_all_sample_results(iounit, i_total, ierr)
         close(iounit)
         call free_iounit(iounit)         
      end subroutine save_sample_results_to_file
      
      
      subroutine set_sample_index_by_chi2
         use num_lib, only: qsort
         if (sample_number <= 0) return
         if (sample_number == 1) then
            sample_index_by_chi2(1) = 1
            return
         end if
         call qsort(sample_index_by_chi2, sample_number, sample_chi2)
      end subroutine set_sample_index_by_chi2
      
      
      subroutine show_sample_header(iounit)
         integer, intent(in) ::iounit
         
         integer :: j
         character (len=10) :: str
      
         write(iounit,'(2x,a6,7a26,a16,22a26,7a20)',advance='no') &
            'sample', &
            
            'chi2', &
            'mass', &
            'init_Y', &
            'init_FeH', &
            'alpha', &
            'f_ov', &
            'age', &
            
            'model_number', &
            
            'init_h1', &
            'init_he3', &
            'init_he4', &
            'init_Z', &
            'log_radius', &
            'logL', &
            'Teff', &
            'logg', &
            'Fe_H', &
            'logR', &
            'surface_Z_div_X', &
            'surface_He', &
            'Rcz', &
            'csound_rms', &
            trim(my_var1_name), &
            trim(my_var2_name), &
            trim(my_var3_name), &
            'delta_nu', &
            'a_div_r', &
            'correction_r', &
            'chi2_seismo', &
            'chi2_spectro', &
            
            'nl0', &
            'nl1', &
            'nl2', &
            'nl3', &
            'ratios_n', &
            'ratios_l0_first', &
            'ratios_l1_first'
         
         if (chi2_seismo_fraction > 0) then
         
            do j=1,nl0
               if (j < 10) then
                  write(str,'(i1)') j
               else if (j < 100) then
                  write(str,'(i2)') j
               else
                  write(str,'(i3)') j
               end if
               write(iounit,'(99a26)',advance='no') &
                  'l0_order_' // trim(str), &
                  'l0_obs_' // trim(str), &
                  'l0_obs_sigma_' // trim(str), &
                  'l0_freq_' // trim(str), &
                  'l0_freq_corr_' // trim(str), &
                  'l0_inertia_' // trim(str)
            end do
            
            do j=1,nl1
               if (j < 10) then
                  write(str,'(i1)') j
               else if (j < 100) then
                  write(str,'(i2)') j
               else
                  write(str,'(i3)') j
               end if
               write(iounit,'(99a26)',advance='no') &
                  'l1_order_' // trim(str), &
                  'l1_obs_' // trim(str), &
                  'l1_obs_sigma_' // trim(str), &
                  'l1_freq_' // trim(str), &
                  'l1_freq_corr_' // trim(str), &
                  'l1_inertia_' // trim(str)
            end do
            
            do j=1,nl2
               if (j < 10) then
                  write(str,'(i1)') j
               else if (j < 100) then
                  write(str,'(i2)') j
               else
                  write(str,'(i3)') j
               end if
               write(iounit,'(99a26)',advance='no') &
                  'l2_order_' // trim(str), &
                  'l2_obs_' // trim(str), &
                  'l2_obs_sigma_' // trim(str), &
                  'l2_freq_' // trim(str), &
                  'l2_freq_corr_' // trim(str), &
                  'l2_inertia_' // trim(str)
            end do
            
            do j=1,nl3
               if (j < 10) then
                  write(str,'(i1)') j
               else if (j < 100) then
                  write(str,'(i2)') j
               else
                  write(str,'(i3)') j
               end if
               write(iounit,'(99a26)',advance='no') &
                  'l3_order_' // trim(str), &
                  'l3_obs_' // trim(str), &
                  'l3_obs_sigma_' // trim(str), &
                  'l3_freq_' // trim(str), &
                  'l3_freq_corr_' // trim(str), &
                  'l3_inertia_' // trim(str)
            end do

            do j=1,ratios_n
               if (j < 10) then
                  write(str,'(i1)') j
               else if (j < 100) then
                  write(str,'(i2)') j
               else
                  write(str,'(i3)') j
               end if
               write(iounit,'(99a26)',advance='no') &
                  'r01_obs_' // trim(str), &
                  'r01_obs_sigmas_' // trim(str), &
                  'r01_' // trim(str), &
                  'r10_obs_' // trim(str), &
                  'r10_obs_sigmas_' // trim(str), &
                  'r10_' // trim(str)
            end do

            do j=1,nl0
               if (j < 10) then
                  write(str,'(i1)') j
               else if (j < 100) then
                  write(str,'(i2)') j
               else
                  write(str,'(i3)') j
               end if
               write(iounit,'(99a26)',advance='no') &
                  'r02_obs_' // trim(str), &
                  'r02_obs_sigmas_' // trim(str), &
                  'r02_' // trim(str)
            end do
         
         end if
         
         write(iounit,*) ! end of line
                                          
      end subroutine show_sample_header
      
      
      subroutine show1_sample_results(i, iounit)
         use num_lib, only: simplex_info_str
         integer, intent(in) :: i, iounit
            
         integer :: j, k, op_code, ierr
         character (len=256) :: info_str
         
         ierr = 0

         op_code = sample_op_code(i) 
         if (op_code <= 0) then
            info_str = ''
         else
            call simplex_info_str(op_code, info_str, ierr)
            if (ierr /= 0) then
               info_str = ''
               ierr = 0
            end if
         end if
         
         write(iounit,'(3x,i5,7(1pes26.16),i16,22(1pes26.16),7i20)',advance='no') i, &
            sample_chi2(i), &
            sample_mass(i), &
            sample_init_Y(i), &
            sample_init_FeH(i), &
            sample_alpha(i), &
            sample_f_ov(i), &
            sample_age(i), &
            sample_model_number(i), &
            sample_init_h1(i), &
            sample_init_he3(i), &
            sample_init_he4(i), &
            sample_init_Z(i), &
            safe_log10_cr(sample_radius(i)), &
            sample_logL(i), &
            sample_Teff(i), &
            sample_logg(i), &
            sample_FeH(i), &
            sample_logR(i), &
            sample_surface_Z_div_X(i), &
            sample_surface_He(i), &
            sample_Rcz(i), &
            sample_csound_rms(i), &
            sample_my_var1(i), &
            sample_my_var2(i), &
            sample_my_var3(i), &
            sample_delta_nu(i), &
            sample_a_div_r(i), &
            sample_correction_r(i), &
            sample_chi2_seismo(i), &
            sample_chi2_spectro(i), &
            nl0, &
            nl1, &
            nl2, &
            nl3, &
            ratios_n, &
            ratios_l0_first, &
            ratios_l1_first
            
         if (iounit == 6) return
         
         if (chi2_seismo_fraction > 0) then
            
            do k=1,nl0
               write(iounit,'(i26,99(1pes26.16))',advance='no') &
                  sample_l0_order(k,i), l0_obs(k), l0_obs_sigma(k), &
                  sample_l0_freq(k,i), sample_l0_freq_corr(k,i), sample_l0_inertia(k,i)
            end do
            
            do k=1,nl1
               write(iounit,'(i26,99(1pes26.16))',advance='no') &
                  sample_l1_order(k,i), l1_obs(k), l1_obs_sigma(k), &
                  sample_l1_freq(k,i), sample_l1_freq_corr(k,i), sample_l1_inertia(k,i)
            end do
            
            do k=1,nl2
               write(iounit,'(i26,99(1pes26.16))',advance='no') &
                  sample_l2_order(k,i), l2_obs(k), l2_obs_sigma(k), &
                  sample_l2_freq(k,i), sample_l2_freq_corr(k,i), sample_l2_inertia(k,i)
            end do
            
            do k=1,nl3
               write(iounit,'(i26,99(1pes26.16))',advance='no') &
                  sample_l3_order(k,i), l3_obs(k), l3_obs_sigma(k), &
                  sample_l3_freq(k,i), sample_l3_freq_corr(k,i), sample_l3_inertia(k,i)
            end do

            do k=1,ratios_n
               write(iounit,'(99(1pes26.16))',advance='no') &
                  ratios_r01(k), sigmas_r01(k), sample_ratios_r01(k,i), &
                  ratios_r10(k), sigmas_r10(k), sample_ratios_r10(k,i)
            end do

            do k=1,nl0
               write(iounit,'(99(1pes26.16))',advance='no') &
                  ratios_r02(k), sigmas_r02(k), sample_ratios_r02(k,i)
            end do
         
         end if
            
         write(iounit,'(a12)') trim(info_str)
      
      
      end subroutine show1_sample_results
      
      
      subroutine show_all_sample_results(iounit, i_total, ierr)
         integer, intent(in) :: iounit, i_total
         integer, intent(out) :: ierr
         integer :: i, j

         ierr = 0
         ! sort results by increasing sample_chi2
         call set_sample_index_by_chi2
         if (i_total > 0) then
            write(iounit,*) sample_number, ' of ', i_total
         else
            write(iounit,*) sample_number, ' samples'
         end if
         call show_sample_header(iounit)
         do j = 1, sample_number
            i = sample_index_by_chi2(j)
            call show1_sample_results(i, iounit)
         end do

         call show_sample_header(iounit)
         do i = 1, 3
            write(iounit,*)
         end do

      end subroutine show_all_sample_results
      
      
      subroutine show_best_el_info(io)
         integer, intent(in) :: io
         
         real(dp) :: chi2term
         integer :: i
          
         write(io,'(/,2a6,99a20)') &
            'l=0', 'n', 'chi2term', 'l0_freq', 'l0_corr', 'l0_obs', 'l0_sigma', 'log E'
         do i = 1, nl0
            if (l0_obs(i) < 0) cycle
            chi2term = pow2((best_l0_freq_corr(i) - l0_obs(i))/l0_obs_sigma(i))
            write(io,'(6x,i6,e20.10,99f20.10)') &
               best_l0_order(i), chi2term, best_l0_freq(i), best_l0_freq_corr(i), &
               l0_obs(i), l0_obs_sigma(i), safe_log10_cr(best_l0_inertia(i))
         end do
      
         if (nl1 > 0) then
            write(io,*)
            write(io,'(2a6,99a20)') &
               'l=1', 'n', 'chi2term', 'l1_freq', 'l1_corr', 'l1_obs', 'l1_sigma', 'log E'
            do i = 1, nl1
               if (l1_obs(i) < 0) cycle
               chi2term = pow2((best_l1_freq_corr(i) - l1_obs(i))/l1_obs_sigma(i))
               if (is_bad(chi2term)) cycle
               write(io,'(6x,i6,e20.10,99f20.10)') &
                  best_l1_order(i), chi2term, best_l1_freq(i), best_l1_freq_corr(i), &
                  l1_obs(i), l1_obs_sigma(i), safe_log10_cr(best_l1_inertia(i))
            end do
         end if
      
         if (nl2 > 0) then
            write(io,*)
            write(io,'(2a6,99a20)') &
               'l=2', 'n', 'chi2term', 'l2_freq', 'l2_corr', 'l2_obs', 'l2_sigma', 'log E'
            do i = 1, nl2
               if (l2_obs(i) < 0) cycle
               chi2term = pow2((best_l2_freq_corr(i) - l2_obs(i))/l2_obs_sigma(i))
               if (is_bad(chi2term)) cycle
               write(io,'(6x,i6,e20.10,99f20.10)') &
                  best_l2_order(i), chi2term, best_l2_freq(i), best_l2_freq_corr(i), &
                  l2_obs(i), l2_obs_sigma(i), safe_log10_cr(best_l2_inertia(i))
            end do
         end if
         
         if (nl3 > 0) then
            write(io,*)
            write(io,'(2a6,99a20)') &
               'l=3', 'n', 'chi2term', 'l3_freq', 'l3_corr', 'l3_obs', 'l3_sigma', 'log E'
            do i = 1, nl3
               if (l3_obs(i) < 0) cycle
               chi2term = pow2((best_l3_freq_corr(i) - l3_obs(i))/l3_obs_sigma(i))
               if (is_bad(chi2term)) cycle
               write(io,'(6x,i6,e20.10,99f20.10)') &
                  best_l3_order(i), chi2term, best_l3_freq(i), best_l3_freq_corr(i), &
                  l3_obs(i), l3_obs_sigma(i), safe_log10_cr(best_l3_inertia(i))
            end do
         end if
      
      end subroutine show_best_el_info
      
      
      subroutine show_best_r010_ratios_info(io)
         integer, intent(in) :: io
         
         real(dp) :: chi2term
         integer :: i, l0_first, l1_first

         l0_first = ratios_l0_first
         l1_first = ratios_l1_first
          
         write(io,'(/,2a6,99a16)') &
            'r01', 'l=0 n', 'chi2term', 'r01', 'r01_obs', 'r01_sigma', 'l0_obs'
         do i=1,ratios_n
            chi2term = &
               pow2((model_ratios_r01(i) - ratios_r01(i))/sigmas_r01(i))
            write(io,'(6x,i6,e20.10,99f20.10)') l0_order(i + l0_first), &
               chi2term, model_ratios_r01(i), ratios_r01(i), sigmas_r01(i), &
               l0_obs(i + l0_first)
         end do
          
         write(io,'(/,2a6,99a16)') &
            'r10', 'l=1 n', 'chi2term', 'r10', 'r10_obs', 'r10_sigma', 'l1_obs'
         do i=1,ratios_n
            chi2term = &
               pow2((model_ratios_r10(i) - ratios_r10(i))/sigmas_r10(i))
            write(io,'(6x,i6,e20.10,99f20.10)') l1_order(i + l1_first), &
               chi2term, model_ratios_r10(i), ratios_r10(i), sigmas_r10(i), &
               l1_obs(i + l1_first)
         end do
               
      end subroutine show_best_r010_ratios_info

          
      subroutine show_best_r02_ratios_info(io)
         integer, intent(in) :: io
         
         real(dp) :: chi2term
         integer :: i
         
         write(io,'(/,2a6,99a16)') &
            'r02', 'l=0 n', 'chi2term', 'r02', 'r02_obs', 'r02_sigma', 'l0_obs'
         do i=1,nl0
            if (sigmas_r02(i) == 0d0) cycle
            chi2term = &
               pow2((model_ratios_r02(i) - ratios_r02(i))/sigmas_r02(i))
            write(io,'(6x,i6,e20.10,99f20.10)') l0_order(i), &
               chi2term, model_ratios_r02(i), ratios_r02(i), sigmas_r02(i), &
               l0_obs(i)
         end do
               
      end subroutine show_best_r02_ratios_info
      
      
      subroutine show_best(io)
         integer, intent(in) :: io
         
         real(dp) :: chi2term
         include 'formats'
         
         if (chi2_seismo_fraction > 0) then
            call show_best_el_info(io)         
            if (chi2_seismo_r_010_fraction > 0) &
               call show_best_r010_ratios_info(io)        
            if (chi2_seismo_r_02_fraction > 0) &
               call show_best_r02_ratios_info(io)
         end if

         if (Teff_sigma > 0 .and. include_Teff_in_chi2_spectro) then
            chi2term = pow2((best_Teff - Teff_target)/Teff_sigma)
            write(io,*)
            call write1('Teff chi2term', chi2term)
            call write1('Teff', best_Teff)
            call write1('Teff_obs', Teff_target)
            call write1('Teff_sigma', Teff_sigma)
         end if
         
         if (logL_sigma > 0 .and. include_logL_in_chi2_spectro) then
            chi2term = pow2((best_logL - logL_target)/logL_sigma)
            write(io,*)
            call write1('logL chi2term', chi2term)
            call write1('logL', best_logL)
            call write1('logL_obs', logL_target)
            call write1('logL_sigma', logL_sigma)
         end if
         
         if (logg_sigma > 0 .and. include_logg_in_chi2_spectro) then
            chi2term = pow2((best_logg - logg_target)/logg_sigma)
            write(io,*)
            call write1('logg chi2term', chi2term)
            call write1('logg', best_logg)
            call write1('logg_obs', logg_target)
            call write1('logg_sigma', logg_sigma)
         end if
         
         if (FeH_sigma > 0 .and. include_FeH_in_chi2_spectro) then
            chi2term = pow2((best_FeH - FeH_target)/FeH_sigma)
            write(io,*)
            call write1('FeH chi2term', chi2term)
            call write1('FeH', best_FeH)
            call write1('FeH_obs', FeH_target)
            call write1('FeH_sigma', FeH_sigma)
         end if
         
         if (logR_sigma > 0 .and. include_logR_in_chi2_spectro) then
            chi2term = pow2((best_logR - logR_target)/logR_sigma)
            write(io,*)
            call write1('logR chi2term', chi2term)
            call write1('logR', best_logR)
            call write1('logR_obs', logR_target)
            call write1('logR_sigma', logR_sigma)
         end if
         
         if (age_sigma > 0 .and. include_age_in_chi2_spectro) then
            chi2term = pow2((best_age - age_target)/age_sigma)
            write(io,*)
            write(io,'(a40,e20.10,99f20.10)') 'age chi2term', chi2term
            write(io,'(a40,1pes20.10)') 'age', best_age
            write(io,'(a40,1pes20.10)') 'age_target', age_target
            write(io,'(a40,1pes20.10)') 'age_sigma', age_sigma
         end if
         
         if (surface_Z_div_X_sigma > 0 .and. &
               include_surface_Z_div_X_in_chi2_spectro) then
            chi2term = &
               pow2((best_surface_Z_div_X - surface_Z_div_X_target)/surface_Z_div_X_sigma)
            write(io,*)
            write(io,'(a40,e20.10,99f20.10)') 'surface_Z_div_X chi2term', chi2term
            call write1('surface_Z_div_X', best_surface_Z_div_X)
            call write1('surface_Z_div_X_obs', surface_Z_div_X_target)
            call write1('surface_Z_div_X_sigma', surface_Z_div_X_sigma)
         end if
         
         if (surface_He_sigma > 0 .and. include_surface_He_in_chi2_spectro) then
            chi2term = pow2((best_surface_He - surface_He_target)/surface_He_sigma)
            write(io,*)
            call write1('surface_He chi2term', chi2term)
            call write1('surface_He', best_surface_He)
            call write1('surface_He_obs', surface_He_target)
            call write1('surface_He_sigma', surface_He_sigma)
         end if
         
         if (Rcz_sigma > 0 .and. include_Rcz_in_chi2_spectro) then
            chi2term = pow2((best_Rcz - Rcz_target)/Rcz_sigma)
            write(io,*)
            call write1('Rcz chi2term', chi2term)
            call write1('Rcz', best_Rcz)
            call write1('Rcz_obs', Rcz_target)
            call write1('Rcz_sigma', Rcz_sigma)
         end if
         
         if (csound_rms_sigma > 0 .and. include_csound_rms_in_chi2_spectro) then
            chi2term = pow2((best_csound_rms - csound_rms_target)/csound_rms_sigma)
            write(io,*)
            call write1('csound_rms chi2term', chi2term)
            call write1('csound_rms', best_csound_rms)
            call write1('csound_rms_obs', csound_rms_target)
            call write1('csound_rms_sigma', csound_rms_sigma)
         end if
         
         if (my_var1_sigma > 0 .and. include_my_var1_in_chi2_spectro) then
            chi2term = pow2( &
                  (best_my_var1 - my_var1_target)/my_var1_sigma)
            write(io,*)
            call write1(trim(my_var1_name) // ' chi2term', chi2term)
            call write1(trim(my_var1_name), best_my_var1)
            call write1(trim(my_var1_name) // '_obs', my_var1_target)
            call write1(trim(my_var1_name) // '_sigma', my_var1_sigma)
         end if
         
         if (my_var2_sigma > 0 .and. include_my_var2_in_chi2_spectro) then
            chi2term = pow2( &
                  (best_my_var2 - my_var2_target)/my_var2_sigma)
            write(io,*)
            call write1(trim(my_var2_name) // ' chi2term', chi2term)
            call write1(trim(my_var2_name), best_my_var2)
            call write1(trim(my_var2_name) // '_obs', my_var2_target)
            call write1(trim(my_var2_name) // '_sigma', my_var2_sigma)
         end if
         
         if (my_var3_sigma > 0 .and. include_my_var3_in_chi2_spectro) then
            chi2term = pow2( &
                  (best_my_var3 - my_var3_target)/my_var3_sigma)
            write(io,*)
            call write1(trim(my_var3_name) // ' chi2term', chi2term)
            call write1(trim(my_var3_name), best_my_var3)
            call write1(trim(my_var3_name) // '_obs', my_var3_target)
            call write1(trim(my_var3_name) // '_sigma', my_var3_sigma)
         end if
         
         write(io,*)
         call write1('R/Rsun', best_radius)
         call write1('logL/Lsun', best_logL)
         call write1('Teff', best_Teff)
         call write1('logg', best_logg)
         call write1('FeH', best_FeH)
         call write1('logR', best_logR)
         call write1('surface_Z_div_X', best_surface_Z_div_X)
         call write1('surface_He', best_surface_He)
         call write1('Rcz', best_Rcz)
         call write1('csound_rms', best_csound_rms)
         call write1('delta_nu', best_delta_nu)
         call write1('nu_max', best_nu_max)
         write(io,*)        
         call write1('a_div_r', best_a_div_r)
         call write1('correction_r', best_correction_r)
         write(io,*)        
         call write1('initial h1', current_h1)
         call write1('initial he3', current_he3)
         call write1('initial he4', current_he4)
         call write1('initial Y', current_Y)
         call write1('initial Z', current_Z)
         call write1('initial FeH', current_FeH)
         write(io,*)        
         call write1('mass/Msun', current_mass)
         call write1('alpha', current_alpha)
         call write1('f_ov', current_f_ov)
         write(io,'(a40,1pes26.16)') 'age', best_age
         write(io,*)
         if (chi2_seismo_fraction == 1d0) then
            call write1('chi^2 seismo', best_chi2_seismo)
         else if (chi2_seismo_fraction == 0d0) then
            call write1('chi^2 spectro', best_chi2_spectro)
         else
            call write1('chi^2 combined', best_chi2)
            call write1('chi2_seismo_fraction', chi2_seismo_fraction)
            call write1('chi^2 seismo', best_chi2_seismo)
            call write1('chi^2 spectro', best_chi2_spectro)
         end if
         write(io,*)
         write(io,'(a40,i16)') 'model number', best_model_number
         write(io,*)
         write(io,*)
         
         contains
         
         subroutine write1(str,x)
            character (len=*), intent(in) :: str
            real(dp), intent(in) :: x
            if (abs(x) < 1d6) then
               write(io,'(a40,99f20.10)') trim(str), x
            else
               write(io,'(a40,99e20.10)') trim(str), x
            end if
         end subroutine write1

      end subroutine show_best


      subroutine read_samples_from_file(results_fname, ierr)
         use utils_lib
         character (len=*), intent(in) :: results_fname
         integer, intent(out) :: ierr
         integer :: iounit, num, i, j, model_number
         character (len=100) :: line
         
         include 'formats'
         
         ierr = 0         
         write(*,*) 'read samples from file ' // trim(results_fname)
         
         iounit = alloc_iounit(ierr)
         if (ierr /= 0) stop 'alloc_iounit failed'
         open(unit=iounit, file=trim(results_fname), action='read', status='old', iostat=ierr)
         if (ierr /= 0) then
            write(*,*) 'failed to open ' // trim(results_fname)
            call free_iounit(iounit) 
            return
         end if
         
         read(iounit, fmt=*, iostat=ierr) num
         if (ierr /= 0) then
            write(*,*) 'failed to read number of samples on 1st line of ' // trim(results_fname)
            call done
            return
         end if
         
         write(*,2) 'number of samples in file', num
         
         read(iounit, fmt='(a)', iostat=ierr) line
         if (ierr /= 0) then
            write(*,*) 'failed to read 2nd line of ' // trim(results_fname)
            write(*,'(a)') 'line <' // trim(line) // '>'
            call done
            return
         end if
         
         do while (max_num_samples < num)
            call alloc_sample_ptrs(ierr)
            if (ierr /= 0) then
               write(*,*) 'ERROR -- failed to allocate for samples'
               call done
               return
            end if
         end do
         
         do j = 1, num
            call read1_sample_from_file(j, iounit, ierr)
            if (ierr /= 0) then
               write(*,2) 'ERROR -- failed while reading sample on line', j+2
               call done
               return
            end if
         end do
                  
         sample_number = num
         write(*,2) 'number of samples read from file', num
         
         call done

         
         contains
         
         
         subroutine done
            close(iounit)
            call free_iounit(iounit)         
         end subroutine done
         

      end subroutine read_samples_from_file
      
      
      subroutine read1_sample_from_file(j, iounit, ierr)
         use num_lib, only: simplex_op_code
         integer, intent(in) :: j, iounit
         integer, intent(out) :: ierr
            
         integer :: i, k
         character (len=256) :: info_str
         real(dp) :: logR
         
         include 'formats'
         
         ierr = 0
         read(iounit,fmt='(i8)',advance='no',iostat=ierr) i
         if (ierr /= 0) return
         if (i <= 0 .or. i > size(sample_chi2,dim=1)) then
            write(*,2) 'invalid sample number', i
            ierr = -1
            return
         end if
         
         read(iounit,'(7(1pes26.16),i16,22(1pes26.16),7i20)',advance='no',iostat=ierr) &
            sample_chi2(i), &
            sample_mass(i), &
            sample_init_Y(i), &
            sample_init_FeH(i), &
            sample_alpha(i), &
            sample_f_ov(i), &
            sample_age(i), &
            sample_model_number(i), &
            sample_init_h1(i), &
            sample_init_he3(i), &
            sample_init_he4(i), &
            sample_init_Z(i), &
            logR, &
            sample_logL(i), &
            sample_Teff(i), &
            sample_logg(i), &
            sample_FeH(i), &
            sample_logR(i), &
            sample_surface_Z_div_X(i), &
            sample_surface_He(i), &
            sample_Rcz(i), &
            sample_csound_rms(i), &
            sample_my_var1(i), &
            sample_my_var2(i), &
            sample_my_var3(i), &
            sample_delta_nu(i), &
            sample_a_div_r(i), &
            sample_correction_r(i), &
            sample_chi2_seismo(i), &
            sample_chi2_spectro(i), &
            nl0, &
            nl1, &
            nl2, &
            nl3, &
            ratios_n, &
            ratios_l0_first, &
            ratios_l1_first
         if (failed('results')) return
            
         sample_radius(i) = exp10_cr(logR)

         if (chi2_seismo_fraction > 0) then
            
            do k=1,nl0
               read(iounit,'(i26,99(1pes26.16))',advance='no',iostat=ierr) &
                  sample_l0_order(k,i), l0_obs(k), l0_obs_sigma(k), &
                  sample_l0_freq(k,i), sample_l0_freq_corr(k,i), sample_l0_inertia(k,i)
               if (failed('l=0')) return
            end do
            
            do k=1,nl1
               read(iounit,'(i26,99(1pes26.16))',advance='no',iostat=ierr) &
                  sample_l1_order(k,i), l1_obs(k), l1_obs_sigma(k), &
                  sample_l1_freq(k,i), sample_l1_freq_corr(k,i), sample_l1_inertia(k,i)
               if (failed('l=1')) return
            end do
            
            do k=1,nl2
               read(iounit,'(i26,99(1pes26.16))',advance='no',iostat=ierr) &
                  sample_l2_order(k,i), l2_obs(k), l2_obs_sigma(k), &
                  sample_l2_freq(k,i), sample_l2_freq_corr(k,i), sample_l2_inertia(k,i)
               if (failed('l=2')) return
            end do
            
            do k=1,nl3
               read(iounit,'(i26,99(1pes26.16))',advance='no',iostat=ierr) &
                  sample_l3_order(k,i), l3_obs(k), l3_obs_sigma(k), &
                  sample_l3_freq(k,i), sample_l3_freq_corr(k,i), sample_l3_inertia(k,i)
               if (failed('l=3')) return
            end do

            do k=1,ratios_n
               read(iounit,'(99(1pes26.16))',advance='no',iostat=ierr) &
                  ratios_r01(k), sigmas_r01(k), sample_ratios_r01(k,i), &
                  ratios_r10(k), sigmas_r10(k), sample_ratios_r10(k,i)
               if (failed('ratios_r010')) return
            end do

            do k=1,nl0
               read(iounit,'(99(1pes26.16))',advance='no',iostat=ierr) &
                  ratios_r02(k), sigmas_r02(k), sample_ratios_r02(k,i)
               if (failed('ratios_r02')) return
            end do
         
         end if
            
         read(iounit,'(a12)',iostat=ierr) info_str
         if (ierr /= 0) then
            ierr = 0
            sample_op_code(i) = 0
            return
         end if
      
         if (len_trim(info_str) == 0) then
            sample_op_code(i) = 0
         else
            sample_op_code(i) = simplex_op_code(info_str, ierr)
            if (ierr /= 0) then
               ierr = 0
               sample_op_code(i) = 0
               return
            end if
         end if
         
         
         contains
         
         
         logical function failed(str)
            character (len=*), intent(in) :: str
            include 'formats'
            failed = .false.
            if (ierr == 0) return
            write(*,2) 'failed reading ' // trim(str) // ' data for sample number', i
            failed = .true.
         end function failed
         
      
      end subroutine read1_sample_from_file


      end module astero_data
