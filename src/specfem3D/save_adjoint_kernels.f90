!=====================================================================
!
!               S p e c f e m 3 D  V e r s i o n  2 . 1
!               ---------------------------------------
!
!          Main authors: Dimitri Komatitsch and Jeroen Tromp
!    Princeton University, USA and CNRS / INRIA / University of Pau
! (c) Princeton University / California Institute of Technology and CNRS / INRIA / University of Pau
!                             July 2012
!
! This program is free software; you can redistribute it and/or modify
! it under the terms of the GNU General Public License as published by
! the Free Software Foundation; either version 2 of the License, or
! (at your option) any later version.
!
! This program is distributed in the hope that it will be useful,
! but WITHOUT ANY WARRANTY; without even the implied warranty of
! MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
! GNU General Public License for more details.
!
! You should have received a copy of the GNU General Public License along
! with this program; if not, write to the Free Software Foundation, Inc.,
! 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
!
!=====================================================================
!
! United States and French Government Sponsorship Acknowledged.

  subroutine save_adjoint_kernels()

  use specfem_par
  use specfem_par_acoustic
  use specfem_par_elastic
  use specfem_par_poroelastic

  implicit none
  ! local parameters
  integer:: ispec,i,j,k,ier
  real(kind=CUSTOM_REAL), dimension(:,:,:,:), allocatable :: weights_kernel

  ! flag to save GLL weights
  logical,parameter :: SAVE_WEIGHTS = .false.

  ! acoustic domains
  if( ACOUSTIC_SIMULATION ) then
    call save_kernels_acoustic()
  endif

  ! elastic domains
  if( ELASTIC_SIMULATION ) then
    call save_kernels_elastic()
  endif

  if( POROELASTIC_SIMULATION ) then
    call save_kernels_poroelastic()
  endif

  ! save weights for volume integration, in order to benchmark the kernels with analytical expressions
  if( SAVE_WEIGHTS ) then
    allocate(weights_kernel(NGLLX,NGLLY,NGLLZ,NSPEC_AB),stat=ier)
    if( ier /= 0 ) stop 'error allocating array weights_kernel'
    do ispec = 1, NSPEC_AB
        do k = 1, NGLLZ
          do j = 1, NGLLY
            do i = 1, NGLLX
              weights_kernel(i,j,k,ispec) = wxgll(i) * wygll(j) * wzgll(k) * jacobian(i,j,k,ispec)
            enddo ! i
          enddo ! j
        enddo ! k
    enddo ! ispec
    open(unit=27,file=prname(1:len_trim(prname))//'weights_kernel.bin',status='unknown',form='unformatted',iostat=ier)
    if( ier /= 0 ) stop 'error opening file weights_kernel.bin'
    write(27) weights_kernel
    close(27)
  endif

  ! for noise simulations --- noise strength kernel
  if (NOISE_TOMOGRAPHY == 3) then
    call save_kernels_strength_noise(myrank,LOCAL_PATH,sigma_kl,NSPEC_AB)
  endif

  ! for preconditioner
  if ( APPROXIMATE_HESS_KL ) then
    call save_kernels_hessian()
  endif

  end subroutine save_adjoint_kernels

!
!-------------------------------------------------------------------------------------------------
!

  subroutine save_kernels_acoustic()

  use specfem_par
  use specfem_par_acoustic

  implicit none
  ! local parameters
  integer:: ispec,i,j,k,ier

  ! finalizes calculation of rhop, beta, alpha kernels
  do ispec = 1, NSPEC_AB

    ! acoustic simulations
    if( ispec_is_acoustic(ispec) ) then

      do k = 1, NGLLZ
        do j = 1, NGLLY
          do i = 1, NGLLX
            ! rho prime kernel
            rhop_ac_kl(i,j,k,ispec) = rho_ac_kl(i,j,k,ispec) + kappa_ac_kl(i,j,k,ispec)

            ! vp kernel
            alpha_ac_kl(i,j,k,ispec) = 2._CUSTOM_REAL *  kappa_ac_kl(i,j,k,ispec)

          enddo
        enddo
      enddo

    endif ! acoustic

  enddo

  ! save kernels to binary files
  open(unit=27,file=prname(1:len_trim(prname))//'rho_acoustic_kernel.bin',status='unknown',form='unformatted',iostat=ier)
  if( ier /= 0 ) stop 'error opening file rho_acoustic_kernel.bin'
  write(27) rho_ac_kl
  close(27)

  open(unit=27,file=prname(1:len_trim(prname))//'kappa_acoustic_kernel.bin',status='unknown',form='unformatted',iostat=ier)
  if( ier /= 0 ) stop 'error opening file kappa_acoustic_kernel.bin'
  write(27) kappa_ac_kl
  close(27)

  open(unit=27,file=prname(1:len_trim(prname))//'rhop_acoustic_kernel.bin',status='unknown',form='unformatted',iostat=ier)
  if( ier /= 0 ) stop 'error opening file rhop_acoustic_kernel.bin'
  write(27) rhop_ac_kl
  close(27)

  open(unit=27,file=prname(1:len_trim(prname))//'alpha_acoustic_kernel.bin',status='unknown',form='unformatted',iostat=ier)
  if( ier /= 0 ) stop 'error opening file alpha_acoustic_kernel.bin'
  write(27) alpha_ac_kl
  close(27)

  end subroutine save_kernels_acoustic


!
!-------------------------------------------------------------------------------------------------
!

  subroutine save_kernels_elastic()

  use specfem_par
  use specfem_par_elastic

  implicit none
  ! local parameters
  integer:: ispec,i,j,k,iglob,ier
  real(kind=CUSTOM_REAL) :: rhol,mul,kappal

  ! finalizes calculation of rhop, beta, alpha kernels
  do ispec = 1, NSPEC_AB

    ! elastic simulations
    if( ispec_is_elastic(ispec) ) then

      do k = 1, NGLLZ
        do j = 1, NGLLY
          do i = 1, NGLLX
            iglob = ibool(i,j,k,ispec)

            ! isotropic adjoint kernels (see e.g. Tromp et al. 2005)
            rhol = rho_vs(i,j,k,ispec)*rho_vs(i,j,k,ispec) / mustore(i,j,k,ispec)
            mul = mustore(i,j,k,ispec)
            kappal = kappastore(i,j,k,ispec)

            ! for a parameterization: (rho,mu,kappa) "primary" kernels
            ! density kernel
            ! multiplies with rho
            rho_kl(i,j,k,ispec) = - rhol * rho_kl(i,j,k,ispec)

            ! shear modulus kernel
            mu_kl(i,j,k,ispec) = - 2._CUSTOM_REAL * mul * mu_kl(i,j,k,ispec)

            ! bulk modulus kernel
            kappa_kl(i,j,k,ispec) = - kappal * kappa_kl(i,j,k,ispec)

            ! for a parameterization: (rho,alpha,beta)
            ! density prime kernel
            rhop_kl(i,j,k,ispec) = rho_kl(i,j,k,ispec) + kappa_kl(i,j,k,ispec) + mu_kl(i,j,k,ispec)

            ! vs kernel
            beta_kl(i,j,k,ispec) = 2._CUSTOM_REAL * (mu_kl(i,j,k,ispec) &
                  - 4._CUSTOM_REAL * mul / (3._CUSTOM_REAL * kappal) * kappa_kl(i,j,k,ispec))

            ! vp kernel
            alpha_kl(i,j,k,ispec) = 2._CUSTOM_REAL * (1._CUSTOM_REAL &
                  + 4._CUSTOM_REAL * mul / (3._CUSTOM_REAL * kappal) ) * kappa_kl(i,j,k,ispec)

            ! for a parameterization: (rho,bulk, beta)
            ! where bulk wave speed is c = sqrt( kappa / rho)
            ! note: rhoprime is the same as for (rho,alpha,beta) parameterization
            !bulk_c_kl_crust_mantle(i,j,k,ispec) = 2._CUSTOM_REAL * kappa_kl(i,j,k,ispec)
            !bulk_beta_kl_crust_mantle(i,j,k,ispec ) = 2._CUSTOM_REAL * mu_kl(i,j,k,ispec)

          enddo
        enddo
      enddo

    endif ! elastic

  enddo

  ! save kernels to binary files
  open(unit=27,file=prname(1:len_trim(prname))//'rho_kernel.bin',status='unknown',form='unformatted',iostat=ier)
  if( ier /= 0 ) stop 'error opening file rho_kernel.bin'
  write(27) rho_kl
  close(27)

  open(unit=27,file=prname(1:len_trim(prname))//'mu_kernel.bin',status='unknown',form='unformatted',iostat=ier)
  if( ier /= 0 ) stop 'error opening file mu_kernel.bin'
  write(27) mu_kl
  close(27)

  open(unit=27,file=prname(1:len_trim(prname))//'kappa_kernel.bin',status='unknown',form='unformatted',iostat=ier)
  if( ier /= 0 ) stop 'error opening file kappa_kernel.bin'
  write(27) kappa_kl
  close(27)

  open(unit=27,file=prname(1:len_trim(prname))//'rhop_kernel.bin',status='unknown',form='unformatted',iostat=ier)
  if( ier /= 0 ) stop 'error opening file rhop_kernel.bin'
  write(27) rhop_kl
  close(27)

  open(unit=27,file=prname(1:len_trim(prname))//'beta_kernel.bin',status='unknown',form='unformatted',iostat=ier)
  if( ier /= 0 ) stop 'error opening file beta_kernel.bin'
  write(27) beta_kl
  close(27)

  open(unit=27,file=prname(1:len_trim(prname))//'alpha_kernel.bin',status='unknown',form='unformatted',iostat=ier)
  if( ier /= 0 ) stop 'error opening file alpha_kernel.bin'
  write(27) alpha_kl
  close(27)

  if (SAVE_MOHO_MESH) then
    open(unit=27,file=prname(1:len_trim(prname))//'moho_kernel.bin',status='unknown',form='unformatted',iostat=ier)
    if( ier /= 0 ) stop 'error opening file moho_kernel.bin'
    write(27) moho_kl
    close(27)
  endif

  end subroutine save_kernels_elastic

!
!-------------------------------------------------------------------------------------------------
!

  subroutine save_kernels_poroelastic

  use specfem_par
  use specfem_par_poroelastic

  implicit none
  ! local parameters
  integer:: ispec,i,j,k,ier
  real(kind=CUSTOM_REAL) :: rhol_s,rhol_f,rhol_bar,phil,tortl
  real(kind=CUSTOM_REAL) :: kappal_s ! mul_s
  real(kind=CUSTOM_REAL) :: kappal_f,etal_f
  real(kind=CUSTOM_REAL) :: mul_fr,kappal_fr
  real(kind=CUSTOM_REAL) :: permlxx,permlxy,permlxz,permlyz,permlyy,permlzz
  real(kind=CUSTOM_REAL) :: D_biot,H_biot,C_biot,M_biot,B_biot
  real(kind=CUSTOM_REAL) :: cpIsquare,cpIIsquare,cssquare
  real(kind=CUSTOM_REAL) :: rholb,ratio,dd1,gamma1,gamma2,gamma3,gamma4
  real(kind=CUSTOM_REAL) :: afactor,bfactor,cfactor

  ! finalizes calculation of rhop, beta, alpha kernels
  do ispec = 1, NSPEC_AB

    ! poroelastic simulations
    if( ispec_is_poroelastic(ispec) ) then

      do k = 1, NGLLZ
        do j = 1, NGLLY
          do i = 1, NGLLX

            ! isotropic adjoint kernels (see e.g. Morency et al. 2009)

            ! get poroelastic parameters of current local GLL
            phil = phistore(i,j,k,ispec)
            tortl = tortstore(i,j,k,ispec)
            rhol_s = rhoarraystore(1,i,j,k,ispec)
            rhol_f = rhoarraystore(2,i,j,k,ispec)
            rhol_bar =  (1._CUSTOM_REAL - phil)*rhol_s + phil*rhol_f
            kappal_s = kappaarraystore(1,i,j,k,ispec)
            kappal_f = kappaarraystore(2,i,j,k,ispec)
            kappal_fr = kappaarraystore(3,i,j,k,ispec)
            mul_fr = mustore(i,j,k,ispec)
            etal_f = etastore(i,j,k,ispec)
            permlxx = permstore(1,i,j,k,ispec)
            permlxy = permstore(2,i,j,k,ispec)
            permlxz = permstore(3,i,j,k,ispec)
            permlyy = permstore(4,i,j,k,ispec)
            permlyz = permstore(5,i,j,k,ispec)
            permlzz = permstore(6,i,j,k,ispec)

            ! Biot coef
            D_biot = kappal_s*(1._CUSTOM_REAL + phil*(kappal_s/kappal_f - 1._CUSTOM_REAL))
            H_biot = (kappal_s - kappal_fr)*(kappal_s - kappal_fr)/(D_biot - kappal_fr) + &
                      kappal_fr + 4._CUSTOM_REAL*mul_fr/3._CUSTOM_REAL
            B_biot = H_biot - 4._CUSTOM_REAL*mul_fr/3._CUSTOM_REAL
            C_biot = kappal_s*(kappal_s - kappal_fr)/(D_biot - kappal_fr)
            M_biot = kappal_s*kappal_s/(D_biot - kappal_fr)

            ! Approximated velocities (no viscous dissipation)
            afactor = rhol_bar - phil/tortl*rhol_f
            bfactor = H_biot + phil*rhol_bar/(tortl*rhol_f)*M_biot - 2._CUSTOM_REAL*phil/tortl*C_biot
            cfactor = phil/(tortl*rhol_f)*(H_biot*M_biot - C_biot*C_biot)
            cpIsquare = (bfactor + sqrt(bfactor*bfactor - 4._CUSTOM_REAL*afactor*cfactor))/(2._CUSTOM_REAL*afactor)
            cpIIsquare = (bfactor - sqrt(bfactor*bfactor - 4._CUSTOM_REAL*afactor*cfactor))/(2._CUSTOM_REAL*afactor)
            cssquare = mul_fr/afactor

            ! extras needed
            ! Approximated ratio r = amplitude "w" field/amplitude "s" field (no viscous
            ! dissipation)
            gamma1 = H_biot - phil/tortl*C_biot
            gamma2 = C_biot - phil/tortl*M_biot
            gamma3 = phil/tortl*( M_biot*(afactor/rhol_f + phil/tortl) - C_biot)
            gamma4 = phil/tortl*( C_biot*(afactor/rhol_f + phil/tortl) - H_biot)
            ratio = 0.5_CUSTOM_REAL*(gamma1 - gamma3)/gamma4 + &
                    0.5_CUSTOM_REAL*sqrt((gamma1-gamma3)**2/gamma4**2 + 4._CUSTOM_REAL * gamma2/gamma4)
            rholb = rhol_bar - phil*rhol_f/tortl
            dd1 = (1._CUSTOM_REAL+rholb/rhol_f)*ratio**2 + 2._CUSTOM_REAL*ratio + tortl/phil

            ! primary kernels
            rhot_kl(i,j,k,ispec) = - rhol_bar * rhot_kl(i,j,k,ispec)
            rhof_kl(i,j,k,ispec) = - rhol_f * rhof_kl(i,j,k,ispec)
            sm_kl(i,j,k,ispec) = - rhol_f*tortl/phil * sm_kl(i,j,k,ispec)
            !at the moment suitable for constant permeability
            eta_kl(i,j,k,ispec) = - etal_f/permlxx * eta_kl(i,j,k,ispec)
            mufr_kl(i,j,k,ispec) = - 2._CUSTOM_REAL * mul_fr * mufr_kl(i,j,k,ispec)
            B_kl(i,j,k,ispec) = - B_biot * B_kl(i,j,k,ispec)
            C_kl(i,j,k,ispec) = - C_biot * C_kl(i,j,k,ispec)
            M_kl(i,j,k,ispec) = - M_biot * M_kl(i,j,k,ispec)

            ! density kernels
            rhob_kl(i,j,k,ispec) = rhot_kl(i,j,k,ispec) + B_kl(i,j,k,ispec) + mufr_kl(i,j,k,ispec)
            rhofb_kl(i,j,k,ispec) = rhof_kl(i,j,k,ispec) + C_kl(i,j,k,ispec) + M_kl(i,j,k,ispec) + sm_kl(i,j,k,ispec)
            Bb_kl(i,j,k,ispec) = B_kl(i,j,k,ispec)
            Cb_kl(i,j,k,ispec) = C_kl(i,j,k,ispec)
            Mb_kl(i,j,k,ispec) = M_kl(i,j,k,ispec)
            mufrb_kl(i,j,k,ispec) = mufr_kl(i,j,k,ispec)
            phi_kl(i,j,k,ispec) = - sm_kl(i,j,k,ispec) - M_kl(i,j,k,ispec)

            ! wavespeed kernels
            rhobb_kl(i,j,k,ispec) = rhob_kl(i,j,k,ispec) - &
                      phil*rhol_f/(tortl*B_biot) * &
                      (cpIIsquare + (cpIsquare - cpIIsquare)*( (phil / &
                      tortl*ratio +1._CUSTOM_REAL)/dd1 + &
                      (rhol_bar**2*ratio**2/rhol_f**2*(phil / &
                      tortl*ratio+1)*(phil/tortl*ratio + &
                      phil/tortl * &
                      (1+rhol_f/rhol_bar)-1))/dd1**2 ) - &
                      4._CUSTOM_REAL/3._CUSTOM_REAL*cssquare )*Bb_kl(i,j,k,ispec) - &
                      rhol_bar*ratio**2/M_biot * (cpIsquare - cpIIsquare)* &
                      (phil/tortl*ratio + &
                      1._CUSTOM_REAL)**2/dd1**2*Mb_kl(i,j,k,ispec) + &
                      rhol_bar*ratio/C_biot * (cpIsquare - cpIIsquare)* (&
                      (phil/tortl*ratio+1._CUSTOM_REAL)/dd1 - &
                      phil*ratio/tortl*(phil / &
                      tortl*ratio+1._CUSTOM_REAL)*&
                      (1+rhol_bar*ratio/rhol_f)/dd1**2)*Cb_kl(i,j,k,ispec)+ &
                      phil*rhol_f*cssquare / &
                      (tortl*mul_fr)*mufrb_kl(i,j,k,ispec)
            rhofbb_kl(i,j,k,ispec) = rhofb_kl(i,j,k,ispec) + &
                       phil*rhol_f/(tortl*B_biot) * &
                       (cpIIsquare + (cpIsquare - cpIIsquare)*( (phil/ &
                       tortl*ratio +1._CUSTOM_REAL)/dd1+&
                       (rhol_bar**2*ratio**2/rhol_f**2*(phil/ &
                       tortl*ratio+1)*(phil/tortl*ratio+ &
                       phil/tortl*&
                       (1+rhol_f/rhol_bar)-1))/dd1**2 )- &
                       4._CUSTOM_REAL/3._CUSTOM_REAL*cssquare )*Bb_kl(i,j,k,ispec) + &
                       rhol_bar*ratio**2/M_biot * (cpIsquare - cpIIsquare)* &
                       (phil/tortl*ratio + &
                       1._CUSTOM_REAL)**2/dd1**2*Mb_kl(i,j,k,ispec) - &
                       rhol_bar*ratio/C_biot * (cpIsquare - cpIIsquare)* (&
                       (phil/tortl*ratio+1._CUSTOM_REAL)/dd1 - &
                       phil*ratio/tortl*(phil/ &
                       tortl*ratio+1._CUSTOM_REAL)*&
                       (1+rhol_bar*ratio/rhol_f)/dd1**2)*Cb_kl(i,j,k,ispec)- &
                       phil*rhol_f*cssquare/ &
                       (tortl*mul_fr)*mufrb_kl(i,j,k,ispec)
            phib_kl(i,j,k,ispec) = phi_kl(i,j,k,ispec) - &
                       phil*rhol_bar/(tortl*B_biot) &
                       * ( cpIsquare - rhol_f/rhol_bar*cpIIsquare- &
                       (cpIsquare-cpIIsquare)*( (2._CUSTOM_REAL*ratio**2*phil/ &
                       tortl + (1._CUSTOM_REAL+&
                       rhol_f/rhol_bar)* &
                       (2._CUSTOM_REAL*ratio*phil/tortl+&
                       1._CUSTOM_REAL))/dd1 + (phil/tortl*ratio+ &
                       1._CUSTOM_REAL)*(phil*&
                       ratio/tortl+phil/tortl* &
                       (1._CUSTOM_REAL+rhol_f/&
                       rhol_bar)-1._CUSTOM_REAL)*((1._CUSTOM_REAL+ &
                       rhol_bar/rhol_f-&
                       2._CUSTOM_REAL*phil/tortl)*ratio**2+2._CUSTOM_REAL*ratio)/dd1**2) - &
                       4._CUSTOM_REAL/3._CUSTOM_REAL*rhol_f*cssquare/rhol_bar)*Bb_kl(i,j,k,ispec) + &
                       rhol_f/M_biot * (cpIsquare-cpIIsquare)*(&
                       2._CUSTOM_REAL*ratio*(phil/tortl*ratio+1._CUSTOM_REAL)/dd1 - &
                       (phil/tortl*ratio+1._CUSTOM_REAL)**2*( &
                       (1._CUSTOM_REAL+rhol_bar/&
                       rhol_f-2._CUSTOM_REAL*phil/tortl)*ratio**2+2._CUSTOM_REAL*ratio)/dd1**2 &
                       )*Mb_kl(i,j,k,ispec) + &
                       phil*rhol_f/(tortl*C_biot)* &
                       (cpIsquare-cpIIsquare)*ratio* (&
                       (1._CUSTOM_REAL+rhol_f/rhol_bar*ratio)/dd1 - &
                       (phil/tortl*ratio+1._CUSTOM_REAL)* &
                       (1._CUSTOM_REAL+rhol_bar/&
                       rhol_f*ratio)*((1._CUSTOM_REAL+rhol_bar/rhol_f-2._CUSTOM_REAL*&
                       phil/tortl)*ratio+2._CUSTOM_REAL)/dd1**2&
                        )*Cb_kl(i,j,k,ispec) -&
                       phil*rhol_f*cssquare &
                       /(tortl*mul_fr)*mufrb_kl(i,j,k,ispec)
            cpI_kl(i,j,k,ispec) = 2._CUSTOM_REAL*cpIsquare/B_biot*rhol_bar*( &
                       1._CUSTOM_REAL-phil/tortl + &
                       (phil/tortl*ratio+ &
                       1._CUSTOM_REAL)*(phil/tortl*&
                       ratio+phil/tortl* &
                       (1._CUSTOM_REAL+rhol_f/rhol_bar)-&
                       1._CUSTOM_REAL)/dd1 &
                        )* Bb_kl(i,j,k,ispec) +&
                       2._CUSTOM_REAL*cpIsquare*rhol_f*tortl/(phil*M_biot) *&
                       (phil/tortl*ratio+1._CUSTOM_REAL)**2/dd1*Mb_kl(i,j,k,ispec)+&
                       2._CUSTOM_REAL*cpIsquare*rhol_f/C_biot * &
                       (phil/tortl*ratio+1._CUSTOM_REAL)* &
                       (1._CUSTOM_REAL+rhol_bar/&
                       rhol_f*ratio)/dd1*Cb_kl(i,j,k,ispec)
            cpII_kl(i,j,k,ispec) = 2._CUSTOM_REAL*cpIIsquare*rhol_bar/B_biot * (&
                       phil*rhol_f/(tortl*rhol_bar) - &
                       (phil/tortl*ratio+ &
                       1._CUSTOM_REAL)*(phil/tortl*&
                       ratio+phil/tortl* &
                       (1._CUSTOM_REAL+rhol_f/rhol_bar)-&
                       1._CUSTOM_REAL)/dd1  ) * Bb_kl(i,j,k,ispec) +&
                       2._CUSTOM_REAL*cpIIsquare*rhol_f*tortl/(phil*M_biot) * (&
                       1._CUSTOM_REAL - (phil/tortl*ratio+ &
                       1._CUSTOM_REAL)**2/dd1  )*Mb_kl(i,j,k,ispec) + &
                       2._CUSTOM_REAL*cpIIsquare*rhol_f/C_biot * (&
                       1._CUSTOM_REAL - (phil/tortl*ratio+ &
                       1._CUSTOM_REAL)*(1._CUSTOM_REAL+&
                       rhol_bar/rhol_f*ratio)/dd1)*Cb_kl(i,j,k,ispec)
            cs_kl(i,j,k,ispec) = - 8._CUSTOM_REAL/3._CUSTOM_REAL*cssquare* &
                       rhol_bar/B_biot*(1._CUSTOM_REAL-&
                       phil*rhol_f/(tortl* &
                       rhol_bar))*Bb_kl(i,j,k,ispec) + &
                       2._CUSTOM_REAL*(rhol_bar-rhol_f*&
                       phil/tortl)/&
                       mul_fr*cssquare*mufrb_kl(i,j,k,ispec)
            ratio_kl(i,j,k,ispec) = ratio*rhol_bar*phil/(tortl*B_biot) * &
                       (cpIsquare-cpIIsquare) * ( &
                       phil/tortl*(2._CUSTOM_REAL*ratio+1._CUSTOM_REAL+rhol_f/ &
                       rhol_bar)/dd1 - (phil/tortl*ratio+1._CUSTOM_REAL)*&
                       (phil/tortl*ratio+phil/tortl*(&
                       1._CUSTOM_REAL+rhol_f/rhol_bar)-1._CUSTOM_REAL)*(2._CUSTOM_REAL*ratio*(&
                       1._CUSTOM_REAL+rhol_bar/rhol_f-phil/tortl) +&
                       2._CUSTOM_REAL)/dd1**2  )*Bb_kl(i,j,k,ispec) + &
                       ratio*rhol_f*tortl/(phil*M_biot)*(cpIsquare-cpIIsquare) * &
                       2._CUSTOM_REAL*phil/tortl * (&
                       (phil/tortl*ratio+1._CUSTOM_REAL)/dd1 - &
                       (phil/tortl*ratio+1._CUSTOM_REAL)**2*( &
                       (1._CUSTOM_REAL+rhol_bar/&
                       rhol_f-phil/tortl)*ratio+ &
                       1._CUSTOM_REAL)/dd1**2 )*Mb_kl(i,j,k,ispec) +&
                       ratio*rhol_f/C_biot*(cpIsquare-cpIIsquare) * (&
                       (2._CUSTOM_REAL*phil*rhol_bar* &
                       ratio/(tortl*rhol_f)+&
                       phil/tortl+rhol_bar/rhol_f)/dd1 - &
                       2._CUSTOM_REAL*phil/tortl*(phil/tortl*ratio+&
                       1._CUSTOM_REAL)*(1._CUSTOM_REAL+rhol_bar/rhol_f*ratio)*((1._CUSTOM_REAL+&
                       rhol_bar/rhol_f- &
                       phil/tortl)*ratio+1._CUSTOM_REAL)/&
                       dd1**2 )*Cb_kl(i,j,k,ispec)
          enddo
        enddo
      enddo

    endif ! poroelastic

  enddo

  ! save kernels to binary files

  ! primary kernels
  open(unit=27,file=prname(1:len_trim(prname))//'rhot_primeporo_kernel.bin',status='unknown',form='unformatted',iostat=ier)
  if( ier /= 0 ) stop 'error opening file rhot_primeporo_kernel.bin'
  write(27) rhot_kl
  close(27)
  open(unit=27,file=prname(1:len_trim(prname))//'rhof_primeporo_kernel.bin',status='unknown',form='unformatted',iostat=ier)
  if( ier /= 0 ) stop 'error opening file rhof_primeporo_kernel.bin'
  write(27) rhof_kl
  close(27)
  open(unit=27,file=prname(1:len_trim(prname))//'sm_primeporo_kernel.bin',status='unknown',form='unformatted',iostat=ier)
  if( ier /= 0 ) stop 'error opening file sm_primeporo_kernel.bin'
  write(27) sm_kl
  close(27)
  open(unit=27,file=prname(1:len_trim(prname))//'eta_primeporo_kernel.bin',status='unknown',form='unformatted',iostat=ier)
  if( ier /= 0 ) stop 'error opening file eta_primeporo_kernel.bin'
  write(27) eta_kl
  close(27)
  open(unit=27,file=prname(1:len_trim(prname))//'mufr_primeporo_kernel.bin',status='unknown',form='unformatted',iostat=ier)
  if( ier /= 0 ) stop 'error opening file mufr_primeporo_kernel.bin'
  write(27) mufr_kl
  close(27)
  open(unit=27,file=prname(1:len_trim(prname))//'B_primeporo_kernel.bin',status='unknown',form='unformatted',iostat=ier)
  if( ier /= 0 ) stop 'error opening file B_primeporo_kernel.bin'
  write(27) B_kl
  close(27)
  open(unit=27,file=prname(1:len_trim(prname))//'C_primeporo_kernel.bin',status='unknown',form='unformatted',iostat=ier)
  if( ier /= 0 ) stop 'error opening file C_primeporo_kernel.bin'
  write(27) C_kl
  close(27)
  open(unit=27,file=prname(1:len_trim(prname))//'M_primeporo_kernel.bin',status='unknown',form='unformatted',iostat=ier)
  if( ier /= 0 ) stop 'error opening file M_primeporo_kernel.bin'
  write(27) M_kl
  close(27)

  ! density kernels
  open(unit=27,file=prname(1:len_trim(prname))//'rhob_densityporo_kernel.bin',status='unknown',form='unformatted',iostat=ier)
  if( ier /= 0 ) stop 'error opening file rhob_densityporo_kernel.bin'
  write(27) rhob_kl
  close(27)
  open(unit=27,file=prname(1:len_trim(prname))//'rhofb_densityporo_kernel.bin',status='unknown',form='unformatted',iostat=ier)
  if( ier /= 0 ) stop 'error opening file rhofb_densityporo_kernel.bin'
  write(27) rhofb_kl
  close(27)
  open(unit=27,file=prname(1:len_trim(prname))//'phi_densityporo_kernel.bin',status='unknown',form='unformatted',iostat=ier)
  if( ier /= 0 ) stop 'error opening file phi_densityporo_kernel.bin'
  write(27) phi_kl
  close(27)
  open(unit=27,file=prname(1:len_trim(prname))//'mufrb_densityporo_kernel.bin',status='unknown',form='unformatted',iostat=ier)
  if( ier /= 0 ) stop 'error opening file mufrb_densityporo_kernel.bin'
  write(27) mufrb_kl
  close(27)
  open(unit=27,file=prname(1:len_trim(prname))//'Bb_densityporo_kernel.bin',status='unknown',form='unformatted',iostat=ier)
  if( ier /= 0 ) stop 'error opening file Bb_densityporo_kernel.bin'
  write(27) Bb_kl
  close(27)
  open(unit=27,file=prname(1:len_trim(prname))//'Cb_densityporo_kernel.bin',status='unknown',form='unformatted',iostat=ier)
  if( ier /= 0 ) stop 'error opening file Cb_densityporo_kernel.bin'
  write(27) Cb_kl
  close(27)
  open(unit=27,file=prname(1:len_trim(prname))//'Mb_densityporo_kernel.bin',status='unknown',form='unformatted',iostat=ier)
  if( ier /= 0 ) stop 'error opening file Mb_densityporo_kernel.bin'
  write(27) Mb_kl
  close(27)

  ! wavespeed kernels
  open(unit=27,file=prname(1:len_trim(prname))//'rhobb_waveporo_kernel.bin',status='unknown',form='unformatted',iostat=ier)
  if( ier /= 0 ) stop 'error opening file rhobb_waveporo_kernel.bin'
  write(27) rhobb_kl
  close(27)
  open(unit=27,file=prname(1:len_trim(prname))//'rhofbb_waveporo_kernel.bin',status='unknown',form='unformatted',iostat=ier)
  if( ier /= 0 ) stop 'error opening file rhofbb_waveporo_kernel.bin'
  write(27) rhofbb_kl
  close(27)
  open(unit=27,file=prname(1:len_trim(prname))//'phib_waveporo_kernel.bin',status='unknown',form='unformatted',iostat=ier)
  if( ier /= 0 ) stop 'error opening file phib_waveporo_kernel.bin'
  write(27) phib_kl
  close(27)
  open(unit=27,file=prname(1:len_trim(prname))//'cs_waveporo_kernel.bin',status='unknown',form='unformatted',iostat=ier)
  if( ier /= 0 ) stop 'error opening file cs_waveporo_kernel.bin'
  write(27) cs_kl
  close(27)
  open(unit=27,file=prname(1:len_trim(prname))//'cpI_waveporo_kernel.bin',status='unknown',form='unformatted',iostat=ier)
  if( ier /= 0 ) stop 'error opening file cpI_waveporo_kernel.bin'
  write(27) cpI_kl
  close(27)
  open(unit=27,file=prname(1:len_trim(prname))//'cpII_waveporo_kernel.bin',status='unknown',form='unformatted',iostat=ier)
  if( ier /= 0 ) stop 'error opening file cpII_waveporo_kernel.bin'
  write(27) cpII_kl
  close(27)
  open(unit=27,file=prname(1:len_trim(prname))//'ratio_waveporo_kernel.bin',status='unknown',form='unformatted',iostat=ier)
  if( ier /= 0 ) stop 'error opening file ratio_waveporo_kernel.bin'
  write(27) ratio_kl
  close(27)

  end subroutine save_kernels_poroelastic

!
!-------------------------------------------------------------------------------------------------
!

  subroutine save_kernels_hessian()

  use specfem_par
  use specfem_par_elastic
  use specfem_par_acoustic

  implicit none
  integer :: ier

  ! acoustic domains
  if( ACOUSTIC_SIMULATION ) then
    ! scales approximate hessian
    hess_ac_kl(:,:,:,:) = 2._CUSTOM_REAL * hess_ac_kl(:,:,:,:)

    ! stores into file
    open(unit=27,file=trim(prname)//'hess_acoustic_kernel.bin', &
          status='unknown',form='unformatted',action='write',iostat=ier)
    if( ier /= 0 ) stop 'error opening file hess_acoustic_kernel.bin'
    write(27) hess_ac_kl
    close(27)
  endif

  ! elastic domains
  if( ELASTIC_SIMULATION ) then
    ! scales approximate hessian
    hess_kl(:,:,:,:) = 2._CUSTOM_REAL * hess_kl(:,:,:,:)

    ! stores into file
    open(unit=27,file=trim(prname)//'hess_kernel.bin', &
          status='unknown',form='unformatted',action='write',iostat=ier)
    if( ier /= 0 ) stop 'error opening file hess_kernel.bin'
    write(27) hess_kl
    close(27)
  endif

  end subroutine save_kernels_hessian

