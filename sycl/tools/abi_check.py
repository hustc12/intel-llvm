#!/usr/bin/env python
#
# Compare symbols that are exported from the binary against a known snapshot.
# Return an error if there are new or missing symbols in the library.
#
import argparse
import os
import subprocess
import sys
import re


def get_llvm_bin_path():
  if 'LLVM_BIN_PATH' in os.environ:
    return os.environ['LLVM_BIN_PATH']
  return ""


def match_symbol(sym_binding, sym_type, sym_section):
  if sym_binding is None or sym_type is None or sym_section is None:
    return False
  if not sym_type.group() == "Function":
    return False
  if not (sym_binding.group() == "Global" or sym_binding.group() == "Weak"):
    return False
  if not sym_section.group() == ".text":
    return False
  return True


def parse_readobj_output(output):
  symbol_key = r"Export" if os.name == 'nt' else r"Symbol"
  symbols = re.findall(symbol_key + r" \{[^\}]*\}",
                        output.decode().strip())
  parsed_symbols = []
  for sym in symbols:
    # Name section on Linux has the following structure:
    # SYMBOL_NAME (ID)\n
    # regex takes SYMBOL_NAME before the space.
    # Name section on Windows has the following structure
    # SYMBOL_NAME\n
    # and has special characters in comparison with symbols
    # on Linux
    name = re.search(r"(?<=Name:\s)[^ \n]+", sym)
    if os.name == 'nt':
      # no additional info about the symbols on Windows in comparison with symbols on Linux below
      parsed_symbols.append(name.group())
    else:
      sym_binding = re.search(r"(?<=Binding:\s)[\w]+", sym)
      sym_type = re.search(r"(?<=Type:\s)[\w]+", sym)
      sym_section = re.search(r"(?<=Section:\s)[\.\w]+", sym)
      if match_symbol(sym_binding, sym_type, sym_section):
        parsed_symbols.append(name.group())

  # Presence of _dl_relocate_static_pie depends on whether ld.gold or ld.lld
  # is used. Ignore it for the purpose of the library ABI check.
  ignore_symbols = ["_dl_relocate_static_pie"]

  # Starting from glibc 2.34 these symbols are not present anymore in the binary
  # Ignoring these in case older glibc is used.
  # Note that Ubuntu 20 has glibc 2.31 and Ubuntu 22 has glibc 2.35
  # See: https://github.com/bminor/glibc/commit/035c012e32c11e84d64905efaf55e74f704d3668
  ignore_symbols += ["__libc_csu_fini",
                     "__libc_csu_init"]

  # In some scenarios MSVC and clang-cl exhibit differences in regards to the exported symbols they generate.
  # Some of them happen in the SYCL RT library and we think clang-cl's behavior is more reasonable.
  #
  # Case 1:
  # pi.hpp:
  #   template <backend BE> __SYCL_EXPORT const PluginPtr &getPlugin();
  #
  # pi.cpp:
  #   template <backend BE> const PluginPtr &getPlugin() {
  #     static const plugin *Plugin = nullptr;
  #     ...
  #   }
  #   // explicit dllexport instantiations.
  #
  # clang-cl generates exported symbols for the static variables Plugin. These are never referenced
  # in the user's headers so cannot be used outside DLL and not exporting them should not affect any
  # usage scenario.
  #
  # In general, the compiler doesn't know if the definition is in the DLL or in the header and inline
  # dllexport/dllimport functions have to be supported, hence clang-cl's behavior.
  #
  # See also https://devblogs.microsoft.com/oldnewthing/20140109-00/?p=2123.
  ignore_symbols += ["?Plugin@?1???$getPlugin@$01@pi@detail@_V1@sycl@@YAAEBVplugin@234@XZ@4PEBV5234@EB",
                     "?Plugin@?1???$getPlugin@$00@pi@detail@_V1@sycl@@YAAEBVplugin@234@XZ@4PEBV5234@EB",
                     "?Plugin@?1???$getPlugin@$04@pi@detail@_V1@sycl@@YAAEBVplugin@234@XZ@4PEBV5234@EB",
                     "?Plugin@?1???$getPlugin@$02@pi@detail@_V1@sycl@@YAAEBVplugin@234@XZ@4PEBV5234@EB"]
  # Case 2:
  # half_type.hpp:
  #   class __SYCL_EXPORT half {
  #     ...
  #     constexpr half(const half &) = default;
  #     constexpr half(half &&) = default;
  #     ...
  #   };
  #
  # For some reason MSVC creates exported symbols for the constexpr versions of those defaulted ctors
  # although it never calls them at use point. Instead, those trivially copyable/moveable objects are
  # memcpy/memmove'ed. We don't expect these symbols are ever referenced directly so having or not
  # having them won't cause ABI issues.
  ignore_symbols += ["??0half@host_half_impl@detail@_V1@sycl@@QEAA@AEBV01234@@Z",
                     "??0half@host_half_impl@detail@_V1@sycl@@QEAA@$$QEAV01234@@Z"]
  parsed_symbols = [s for s in parsed_symbols if s not in ignore_symbols]
  return parsed_symbols


def dump_symbols(target_path, output):
  with open(output, "w") as out:
    out.write("################################################################################")
    out.write("\n# This file is automatically generated by abi_check.py tool.")
    out.write("\n# DO NOT EDIT IT MANUALLY. Refer to sycl/doc/developer/ABIPolicyGuide.md for more info.")
    out.write("\n################################################################################")
    out.write("\n\n# RUN: env LLVM_BIN_PATH=%llvm_build_bin_dir %python")
    out.write(" %sycl_tools_src_dir/abi_check.py --mode check_symbols")
    if os.name == 'nt':
      out.write(" --reference %s %llvm_build_bin_dir/")
    else:
      out.write(" --reference %s %sycl_libs_dir/")
    out.write(os.path.basename(target_path))
    if os.name == 'nt':
      out.write("\n# REQUIRES: windows")
    else:
      out.write("\n# REQUIRES: linux")
    out.write("\n# UNSUPPORTED: libcxx")
    out.write("\n\n")
    readobj_opts = "--coff-exports" if os.name == 'nt' else "--syms"
    readobj_out = subprocess.check_output([get_llvm_bin_path()+"llvm-readobj",
                                           readobj_opts, target_path])
    symbols = parse_readobj_output(readobj_out)
    symbols.sort()
    out.write("\n".join(symbols))
    out.write("\n")


def compare_results(ref_records, records):
  missing_records = set(ref_records).difference(set(records))
  new_records = set(records).difference(set(ref_records))

  return (missing_records, new_records)


# Dumps symbols from from binary at target_path and compares with a snapshot
# stored at ref_path. Reports new and absent symbols (if there are any).
def check_symbols(ref_path, target_path):
  with open(ref_path, "r") as ref:
    ref_symbols = []
    for line in ref:
      if not line.startswith('#') and line.strip():
        ref_symbols.append(line.strip())

    readobj_opts = "--coff-exports" if os.name == 'nt' else "--syms"
    readobj_out = subprocess.check_output([get_llvm_bin_path()+"llvm-readobj",
                                           readobj_opts, target_path])
    symbols = parse_readobj_output(readobj_out)

    missing_symbols, new_symbols = compare_results(ref_symbols, symbols)

    correct_return = True
    if missing_symbols:
      correct_return = False
      print(("There are missing symbols in the new library. It is a breaking "
      "change. Refer to sycl/doc/developer/ABIPolicyGuide.md for further instructions. "
      "Do not forget to update ABI version according to the policy."))
      print('The following symbols are missing from the new object file:\n')
      print("\n".join(missing_symbols))

    if new_symbols:
      correct_return = False
      print(("There are new symbols in the new library. It is a non-breaking "
      "change. Refer to sycl/doc/developer/ABIPolicyGuide.md for further instructions."))
      print('The following symbols are new to the object file:\n')
      print("\n".join(new_symbols))

    if not correct_return:
      sys.exit(-1)


def main():
  parser = argparse.ArgumentParser(description='ABI checker utility.')
  parser.add_argument('--mode', type=str,
                      choices=['check_symbols', 'dump_symbols'],
                      help='ABI checking mode', required=True)
  parser.add_argument('--reference', type=str, help='Reference ABI dump')
  parser.add_argument('--output', type=str, help='Output for dump modes')
  parser.add_argument('target_library', type=str)

  args = parser.parse_args()

  if args.mode == 'check_symbols':
    if args.reference is None:
      print("Please specify --reference option. Quiting.")
      sys.exit(-2)
    check_symbols(args.reference, args.target_library)
  elif args.mode == 'dump_symbols':
    if args.output is None:
      print("Please specify --output option. Quiting.")
      sys.exit(-2)
    dump_symbols(args.target_library, args.output)


if __name__ == "__main__":
  main()

