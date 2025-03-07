### Project Title: Detergent Dispensing Simulation Device
[![video](https://img.youtube.com/vi/RbaBZa_uVXU/hqdefault.jpg)](https://www.youtube.com/watch?v=RbaBZa_uVXU)


### 1. Abstract
This project utilizes Assembly Language to control the 8-bit microcontroller PIC18F45K22. By designing precise mid-level triggering, program stack sequencing, and microsecond-level timers, the system integrates various peripheral components from the Microchip APP025 experiment board, such as a buzzer, variable resistor, LCD, and UART interface. The project successfully simulates the detergent dispensing process in a washing machine.

### 2. Research Background
Washing machines have evolved with various functionalities, including ultrasonic washing, steam cleaning, and nano-coating. However, most top-loading washing machines lack an automatic detergent dispensing feature, which is only found in select front-loading models. This project designs and simulates an automatic detergent dispensing function to improve efficiency and accuracy in detergent usage.

###  3. Research Plan and Methods
#### (1) Peripheral Function Mapping
The project incorporates several functions, as outlined in the table below:

| Peripheral Module | Function |
|------------------|----------|
| VR1 (Variable Resistor) | Simulates clothing weight changes |
| Timer 1 | Controls LED sequential lighting timing |
| Timer 2 | Provides PWM comparator timing |
| Timer 3 | Manages LCD timing |
| LED | Displays progress through a marquee effect |
| LCD | Displays voltage values, cumulative dispensing count, and time |
| EEPROM | Permanently stores cumulative dispensing count |
| Buzzer | Plays music via PWM frequency control |
| UART | Communicates with a computer via RS232 for reset operations |

The voltage variation detected by VR1 simulates changes in clothing weight. The AD conversion result is amplified to adjust Timer 1 (dispensing time), where the maximum VR1 value (5V) corresponds to 5 seconds. Upon pressing the start button, the LED sequence acts as a progress indicator while playing the melody "Für Elise" with varying tempos. The cumulative dispensing count is stored in EEPROM, along with the converted decimal VR1 voltage and dispensing time displayed on the LCD. To reset the EEPROM record, users can press the "R" key via UART communication.

#### (2) Interrupt Function Allocation
The PIC18F45K22 microcontroller has only two interrupt priorities: high and low. When an interrupt occurs, execution jumps to the designated memory locations (0x08 for high-priority and 0x18 for low-priority) to handle the event before returning to the previous execution state. Since this project requires more than two interrupts, additional conditions are checked upon flag changes to determine which function was triggered. The allocation is as follows:

| High-Priority Interrupt | Low-Priority Interrupt |
|------------------------|------------------------|
| Timer 1 | UART RX Reception |
| Timer 3 | |

### 4. Experimental Results
Testing confirmed that pressing buttons and adjusting the variable resistor successfully converted voltage values to decimal format and displayed them on the LCD. The LED and buzzer adjusted timing dynamically, evenly distributing the total duration into eight segments.

Demo Video: [YouTube Link](https://youtu.be/RbaBZa_uVXU)
