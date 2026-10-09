find_program(XXD xxd)
find_program(LLVM_DIS NAMES llvm-dis-${LLVM_VERSION_MAJOR} llvm-dis
    HINTS "${LLVM_TOOLS_BINARY_DIR}")
if (NOT XXD OR NOT LLVM_DIS)
    message(FATAL_ERROR "Decoder generation requires xxd and llvm-dis")
endif()

# If defined, use the target compiler.
# For cross-compilation the LLVM-IR generated is still arch specific.
if (TARGET_C_COMPILER)
    set(CLANG "${TARGET_C_COMPILER}")
else()
    set(CLANG "${LLVM_TOOLS_BINARY_DIR}/clang")
endif()

set(DECODER_TARGET "" CACHE STRING "Target triple for the embedded decoder")
set(DECODER_SYSROOT "" CACHE PATH "Sysroot for the embedded decoder")
# Track configuration changes even when using a Makefile generator.
file(GENERATE OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/decode-config.txt"
    CONTENT "${CLANG}\n${DECODER_TARGET}\n${DECODER_SYSROOT}\n${LLVM_DIS}\n${XXD}\n")

# Compile the string decode function into IR bitcode and embed it as a c array
ADD_CUSTOM_COMMAND(
    OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/decode.h
    BYPRODUCTS ${CMAKE_CURRENT_BINARY_DIR}/decode.c.bc
    COMMAND ${CMAKE_CURRENT_SOURCE_DIR}/generate_ir_header.sh
                ${CLANG} ${XXD}
                ${CMAKE_CURRENT_SOURCE_DIR}/decode.c
                ${CMAKE_CURRENT_BINARY_DIR} decode.h
                "${LLVM_DIS}" "${DECODER_TARGET}" "${DECODER_SYSROOT}"
    DEPENDS decode.c generate_ir_header.sh
            "${CMAKE_CURRENT_BINARY_DIR}/decode-config.txt"
    VERBATIM
)

add_custom_target(generateDecodeIRHeader ALL
    DEPENDS ${CMAKE_CURRENT_BINARY_DIR}/decode.h
)

add_dependencies(LLVMObfuscator generateDecodeIRHeader)
target_sources(LLVMObfuscator PRIVATE StringObfuscation.cpp)
