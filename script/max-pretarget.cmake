# Copyright 2018 The Max-API Authors. All rights reserved.
# Use of this source code is governed by the MIT License found in the License.md file.

option(MAX_SDK_CODESIGN_EXTERNS "Sign macos externs during build" ON) # use MAX_SDK_CODESIGN_IDENTITY to override the default adhoc identity "-"

cmake_path(GET CMAKE_CURRENT_SOURCE_DIR FILENAME THIS_FOLDER_NAME)

string(REPLACE "~" "_tilde" THIS_FOLDER_NAME "${THIS_FOLDER_NAME}")

if (WIN32)
	# These must be prior to the "project" command
	# https://stackoverflow.com/questions/14172856/compile-with-mt-instead-of-md-using-cmake

	if (CMAKE_GENERATOR MATCHES "Visual Studio")
		set(CMAKE_C_FLAGS_DEBUG            "/D_DEBUG /MTd /Zi /Ob0 /Od /RTC1")
		set(CMAKE_C_FLAGS_MINSIZEREL       "/MT /O1 /Ob1 /D NDEBUG")
		set(CMAKE_C_FLAGS_RELEASE          "/MT /O2 /Ob2 /D NDEBUG")
		set(CMAKE_C_FLAGS_RELWITHDEBINFO   "/MT /Zi /O2 /Ob1 /D NDEBUG")

		set(CMAKE_CXX_FLAGS_DEBUG          "/D_DEBUG /MTd /Zi /Ob0 /Od /RTC1")
		set(CMAKE_CXX_FLAGS_MINSIZEREL     "/MT /O1 /Ob1 /D NDEBUG")
		set(CMAKE_CXX_FLAGS_RELEASE        "/MT /O2 /Ob2 /D NDEBUG")
		set(CMAKE_CXX_FLAGS_RELWITHDEBINFO "/MT /Zi /O2 /Ob1 /D NDEBUG")

		add_compile_options(
			$<$<CONFIG:>:/MT>
			$<$<CONFIG:Debug>:/MTd>
			$<$<CONFIG:Release>:/MT>
			$<$<CONFIG:MinSizeRel>:/MT>
			$<$<CONFIG:RelWithDebInfo>:/MT>
		)
	else()
		set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -static")
	endif ()
endif ()

project(${THIS_FOLDER_NAME})

if ("${PROJECT_NAME}" MATCHES ".*_tilde")
	string(REGEX REPLACE "_tilde" "~" EXTERN_OUTPUT_NAME_DEFAULT "${PROJECT_NAME}")
else ()
	set(EXTERN_OUTPUT_NAME_DEFAULT "${PROJECT_NAME}")
endif ()
set("${PROJECT_NAME}_EXTERN_OUTPUT_NAME" "${EXTERN_OUTPUT_NAME_DEFAULT}" CACHE STRING "The name to give to the external output file/directory")
mark_as_advanced("${PROJECT_NAME}_EXTERN_OUTPUT_NAME")

if (NOT DEFINED C74_SUPPORT_DIR)
	set(C74_SUPPORT_DIR ${CMAKE_CURRENT_LIST_DIR}/../c74support)
endif ()

set(MAX_SDK_INCLUDES "${C74_SUPPORT_DIR}/max-includes")
set(MAX_SDK_MSP_INCLUDES "${C74_SUPPORT_DIR}/msp-includes")
set(MAX_SDK_JIT_INCLUDES "${C74_SUPPORT_DIR}/jit-includes")

set(C74_INCLUDES "${C74_SUPPORT_DIR}" "${MAX_SDK_INCLUDES}" "${MAX_SDK_MSP_INCLUDES}" "${MAX_SDK_JIT_INCLUDES}")
set(C74_SCRIPTS "${CMAKE_CURRENT_LIST_DIR}")

set(C74_CXX_STANDARD 0)

if (APPLE)
	if (CMAKE_OSX_ARCHITECTURES STREQUAL "")
		set(CMAKE_OSX_ARCHITECTURES x86_64)
	endif()
	set(CMAKE_OSX_DEPLOYMENT_TARGET "10.11" CACHE STRING "Minimum OS X deployment version" FORCE)
endif ()

if (DEFINED C74_LIBRARY_OUTPUT_DIRECTORY)
	set(CMAKE_LIBRARY_OUTPUT_DIRECTORY "${C74_LIBRARY_OUTPUT_DIRECTORY}")
else ()
	if (NOT DEFINED C74_BUILD_MAX_EXTENSION)
		set(CMAKE_LIBRARY_OUTPUT_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/../../../externals")
	else ()
		set(CMAKE_LIBRARY_OUTPUT_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/../../../extensions")
	endif ()
endif()
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY_DEBUG "${CMAKE_LIBRARY_OUTPUT_DIRECTORY}")
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY_RELEASE "${CMAKE_LIBRARY_OUTPUT_DIRECTORY}")

if (WIN32)
	set(CMAKE_PDB_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/pdb/$<CONFIG>")

	SET(MaxAPI_LIB ${MAX_SDK_INCLUDES}/x64/MaxAPI.lib)
	SET(MaxAudio_LIB ${MAX_SDK_MSP_INCLUDES}/x64/MaxAudio.lib)
	SET(Jitter_LIB ${MAX_SDK_JIT_INCLUDES}/x64/jitlib.lib)

	MARK_AS_ADVANCED (MaxAPI_LIB)
	MARK_AS_ADVANCED (MaxAudio_LIB)
	MARK_AS_ADVANCED (Jitter_LIB)

	add_definitions(
		-DMAXAPI_USE_MSCRT
		-DWIN_VERSION
		-D_USE_MATH_DEFINES
	)
elseif (APPLE)
	file(STRINGS "${MAX_SDK_INCLUDES}/c74_linker_flags.txt" C74_SYM_MAX_LINKER_FLAGS)

	set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} ${C74_SYM_MAX_LINKER_FLAGS}")
	set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} ${C74_SYM_MAX_LINKER_FLAGS}")
	set(CMAKE_MODULE_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} ${C74_SYM_MAX_LINKER_FLAGS}")
endif ()
