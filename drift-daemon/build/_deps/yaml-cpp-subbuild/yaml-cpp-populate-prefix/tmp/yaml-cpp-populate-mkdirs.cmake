# Distributed under the OSI-approved BSD 3-Clause License.  See accompanying
# file LICENSE.rst or https://cmake.org/licensing for details.

cmake_minimum_required(VERSION ${CMAKE_VERSION}) # this file comes with cmake

# If CMAKE_DISABLE_SOURCE_CHANGES is set to true and the source directory is an
# existing directory in our source tree, calling file(MAKE_DIRECTORY) on it
# would cause a fatal error, even though it would be a no-op.
if(NOT EXISTS "/home/suzie/Projects/HyprDriftDE/drift-daemon/build/_deps/yaml-cpp-src")
  file(MAKE_DIRECTORY "/home/suzie/Projects/HyprDriftDE/drift-daemon/build/_deps/yaml-cpp-src")
endif()
file(MAKE_DIRECTORY
  "/home/suzie/Projects/HyprDriftDE/drift-daemon/build/_deps/yaml-cpp-build"
  "/home/suzie/Projects/HyprDriftDE/drift-daemon/build/_deps/yaml-cpp-subbuild/yaml-cpp-populate-prefix"
  "/home/suzie/Projects/HyprDriftDE/drift-daemon/build/_deps/yaml-cpp-subbuild/yaml-cpp-populate-prefix/tmp"
  "/home/suzie/Projects/HyprDriftDE/drift-daemon/build/_deps/yaml-cpp-subbuild/yaml-cpp-populate-prefix/src/yaml-cpp-populate-stamp"
  "/home/suzie/Projects/HyprDriftDE/drift-daemon/build/_deps/yaml-cpp-subbuild/yaml-cpp-populate-prefix/src"
  "/home/suzie/Projects/HyprDriftDE/drift-daemon/build/_deps/yaml-cpp-subbuild/yaml-cpp-populate-prefix/src/yaml-cpp-populate-stamp"
)

set(configSubDirs )
foreach(subDir IN LISTS configSubDirs)
    file(MAKE_DIRECTORY "/home/suzie/Projects/HyprDriftDE/drift-daemon/build/_deps/yaml-cpp-subbuild/yaml-cpp-populate-prefix/src/yaml-cpp-populate-stamp/${subDir}")
endforeach()
if(cfgdir)
  file(MAKE_DIRECTORY "/home/suzie/Projects/HyprDriftDE/drift-daemon/build/_deps/yaml-cpp-subbuild/yaml-cpp-populate-prefix/src/yaml-cpp-populate-stamp${cfgdir}") # cfgdir has leading slash
endif()
