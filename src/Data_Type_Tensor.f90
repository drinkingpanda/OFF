!>This module contains the definition of Type_Tensor and its procedures.
!>This derived type is useful for manipulating second order tensors in 3D space. The components of the tensors
!>are derived type of Type_Vector. The components are defined in a three-dimensional cartesian frame of reference.
!>All the tensorial math procedures (cross, dot products, normL2...) assume a three-dimensional cartesian frame of reference.
!> @note The operators of assignment (=), multiplication (*), division (/), sum (+) and subtraction (-) have been overloaded.
!> Furthermore the \em dot, \em double \em dot and \em diadic products have been defined.
!> Therefore this module provides a far-complete algebra based on Type_Tensor derived type. This algebra simplifies the
!> tensorial operations of Partial Differential Equations (PDE) systems.
!> @todo \b DocComplete: Complete the documentation of internal procedures
module Data_Type_Tensor
!-----------------------------------------------------------------------------------------------------------------------------------
USE IR_Precision                                     ! Integers and reals precision definition.
USE Data_Type_Vector, set_vec => set, get_vec => get ! Definition of type Type_Vector.
!-----------------------------------------------------------------------------------------------------------------------------------

!-----------------------------------------------------------------------------------------------------------------------------------
implicit none
private
public:: unity
public:: set,get
public:: write,read
public:: assignment (=)
public:: operator (*)
public:: operator (/)
public:: operator (+)
public:: operator (-)
public:: operator (.ddot.)
public:: operator (.dot.)
public:: operator (.diad.)
public:: sq_norm
public:: normL2
public:: normalize
public:: transpose
public:: determinant
public:: invert,invertible
!-----------------------------------------------------------------------------------------------------------------------------------

!-----------------------------------------------------------------------------------------------------------------------------------
!> Derived type defining tensors.
!> @note The components the tensor are 3 vectors arranged as following: \n
!> \f$ T_{ij}=\left[{\begin{array}{*{20}{c}}t_{11}&t_{12}&t_{13}\\ t_{21}&t_{22}&t_{23}\\ t_{31}&t_{32}&t_{33}\end{array}}\right]
!> =\left[{\begin{array}{*{20}{c}} {x\% x}&{x\% y}&{x\% z}\\ {y\% x}&{y\% y}&{y\% z}\\ {z\% x}&{z\% y}&{z\% z}\end{array}}\right]\f$
type, public:: Type_Tensor
  sequence
  type(Type_Vector):: x !< Cartesian vector component in x direction.
  type(Type_Vector):: y !< Cartesian vector component in y direction.
  type(Type_Vector):: z !< Cartesian vector component in z direction.
endtype Type_Tensor
type(Type_Tensor), parameter:: unity = Type_Tensor(ex,ey,ez) !< Unity (identity) tensor.
!-----------------------------------------------------------------------------------------------------------------------------------

!-----------------------------------------------------------------------------------------------------------------------------------
!> @brief Write overloading of Type_Tensor variable.
!> This is a generic interface to 8 functions: there are 2 functions (one binary and another ascii) for writing scalar variables,
!> 1D/2D or 3D arrays. The functions return an error integer code. The calling signatures are:
!> @code ...
!> integer(I4P):: err,unit
!> character(1):: format="*"
!> type(Type_Tensor):: ten_scal,ten_1D(10),ten_2D(10,2),ten_3D(10,2,3)
!> ...
!> ! formatted writing of ten_scal, ten_1D, ten_2D and ten_3D
!> err = write(unit,format,ten_scal)
!> err = write(unit,format,ten_1D)
!> err = write(unit,format,ten_2D)
!> err = write(unit,format,ten_3D)
!> ! binary writing of ten_scal, ten_1D, ten_2D and ten_3D
!> err = write(unit,ten_scal)
!> err = write(unit,ten_1D)
!> err = write(unit,ten_2D)
!> err = write(unit,ten_3D)
!> ... @endcode
interface write
  module procedure Write_Bin_Scalar, Write_Ascii_Scalar
  module procedure Write_Bin_Array1D,Write_Ascii_Array1D
  module procedure Write_Bin_Array2D,Write_Ascii_Array2D
  module procedure Write_Bin_Array3D,Write_Ascii_Array3D
endinterface
!> @brief Read overloading of Type_Tensor variable.
!> This is a generic interface to 8 functions: there are 2 functions (one binary and another ascii) for reading scalar variables,
!> 1D/2D or 3D arrays. The functions return an error integer code. The calling signatures are:
!> @code ...
!> integer(I4P):: err,unit
!> character(1):: format="*"
!> type(Type_Tensor):: ten_scal,ten_1D(10),ten_2D(10,2),ten_3D(10,2,3)
!> ...
!> ! formatted reading of ten_scal, ten_1D, ten_2D and ten_3D
!> err = read(unit,format,ten_scal)
!> err = read(unit,format,ten_1D)
!> err = read(unit,format,ten_2D)
!> err = read(unit,format,ten_3D)
!> ! binary reading of ten_scal, ten_1D, ten_2D and ten_3D
!> err = read(unit,ten_scal)
!> err = read(unit,ten_1D)
!> err = read(unit,ten_2D)
!> err = read(unit,ten_3D)
!> ... @endcode
interface read
  module procedure Read_Bin_Scalar, Read_Ascii_Scalar
  module procedure Read_Bin_Array1D,Read_Ascii_Array1D
  module procedure Read_Bin_Array2D,Read_Ascii_Array2D
  module procedure Read_Bin_Array3D,Read_Ascii_Array3D
endinterface
!> @brief Assignment operator (=) overloading.
interface assignment (=)
  module procedure assign_Vec
#ifdef r16p
  module procedure assign_ScalR16P
#endif
  module procedure assign_ScalR8P
  module procedure assign_ScalR4P
  module procedure assign_ScalI8P
  module procedure assign_ScalI4P
  module procedure assign_ScalI2P
  module procedure assign_ScalI1P
end interface
!> @brief Multiplication operator (*) overloading.
!> @note The admissible multiplications are:
!>       - Type_Tensor * Type_Tensor: each component of first tensor variable (ten1) is multiplied for the
!>         corresponding component of the second one (ten2), i.e. \n
!>         \f$ {\rm result\%x = ten1\%x*ten2\%x} \f$ \n
!>         \f$ {\rm result\%y = ten1\%y*ten2\%y} \f$ \n
!>         \f$ {\rm result\%z = ten1\%z*ten2\%z} \f$ \n
!>       - scalar number (real or integer of any kinds defined in IR_Precision module) * Type_Tensor: each component of
!>         Type_Tensor is multiplied for the scalar, i.e. \n
!>         \f$ {\rm result\%x = ten\%x*scalar} \f$ \n
!>         \f$ {\rm result\%y = ten\%y*scalar} \f$ \n
!>         \f$ {\rm result\%z = ten\%z*scalar} \f$ \n
!>       - Type_Tensor * scalar number (real or integer of any kinds defined in IR_Precision module): each component of
!>         Type_Tensor is multiplied for the scalar, i.e. \n
!>         \f$ {\rm result\%x = ten\%x*scalar} \f$ \n
!>         \f$ {\rm result\%y = ten\%y*scalar} \f$ \n
!>         \f$ {\rm result\%z = ten\%z*scalar} \f$ \n
interface operator (*)
  module procedure ten_mul_ten
#ifdef r16p
  module procedure ScalR16P_mul_ten
#endif
  module procedure ScalR8P_mul_ten
  module procedure ScalR4P_mul_ten
  module procedure ScalI8P_mul_ten
  module procedure ScalI4P_mul_ten
  module procedure ScalI2P_mul_ten
  module procedure ScalI1P_mul_ten
#ifdef r16p
  module procedure ten_mul_ScalR16P
#endif
  module procedure ten_mul_ScalR8P
  module procedure ten_mul_ScalR4P
  module procedure ten_mul_ScalI8P
  module procedure ten_mul_ScalI4P
  module procedure ten_mul_ScalI2P
  module procedure ten_mul_ScalI1P
endinterface
!> @brief Division operator (/) overloading.
!> @note The admissible divisions are:
!>       - Type_Tensor / Type_Tensor: each component of first tensor variable (ten1) is divided for the
!>         corresponding component of the second one (ten2), i.e. \n
!>         \f$ {\rm result\%x = \frac{ten1\%x}{ten2\%x}} \f$ \n
!>         \f$ {\rm result\%y = \frac{ten1\%y}{ten2\%y}} \f$ \n
!>         \f$ {\rm result\%z = \frac{ten1\%z}{ten2\%z}} \f$ \n
!>       - Type_Tensor / scalar number (real or integer of any kinds defined in IR_Precision module): each component of
!>         Type_Tensor is divided for the scalar, i.e. \n
!>         \f$ {\rm result\%x = \frac{ten\%x}{scalar}} \f$ \n
!>         \f$ {\rm result\%y = \frac{ten\%y}{scalar}} \f$ \n
!>         \f$ {\rm result\%z = \frac{ten\%z}{scalar}} \f$ \n
interface operator (/)
  module procedure ten_div_ten
#ifdef r16p
  module procedure ten_div_ScalR16P
#endif
  module procedure ten_div_ScalR8P
  module procedure ten_div_ScalR4P
  module procedure ten_div_ScalI8P
  module procedure ten_div_ScalI4P
  module procedure ten_div_ScalI2P
  module procedure ten_div_ScalI1P
endinterface
!> @brief Sum operator (+) overloading.
!> @note The admissible summations are:
!>       - Type_Tensor + Type_Tensor: each component of first tensor variable (ten1) is summed with the
!>         corresponding component of the second one (ten2), i.e. \n
!>         \f$ {\rm result\%x = ten1\%x+ten2\%x} \f$ \n
!>         \f$ {\rm result\%y = ten1\%y+ten2\%y} \f$ \n
!>         \f$ {\rm result\%z = ten1\%z+ten2\%z} \f$ \n
!>       - scalar number (real or integer of any kinds defined in IR_Precision module) + Type_Tensor: each component of
!>         Type_Tensor is summed with the scalar, i.e. \n
!>         \f$ {\rm result\%x = ten\%x+scalar} \f$ \n
!>         \f$ {\rm result\%y = ten\%y+scalar} \f$ \n
!>         \f$ {\rm result\%z = ten\%z+scalar} \f$ \n
!>       - Type_Tensor + scalar number (real or integer of any kinds defined in IR_Precision module): each component of
!>         Type_Tensor is summed with the scalar, i.e. \n
!>         \f$ {\rm result\%x = ten\%x+scalar} \f$ \n
!>         \f$ {\rm result\%y = ten\%y+scalar} \f$ \n
!>         \f$ {\rm result\%z = ten\%z+scalar} \f$ \n
interface operator (+)
  module procedure positive_ten
  module procedure ten_sum_ten
#ifdef r16p
  module procedure ScalR16P_sum_ten
#endif
  module procedure ScalR8P_sum_ten
  module procedure ScalR4P_sum_ten
  module procedure ScalI8P_sum_ten
  module procedure ScalI4P_sum_ten
  module procedure ScalI2P_sum_ten
  module procedure ScalI1P_sum_ten
#ifdef r16p
  module procedure ten_sum_ScalR16P
#endif
  module procedure ten_sum_ScalR8P
  module procedure ten_sum_ScalR4P
  module procedure ten_sum_ScalI8P
  module procedure ten_sum_ScalI4P
  module procedure ten_sum_ScalI2P
  module procedure ten_sum_ScalI1P
endinterface
!> @brief Subtraction operator (-) overloading.
!> @note The admissible subtractions are:
!>       - Type_Tensor - Type_Tensor: each component of first tensor variable (ten1) is subtracted with the
!>         corresponding component of the second one (ten2), i.e. \n
!>         \f$ {\rm result\%x = ten1\%x-ten2\%x} \f$ \n
!>         \f$ {\rm result\%y = ten1\%y-ten2\%y} \f$ \n
!>         \f$ {\rm result\%z = ten1\%z-ten2\%z} \f$ \n
!>       - scalar number (real or integer of any kinds defined in IR_Precision module) - Type_Tensor: each component of
!>         Type_Tensor is subtracted with the scalar, i.e. \n
!>         \f$ {\rm result\%x = scalar-ten\%x} \f$ \n
!>         \f$ {\rm result\%y = scalar-ten\%y} \f$ \n
!>         \f$ {\rm result\%z = scalar-ten\%z} \f$ \n
!>       - Type_Tensor - scalar number (real or integer of any kinds defined in IR_Precision module): each component of
!>         Type_Tensor is subtracted with the scalar, i.e. \n
!>         \f$ {\rm result\%x = ten\%x-scalar} \f$ \n
!>         \f$ {\rm result\%y = ten\%y-scalar} \f$ \n
!>         \f$ {\rm result\%z = ten\%z-scalar} \f$ \n
interface operator (-)
  module procedure negative_ten
  module procedure ten_sub_ten
#ifdef r16p
  module procedure ScalR16P_sub_ten
#endif
  module procedure ScalR8P_sub_ten
  module procedure ScalR4P_sub_ten
  module procedure ScalI8P_sub_ten
  module procedure ScalI4P_sub_ten
  module procedure ScalI2P_sub_ten
  module procedure ScalI1P_sub_ten
#ifdef r16p
  module procedure ten_sub_ScalR16P
#endif
  module procedure ten_sub_ScalR8P
  module procedure ten_sub_ScalR4P
  module procedure ten_sub_ScalI8P
  module procedure ten_sub_ScalI4P
  module procedure ten_sub_ScalI2P
  module procedure ten_sub_ScalI1P
endinterface
!> @brief Double dot product operator (.ddot.) definition.
interface operator (.ddot.)
  module procedure ddotproduct
endinterface
!> @brief Dot product operator (.dot.) definition.
interface operator (.dot.)
  module procedure ten_dot_vec,vec_dot_ten
endinterface
!> @brief Diadic product operator (.diad.) definition.
interface operator (.diad.)
  module procedure diadicproduct
endinterface
!> @brief Square norm function \em sq_norm overloading.
!> The function \em sq_norm defined for Type_Vector is overloaded for handling also Type_Tensor.
interface sq_norm
  module procedure sq_norm,sq_norm_ten
endinterface
!> @brief L2 norm function \em normL2 overloading.
!> The function \em normL2 defined for Type_Vector is overloaded for handling also Type_Tensor.
interface normL2
  module procedure normL2,normL2_ten
endinterface
!> @brief Normalize function \em normalize overloading.
!> The function \em normalize defined for Type_Vector is overloaded for handling also Type_Tensor.
interface normalize
  module procedure normalize,normalize_ten
endinterface
!> @brief Transpose function \em transpose overloading.
!> The built in function \em transpose defined for rank 2 arrays is overloaded for handling also Type_Tensor.
interface transpose
  module procedure transpose_ten
endinterface
!-----------------------------------------------------------------------------------------------------------------------------------
contains
  !> Subroutine for setting components of Type_Tensor variable.
  elemental subroutine set(x,y,z,ten)
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  type(Type_Vector), intent(IN), optional:: x   !< Cartesian vector component in x direction.
  type(Type_Vector), intent(IN), optional:: y   !< Cartesian vector component in y direction.
  type(Type_Vector), intent(IN), optional:: z   !< Cartesian vector component in z direction.
  type(Type_Tensor), intent(INOUT)::        ten !< Tensor.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  if (present(x)) ten%x = x
  if (present(y)) ten%y = y
  if (present(z)) ten%z = z
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine set

  !> Subroutine for extracting Type_Tensor variable components.
  elemental subroutine get(x,y,z,ten)
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  type(Type_Vector), intent(OUT), optional:: x   !< Cartesian vector component in x direction.
  type(Type_Vector), intent(OUT), optional:: y   !< Cartesian vector component in y direction.
  type(Type_Vector), intent(OUT), optional:: z   !< Cartesian vector component in z direction.
  type(Type_Tensor), intent(IN)::            ten !< Tensor.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  if (present(x)) x = ten%x
  if (present(y)) y = ten%y
  if (present(z)) z = ten%z
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine get

  ! write
  function Write_Bin_Scalar(unit,ten) result(err)
  !---------------------------------------------------------------------------------------------------------------------------------
  !!Function for writing Type_Tensor (binary, scalar).
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  integer(I4P),      intent(IN):: unit ! Logic unit.
  type(Type_Tensor), intent(IN):: ten  ! Tensor.
  integer(I_P)::                  err  ! Error traping flag: 0 no errors, >0 error occours.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  write(unit,iostat=err)ten
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction Write_Bin_Scalar

  function Write_Ascii_Scalar(unit,format,ten) result(err)
  !---------------------------------------------------------------------------------------------------------------------------------
  !!Function for writing Type_Tensor (ascii, scalar).
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  integer(I4P),      intent(IN):: unit   ! Logic unit.
  character(*),      intent(IN):: format ! Format specifier.
  type(Type_Tensor), intent(IN):: ten    ! Tensor.
  integer(I_P)::                  err    ! Error traping flag: 0 no errors, >0 error occours.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  select case(adjustl(trim(format)))
  case('*')
    write(unit,*,iostat=err)ten
  case default
    write(unit,adjustl(trim(format)),iostat=err)ten
  endselect
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction Write_Ascii_Scalar

  function Write_Bin_Array1D(unit,ten) result(err)
  !---------------------------------------------------------------------------------------------------------------------------------
  !!Function for writing Type_Tensor (binary, array 1D).
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  integer(I4P),      intent(IN):: unit   ! Logic unit.
  type(Type_Tensor), intent(IN):: ten(:) ! Tensor.
  integer(I_P)::                  err    ! Error traping flag: 0 no errors, >0 error occours.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  write(unit,iostat=err)ten
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction Write_Bin_Array1D

  function Write_Ascii_Array1D(unit,format,ten) result(err)
  !---------------------------------------------------------------------------------------------------------------------------------
  !!Function for writing Type_Tensor (ascii, array 1D).
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  integer(I4P),      intent(IN):: unit   ! Logic unit.
  character(*),      intent(IN):: format ! Format specifier.
  type(Type_Tensor), intent(IN):: ten(:) ! Tensor.
  integer(I_P)::                  err    ! Error traping flag: 0 no errors, >0 error occours.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  select case(adjustl(trim(format)))
  case('*')
    write(unit,*,iostat=err)ten
  case default
    write(unit,adjustl(trim(format)),iostat=err)ten
  endselect
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction Write_Ascii_Array1D

  function Write_Bin_Array2D(unit,ten) result(err)
  !---------------------------------------------------------------------------------------------------------------------------------
  !!Function for writing Type_Tensor (binary, array 2D).
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  integer(I4P),      intent(IN):: unit     ! Logic unit.
  type(Type_Tensor), intent(IN):: ten(:,:) ! Tensor.
  integer(I_P)::                  err      ! Error traping flag: 0 no errors, >0 error occours.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  write(unit,iostat=err)ten
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction Write_Bin_Array2D

  function Write_Ascii_Array2D(unit,format,ten) result(err)
  !---------------------------------------------------------------------------------------------------------------------------------
  !!Function for writing Type_Tensor (ascii, array 2D).
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  integer(I4P),      intent(IN):: unit     ! Logic unit.
  character(*),      intent(IN):: format   ! Format specifier.
  type(Type_Tensor), intent(IN):: ten(:,:) ! Tensor.
  integer(I_P)::                  err      ! Error traping flag: 0 no errors, >0 error occours.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  select case(adjustl(trim(format)))
  case('*')
    write(unit,*,iostat=err)ten
  case default
    write(unit,adjustl(trim(format)),iostat=err)ten
  endselect
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction Write_Ascii_Array2D

  function Write_Bin_Array3D(unit,ten) result(err)
  !---------------------------------------------------------------------------------------------------------------------------------
  !!Function for writing Type_Tensor (binary, array 3D).
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  integer(I4P),      intent(IN):: unit       ! Logic unit.
  type(Type_Tensor), intent(IN):: ten(:,:,:) ! Tensor.
  integer(I_P)::                  err        ! Error traping flag: 0 no errors, >0 error occours.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  write(unit,iostat=err)ten
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction Write_Bin_Array3D

  function Write_Ascii_Array3D(unit,format,ten) result(err)
  !---------------------------------------------------------------------------------------------------------------------------------
  !!Function for writing Type_Tensor (ascii, Array 3D).
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  integer(I4P),      intent(IN):: unit       ! Logic unit
  character(*),      intent(IN):: format     ! Format specifier.
  type(Type_Tensor), intent(IN):: ten(:,:,:) ! Tensor.
  integer(I_P)::                  err        ! Error traping flag: 0 no errors, >0 error occours.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  select case(adjustl(trim(format)))
  case('*')
    write(unit,*,iostat=err)ten
  case default
    write(unit,adjustl(trim(format)),iostat=err)ten
  endselect
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction Write_Ascii_Array3D

  ! read
  function Read_Bin_Scalar(unit,ten) result(err)
  !---------------------------------------------------------------------------------------------------------------------------------
  !!Function for reading Type_Tensor (binary, scalar).
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  integer(I4P),      intent(IN)::    unit  ! Logic unit.
  type(Type_Tensor), intent(INOUT):: ten   ! Tensor.
  integer(I_P)::                     err   ! Error traping flag: 0 no errors, >0 error occours.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  read(unit,iostat=err)ten
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction Read_Bin_Scalar

  function Read_Ascii_Scalar(unit,format,ten) result(err)
  !---------------------------------------------------------------------------------------------------------------------------------
  !!Function for reading Type_Tensor (ascii, scalar).
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  integer(I4P),      intent(IN)::    unit   ! Logic unit.
  character(*),      intent(IN)::    format ! Format specifier.
  type(Type_Tensor), intent(INOUT):: ten    ! Tensor.
  integer(I_P)::                     err    ! Error traping flag: 0 no errors, >0 error occours.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  select case(adjustl(trim(format)))
  case('*')
    read(unit,*,iostat=err)ten
  case default
    read(unit,adjustl(trim(format)),iostat=err)ten
  endselect
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction Read_Ascii_Scalar

  function Read_Bin_Array1D(unit,ten) result(err)
  !---------------------------------------------------------------------------------------------------------------------------------
  !!Function for reading Type_Tensor (binary, array 1D).
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  integer(I4P),      intent(IN)::    unit   ! Logic unit.
  type(Type_Tensor), intent(INOUT):: ten(:) ! Tensor.
  integer(I_P)::                     err    ! Error traping flag: 0 no errors, >0 error occours.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  read(unit,iostat=err)ten
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction Read_Bin_Array1D

  function Read_Ascii_Array1D(unit,format,ten) result(err)
  !---------------------------------------------------------------------------------------------------------------------------------
  !!Function for reading Type_Tensor (ascii, array 1D).
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  integer(I4P),      intent(IN)::    unit   ! logic unit
  character(*),      intent(IN)::    format ! format specifier
  type(Type_Tensor), intent(INOUT):: ten(:) ! Tensor.
  integer(I_P)::                     err    ! Error traping flag: 0 no errors, >0 error occours.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  select case(adjustl(trim(format)))
  case('*')
    read(unit,*,iostat=err)ten
  case default
    read(unit,adjustl(trim(format)),iostat=err)ten
  endselect
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction Read_Ascii_Array1D

  function Read_Bin_Array2D(unit,ten) result(err)
  !---------------------------------------------------------------------------------------------------------------------------------
  !!Function for reading Type_Tensor (binary, array 2D).
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  integer(I4P),      intent(IN)::    unit     ! Logic unit.
  type(Type_Tensor), intent(INOUT):: ten(:,:) ! Tensor.
  integer(I_P)::                     err      ! Error traping flag: 0 no errors, >0 error occours.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  read(unit,iostat=err)ten
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction Read_Bin_Array2D

  function Read_Ascii_Array2D(unit,format,ten) result(err)
  !---------------------------------------------------------------------------------------------------------------------------------
  !!Function for reading Type_Tensor (ascii, array 2D).
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  integer(I4P),      intent(IN)::    unit     ! Logic unit.
  character(*),      intent(IN)::    format   ! Format specifier.
  type(Type_Tensor), intent(INOUT):: ten(:,:) ! Tensor.
  integer(I_P)::                     err      ! Error traping flag: 0 no errors, >0 error occours.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  select case(adjustl(trim(format)))
  case('*')
    read(unit,*,iostat=err)ten
  case default
    read(unit,adjustl(trim(format)),iostat=err)ten
  endselect
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction Read_Ascii_Array2D

  function Read_Bin_Array3D(unit,ten) result(err)
  !---------------------------------------------------------------------------------------------------------------------------------
  !!Function for reading Type_Tensor (binary, array 3D).
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  integer(I4P),      intent(IN)::    unit       ! Logic unit.
  type(Type_Tensor), intent(INOUT):: ten(:,:,:) ! Tensor.
  integer(I_P)::                     err        ! Error traping flag: 0 no errors, >0 error occours.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  read(unit,iostat=err)ten
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction Read_Bin_Array3D

  function Read_Ascii_Array3D(unit,format,ten) result(err)
  !---------------------------------------------------------------------------------------------------------------------------------
  !!Subroutine for reading Type_Tensor (ascii, array 3D).
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  integer(I4P),      intent(IN)::    unit       ! Logic unit.
  character(*),      intent(IN)::    format     ! Format specifier.
  type(Type_Tensor), intent(INOUT):: ten(:,:,:) ! Tensor.
  integer(I_P)::                     err        ! Error traping flag: 0 no errors, >0 error occours.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  select case(adjustl(trim(format)))
  case('*')
    read(unit,*,iostat=err)ten
  case default
    read(unit,adjustl(trim(format)),iostat=err)ten
  endselect
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction Read_Ascii_Array3D

  ! Assignment (=)
  elemental subroutine assign_Vec(ten,vec)
  !---------------------------------------------------------------------------------------------------------------------------------
  !!Subroutine for assignment between a vector and ten.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  type(Type_Tensor), intent(INOUT):: ten
  type(Type_Vector), intent(IN)::    vec
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  ten%x = vec
  ten%y = vec
  ten%z = vec
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine assign_Vec

#ifdef r16p
  elemental subroutine assign_ScalR16P(ten,scal)
  !---------------------------------------------------------------------------------------------------------------------------------
  !!Subroutine for assignment between a scalar (real R16P) and ten.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  type(Type_Tensor), intent(INOUT):: ten
  real(R16P),        intent(IN)::    scal
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  ten%x = real(scal,R_P)
  ten%y = real(scal,R_P)
  ten%z = real(scal,R_P)
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine assign_ScalR16P
#endif

  elemental subroutine assign_ScalR8P(ten,scal)
  !---------------------------------------------------------------------------------------------------------------------------------
  !!Subroutine for assignment between a scalar (real R8P) and ten.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  type(Type_Tensor), intent(INOUT):: ten
  real(R8P),         intent(IN)::    scal
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  ten%x = real(scal,R_P)
  ten%y = real(scal,R_P)
  ten%z = real(scal,R_P)
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine assign_ScalR8P

  elemental subroutine assign_ScalR4P(ten,scal)
  !---------------------------------------------------------------------------------------------------------------------------------
  !!Subroutine for assignment between a scalar (real R4P) and ten.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  type(Type_Tensor), intent(INOUT):: ten
  real(R4P),         intent(IN)::    scal
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  ten%x = real(scal,R_P)
  ten%y = real(scal,R_P)
  ten%z = real(scal,R_P)
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine assign_ScalR4P

  elemental subroutine assign_ScalI8P(ten,scal)
  !---------------------------------------------------------------------------------------------------------------------------------
  !!Subroutine for assignment between a scalar (integer I8P) and ten.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  type(Type_Tensor), intent(INOUT):: ten
  integer(I8P),      intent(IN)::    scal
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  ten%x = real(scal,R_P)
  ten%y = real(scal,R_P)
  ten%z = real(scal,R_P)
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine assign_ScalI8P

  elemental subroutine assign_ScalI4P(ten,scal)
  !---------------------------------------------------------------------------------------------------------------------------------
  !!Subroutine for assignment between a scalar (integer I4P) and ten.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  type(Type_Tensor), intent(INOUT):: ten
  integer(I4P),      intent(IN)::    scal
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  ten%x = real(scal,R_P)
  ten%y = real(scal,R_P)
  ten%z = real(scal,R_P)
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine assign_ScalI4P

  elemental subroutine assign_ScalI2P(ten,scal)
  !---------------------------------------------------------------------------------------------------------------------------------
  !!Subroutine for assignment between a scalar (integer I2P) and ten.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  type(Type_Tensor), intent(INOUT):: ten
  integer(I2P),      intent(IN)::    scal
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  ten%x = real(scal,R_P)
  ten%y = real(scal,R_P)
  ten%z = real(scal,R_P)
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine assign_ScalI2P

  elemental subroutine assign_ScalI1P(ten,scal)
  !---------------------------------------------------------------------------------------------------------------------------------
  !!Subroutine for assignment between a scalar (integer I1P) and ten.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  type(Type_Tensor), intent(INOUT):: ten
  integer(I1P),      intent(IN)::    scal
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  ten%x = real(scal,R_P)
  ten%y = real(scal,R_P)
  ten%z = real(scal,R_P)
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine assign_ScalI1P

  ! Multiplication (*)
  elemental function ten_mul_ten(ten1,ten2) result(mul)
  !---------------------------------------------------------------------------------------------------------------------------------
  !!Function for multiply (by components) tensors.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  type(Type_Tensor), intent(IN):: ten1 ! First tensor.
  type(Type_Tensor), intent(IN):: ten2 ! Second tensor.
  type(Type_Tensor)::             mul  ! Resulting tensor.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  mul%x = ten1%x * ten2%x
  mul%y = ten1%y * ten2%y
  mul%z = ten1%z * ten2%z
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction ten_mul_ten

#ifdef r16p
  elemental function ScalR16P_mul_ten(scal,ten) result(mul)
  !---------------------------------------------------------------------------------------------------------------------------------
  !!Function for multiply scalar (real R16P) for ten.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  real(R16P),        intent(IN):: scal
  type(Type_Tensor), intent(IN):: ten
  type(Type_Tensor)::             mul
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  mul%x = real(scal,R_P) * ten%x
  mul%y = real(scal,R_P) * ten%y
  mul%z = real(scal,R_P) * ten%z
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction ScalR16P_mul_ten

  elemental function ten_mul_ScalR16P(ten,scal) result(mul)
  !---------------------------------------------------------------------------------------------------------------------------------
  !!Function for multiply ten for scalar (real R16P).
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  type(Type_Tensor), intent(IN):: ten
  real(R16P),        intent(IN):: scal
  type(Type_Tensor)::             mul
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  mul%x = real(scal,R_P) * ten%x
  mul%y = real(scal,R_P) * ten%y
  mul%z = real(scal,R_P) * ten%z
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction ten_mul_ScalR16P
#endif

  elemental function ScalR8P_mul_ten(scal,ten) result(mul)
  !---------------------------------------------------------------------------------------------------------------------------------
  !!Function for multiply scalar (real R8P) for ten.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  real(R8P),         intent(IN):: scal
  type(Type_Tensor), intent(IN):: ten
  type(Type_Tensor)::             mul
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  mul%x = real(scal,R_P) * ten%x
  mul%y = real(scal,R_P) * ten%y
  mul%z = real(scal,R_P) * ten%z
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction ScalR8P_mul_ten

  elemental function ten_mul_ScalR8P(ten,scal) result(mul)
  !---------------------------------------------------------------------------------------------------------------------------------
  !!Function for multiply ten for scalar (real R8P).
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  type(Type_Tensor), intent(IN):: ten
  real(R8P),         intent(IN):: scal
  type(Type_Tensor)::             mul
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  mul%x = real(scal,R_P) * ten%x
  mul%y = real(scal,R_P) * ten%y
  mul%z = real(scal,R_P) * ten%z
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction ten_mul_ScalR8P

  elemental function ScalR4P_mul_ten(scal,ten) result(mul)
  !---------------------------------------------------------------------------------------------------------------------------------
  !!Function for multiply scalar (real R4P) for ten.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  real(R4P),         intent(IN):: scal
  type(Type_Tensor), intent(IN):: ten
  type(Type_Tensor)::             mul
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  mul%x = real(scal,R_P) * ten%x
  mul%y = real(scal,R_P) * ten%y
  mul%z = real(scal,R_P) * ten%z
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction ScalR4P_mul_ten

  elemental function ten_mul_ScalR4P(ten,scal) result(mul)
  !---------------------------------------------------------------------------------------------------------------------------------
  !!Function for multiply ten for scalar (real R4P).
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  type(Type_Tensor), intent(IN):: ten
  real(R4P),         intent(IN):: scal
  type(Type_Tensor)::             mul
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  mul%x = real(scal,R_P) * ten%x
  mul%y = real(scal,R_P) * ten%y
  mul%z = real(scal,R_P) * ten%z
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction ten_mul_ScalR4P

  elemental function ScalI8P_mul_ten(scal,ten) result(mul)
  !---------------------------------------------------------------------------------------------------------------------------------
  !!Function for multiply scalar (integer I8P) for ten.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  integer(I8P),      intent(IN):: scal
  type(Type_Tensor), intent(IN):: ten
  type(Type_Tensor)::             mul
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  mul%x = real(scal,R_P) * ten%x
  mul%y = real(scal,R_P) * ten%y
  mul%z = real(scal,R_P) * ten%z
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction ScalI8P_mul_ten

  elemental function ten_mul_ScalI8P(ten,scal) result(mul)
  !---------------------------------------------------------------------------------------------------------------------------------
  !!Function for multiply ten for scalar (integer I8P).
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  type(Type_Tensor), intent(IN):: ten
  integer(I8P),      intent(IN):: scal
  type(Type_Tensor)::             mul
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  mul%x = real(scal,R_P) * ten%x
  mul%y = real(scal,R_P) * ten%y
  mul%z = real(scal,R_P) * ten%z
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction ten_mul_ScalI8P

  elemental function ScalI4P_mul_ten(scal,ten) result(mul)
  !---------------------------------------------------------------------------------------------------------------------------------
  !!Function for multiply scalar (integer I4P) for ten.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  integer(I4P),      intent(IN):: scal
  type(Type_Tensor), intent(IN):: ten
  type(Type_Tensor)::             mul
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  mul%x = real(scal,R_P) * ten%x
  mul%y = real(scal,R_P) * ten%y
  mul%z = real(scal,R_P) * ten%z
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction ScalI4P_mul_ten

  elemental function ten_mul_ScalI4P(ten,scal) result(mul)
  !---------------------------------------------------------------------------------------------------------------------------------
  !!Function for multiply ten for scalar (integer I4P).
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  type(Type_Tensor), intent(IN):: ten
  integer(I4P),      intent(IN):: scal
  type(Type_Tensor)::             mul
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  mul%x = real(scal,R_P) * ten%x
  mul%y = real(scal,R_P) * ten%y
  mul%z = real(scal,R_P) * ten%z
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction ten_mul_ScalI4P

  elemental function ScalI2P_mul_ten(scal,ten) result(mul)
  !---------------------------------------------------------------------------------------------------------------------------------
  !!Function for multiply scalar (integer I2P) for ten.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  integer(I2P),      intent(IN):: scal
  type(Type_Tensor), intent(IN):: ten
  type(Type_Tensor)::             mul
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  mul%x = real(scal,R_P) * ten%x
  mul%y = real(scal,R_P) * ten%y
  mul%z = real(scal,R_P) * ten%z
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction ScalI2P_mul_ten

  elemental function ten_mul_ScalI2P(ten,scal) result(mul)
  !---------------------------------------------------------------------------------------------------------------------------------
  !!Function for multiply ten for scalar (integer I2P).
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  type(Type_Tensor), intent(IN):: ten
  integer(I2P),      intent(IN):: scal
  type(Type_Tensor)::             mul
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  mul%x = real(scal,R_P) * ten%x
  mul%y = real(scal,R_P) * ten%y
  mul%z = real(scal,R_P) * ten%z
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction ten_mul_ScalI2P

  elemental function ScalI1P_mul_ten(scal,ten) result(mul)
  !---------------------------------------------------------------------------------------------------------------------------------
  !!Function for multiply scalar (integer I1P) for ten.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  integer(I1P),      intent(IN):: scal
  type(Type_Tensor), intent(IN):: ten
  type(Type_Tensor)::             mul
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  mul%x = real(scal,R_P) * ten%x
  mul%y = real(scal,R_P) * ten%y
  mul%z = real(scal,R_P) * ten%z
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction ScalI1P_mul_ten

  elemental function ten_mul_ScalI1P(ten,scal) result(mul)
  !---------------------------------------------------------------------------------------------------------------------------------
  !!Function for multiply ten for scalar (integer I1P).
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  type(Type_Tensor), intent(IN):: ten
  integer(I1P),      intent(IN):: scal
  type(Type_Tensor)::             mul
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  mul%x = real(scal,R_P) * ten%x
  mul%y = real(scal,R_P) * ten%y
  mul%z = real(scal,R_P) * ten%z
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction ten_mul_ScalI1P

  ! Division (/)
  elemental function ten_div_ten(ten1,ten2) result(div)
  !---------------------------------------------------------------------------------------------------------------------------------
  !!Function for divide ten for ten.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  type(Type_Tensor), intent(IN):: ten1
  type(Type_Tensor), intent(IN):: ten2
  type(Type_Tensor)::             div
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  div%x = ten1%x / ten2%x
  div%y = ten1%y / ten2%y
  div%z = ten1%z / ten2%z
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction ten_div_ten

#ifdef r16p
  elemental function ten_div_ScalR16P(ten,scal) result(div)
  !---------------------------------------------------------------------------------------------------------------------------------
  !!Function for divide ten for scalar (real R16P).
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  type(Type_Tensor), intent(IN):: ten
  real(R16P),        intent(IN):: scal
  type(Type_Tensor)::             div
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  div%x = ten%x / real(scal,R_P)
  div%y = ten%y / real(scal,R_P)
  div%z = ten%z / real(scal,R_P)
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction ten_div_ScalR16P
#endif

  elemental function ten_div_ScalR8P(ten,scal) result(div)
  !---------------------------------------------------------------------------------------------------------------------------------
  !!Function for divide ten for scalar (real R8P).
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  type(Type_Tensor), intent(IN):: ten
  real(R8P),         intent(IN):: scal
  type(Type_Tensor)::             div
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  div%x = ten%x / real(scal,R_P)
  div%y = ten%y / real(scal,R_P)
  div%z = ten%z / real(scal,R_P)
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction ten_div_ScalR8P

  elemental function ten_div_ScalR4P(ten,scal) result(div)
  !---------------------------------------------------------------------------------------------------------------------------------
  !!Function for divide ten for scalar (real R4P).
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  type(Type_Tensor), intent(IN):: ten
  real(R4P),         intent(IN):: scal
  type(Type_Tensor)::             div
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  div%x = ten%x / real(scal,R_P)
  div%y = ten%y / real(scal,R_P)
  div%z = ten%z / real(scal,R_P)
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction ten_div_ScalR4P

  elemental function ten_div_ScalI8P(ten,scal) result(div)
  !---------------------------------------------------------------------------------------------------------------------------------
  !!Function for divide ten for scalar (integer I8P).
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  type(Type_Tensor), intent(IN):: ten
  integer(I8P),      intent(IN):: scal
  type(Type_Tensor)::             div
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  div%x = ten%x / real(scal,R_P)
  div%y = ten%y / real(scal,R_P)
  div%z = ten%z / real(scal,R_P)
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction ten_div_ScalI8P

  elemental function ten_div_ScalI4P(ten,scal) result(div)
  !---------------------------------------------------------------------------------------------------------------------------------
  !!Function for divide ten for scalar (integer I4P).
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  type(Type_Tensor), intent(IN):: ten
  integer(I4P),      intent(IN):: scal
  type(Type_Tensor)::             div
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  div%x = ten%x / real(scal,R_P)
  div%y = ten%y / real(scal,R_P)
  div%z = ten%z / real(scal,R_P)
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction ten_div_ScalI4P

  elemental function ten_div_ScalI2P(ten,scal) result(div)
  !---------------------------------------------------------------------------------------------------------------------------------
  !!Function for divide ten for scalar (integer I2P).
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  type(Type_Tensor), intent(IN):: ten
  integer(I2P),      intent(IN):: scal
  type(Type_Tensor)::             div
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  div%x = ten%x / real(scal,R_P)
  div%y = ten%y / real(scal,R_P)
  div%z = ten%z / real(scal,R_P)
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction ten_div_ScalI2P

  elemental function ten_div_ScalI1P(ten,scal) result(div)
  !---------------------------------------------------------------------------------------------------------------------------------
  !!Function for divide ten for scalar (integer I1P).
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  type(Type_Tensor), intent(IN):: ten
  integer(I1P),      intent(IN):: scal
  type(Type_Tensor)::             div
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  div%x = ten%x / real(scal,R_P)
  div%y = ten%y / real(scal,R_P)
  div%z = ten%z / real(scal,R_P)
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction ten_div_ScalI1P

  ! Sum (+)
  elemental function positive_ten(ten) result(pos)
  !---------------------------------------------------------------------------------------------------------------------------------
  !!Function for applay unary + to an ten.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  type(Type_Tensor), intent(IN):: ten
  type(Type_Tensor)::             pos
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  pos%x =  + ten%x
  pos%y =  + ten%y
  pos%z =  + ten%z
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction positive_ten

  elemental function ten_sum_ten(ten1,ten2) result(summ)
  !---------------------------------------------------------------------------------------------------------------------------------
  !!Function for sum vec and vec.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  type(Type_Tensor), intent(IN):: ten1
  type(Type_Tensor), intent(IN):: ten2
  type(Type_Tensor)::             summ
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  summ%x = ten1%x + ten2%x
  summ%y = ten1%y + ten2%y
  summ%z = ten1%z + ten2%z
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction ten_sum_ten

#ifdef r16p
  elemental function ScalR16P_sum_ten(scal,ten) result(summ)
  !---------------------------------------------------------------------------------------------------------------------------------
  !!Function for sum scalar (real R16P) and ten.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  real(R16P),        intent(IN):: scal
  type(Type_Tensor), intent(IN):: ten
  type(Type_Tensor)::             summ
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  summ%x = real(scal,R_P) + ten%x
  summ%y = real(scal,R_P) + ten%y
  summ%z = real(scal,R_P) + ten%z
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction ScalR16P_sum_ten

  elemental function ten_sum_ScalR16P(ten,scal) result(summ)
  !---------------------------------------------------------------------------------------------------------------------------------
  !!Function for sum ten and scalar (real R16P).
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  type(Type_Tensor), intent(IN):: ten
  real(R16P),        intent(IN):: scal
  type(Type_Tensor)::             summ
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  summ%x = real(scal,R_P) + ten%x
  summ%y = real(scal,R_P) + ten%y
  summ%z = real(scal,R_P) + ten%z
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction ten_sum_ScalR16P
#endif

  elemental function ScalR8P_sum_ten(scal,ten) result(summ)
  !---------------------------------------------------------------------------------------------------------------------------------
  !!Function for sum scalar (real R8P) and ten.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  real(R8P),         intent(IN):: scal
  type(Type_Tensor), intent(IN):: ten
  type(Type_Tensor)::             summ
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  summ%x = real(scal,R_P) + ten%x
  summ%y = real(scal,R_P) + ten%y
  summ%z = real(scal,R_P) + ten%z
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction ScalR8P_sum_ten

  elemental function ten_sum_ScalR8P(ten,scal) result(summ)
  !---------------------------------------------------------------------------------------------------------------------------------
  !!Function for sum ten and scalar (real R8P).
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  type(Type_Tensor), intent(IN):: ten
  real(R8P),         intent(IN):: scal
  type(Type_Tensor)::             summ
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  summ%x = real(scal,R_P) + ten%x
  summ%y = real(scal,R_P) + ten%y
  summ%z = real(scal,R_P) + ten%z
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction ten_sum_ScalR8P

  elemental function ScalR4P_sum_ten(scal,ten) result(summ)
  !---------------------------------------------------------------------------------------------------------------------------------
  !!Function for sum scalar (real R4P) and ten.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  real(R4P),         intent(IN):: scal
  type(Type_Tensor), intent(IN):: ten
  type(Type_Tensor)::             summ
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  summ%x = real(scal,R_P) + ten%x
  summ%y = real(scal,R_P) + ten%y
  summ%z = real(scal,R_P) + ten%z
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction ScalR4P_sum_ten

  elemental function ten_sum_ScalR4P(ten,scal) result(summ)
  !---------------------------------------------------------------------------------------------------------------------------------
  !!Function for sum ten and scalar (real R4P).
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  type(Type_Tensor), intent(IN):: ten
  real(R4P),         intent(IN):: scal
  type(Type_Tensor)::             summ
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  summ%x = real(scal,R_P) + ten%x
  summ%y = real(scal,R_P) + ten%y
  summ%z = real(scal,R_P) + ten%z
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction ten_sum_ScalR4P

  elemental function ScalI8P_sum_ten(scal,ten) result(summ)
  !---------------------------------------------------------------------------------------------------------------------------------
  !!Function for sum scalar (integer I8P) and ten.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  integer(I8P),      intent(IN):: scal
  type(Type_Tensor), intent(IN):: ten
  type(Type_Tensor)::             summ
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  summ%x = real(scal,R_P) + ten%x
  summ%y = real(scal,R_P) + ten%y
  summ%z = real(scal,R_P) + ten%z
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction ScalI8P_sum_ten

  elemental function ten_sum_ScalI8P(ten,scal) result(summ)
  !---------------------------------------------------------------------------------------------------------------------------------
  !!Function for sum ten and scalar (integer I8P).
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  type(Type_Tensor), intent(IN):: ten
  integer(I8P),      intent(IN):: scal
  type(Type_Tensor)::             summ
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  summ%x = real(scal,R_P) + ten%x
  summ%y = real(scal,R_P) + ten%y
  summ%z = real(scal,R_P) + ten%z
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction ten_sum_ScalI8P

  elemental function ScalI4P_sum_ten(scal,ten) result(summ)
  !---------------------------------------------------------------------------------------------------------------------------------
  !!Function for sum scalar (integer I4P) and ten.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  integer(I4P),      intent(IN):: scal
  type(Type_Tensor), intent(IN):: ten
  type(Type_Tensor)::             summ
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  summ%x = real(scal,R_P) + ten%x
  summ%y = real(scal,R_P) + ten%y
  summ%z = real(scal,R_P) + ten%z
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction ScalI4P_sum_ten

  elemental function ten_sum_ScalI4P(ten,scal) result(summ)
  !---------------------------------------------------------------------------------------------------------------------------------
  !!Function for sum ten and scalar (integer I4P).
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  type(Type_Tensor), intent(IN):: ten
  integer(I4P),      intent(IN):: scal
  type(Type_Tensor)::             summ
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  summ%x = real(scal,R_P) + ten%x
  summ%y = real(scal,R_P) + ten%y
  summ%z = real(scal,R_P) + ten%z
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction ten_sum_ScalI4P

  elemental function ScalI2P_sum_ten(scal,ten) result(summ)
  !---------------------------------------------------------------------------------------------------------------------------------
  !!Function for sum scalar (integer I2P) and ten.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  integer(I2P),      intent(IN):: scal
  type(Type_Tensor), intent(IN):: ten
  type(Type_Tensor)::             summ
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  summ%x = real(scal,R_P) + ten%x
  summ%y = real(scal,R_P) + ten%y
  summ%z = real(scal,R_P) + ten%z
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction ScalI2P_sum_ten

  elemental function ten_sum_ScalI2P(ten,scal) result(summ)
  !---------------------------------------------------------------------------------------------------------------------------------
  !!Function for sum ten and scalar (integer I2P).
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  type(Type_Tensor), intent(IN):: ten
  integer(I2P),      intent(IN):: scal
  type(Type_Tensor)::             summ
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  summ%x = real(scal,R_P) + ten%x
  summ%y = real(scal,R_P) + ten%y
  summ%z = real(scal,R_P) + ten%z
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction ten_sum_ScalI2P

  elemental function ScalI1P_sum_ten(scal,ten) result(summ)
  !---------------------------------------------------------------------------------------------------------------------------------
  !!Function for sum scalar (integer I1P) and ten.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  integer(I1P),      intent(IN):: scal
  type(Type_Tensor), intent(IN):: ten
  type(Type_Tensor)::             summ
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  summ%x = real(scal,R_P) + ten%x
  summ%y = real(scal,R_P) + ten%y
  summ%z = real(scal,R_P) + ten%z
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction ScalI1P_sum_ten

  elemental function ten_sum_ScalI1P(ten,scal) result(summ)
  !---------------------------------------------------------------------------------------------------------------------------------
  !!Function for sum ten and scalar (integer I1P).
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  type(Type_Tensor), intent(IN):: ten
  integer(I1P),      intent(IN):: scal
  type(Type_Tensor)::             summ
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  summ%x = real(scal,R_P) + ten%x
  summ%y = real(scal,R_P) + ten%y
  summ%z = real(scal,R_P) + ten%z
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction ten_sum_ScalI1P

  ! Subtraction (-)
  elemental function negative_ten(ten) result(neg)
  !---------------------------------------------------------------------------------------------------------------------------------
  !!Function for applay unary - to an ten.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  type(Type_Tensor), intent(IN):: ten
  type(Type_Tensor)::             neg
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  neg%x =  - ten%x
  neg%y =  - ten%y
  neg%z =  - ten%z
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction negative_ten

  elemental function ten_sub_ten(ten1,ten2) result(sub)
  !---------------------------------------------------------------------------------------------------------------------------------
  !!Function for subtract vec and ten.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  type(Type_Tensor), intent(IN):: ten1
  type(Type_Tensor), intent(IN):: ten2
  type(Type_Tensor)::             sub
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  sub%x = ten1%x - ten2%x
  sub%y = ten1%y - ten2%y
  sub%z = ten1%z - ten2%z
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction ten_sub_ten

#ifdef r16p
  elemental function ScalR16P_sub_ten(scal,ten) result(sub)
  !---------------------------------------------------------------------------------------------------------------------------------
  !!Function for subtract scalar (real R16P) and ten.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  real(R16P),        intent(IN):: scal
  type(Type_Tensor), intent(IN):: ten
  type(Type_Tensor)::             sub
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  sub%x = real(scal,R_P) - ten%x
  sub%y = real(scal,R_P) - ten%y
  sub%z = real(scal,R_P) - ten%z
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction ScalR16P_sub_ten

  elemental function ten_sub_ScalR16P(ten,scal) result(sub)
  !---------------------------------------------------------------------------------------------------------------------------------
  !!Function for subtract ten and scalar (real R16P).
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  type(Type_Tensor), intent(IN):: ten
  real(R16P),        intent(IN):: scal
  type(Type_Tensor)::             sub
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  sub%x = ten%x - real(scal,R_P)
  sub%y = ten%y - real(scal,R_P)
  sub%z = ten%z - real(scal,R_P)
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction ten_sub_ScalR16P
#endif

  elemental function ScalR8P_sub_ten(scal,ten) result(sub)
  !---------------------------------------------------------------------------------------------------------------------------------
  !!Function for subtract scalar (real R8P) and ten.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  real(R8P),         intent(IN):: scal
  type(Type_Tensor), intent(IN):: ten
  type(Type_Tensor)::             sub
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  sub%x = real(scal,R_P) - ten%x
  sub%y = real(scal,R_P) - ten%y
  sub%z = real(scal,R_P) - ten%z
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction ScalR8P_sub_ten

  elemental function ten_sub_ScalR8P(ten,scal) result(sub)
  !---------------------------------------------------------------------------------------------------------------------------------
  !!Function for subtract ten and scalar (real R8P).
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  type(Type_Tensor), intent(IN):: ten
  real(R8P),         intent(IN):: scal
  type(Type_Tensor)::             sub
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  sub%x = ten%x - real(scal,R_P)
  sub%y = ten%y - real(scal,R_P)
  sub%z = ten%z - real(scal,R_P)
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction ten_sub_ScalR8P

  elemental function ScalR4P_sub_ten(scal,ten) result(sub)
  !---------------------------------------------------------------------------------------------------------------------------------
  !!Function for subtract scalar (real R4P) and ten.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  real(R4P),         intent(IN):: scal
  type(Type_Tensor), intent(IN):: ten
  type(Type_Tensor)::             sub
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  sub%x = real(scal,R_P) - ten%x
  sub%y = real(scal,R_P) - ten%y
  sub%z = real(scal,R_P) - ten%z
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction ScalR4P_sub_ten

  elemental function ten_sub_ScalR4P(ten,scal) result(sub)
  !---------------------------------------------------------------------------------------------------------------------------------
  !!Function for subtract ten and scalar (real R4P).
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  type(Type_Tensor), intent(IN):: ten
  real(R4P),         intent(IN):: scal
  type(Type_Tensor)::             sub
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  sub%x = ten%x - real(scal,R_P)
  sub%y = ten%y - real(scal,R_P)
  sub%z = ten%z - real(scal,R_P)
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction ten_sub_ScalR4P

  elemental function ScalI8P_sub_ten(scal,ten) result(sub)
  !---------------------------------------------------------------------------------------------------------------------------------
  !!Function for subtract scalar (integer I8P) and ten.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  integer(I8P),      intent(IN):: scal
  type(Type_Tensor), intent(IN):: ten
  type(Type_Tensor)::             sub
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  sub%x = real(scal,R_P) - ten%x
  sub%y = real(scal,R_P) - ten%y
  sub%z = real(scal,R_P) - ten%z
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction ScalI8P_sub_ten

  elemental function ten_sub_ScalI8P(ten,scal) result(sub)
  !---------------------------------------------------------------------------------------------------------------------------------
  !!Function for subtract ten and scalar (integer I8P).
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  type(Type_Tensor), intent(IN):: ten
  integer(I8P),      intent(IN):: scal
  type(Type_Tensor)::             sub
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  sub%x = ten%x - real(scal,R_P)
  sub%y = ten%y - real(scal,R_P)
  sub%z = ten%z - real(scal,R_P)
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction ten_sub_ScalI8P

  elemental function ScalI4P_sub_ten(scal,ten) result(sub)
  !---------------------------------------------------------------------------------------------------------------------------------
  !!Function for subtract scalar (integer I4P) and ten.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  integer(I4P),      intent(IN):: scal
  type(Type_Tensor), intent(IN):: ten
  type(Type_Tensor)::             sub
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  sub%x = real(scal,R_P) - ten%x
  sub%y = real(scal,R_P) - ten%y
  sub%z = real(scal,R_P) - ten%z
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction ScalI4P_sub_ten

  elemental function ten_sub_ScalI4P(ten,scal) result(sub)
  !---------------------------------------------------------------------------------------------------------------------------------
  !!Function for subtract ten and scalar (integer I4P).
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  type(Type_Tensor), intent(IN):: ten
  integer(I4P),      intent(IN):: scal
  type(Type_Tensor)::             sub
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  sub%x = ten%x - real(scal,R_P)
  sub%y = ten%y - real(scal,R_P)
  sub%z = ten%z - real(scal,R_P)
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction ten_sub_ScalI4P

  elemental function ScalI2P_sub_ten(scal,ten) result(sub)
  !---------------------------------------------------------------------------------------------------------------------------------
  !!Function for subtract scalar (integer I2P) and ten.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  integer(I2P),      intent(IN):: scal
  type(Type_Tensor), intent(IN):: ten
  type(Type_Tensor)::             sub
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  sub%x = real(scal,R_P) - ten%x
  sub%y = real(scal,R_P) - ten%y
  sub%z = real(scal,R_P) - ten%z
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction ScalI2P_sub_ten

  elemental function ten_sub_ScalI2P(ten,scal) result(sub)
  !---------------------------------------------------------------------------------------------------------------------------------
  !!Function for subtract ten and scalar (integer I2P).
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  type(Type_Tensor), intent(IN):: ten
  integer(I2P),      intent(IN):: scal
  type(Type_Tensor)::             sub
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  sub%x = ten%x - real(scal,R_P)
  sub%y = ten%y - real(scal,R_P)
  sub%z = ten%z - real(scal,R_P)
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction ten_sub_ScalI2P

  elemental function ScalI1P_sub_ten(scal,ten) result(sub)
  !---------------------------------------------------------------------------------------------------------------------------------
  !!Function for subtract scalar (integer I1P) and ten.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  integer(I1P),      intent(IN):: scal
  type(Type_Tensor), intent(IN):: ten
  type(Type_Tensor)::             sub
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  sub%x = real(scal,R_P) - ten%x
  sub%y = real(scal,R_P) - ten%y
  sub%z = real(scal,R_P) - ten%z
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction ScalI1P_sub_ten

  elemental function ten_sub_ScalI1P(ten,scal) result(sub)
  !---------------------------------------------------------------------------------------------------------------------------------
  !!Function for subtract ten and scalar (integer I1P).
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  type(Type_Tensor), intent(IN):: ten
  integer(I1P),      intent(IN):: scal
  type(Type_Tensor)::             sub
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  sub%x = ten%x - real(scal,R_P)
  sub%y = ten%y - real(scal,R_P)
  sub%z = ten%z - real(scal,R_P)
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction ten_sub_ScalI1P

  ! dot product (.dot.)
  elemental function ten_dot_vec(ten,vec) result(dot)
  !---------------------------------------------------------------------------------------------------------------------------------
  !!This function computes the vector (dot) product of a tensor and a vector.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  type(Type_Tensor), intent(IN):: ten ! Tensor.
  type(Type_Vector), intent(IN):: vec ! Vector.
  type(Type_Vector)::             dot ! Dot product (vector).
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  call set_vec(x=(ten%x.dot.vec),y=(ten%y.dot.vec),z=(ten%z.dot.vec),vec=dot)
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction ten_dot_vec

  elemental function vec_dot_ten(vec,ten) result(dot)
  !---------------------------------------------------------------------------------------------------------------------------------
  !!This function computes the vector (dot) product of a vector and a tensor.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  type(Type_Vector), intent(IN):: vec ! Vector.
  type(Type_Tensor), intent(IN):: ten ! Tensor.
  type(Type_Vector)::             dot ! Dot product (vector).
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  call set_vec(x=((ten.dot.ex).dot.vec),y=((ten.dot.ey).dot.vec),z=((ten.dot.ez).dot.vec),vec=dot)
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction vec_dot_ten

  ! double dot product (.ddot.)
  elemental function ddotproduct(ten1,ten2) result(ddot)
  !---------------------------------------------------------------------------------------------------------------------------------
  !!This function computes the scalar (double dot) product of 2 tensors.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  type(Type_Tensor), intent(IN):: ten1 ! First tensor.
  type(Type_Tensor), intent(IN):: ten2 ! Second tensor.
  real(R_P)::                     ddot ! Double dot product.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  ddot = (ten1%x.dot.(ten2.dot.ex)) + (ten1%y.dot.(ten2.dot.ey)) + (ten1%z.dot.(ten2.dot.ez))
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction ddotproduct

  ! diadic product (.diad.)
  elemental function diadicproduct(vec1,vec2) result(ten)
  !---------------------------------------------------------------------------------------------------------------------------------
  !!This function computes the diadic product of 2 vectors producing a second order tensor.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  type(Type_Vector), intent(IN):: vec1 ! First vector.
  type(Type_Vector), intent(IN):: vec2 ! Second vector.
  type(Type_Tensor)::             ten  ! Tensor.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  ten%x = vec1%x*vec2
  ten%y = vec1%y*vec2
  ten%z = vec1%z*vec2
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction diadicproduct

  ! sq_norm
  elemental function sq_norm_ten(ten) result(sq)
  !---------------------------------------------------------------------------------------------------------------------------------
  !!This function computes the square of the norm of a tensor.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  type(Type_Tensor), intent(IN):: ten ! Tensor.
  real(R_P)::                     sq  ! Square of the Norm.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  sq = sq_norm(ten%x) + sq_norm(ten%y) + sq_norm(ten%z)
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction sq_norm_ten

  ! normL2
  elemental function normL2_ten(ten) result(norm)
  !---------------------------------------------------------------------------------------------------------------------------------
  !!This function computes the norm L2 of a tensor.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  type(Type_Tensor), intent(IN):: ten  ! Tensor.
  real(R_P)::                     norm ! Norm L2.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  norm = sqrt(sq_norm(ten%x) + sq_norm(ten%y) + sq_norm(ten%z))
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction normL2_ten

  ! normalize
  elemental function normalize_ten(ten) result(norm)
  !---------------------------------------------------------------------------------------------------------------------------------
  !!This function normalize a tensor.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  type(Type_Tensor), intent(IN):: ten  ! Tensor to be normalized.
  type(Type_Tensor)::             norm ! Tensor normalized.
  real(R_P)::                     nm   ! Norm L2 of tensor.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  nm = normL2_ten(ten)
  if (nm < smallR_P) then
    nm = nm + smallR_P
  endif
  norm%x = ten%x/nm
  norm%y = ten%y/nm
  norm%z = ten%z/nm
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction normalize_ten

  ! transpose
  elemental function transpose_ten(ten) result(tran)
  !---------------------------------------------------------------------------------------------------------------------------------
  !!This function transpose a tensor.
  !       |x%x x%y x%z|           |x%x y%x z%x|
  ! ten = |y%x y%y y%z| => tran = |x%y y%y z%y|
  !       |z%x z%y z%z|           |x%z y%z z%z|
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  type(Type_Tensor), intent(IN):: ten  ! Tensor to be transposed.
  type(Type_Tensor)::             tran ! Tensor transposed.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  tran%x = ten.dot.ex
  tran%y = ten.dot.ey
  tran%z = ten.dot.ez
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction transpose_ten

  !> This function computes the determinant of a tensor.
  !> @return \b det real(R_P) variable
  !> @note The determinant is computed according the following equation: \n
  !> \f$ \det  = \left| {\begin{array}{*{20}{c}} {x\% x}&{x\% y}&{x\% z}\\ {y\% x}&{y\% y}&{y\% z}\\ {z\% x}&{z\% y}&{z\% z}
  !> \end{array}} \right| = \f$ \n
  !> \f$=x\%x(z\%z\cdot y\%y-z\%y\cdot y\%z)-\f$
  !> \f$ y\%x(z\%z\cdot x\%y-z\%y\cdot x\%z)+\f$
  !> \f$ z\%x(y\%z\cdot x\%y-y\%y\cdot x\%z) \f$
  elemental function determinant(ten) result(det)
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  type(Type_Tensor), intent(IN):: ten !< Tensor.
  real(R_P)::                     det !< Determinant.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  det=ten%x%x*(ten%z%z*ten%y%y-ten%z%y*ten%y%z)-ten%y%x*(ten%z%z*ten%x%y-ten%z%y*ten%x%z)+ten%z%x*(ten%y%z*ten%x%y-ten%y%y*ten%x%z)
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction determinant

  !> This function computes the inverse of a tensor.
  !> If the tensor is not invertible a null tensor is returned.
  !> @return \b inv type(Type_Tensor) variable
  !> @note The inverse tensor is computed according the following equation: \n
  !> \f$ T_{ij}^{ - 1} = \frac{1}{{\det (T)}}\left[ {\begin{array}{*{20}{c}}
  !> {z\%z\cdot y\%y-z\%y\cdot y\%z}&{-(z\%z\cdot x\%y-z\%y\cdot x\%z)}&{y\%z\cdot x\%y-y\%y\cdot x\%z}\\{-(z\%z\cdot y\%x-
  !> z\%x\cdot y\%z)}&{z\%z\cdot x\%x-z\%x\cdot x\%z}&{-(y\%z\cdot x\%x-y\%x\cdot x\%z)}\\{z\%y\cdot y\%x-z\%x\cdot y\%y}&{-(z\%y
  !> \cdot x\%x-z\%x\cdot x\%y)}&{y\%y\cdot x\%x-y\%x\cdot x\%y} \end{array}} \right]\f$ \n
  !> where det(T) is the determinant computed by means of the function determinant.
  elemental function invert(ten) result(inv)
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  type(Type_Tensor), intent(IN):: ten    !< Tensor to be inverted.
  type(Type_Tensor)::             inv    !< Tensor inverted.
  real(R_P)::                     det,di !< Determinant and 1/Determinant.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  det = determinant(ten)
  if (det/=0._R_P) then
    di = 1._R_P/det
   inv%x=di*( (ten%z%z*ten%y%y-ten%z%y*ten%y%z)*ex - (ten%z%z*ten%x%y-ten%z%y*ten%x%z)*ey + (ten%y%z*ten%x%y-ten%y%y*ten%x%z)*ez)
   inv%y=di*(-(ten%z%z*ten%y%x-ten%z%x*ten%y%z)*ex + (ten%z%z*ten%x%x-ten%z%x*ten%x%z)*ey - (ten%y%z*ten%x%x-ten%y%x*ten%x%z)*ez)
   inv%z=di*( (ten%z%y*ten%y%x-ten%z%x*ten%y%y)*ex - (ten%z%y*ten%x%x-ten%z%x*ten%x%y)*ey + (ten%y%y*ten%x%x-ten%y%x*ten%x%y)*ez)
  else
    inv%x=0._R_P
    inv%y=0._R_P
    inv%z=0._R_P
  endif
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction invert

  !>This function check if a tensor is invertible (determinant /=0, not singular tensor).
  !> @return \b inv logical variable
  elemental function invertible(ten) result(inv)
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  type(Type_Tensor), intent(IN):: ten !< Tensor to be inverted.
  logical::                       inv !< True if the tensor is not singular.
  real(R_P)::                     det !< Determinant.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  det = determinant(ten) ; inv = (det/=0._R_P)
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction invertible
endmodule Data_Type_Tensor
