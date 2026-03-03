<!---

This file is used to generate your project datasheet. Please fill in the information below and delete any unused
sections.

You can also include images in this folder and reference them in the markdown. Each image must be less than
512 kb in size, and the combined size of all images must be less than 1 MB.
-->

## How it works

For this project, I decided to implement a custom accelerator for an algorithm. The project is a hardware accelerator designed to run an algorithm named Adaptive Leaky Integrate-and-Fire (ALIF) model, which is inpired by a machine learning class that I took. The algorithm that this chip accelerates is a process that mimics how information travels through the human brain. The integraion is when the algorithm takes a constant stream of the digital current and adds it to an internal counter. To prevent the counter from just growing endlessly, the algorithm will constantly subtract a small leak value to ensure the neuron only cares about the information that arrives recently.

## How to test

For my testbench, I use cocotb. The testbench monitors the chip over thousands of clock cycle and records evey single spike of activity to create a detailed map of the neuron's behavior. Everytime a spike is detected, the testbench records the timestamp. The core of the testing process is Inter-Spike Interval (ISI) Analysis. It calculates the time gap between every pair of signals. At the beginning we expect the gaps to be short as the neuron is fresh and firing quickly. However, as the hardware's internal "fatigue" logic kicks in, the testbench expects to see these gaps grow wider. After 3000 cycles, the testbench would compare the first gap to the last gap to indicate if they have increase, and if it did, it confirms that the adaptation algortihm is working correctly.

### Use of GenAI Tools
For this project, I used Gemini to assist me with the verilog design and cocotb testbench. I used AI to help me understand the Adaptive Leaky Integrate-and-Fire algorithm. I also used AI to help me create my Python script (cocotb) to prove that the design was working. While I use Gemini to provide suggestions and code frameworks, I review and edited every line of the code to ensure that the logic of my design is working. 

## External hardware

List external hardware used in your project (e.g. PMOD, LED display, etc), if any
