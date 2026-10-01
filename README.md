# FPGA-UART-BRAM-Memory-Loopback

FPGA-based memory loopback system that receives **128×128 8-bit image data through UART RX**, stores the received bytes in **Block RAM (BRAM)**, and retransmits the stored data through **UART TX**.

The project demonstrates RTL design for serial communication, memory control, clock-domain synchronization, and FPGA-based data transfer.

---

## Project Overview

The system implements the following data path:

```text
        PC / Tester
             │
             │ UART
             ▼
        ┌─────────┐
        │ UART RX │
        └────┬────┘
             │
             │ 8-bit data
             ▼
    ┌─────────────────┐
    │ Memory Controller│
    └────────┬────────┘
             │
             ▼
          ┌──────┐
          │ BRAM │
          └───┬──┘
              │
              ▼
    ┌─────────────────┐
    │ Memory Controller│
    └────────┬────────┘
             │
             ▼
        ┌─────────┐
        │ UART TX │
        └────┬────┘
             │
             │ UART
             ▼
        PC / Tester
```

The input image size is:

```text
128 × 128 = 16,384 pixels
```

Since each pixel is represented using **8 bits**, the system receives and stores:

```text
16,384 bytes
```

before transmitting the complete image back to the tester.

---

## Main Features

- UART receiver implemented in RTL
- UART transmitter implemented in RTL
- 128×128 8-bit image transfer
- BRAM-based image storage
- Custom memory controller
- RX and TX operating modes
- FPGA status LED
- Clock synchronization for asynchronous UART input
- Baud-rate generation
- Edge detection for control signals
- Complete UART → BRAM → UART loopback

---

## System Operation

The system operates in two main phases.

### 1. Receive Mode

The `rx_switch` starts the receive operation.

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
```

The process is:

1. Enable receive mode using `rx_switch`.
2. UART RX waits for serial data from the PC.
3. Each received byte is passed to the memory controller.
4. The memory controller writes each byte into BRAM.
5. The BRAM address is incremented after each received byte.
6. After all **16,384 bytes** are received, the memory controller stops writing.
7. The status LED is asserted to indicate that the complete image has been stored.

---

### 2. Transmit Mode

The `tx_switch` starts transmission of the stored image.

```text
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

The process is:

1. Enable transmit mode using `tx_switch`.
2. The memory controller reads the stored image sequentially from BRAM.
3. Each byte is provided to the UART TX module.
4. UART TX converts the parallel 8-bit value into a serial UART frame.
5. The complete image is transmitted back to the PC.
6. The tester compares the received data with the original image.

---

## UART Communication

UART provides asynchronous serial communication between the FPGA and the external tester.

Each UART frame contains:

```text
Idle
 │
 ▼
Start Bit
 │
 ▼
8 Data Bits
 │
 ▼
Stop Bit
```

The data bits are transmitted from **LSB to MSB**.

```text
Idle = 1
Start bit = 0
Data = 8 bits
Stop bit = 1
```

Because UART is asynchronous, the transmitter and receiver do not share a clock. Both sides must therefore use the same configured baud rate.

---

## RTL Architecture

The current RTL hierarchy is:

```text
rtl/
├── loopback_top.v
├── ClockDivider.v
├── uart_rx.v
├── uart_tx.v
├── meta_harden.v
├── uart_baud_gen.v
├── uart_rx_ctl.v
├── posedge_detector.v
├── memory_control.v
└── ip/
    └── blk_mem_gen_0.xci
```

---

## Module Description

### `loopback_top.v`

Top-level module for the complete memory loopback system.

It connects:

```text
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
```

It also connects the clock divider, status/control signals, and external UART interface.

---

### `uart_rx.v`

Implements the UART receiver.

Responsibilities include:

- Detecting the UART start bit
- Sampling incoming serial data
- Reconstructing an 8-bit received value
- Detecting the stop bit
- Generating a valid-data indication

The received byte is passed to the memory controller when reception is complete.

---

### `uart_rx_ctl.v`

Implements the UART RX control logic.

The module coordinates the states required to:

```text
Idle
  ↓
Start detection
  ↓
Receive 8 data bits
  ↓
Check stop bit
  ↓
Data ready
```

---

### `uart_baud_gen.v`

Generates the timing signal required by the UART receiver.

The baud-rate generator allows the receiver to sample the incoming serial data at the appropriate positions within each UART bit period.

---

### `meta_harden.v`

Synchronizes the asynchronous UART RX input to the FPGA system clock.

This helps reduce the risk of metastability when the external serial signal enters the synchronous FPGA logic.

---

### `uart_tx.v`

Implements the UART transmitter.

The module accepts an 8-bit parallel value and sends it serially as:

```text
Start Bit
+
8 Data Bits
+
Stop Bit
```

The memory controller provides the next data byte when the UART transmitter is ready.

---

### `memory_control.v`

Coordinates data movement between UART RX, BRAM, and UART TX.

During receive mode:

```text
UART RX → BRAM
```

During transmit mode:

```text
BRAM → UART TX
```

The controller keeps track of the memory address and determines when all **16,384 image bytes** have been received or transmitted.

---

### `posedge_detector.v`

Generates a short pulse when a control signal changes from LOW to HIGH.

This is useful for converting switch activity or longer control signals into single-event triggers.

---

### `ClockDivider.v`

Generates slower timing signals derived from the FPGA system clock for modules that require a lower operating frequency or control timing.

---

### `blk_mem_gen_0.xci`

Vivado Block Memory Generator configuration used to implement the image storage BRAM.

---

## Memory Organization

The image contains:

```text
128 rows × 128 columns
```

with one 8-bit pixel stored at each memory address.

The image can therefore be mapped linearly into BRAM:

```text
Address 0       → Pixel (0, 0)
Address 1       → Pixel (0, 1)
Address 2       → Pixel (0, 2)
...
Address 127     → Pixel (0, 127)
Address 128     → Pixel (1, 0)
...
Address 16383   → Pixel (127, 127)
```

The address can be expressed as:

```text
address = row × 128 + column
```

---

## Control Flow

The overall control sequence is:

```text
               RESET
                 │
                 ▼
               IDLE
                 │
        ┌────────┴────────┐
        │                 │
   rx_switch          tx_switch
        │                 │
        ▼                 ▼
     RECEIVE           TRANSMIT
        │                 │
        ▼                 ▼
 UART RX → BRAM      BRAM → UART TX
        │                 │
        ▼                 ▼
16,384 bytes        16,384 bytes
 received             transmitted
        │                 │
        └────────┬────────┘
                 ▼
               IDLE
```

---

## Data Verification

The system is designed as a loopback test.

The tester sends:

```text
Original Image
      │
      ▼
    FPGA
      │
      ▼
Stored in BRAM
      │
      ▼
Returned through UART
      │
      ▼
Received Image
```

The returned image data can then be compared with the transmitted data.

A successful loopback should satisfy:

```text
Transmitted Data == Received Data
```

for all:

```text
16,384 bytes
```

## Tools & Technologies

- Verilog HDL
- Xilinx Vivado
- UART
- Block RAM
- RTL simulation
- FPGA implementation
- Finite State Machines
- Clock-domain synchronization
- Serial communication

---

## What This Project Demonstrates

This project demonstrates practical FPGA design concepts including:

- UART serial communication
- UART RX/TX protocol implementation
- Asynchronous input synchronization
- Baud-rate timing
- FSM-based control
- BRAM interfacing
- Sequential memory addressing
- Hardware data buffering
- RTL hierarchy and modular design
- FPGA communication with an external PC

The main objective is to reliably receive a complete image over UART, store it in on-chip memory, and retransmit the same data back to the tester without corruption.
