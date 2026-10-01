# FPGA UART-BRAM Memory Loopback

This project implements a UART-based memory loopback system on FPGA.

A **128×128 8-bit image** is received from a PC through UART RX, stored in BRAM, and then transmitted back through UART TX. The main goal was to design the memory controller and integrate it with the UART receiver, UART transmitter, and BRAM.

## System Flow

```text
PC
 │
 ▼
UART RX
 │
 ▼
Memory Controller
 │
 ▼
BRAM
 │
 ▼
Memory Controller
 │
 ▼
UART TX
 │
 ▼
PC
```

The image size is:

```text
128 × 128 = 16,384 pixels
```

Each pixel is 8 bits, so the BRAM stores 16,384 bytes of image data.

## Operation

The system has two main modes.

### Receive

When `rx_switch` is enabled, the FPGA waits for UART data from the PC.

Each received byte is passed to the memory controller and written into BRAM. The address is incremented until the full image has been received.

Once all image data is stored, the LED is asserted to indicate that reception is complete. 

### Transmit

When `tx_switch` is enabled, the controller reads the image back from BRAM and sends each byte to the UART TX module.

The stored image is then transmitted back to the PC, where the returned data can be compared with the original input. 
### `loopback_top.v`

Top-level module connecting the UART, memory controller, BRAM, switches, and status signals.

### `uart_rx.v`

Receives serial UART data and reconstructs each 8-bit byte.

The UART receiver uses the standard frame format:

```text
Start bit → 8 data bits → Stop bit
```

The lecture notes specify idle = 1, start bit = 0, stop bit = 1, with data sent LSB first. 

### `uart_tx.v`

Serializes 8-bit data read from BRAM and transmits it back to the PC.

### `memory_control.v`

Controls data movement between UART RX, BRAM, and UART TX.

During reception:

```text
UART RX → BRAM
```

During transmission:

```text
BRAM → UART TX
```

### `uart_baud_gen.v`

Generates the timing used by the UART receiver.

### `meta_harden.v`

Synchronizes the asynchronous UART RX input to the FPGA clock domain.

### `posedge_detector.v`

Generates a one-cycle pulse from a rising-edge control signal.

### `ClockDivider.v`

Generates divided clock signals used by the design.

## BRAM Storage

The received image is stored sequentially in BRAM.

```text
Address 0      → first pixel
Address 1      → second pixel
...
Address 16383  → last pixel
```

For a 128×128 image:

```text
address = row × 128 + column
```

## UART

UART is used as the communication interface between the FPGA and the PC.

The design uses:

- UART RX to receive image data
- UART TX to send the stored image back
- baud-rate timing
- start/stop-bit detection
- 8-bit data transfer



## Tools

- Verilog
- Xilinx Vivado
- UART
- Block RAM
- RTL simulation

## Summary

The project implements a complete:

```text
UART RX → BRAM → UART TX
```

data path on FPGA.

It provided practice with UART communication, BRAM access, FSM-based control, asynchronous signal synchronization, and modular RTL design.
