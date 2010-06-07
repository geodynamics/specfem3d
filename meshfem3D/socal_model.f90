!=====================================================================
!
!               S p e c f e m 3 D  V e r s i o n  1 . 4
!               ---------------------------------------
!
!                 Dimitri Komatitsch and Jeroen Tromp
!    Seismological Laboratory - California Institute of Technology
!         (c) California Institute of Technology September 2006
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

  subroutine socal_model(idoubling,rho,vp,vs,iattenuation)

  implicit none

  include "constants.h"

  integer idoubling,iattenuation
  double precision rho,vp,vs

  if(idoubling == IFLAG_HALFSPACE_MOHO) then
        vp=7.8d0
        vs=4.5d0
        rho=3.0d0
        iattenuation=1        

  else if(idoubling == IFLAG_MOHO_16km) then
        vp=6.7d0
        vs=3.87d0
        rho=2.8d0
        iattenuation=1

  else if(idoubling == IFLAG_ONE_LAYER_TOPOGRAPHY .or. idoubling == IFLAG_BASEMENT_TOPO) then
        vp=5.5d0
        vs=3.18d0
        rho=2.4d0
        iattenuation=1

  else
        vp=6.3d0
        vs=3.64d0
        rho=2.67d0
        iattenuation=1
  endif

! scale to standard units
  vp = vp * 1000.d0
  vs = vs * 1000.d0
  rho = rho * 1000.d0

  end subroutine socal_model

