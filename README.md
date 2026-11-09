# I2C-Interfaced Memory Module with UVM Verification
Hi! This is a simple hardware project: a 256-byte memory module that talks using the I2C (IIC) protocol, verified with a UVM setup designed to work with Verilator.

Because Verilator only understands 0 and 1 (not tri-state high-impedance Z), I split the main data line into three separate pins: `sda_in`, `sda_out`, and `sda_ena`.

## Key Features
- **256 Bytes of Memory**: Stores data across 256 different 8-bit memory spots.
- **I2C Slave**: Responds to standard I2C commands (start, stop, ACK, read, write).
- **Verilator Ready**: Easy to simulate with Verilator (v5.052+) without missing high-Z signals. 
- **UVM Environment**: Automatically sends data, checks responses, and tracks testing coverage. It acts as the I2C Master for the memory module (slave).

## Signal Pins
| Pin | Type | Description |
| :---: | :---: | ----------- |
| `rst_n` | Input | Resets the module (active low)|
| `scl` | Input | Clock signal for the slave |
| `sda_in` | Input | Receives data coming from the testbench |
| `sda_out` | Output | Sends data out from the slave |
| `sda_ena` | Output | Turns on when the slave wants to send data |

## Transactions
- **WRITE**: Start -> [Slave Address + Write] -> [Memory Address] -> [Data Byte] -> Stop
- **READ**: Start -> [Slave Address + Write] -> [Memory Address] -> Restart -> [Slave Address + Read] -> [Data from Memory] -> Stop

## Tests Included
1. **Write-Read**: Writes data to an address, then reads it right back to see if it matches.
2. **Overwrite**: Writes data, overwrites it with new data, and checks if the newest data stays.
3. **Random Slave**: Sends commands to wrong slave addresses to check if the chip ignores them.
4. **Random Write/Read**: Mixes random reads and writes to test the memory under stress.
5. **All Tests in Sequence**: Runs all 4 main tests one after another.
6. **All Tests in Random**: Picks tests at random to keep checking for unexpected bugs.

## How to Run
1. Make sure you use Verilator v5.052 or above. See  [Verilator](https://verilator.org/guide/latest/install.html) for more information.
2. Give access to the vrun.py script using:
```chmod +x vrun.py```
3. Run the vrun script:

    *To run a single test*

    ```./vrun.py test=iic_mem_test_wr coverage=1 wave```

    *To run all test simultaneously*
    
    ```./vrun.py run_all coverage=1 wave```
