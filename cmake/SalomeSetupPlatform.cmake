# Copyright (C) 2007-2020  CEA/DEN, EDF R&D, OPEN CASCADE
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307 USA
#
# See http://www.salome-platform.org/ or email : webmaster.salome@opencascade.com
#

INCLUDE(CheckCXXCompilerFlag)

## Detect architecture
IF(WIN32)
  SET(MACHINE WINDOWS)
ELSE()
  SET(MACHINE PCLINUX)
ENDIF()

## Test for 64 bits
IF(CMAKE_SIZEOF_VOID_P EQUAL 8)
  SET(MACHINE_IS_64 TRUE)
ELSE()
  SET(MACHINE_IS_64 FALSE)
ENDIF()

## Force CMAKE_BUILD_TYPE to Release if not set
IF(NOT CMAKE_BUILD_TYPE)
  SET(CMAKE_BUILD_TYPE $ENV{CMAKE_BUILD_TYPE})
ENDIF(NOT CMAKE_BUILD_TYPE)
IF(NOT CMAKE_BUILD_TYPE)
  SET(CMAKE_BUILD_TYPE Release)
ENDIF(NOT CMAKE_BUILD_TYPE)

## Define the log level according to the build type
IF(CMAKE_BUILD_TYPE STREQUAL "DEBUG" OR CMAKE_BUILD_TYPE STREQUAL "Debug")
  SET(PYLOGLEVEL DEBUG)
ELSE()
  SET(PYLOGLEVEL WARNING)
ENDIF()

IF(WIN32)
  ## Windows specific:  
  ADD_DEFINITIONS(-D_CRT_SECURE_NO_WARNINGS)  # To disable windows warnings for strcpy, fopen, ...
  ADD_DEFINITIONS(-D_SCL_SECURE_NO_WARNINGS)  # To disable windows warnings generated by checked iterators(e.g. std::copy, std::transform, ...)
  ADD_DEFINITIONS(-DWNT -DWIN32)
  ADD_DEFINITIONS(-D_WIN32_WINNT=0x0500)      # Windows 2000 or later API is required
  ADD_DEFINITIONS(-DPPRO_NT)                  # For medfile

  SET(PLATFORM_LIBS Ws2_32.lib)
  LIST(APPEND PLATFORM_LIBS Userenv.lib)      # At least for GEOM suit

  IF(MACHINE_IS_64)
    SET(SIZE_OF_LONG 4)                       # Set sizeof(long) to 4 bytes
  ELSE()
    SET(SIZE_OF_LONG ${CMAKE_SIZEOF_VOID_P})  # Set sizeof(long) the same as size of pointers
  ENDIF()
  ADD_DEFINITIONS(-DUNICODE)                  # Unicode 
  ADD_DEFINITIONS(-D_UNICODE)
ELSE()
  ## Linux specific:
  SET(PLATFORM_LIBS dl)                       # Dynamic loading (dlopen, dlsym)
  IF(MACHINE_IS_64) 
    ADD_DEFINITIONS(-DPCLINUX64)
  ENDIF(MACHINE_IS_64)
ENDIF()

## define _DEBUG_ macro
IF(NOT CMAKE_BUILD_TYPE STREQUAL "RELEASE" AND NOT CMAKE_BUILD_TYPE STREQUAL "Release")
  ADD_DEFINITIONS(-D_DEBUG_)
ENDIF()

## Apple specific:
IF(APPLE)
  # Default is clang(llvm) with mountain lion at least
  OPTION(SALOME_APPLE_USE_GCC "Use GCC compiler" OFF)
  MARK_AS_ADVANCED(SALOME_APPLE_USE_GCC)
  IF(SALOME_APPLE_USE_GCC)
    SET(CMAKE_C_COMPILER gcc)
    SET(CMAKE_CXX_COMPILER g++)
  ENDIF()
ENDIF()

# Compiler flags for coverage testing
IF(NOT WIN32) 
  OPTION(SALOME_BUILD_FOR_GCOV "Add the compilation flags for GCov/LCov" OFF)
  MARK_AS_ADVANCED(SALOME_BUILD_FOR_GCOV)
  IF(SALOME_BUILD_FOR_GCOV)
    SET(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fprofile-arcs -ftest-coverage")
    SET(CMAKE_C_FLAGS    "${CMAKE_C_FLAGS} -fprofile-arcs -ftest-coverage")
  ENDIF()
ENDIF()

# Compiler flag to disable treating alternative C++ tokens (compatibility with MSVS)
CHECK_CXX_COMPILER_FLAG("-fno-operator-names" COMPILER_SUPPORTS_NO_OPERATOR_NAMES)
IF(COMPILER_SUPPORTS_NO_OPERATOR_NAMES)
  SET(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fno-operator-names")
ENDIF()

SET(NO_CXX11_SUPPORT OFF CACHE BOOL "Disable C++11 support")
IF(NOT NO_CXX11_SUPPORT)
  # C++11 support
  CHECK_CXX_COMPILER_FLAG("-std=c++11" COMPILER_SUPPORTS_CXX11)
  IF(COMPILER_SUPPORTS_CXX11)
    MESSAGE(STATUS "Enable C++11 support")
    SET(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++11")
  ELSE()
    CHECK_CXX_COMPILER_FLAG("-std=c++0x" COMPILER_SUPPORTS_CXX0X)
    IF(COMPILER_SUPPORTS_CXX0X)
      MESSAGE(STATUS "Enable C++0x support")
      SET(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++0x")
    ELSE()
      MESSAGE(WARNING "Compiler ${CMAKE_CXX_COMPILER} has no C++11 support.")
    ENDIF()
  ENDIF()
ENDIF()

# Fight warnings
IF(NOT (WIN32 OR APPLE))
  OPTION(SALOME_DEBUG_WARNINGS "Report more warnings" OFF)
  OPTION(SALOME_TREAT_WARNINGS_AS_ERRORS "Treat warnings as errors" OFF)
  # Report more warnings
  MARK_AS_ADVANCED(SALOME_DEBUG_WARNINGS SALOME_TREAT_WARNINGS_AS_ERRORS)
  IF(SALOME_DEBUG_WARNINGS)
    SET(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Wall -Wextra -Wpedantic")
    SET(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wall -Wextra -Wpedantic")
  ENDIF()
  ## Treat all warnings as errors
  IF(SALOME_TREAT_WARNINGS_AS_ERRORS)
    SET(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Werror")
    SET(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Werror")
  ENDIF()
ENDIF()
