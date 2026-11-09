#!/usr/bin/env python3

import os, sys, vrun_mod as vmod
from pathlib import Path
from multiprocessing import Pool

# Tuples
test_tuple = (  "iic_mem_test_all_seq"  , "iic_mem_test_all_random_seq" ,
                "iic_mem_test_overwrite", "iic_mem_test_random"         ,
                "iic_mem_test_slave"    , "iic_mem_test_wr"                )

coverage_tuple = (  "no coverage"   , "all coverage"    , "user"    , "toggle", 
                    "branch"        , "line"            , "expr"    , "fsm"     )

verbosity_tuple = ( "UVM_NONE", "UVM_LOW"   , "UVM_MEDIUM" ,
                    "UVM_HIGH", "UVM_FULL"  , "UVM_DEBUG"  )

# Default Values
test            = "iic_mem_test_all_seq"
run_all         = 0
coverage        = 0
open_coverage   = 0
stimulus        = 10000
wave            = 0
open_wave       = 0
verbosity       = "UVM_MEDIUM"
rand_seed       = 0
jobs            = 12
threads         = 2
test_runs        = 1

# Environment
env = os.environ.copy()
env.pop("VERILATOR_ROOT")

# Directories
obj_dir                 = "obj_dir/V"
uvm_home                = env.get("UVM_HOME")
filelist                = "iic_flist"
top_tb                  = "iic_mem_tb"
coverage_files_folder   = Path("coverage")
logs_folder             = Path("test_logs")
wave_folder             = Path("waveforms")

# Get the arguments
for argument in sys.argv:
    if 'vrun.py' in argument:
        pass

    elif argument == 'h' or argument == 'help':
        vmod.print_help(test_tuple, coverage_tuple, verbosity_tuple)

    elif 'test=' in argument:
        test = vmod.is_in_tuple('test', test_tuple, argument.split('=')[1].strip(), default_index=test_tuple.index(test), exit_when_not_found=1)
    
    elif 'run_all' == argument:
        run_all = 1
    
    elif 'coverage=' in argument:
        coverage = vmod.is_in_range('coverage', int(argument.split('=')[1].strip()), default_value=coverage, min=0, max=7)
    
    elif 'open_coverage' == argument:
        open_coverage = 1
    
    elif 'stimulus=' in argument:
        stimulus = vmod.is_in_range('stimulus', int(argument.split('=')[1].strip()), default_value=stimulus, min=1)

    elif 'wave' == argument:
        wave = 1

    elif 'open_wave' == argument:
        open_wave = 1

    elif 'verbosity=' in argument:
        verbosity = vmod.is_in_tuple('verbosity', verbosity_tuple, argument.split('=')[1].strip(), 
                                     exit_when_not_found=0, default_index=verbosity_tuple.index(verbosity))

    elif 'rand_seed' == argument:
        rand_seed = 1

    elif 'jobs=' in argument:
        jobs = vmod.is_in_range('jobs', int(argument.split('=')[1].strip()), default_value=jobs, min=1)

    elif 'threads=' in argument:
        threads = vmod.is_in_range('threads', int(argument.split('=')[1].strip()), default_value=threads, min=1)

    elif 'test_runs=' in argument:
        test_runs = vmod.is_in_range('test_runs', int(argument.split('=')[1].strip()), default_value=test_runs, min=1)

    else:
        print(f"{argument} is an invalid argument. Refer below for more info.")
        vmod.print_help(test_tuple, coverage_tuple, verbosity_tuple)

# Create necessary folders
coverage_files_folder.mkdir(exist_ok=True)
logs_folder.mkdir(exist_ok=True)
wave_folder.mkdir(exist_ok=True)

# Build the test
wave_build_flags = "--trace-fst" if wave == 1 else ""
coverage_flags   = vmod.generate_coverage_flag(coverage_tuple, coverage)
verilator_args   = f"-Wno-fatal --binary -j {jobs} --threads {threads} \
                    --top-module {top_tb} +incdir+{uvm_home} {coverage_flags} \
                    +define+TEST_NUM={stimulus} {wave_build_flags} -f {filelist}"
vmod.build_test(env, verilator_args)

# Run the test
pool_processes  = jobs // threads 
run_test_args   = []

if run_all:
    if __name__ == '__main__':

        # Arguments for Run Test
        for each_run in range(test_runs):
            seed = vmod.generate_random_seed() if rand_seed else 1
            for each_test in test_tuple:
                run_test_args.append(
                    (obj_dir, top_tb, each_test, wave, open_wave, seed, 
                     verbosity, coverage != 0, open_coverage, 
                     coverage_files_folder, logs_folder)
                )
            # If test runs are > 1 but rand_seed is disabled ...
            # Then seeds are incremented in each test run to avoid redundancy
            if test_runs > 1 and rand_seed == 0:
                seed+=1

        with Pool(processes=pool_processes) as pool:
            run_results = pool.starmap(vmod.run_test, run_test_args)

        print(f"{vmod.CGREEN}[ALL TEST DONE] All tests are done!{vmod.CRESET}")

else:
    for each_run in range(test_runs):
        seed = vmod.generate_random_seed() if rand_seed else 1
        vmod.run_test(obj_dir, top_tb, test, wave, open_wave, seed, 
                      verbosity, coverage != 0, open_coverage, 
                      coverage_files_folder, logs_folder)
        
        # If test runs are > 1 but rand_seed is disabled ...
        # Then seeds are incremented in each test run to avoid redundancy
        if test_runs > 1 and rand_seed == 0:
            seed+=1
    
    print(f"{vmod.CGREEN}[ALL TEST DONE] All tests are done!{vmod.CRESET}")
