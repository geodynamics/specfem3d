/* Copyright 2004,2007,2009,2010 ENSEIRB, INRIA & CNRS
**
** This file is part of the Scotch software package for static mapping,
** graph partitioning and sparse matrix ordering.
**
** This software is governed by the CeCILL-C license under French law
** and abiding by the rules of distribution of free software. You can
** use, modify and/or redistribute the software under the terms of the
** CeCILL-C license as circulated by CEA, CNRS and INRIA at the following
** URL: "http://www.cecill.info".
** 
** As a counterpart to the access to the source code and rights to copy,
** modify and redistribute granted by the license, users are provided
** only with a limited warranty and the software's author, the holder of
** the economic rights, and the successive licensors have only limited
** liability.
** 
** In this respect, the user's attention is drawn to the risks associated
** with loading, using, modifying and/or developing or reproducing the
** software by the user in light of its specific status of free software,
** that may mean that it is complicated to manipulate, and that also
** therefore means that it is reserved for developers and experienced
** professionals having in-depth computer knowledge. Users are therefore
** encouraged to load and test the software's suitability as regards
** their requirements in conditions enabling the security of their
** systems and/or data to be ensured and, more generally, to use and
** operate it in the same conditions as regards security.
** 
** The fact that you are presently reading this means that you have had
** knowledge of the CeCILL-C license and that you accept its terms.
*/
/************************************************************/
/**                                                        **/
/**   NAME       : library_arch.c                          **/
/**                                                        **/
/**   AUTHOR     : Francois PELLEGRINI                     **/
/**                                                        **/
/**   FUNCTION   : This module is the API for the target   **/
/**                architecture handling routines of the   **/
/**                libSCOTCH library.                      **/
/**                                                        **/
/**   DATES      : # Version 3.2  : from : 18 aug 1998     **/
/**                                 to   : 18 aug 1998     **/
/**                # Version 3.3  : from : 02 oct 1998     **/
/**                                 to   : 29 mar 1999     **/
/**                # Version 3.4  : from : 01 nov 2001     **/
/**                                 to   : 01 nov 2001     **/
/**                # Version 4.0  : from : 13 jan 2004     **/
/**                                 to   : 13 jan 2004     **/
/**                # Version 5.0  : from : 12 sep 2007     **/
/**                                 to   : 12 sep 2007     **/
/**                # Version 5.1  : from : 05 jun 2009     **/
/**                                 to   : 29 jul 2010     **/
/**                                                        **/
/************************************************************/

/*
**  The defines and includes.
*/

#define LIBRARY

#include "module.h"
#include "common.h"
#include "graph.h"
#include "arch.h"
#include "arch_cmplt.h"
#include "arch_cmpltw.h"
#include "arch_hcub.h"
#include "arch_mesh.h"
#include "arch_tleaf.h"
#include "arch_torus.h"
#include "arch_vcmplt.h"
#include "arch_vhcub.h"
#include "scotch.h"

/***************************************/
/*                                     */
/* These routines are the C API for    */
/* the architecture handling routines. */
/*                                     */
/***************************************/

/*+ This routine initializes the opaque
*** architecture structure used to handle
*** target architectures in the Scotch library.
*** It returns:
*** - 0   : if the initialization succeeded.
*** - !0  : on error.
+*/

int
SCOTCH_archInit (
SCOTCH_Arch * const         archptr)
{
  if (sizeof (SCOTCH_Num) != sizeof (Anum)) {
    errorPrint ("SCOTCH_archInit: internal error (1)");
    return     (1);
  }
  if (sizeof (SCOTCH_Arch) < sizeof (Arch)) {
    errorPrint ("SCOTCH_archInit: internal error (2)");
    return     (1);
  }

  return (archInit ((Arch *) archptr));
}

/*+ This routine frees the contents of the
*** given opaque architecture structure.
*** It returns:
*** - VOID  : in all cases.
+*/

void
SCOTCH_archExit (
SCOTCH_Arch * const         archptr)
{
  archExit ((Arch *) archptr);
}

/*+ This routine loads the given opaque
*** architecture structure with the data of
*** the given stream.
*** It returns:
*** - 0   : if the loading succeeded.
*** - !0  : on error.
+*/

int
SCOTCH_archLoad (
SCOTCH_Arch * const         archptr,
FILE * const                stream)
{
  return (archLoad ((Arch *) archptr, stream));
}

/*+ This routine saves the given opaque
*** architecture structure to the given
*** stream.
*** It returns:
*** - 0   : if the saving succeeded.
*** - !0  : on error.
+*/

int
SCOTCH_archSave (
const SCOTCH_Arch * const   archptr,
FILE * const                stream)
{
  return (archSave ((Arch *) archptr, stream));
}

/*+ This routine returns the name of the
*** given target architecture.
*** It returns:
*** - !NULL  : pointer to the name of the
***            target architecture.
+*/

char *
SCOTCH_archName (
const SCOTCH_Arch * const   archptr)
{
  return (archName ((const Arch * const) archptr));
}

/*+ This routine returns the size of the
*** given target architecture.
*** It returns:
*** - !0  : size of the target architecture.
+*/

SCOTCH_Num
SCOTCH_archSize (
const SCOTCH_Arch * const   archptr)
{
  ArchDom             domdat;

  archDomFrst ((Arch *) archptr, &domdat);        /* Get first domain     */
  return (archDomSize ((Arch *) archptr, &domdat)); /* Return domain size */
}

/*+ These routines fill the contents of the given
*** opaque target structure so as to yield target
*** architectures of the given types.
*** It returns:
*** - 0   : if the computation succeeded.
*** - !0  : on error.
+*/

int
SCOTCH_archCmplt (
SCOTCH_Arch * const         archptr,
const SCOTCH_Num            numnbr)
{
  Arch *              tgtarchptr;
  ArchCmplt *         tgtarchdatptr;

  if (sizeof (SCOTCH_Num) != sizeof (Gnum)) {
    errorPrint ("SCOTCH_archCmplt: internal error");
    return     (1);
  }

  tgtarchptr    = (Arch *) archptr;
  tgtarchdatptr = (ArchCmplt *) (void *) (&tgtarchptr->data);

  tgtarchptr->class     = archClass ("cmplt");
  tgtarchdatptr->numnbr = (Anum) numnbr;

  return (0);
}

/*
**
*/

int
SCOTCH_archCmpltw (
SCOTCH_Arch * const         archptr,
const SCOTCH_Num            vertnbr,
const SCOTCH_Num * const    velotab)
{
  Arch *              tgtarchptr;

  if (sizeof (SCOTCH_Num) != sizeof (Gnum)) {
    errorPrint ("SCOTCH_archCmpltw: internal error");
    return     (1);
  }

  tgtarchptr        = (Arch *) archptr;
  tgtarchptr->class = archClass ("cmpltw");

  return (archCmpltwArchBuild ((ArchCmpltw *) (void *) (&tgtarchptr->data), vertnbr, velotab));
}

/*
**
*/

int
SCOTCH_archHcub (
SCOTCH_Arch * const         archptr,
const SCOTCH_Num            dimmax)               /*+ Number of dimensions +*/
{
  Arch *              tgtarchptr;
  ArchHcub *          tgtarchdatptr;

  if (sizeof (SCOTCH_Num) != sizeof (Gnum)) {
    errorPrint ("SCOTCH_archHcub: internal error");
    return     (1);
  }

  tgtarchptr    = (Arch *) archptr;
  tgtarchdatptr = (ArchHcub *) (void *) (&tgtarchptr->data);

  tgtarchptr->class     = archClass ("hcub");
  tgtarchdatptr->dimmax = (Anum) dimmax;

  return (0);
}

/*
**
*/

int
SCOTCH_archMesh2 (
SCOTCH_Arch * const         archptr,
const SCOTCH_Num            dimxval,
const SCOTCH_Num            dimyval)
{
  Arch *              tgtarchptr;
  ArchMesh2 *         tgtarchdatptr;

  if (sizeof (SCOTCH_Num) != sizeof (Gnum)) {
    errorPrint ("SCOTCH_archMesh2: internal error");
    return     (1);
  }

  tgtarchptr    = (Arch *) archptr;
  tgtarchdatptr = (ArchMesh2 *) (void *) (&tgtarchptr->data);

  tgtarchptr->class   = archClass ("mesh2D");
  tgtarchdatptr->c[0] = (Anum) dimxval;
  tgtarchdatptr->c[1] = (Anum) dimyval;

  return (0);
}

/*
**
*/

int
SCOTCH_archMesh3 (
SCOTCH_Arch * const         archptr,
const SCOTCH_Num            dimxval,
const SCOTCH_Num            dimyval,
const SCOTCH_Num            dimzval)
{
  Arch *              tgtarchptr;
  ArchMesh3 *         tgtarchdatptr;

  if (sizeof (SCOTCH_Num) != sizeof (Gnum)) {
    errorPrint ("SCOTCH_archMesh3: internal error");
    return     (1);
  }

  tgtarchptr    = (Arch *) archptr;
  tgtarchdatptr = (ArchMesh3 *) (void *) (&tgtarchptr->data);

  tgtarchptr->class   = archClass ("mesh3D");
  tgtarchdatptr->c[0] = (Anum) dimxval;
  tgtarchdatptr->c[1] = (Anum) dimyval;
  tgtarchdatptr->c[2] = (Anum) dimzval;

  return (0);
}

/*
**
*/

int
SCOTCH_archTleaf (
SCOTCH_Arch * const         archptr,
const SCOTCH_Num            levlnbr,              /*+ Number of levels in architecture            +*/
const SCOTCH_Num * const    sizetab,              /*+ Size array, by increasing level number      +*/
const SCOTCH_Num * const    linktab)              /*+ Link cost array, by increasing level number +*/
{
  Anum                levlnum;
  Anum                sizeval;
  Arch *              tgtarchptr;
  ArchTleaf *         tgtarchdatptr;

  if (sizeof (SCOTCH_Num) != sizeof (Gnum)) {
    errorPrint ("SCOTCH_archTleaf: internal error");
    return     (1);
  }

  tgtarchptr        = (Arch *) archptr;
  tgtarchdatptr     = (ArchTleaf *) (void *) (&tgtarchptr->data);
  tgtarchptr->class = archClass ("tleaf");

  if ((tgtarchdatptr->sizetab = memAlloc ((levlnbr * 2 + 1) * sizeof (Anum))) == NULL) { /* TRICK: One more slot for linktab[-1] */
    errorPrint ("SCOTCH_archTleaf: out of memory");
    return     (1);
  }
  tgtarchdatptr->levlnbr     = (Anum) levlnbr;
  tgtarchdatptr->linktab     = tgtarchdatptr->sizetab + tgtarchdatptr->levlnbr + 1;
  tgtarchdatptr->linktab[-1] = 0;                 /* TRICK: Dummy slot for for level-0 communication */

  for (levlnum = 0, sizeval = 1; levlnum < tgtarchdatptr->levlnbr; levlnum ++) {
    tgtarchdatptr->sizetab[levlnum] = sizetab[levlnum];
    tgtarchdatptr->linktab[levlnum] = linktab[levlnum];
    sizeval *= tgtarchdatptr->sizetab[levlnum];
  }
  tgtarchdatptr->sizeval = sizeval;

  return (0);
}

/*
**
*/

int
SCOTCH_archTorus2 (
SCOTCH_Arch * const         archptr,
const SCOTCH_Num            dimxval,
const SCOTCH_Num            dimyval)
{
  Arch *              tgtarchptr;
  ArchTorus2 *        tgtarchdatptr;

  if (sizeof (SCOTCH_Num) != sizeof (Gnum)) {
    errorPrint ("SCOTCH_archTorus2: internal error");
    return     (1);
  }

  tgtarchptr    = (Arch *) archptr;
  tgtarchdatptr = (ArchTorus2 *) (void *) (&tgtarchptr->data);

  tgtarchptr->class   = archClass ("torus2D");
  tgtarchdatptr->c[0] = (Anum) dimxval;
  tgtarchdatptr->c[1] = (Anum) dimyval;

  return (0);
}

/*
**
*/

int
SCOTCH_archTorus3 (
SCOTCH_Arch * const         archptr,
const SCOTCH_Num            dimxval,
const SCOTCH_Num            dimyval,
const SCOTCH_Num            dimzval)
{
  Arch *              tgtarchptr;
  ArchTorus3 *        tgtarchdatptr;

  if (sizeof (SCOTCH_Num) != sizeof (Gnum)) {
    errorPrint ("SCOTCH_archTorus3: internal error");
    return     (1);
  }

  tgtarchptr    = (Arch *) archptr;
  tgtarchdatptr = (ArchTorus3 *) (void *) (&tgtarchptr->data);

  tgtarchptr->class   = archClass ("torus3D");
  tgtarchdatptr->c[0] = (Anum) dimxval;
  tgtarchdatptr->c[1] = (Anum) dimyval;
  tgtarchdatptr->c[2] = (Anum) dimzval;

  return (0);
}

/*
**
*/

int
SCOTCH_archVcmplt (
SCOTCH_Arch * const         archptr)
{
  Arch *              tgtarchptr;

  if (sizeof (SCOTCH_Num) != sizeof (Gnum)) {
    errorPrint ("SCOTCH_archVcmplt: internal error");
    return     (1);
  }

  tgtarchptr = (Arch *) archptr;

  tgtarchptr->class = archClass ("varcmplt");

  return (0);
}

/*
**
*/

int
SCOTCH_archVhcub (
SCOTCH_Arch * const         archptr)
{
  Arch *              tgtarchptr;

  if (sizeof (SCOTCH_Num) != sizeof (Gnum)) {
    errorPrint ("SCOTCH_archVhcub: internal error");
    return     (1);
  }

  tgtarchptr = (Arch *) archptr;

  tgtarchptr->class = archClass ("vhcub");

  return (0);
}
