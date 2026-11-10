# MODULES FOR VRUN
import sys, random
import subprocess
from pathlib import Path

CRED = '\033[91m'
CGREEN = '\033[92m'
CYELLOW = '\033[93m'
CBLUE = '\033[94m'
CRESET = '\033[0m'

def error_message(variable_name, value):
    print(f"{value} is not a valid value for '{variable_name}'\nExiting...")
    sys.exit(1)

def invalid_value_message(variable_name, value, default_value):
    print(f"{value} is not a valid value for '{variable_name}'\n")
    print(f"Proceeding with a default value of {default_value}")

def print_help(test_tuple, coverage_tuple, verbosity_tuple):
    print("""\nVRUN ARGUMENTS                                                                                   
        test=<Test Name>            Specifies which test to run                                       
        run_all                     Run all tests simultaneously                                      
        test_runs=<Number>          Specifies how many times will the test be run                                      
        stimulus=<Number>           Specifies sequence/item/test stimulus count per test            
        rand-seed                   Enables randomization of seed value                               
        coverage=<Level>            Specifies coverage level (default to No Coverage)                      
        open_coverage               Opens the coverage results after the simulation                           
        wave                        Enables waveform generation                                       
        open_wave                   Opens the waveform after the simulation                           
        verbosity=<Level>           Specifies UVM Verbosity Level                                     
        jobs=<Jobs Count>           Specifies the number of threads used for for all verilator simulation
        threads=<Threads Count>     Specifies the number of threads used for each verilator simulation""")

    print("\nTESTS")
    for test in test_tuple:
        print(f"\t{test}")
    
    print("\nCOVERAGE LEVELS")
    for index in range(len(coverage_tuple)):
        print(f"\t{index} - {coverage_tuple[index]}")
    print("See https://verilator.org/guide/latest/exe_verilator.html#cmdoption-coverage for more info")
    
    print("\nVERBOSITY LEVELS")
    for verbosity in verbosity_tuple:
        print(f"\t{verbosity}")
    print("See https://chipverify.com/uvm/report-functions for more info")

    sys.exit()

def is_in_tuple(variable_name : str, tuple, value_to_find, default_index = 0, exit_when_not_found = 0):
    for value in tuple:
        if value == value_to_find:
            return value_to_find

    # If not found, error will be produces or the default value will be returned
    if exit_when_not_found:    
        error_message(variable_name, value_to_find)
    else:
        invalid_value_message(variable_name, value_to_find, tuple[default_index])
        return {tuple[default_index]}

def is_bool(variable_name : str, value, default_value = 0, exit_when_error = 0):
    if value in ['0', '1', 'true', 'false']:
        return value
    elif exit_when_error:
        error_message(variable_name, value)
    else:
        invalid_value_message(variable_name, value, default_value)
        return default_value

def is_in_range(variable_name : str, value : int, default_value : int, min = None, max = None):
    if min == None and max == None:
        return value
    elif min == None and max is not None and value <= max:
        return value
    elif min is not None and max == None and value >= min:
        return value
    elif value in range(min, max):
        return value
    else:
        invalid_value_message(variable_name, value, default_value)   
        return default_value

def generate_random_seed():
    # Verilator only accepts seed upto 2**31 
    return random.randint(1, 2**31)

def generate_coverage_flag(coverage_tuple, coverage_index):
    if coverage_index == 0:
        return ""
    elif coverage_index == 1:
        return "--coverage"
    else:
        return f"--coverage --coverage-{coverage_tuple[coverage_index]}"

def build_test(env, verilator_args:str):
    try:
        subprocess.run(f"verilator {verilator_args}", env=env, shell=True, check=True)
    except subprocess.CalledProcessError as e:
        print(f"{CRED}[BUILD FAILED] Build Test failed with error: {e}{CRESET}")
        sys.exit(1)

def run_test(obj_dir:str, top_tb:str, test_name:str, has_wave : bool, 
             open_wave : bool, seed, verbosity:str, has_coverage : bool, 
             open_coverage : bool, coverage_files_folder:str, logs_folder : str):
    # Creates waves folder for the test and generates the wavename
    if has_wave:    
        Path(f"waveforms/{test_name}").mkdir(exist_ok=True, parents=True)
        wave_file = f"waveforms/{test_name}/seed_{seed}_{test_name}"
        wave_flag = f"+WAVE_NAME={wave_file}"
    else:
        wave_flag = ""

    # Creates log folder named for the test
    Path(f"{logs_folder}/{test_name}").mkdir(exist_ok=True, parents=True)

    # Coverage file directory
    if has_coverage:
        coverage_dir = Path(f"{coverage_files_folder}/{test_name}")
        coverage_dir.mkdir(exist_ok=True, parents=True)
        coverage_file = f"{str(coverage_dir)}/seed_{seed}_{test_name}"
        coverage_file_flag = f"+verilator+coverage+file+{coverage_file}.dat"
    else:
        coverage_file_flag = ""

    try:
        # Run the test
        result = subprocess.Popen(f"{obj_dir}{top_tb} +UVM_TESTNAME={test_name} {wave_flag} \
                    +verilator+seed+{seed} +UVM_VERBOSITY={verbosity} +UVM_NO_RELNOTES \
                    {coverage_file_flag}",
                    shell=True, text=True, stdout=subprocess.PIPE, 
                    stderr=subprocess.STDOUT, bufsize=1)
        
        # Print that test has started
        print(f"[TEST STARTED] test={test_name} with seed={seed} is RUNNING ...")
        
        # Create a log file for the test
        with open(f"{logs_folder}/{test_name}/seed_{seed}_{test_name}.log", "w") as log:
            log.write(f"""
========================================================================
 TEST NAME : {test_name}          
 SEED      : {seed}                
 VERBOSITY : {verbosity}           
 TOP MODULE: {top_tb}              
========================================================================\n
            """)
            log.flush()

            # Prints the results of the test in realtime
            for line in result.stdout:
                log.write(line)
                log.flush()
        
        # Print that test is completed
        print(f"{CGREEN}[TEST DONE] test={test_name} with seed={seed} is DONE!{CRESET}")

        # Generate coverage result if enabled
        if has_coverage:
            generate_coverage_result(coverage_file, open_coverage)

        if open_wave:
            open_waveform(wave_file)

    except subprocess.CalledProcessError as e:
        print(f"{CRED}[RUN FAILED] Run Test failed with error: {e}{CRESET}")
        sys.exit(1)

def generate_coverage_result(coverage_file : str, open_coverage : bool):
    subprocess.run(f"verilator_coverage -write-info {coverage_file}.info {coverage_file}.dat", shell=True, text=True)
    subprocess.run(f"genhtml {coverage_file}.info --output-directory {coverage_file}", shell=True,  text=True, capture_output=True)
    
    if open_coverage:
        print(f"{CYELLOW}[COVERAGE] Opening the coverage result of {coverage_file}{CRESET}")
        subprocess.Popen(f"firefox {coverage_file}/index.html", shell=True)

def open_waveform(wave_file : str):
    print(f"{CBLUE}[WAVEFORM] Opening the waveform of {wave_file}.fst{CRESET}")
    subprocess.Popen(f'gnome-terminal --tab --title={wave_file} -- bash -c "surfer {wave_file}.fst; exec bash"', shell=True, text=True)