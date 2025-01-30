!
!! rdrnxn.f90
!!
!!    Copyright (C) 2023 by Wuhan University
!!
!!    This program belongs to PRIDE PPP-AR which is an open source software:
!!    you can redistribute it and/or modify it under the terms of the GNU
!!    General Public License (version 3) as published by the Free Software Foundation.
!!
!!    This program is distributed in the hope that it will be useful,
!!    but WITHOUT ANY WARRANTY; without even the implied warranty of
!!    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
!!    GNU General Public License (version 3) for more details.
!!
!!    You should have received a copy of the GNU General Public License
!!    along with this program. If not, see <https://www.gnu.org/licenses/>.
!!
!! Contributor: Maorong Ge, Jihang Lin, Binchen Fu
!!
!!
!! purpose   : read rinex navigation file.  choose only records
!!             within time (fjd0,fjd1) and duplicated records are
!!             ignored.
!!
!! parameters: flneph -- rinex navigation file name
!!             fjd0,fjd1 -- start and stop time within the records are requested
!!             neph -- total number of records
!!             ephem -- broadcast ephemeris
!!
!
subroutine rdrnxn(flneph, fjd0, fjd1, neph, ephem)
  implicit none
  include '../header/const.h'
  include '../header/brdeph.h'

! parameter
  type(brdeph)  ephem(1:*)
  character*(*) flneph
  integer*4     neph, ierr
  real*8        fjd0, fjd1
! local
  type(brdeph)  eph
  integer*4     i1, i2, i3, i4, i5, j, iver, iday
  integer*4     iunit, iunit_next
  character*3   svn
  character*2   svn_str
  integer*4     svn_int
  integer*4     meph
  logical*1     already
  real*8        sec, dt1, dt2, a0, a1, a2
  real*8        bn, fn, ae
  character*80  line, fmt1
  character*1   satsys
  character*1   indicator
  character*3   navrecord_type
  character*4   nav_type
! function called
  integer*4 get_valid_unit
  integer*4 modified_julday
  real*8 taiutc

  meph = MAXEPH
  if (neph .ne. 0) meph = neph
  neph = 0

  ierr = 0
  iunit = get_valid_unit(10)
  open (iunit, file=flneph, status='OLD', iostat=ierr)
  if (ierr .ne. 0) goto 100

  iday = 0
  do while (.true.)
    read (iunit, '(i6,a)', iostat=ierr) iver, line
    if (ierr .ne. 0) return

    line = adjustl(line)
    do while (index(line, 'END OF HEADER') .eq. 0 .and. line(1:1) .ne. ' ')
      read (iunit, '(a)', iostat=ierr) line
      if (ierr .ne. 0) goto 100
      line = adjustl(line)
    end do

    if (iver .eq. 1) then
      fmt1 = '(i2,5i3,f5.1,3f19.12/5(3x,4d19.12/),3x,4d19.12)'
    elseif (iver .eq. 2) then
      fmt1 = '(i2,5i3,f5.1,3d19.12/5(3x,4d19.12/),3x,4d19.12/)'
    elseif (iver .ge. 3) then
      fmt1 = '(6(4x,4d19.12/))'
    end if

    do while (.true.)
      if (iver .eq. 1 .or. iver .eq. 2) then
        satsys = "G"
        read (iunit, fmt1, err=100, end=200) svn_int, i1, i2, i3, i4, i5, sec, eph%a0, eph%a1, eph%a2, &
          eph%aode, eph%crs, eph%dn, eph%m0, eph%cuc, eph%e, eph%cus, eph%roota, eph%toe, eph%cic, &
          eph%omega0, eph%cis, eph%i0, eph%crc, eph%omega, eph%omegadot, eph%idot, eph%resvd0, &
          eph%week, eph%resvd1, eph%accu, eph%hlth, eph%tgd, eph%aodc
        write (svn_str, '(i2.2)') svn_int
        eph%svn = 'G'//svn_str
        call yr2year(i1)
        eph%jd = modified_julday(i3, i2, i1)
        eph%sod = i4*3600.d0 + i5*60 + sec
      elseif (iver .ge. 3) then
        satsys = ""
        if (iver .eq. 4) then
          indicator = ""
          navrecord_type = ""
          nav_type = ""
          read (iunit, '(a1,2(1X,a3),1X,a4)', iostat=ierr, end=200) indicator, navrecord_type, svn, nav_type
          if (ierr .ne. 0) cycle
          if (indicator .ne. '>' .or. navrecord_type .ne. "EPH") cycle
          satsys = svn(1:1)
          if (satsys .eq. 'G')then
            if (nav_type .ne. "LNAV") cycle
          elseif (satsys .eq. 'R')then
            if (nav_type .ne. "FDMA") cycle
          elseif (satsys .eq. 'E')then
            if (nav_type .ne. "INAV") cycle
          elseif (satsys .eq. 'C')then
            if (nav_type .ne. "D1  " .and. nav_type .ne. "D2  ") cycle
          elseif (satsys .eq. 'J')then
            if (nav_type .ne. "LNAV") cycle
          else
            cycle
          endif
        end if
        read (iunit, '(a3,1X,i4,4(1x,i2),1x,f2.0,3d19.12)', iostat=ierr, end=200) svn, &
          i1, i2, i3, i4, i5, sec, a0, a1, a2
        if (svn(1:1) .ne. ' ' .and. svn(2:2) .eq. ' ' .and. svn(3:3) .ne. ' ') svn(2:2) = '0'
        satsys = svn(1:1)
        if (ierr .ne. 0) cycle
        if (satsys .eq. 'G' .or. satsys .eq. 'E' .or. satsys .eq. 'C' .or. satsys .eq. 'J') then
          eph%svn = svn
          eph%a0 = a0
          eph%a1 = a1
          eph%a2 = a2
          read (iunit, fmt1, err=100, end=200) &
            eph%aode, eph%crs, eph%dn, eph%m0, &
            eph%cuc, eph%e, eph%cus, eph%roota, &
            eph%toe, eph%cic, eph%omega0, eph%cis, &
            eph%i0, eph%crc, eph%omega, eph%omegadot, &
            eph%idot, eph%resvd0, eph%week, eph%resvd1, &
            eph%accu, eph%hlth, eph%tgd, eph%aodc
          call yr2year(i1)
          eph%jd = modified_julday(i3, i2, i1)
          eph%sod = i4*3600.d0 + i5*60 + sec
          if (satsys .eq. 'C') then
            !! convert to GPST
            call timinc(eph%jd, eph%sod, 14.d0, eph%jd, eph%sod) ! BDT to GPST
          end if
        elseif (satsys .eq. 'R') then
          eph%svn = svn
          eph%a0 = -a0
          eph%a1 = a1
          eph%a2 = a2
          read (iunit, '(4x,4d19.12/,4x,4d19.12/,4x,4d19.12)', err=100, end=200) &
            eph%pos(1), eph%vel(1), eph%acc(1), bn, &
            eph%pos(2), eph%vel(2), eph%acc(2), fn, &
            eph%pos(3), eph%vel(3), eph%acc(3), ae
          if (i5 .ne. 15 .and. i5 .ne. 45 .or. sec .ne. 0.d0) cycle ! see IGSMAIL-6030
          call yr2year(i1)
          eph%jd = modified_julday(i3, i2, i1)
          eph%sod = i4*3600.d0 + i5*60 + sec  ! UTC
          eph%pos(1:3) = eph%pos(1:3)*1.d3 ! km to m
          eph%vel(1:3) = eph%vel(1:3)*1.d3 ! km/s to m/s
          eph%acc(1:3) = eph%acc(1:3)*1.d3 ! km/s^2 to m/s^2
          eph%bn = int(bn)
          eph%fn = int(fn)
          eph%ae = int(ae)
          call timinc(eph%jd, eph%sod, taiutc(eph%jd) - 19.d0, eph%jd, eph%sod) ! UTC to GPST
        else
          cycle
        end if
      end if
!
!! check time
      dt1 = 0.d0
      dt2 = 0.d0
      if (fjd0 .ne. 0.d0) dt1 = eph%jd + eph%sod/86400.d0 - fjd0
      if (fjd1 .ne. 0.d0) dt2 = eph%jd + eph%sod/86400.d0 - fjd1
      !! GPS ephemerides interval (2 hours)
      if (dt1 .lt. -2.d0/24.d0 .or. dt2 .gt. 2.d0/24.d0) cycle
!
!! in case of repetition
      already = .false.
      do j = 1, neph
        if (ephem(j)%svn .ne. eph%svn) cycle
        dt1 = (ephem(j)%jd - eph%jd)*86400.d0 + (ephem(j)%sod - eph%sod)
        !! Galileo ephemerides interval (10 minutes)
        if (dt1 .lt. -600.d0 .or. dt1 .gt. 600.d0) cycle
        already = .true.
        exit
      end do
      if (.not. already .and. neph .lt. meph) then
        neph = neph + 1
        ephem(neph) = eph
      else if (neph .gt. meph) then
        write (*, *) '###WARNING(rdrnxn): too many ephemeris records(maxeph, neph),', meph, neph
        return
      end if
    end do
!
!! try finding the next nav file
200 continue
    iday = iday + 1
    if (eph%jd + eph%sod/864.d2 .gt. fjd1) exit
    call next_rinex(iunit, iunit_next, int(fjd1))
    if (iunit_next .eq. 0) exit
    close (iunit)
    iunit = iunit_next
    if (int(eph%jd) + iday .lt. int(fjd0)) goto 200
  end do

  close (iunit)
  return

100 continue
  write (*, *) '***ERROR(rdrnxn): open/read nav. file,', trim(flneph)
  call exit(1)
end subroutine
