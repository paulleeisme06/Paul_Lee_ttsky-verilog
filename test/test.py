# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, ClockCycles

@cocotb.test()
async def test_alif_self_checking_accelerator(dut):
    clock = Clock(dut.clk, 10, unit="ns")
    cocotb.start_soon(clock.start())

    dut._log.info("Resetting ALIF Accelerator...")
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 10)
    dut.rst_n.value = 1
    
    await RisingEdge(dut.clk)

    dut.ui_in.value = 80
    dut.uio_in.value = 0x24 
    
    dut._log.info("Waiting for first spike (Threshold Check)...")
    
    timeout = 10
    found_spike = False
    
    for i in range(timeout):
        await RisingEdge(dut.clk)
        current_out = int(dut.uo_out.value)
        # Check bit 0 (Spike signal)
        if current_out & 0x01:
            dut._log.info(f"ASSERTION SUCCESS: First spike detected at cycle {i}")
            dut._log.info(f"Vmem MSBs at time of spike: {current_out >> 1}")
            found_spike = True
            break
            
    assert found_spike, f"FAIL: Neuron failed to spike within {timeout} cycles. Final value: {int(dut.uo_out.value)}"

    # Tracking Inter-Spike Intervals (ISI) to verify Adaptation (SFA)
    spike_times = []
    dut._log.info("Monitoring ISI for 3000 cycles to verify Adaptation feedback...")

    for i in range(3000):
        await RisingEdge(dut.clk)
        if int(dut.uo_out.value) & 0x01:
            spike_times.append(i)
            # Log adaptation level via uio_out (bi-directional pins)
            adapt_val = int(dut.uio_out.value)
            dut._log.info(f"Spike at cycle {i} | Adaptation Level: {adapt_val}")

    if len(spike_times) >= 3:
        # Calculate intervals between spikes
        isi = [spike_times[j] - spike_times[j-1] for j in range(1, len(spike_times))]
        dut._log.info(f"Calculated ISI sequence: {isi}")
        
        first_isi = isi[0]
        last_isi = isi[-1]
        
        dut._log.info(f"Initial ISI: {first_isi}, Final Adapted ISI: {last_isi}")
    
        # The interval must increase if adaptation logic is working
        assert last_isi > first_isi, f"FAIL: Adaptation logic failed. ISI did not increase."
        
        dut._log.info("SUCCESS: Accelerator demonstrated Spike-Frequency Adaptation.")
    else:
        assert False, f"FAIL: Insufficient activity ({len(spike_times)} spikes) to verify logic."

    dut._log.info("ALIF Hardware Verification Completed Successfully.")