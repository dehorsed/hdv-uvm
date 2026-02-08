# HDV-UVM Base Library

## Overview

HDV-UVM is a simplified UVM (Universal Verification Methodology) base class library derived from the **OpenTitan** project. This library provides essential UVM components for small to medium-sized verification projects, removing the complexity of virtual sequences and RAL (Register Abstraction Layer) while maintaining a robust verification infrastructure.

## Origin

This codebase is a **modified and simplified version** of the UVM infrastructure from the [OpenTitan](https://opentitan.org/) project, an open-source silicon root of trust initiative. All original code is licensed under the Apache License 2.0, with modifications by Daniil Kanelsky for simplified use in smaller projects.

## Key Simplifications from OpenTitan

1. **No Virtual Sequences**: Removed complex virtual sequence infrastructure
2. **No RAL Integration**: Simplified register access patterns for smaller projects
3. **Reduced Configuration Complexity**: Streamlined configuration objects
4. **Minimal Dependencies**: Self-contained with standard UVM base classes

## Quick Start

### 1. Basic Agent Usage

```systemverilog
// Define your sequence item
class my_item extends uvm_sequence_item;
  rand bit [31:0] addr;
  rand bit [31:0] data;
  // ... uvm_object utilities
endclass

// Create agent configuration
hdv_agent_cfg#(my_item) agent_cfg = new("agent_cfg");
agent_cfg.has_req_fifo = 1;
agent_cfg.has_rsp_fifo = 1;

// Create and configure agent
hdv_agent#(hdv_agent_cfg#(my_item), 
           my_driver, 
           my_sequencer, 
           my_monitor) agent;
agent = new("agent", null);
```

### 2. Environment Setup

```systemverilog
class my_env extends hdv_env#(hdv_env_cfg, my_scoreboard);
  `uvm_component_utils(my_env)
  
  function void build_phase(uvm_phase phase);
    // Create configuration
    cfg = hdv_env_cfg::type_id::create("cfg");
    cfg.en_scb = 1;
    cfg.en_cov = 0;
    
    super.build_phase(phase);
  endfunction
endclass
```

### 3. Using Check Macros

```systemverilog
// Basic checks
`DV_CHECK_EQ(actual_value, expected_value, "Values should match")
`DV_CHECK_FATAL(item.randomize(), "Randomization failed")

// Wait with timeout
`DV_WAIT(signal == 1'b1, "Timeout waiting for signal", 1000)

// Array comparisons
`DV_CHECK_Q_EQ(actual_queue, expected_queue, "Queues should match")
```

## Configuration Options

### Agent Configuration (hdv_agent_cfg)
- `en_cov`: Enable coverage collection
- `has_req_fifo`: Enable request analysis FIFO
- `has_rsp_fifo`: Enable response analysis FIFO
- `in_reset`: Reset state indicator

### Environment Configuration (hdv_env_cfg)
- `is_active`: Environment activity status
- `en_scb`: Scoreboard enable
- `en_cov`: Coverage collection enable

## Differences from Standard UVM

### What's Included
- Built-in reset handling in driver
- Integrated scoreboard with reset awareness
- Optional analysis FIFOs for monitor-sequencer communication
- Comprehensive check and assertion macros
- Configurable coverage collection

### What's Excluded (Compared to Full OpenTitan)
- Virtual sequence infrastructure
- RAL (Register Abstraction Layer) integration
- Complex scoreboard predictors
- Advanced coverage groups
- TL-UL and other specific protocol implementations

## Usage Guidelines

### For Small Projects
1. Use the base classes as-is for simple protocols
2. Extend `hdv_sequence_item` for your transaction types
3. Override `drive_trans()` in your driver
4. Override `collect_trans()` in your monitor
5. Use the built-in scoreboard for transaction comparison

### For Medium Projects
1. Create project-specific configuration classes
2. Extend the base components with protocol-specific behavior
3. Use the analysis FIFOs for monitor-sequencer communication
4. Implement coverage in the subscriber classes

## Checking (linting)

### Prerequisites

- Verilator with UVM support
- UVM IEEE 1800.2-2017 library
- GNU Make build system

### Using the Makefile

The provided Makefile supports linting the HDV-UVM library with Verilator:
Environment Variables
- VERILATOR: Path to Verilator executable (default: verilator)
- UVM_HOME: Path to UVM library (default: /usr/share/1800.2-2017-1.0)

## License

This code is derived from OpenTitan project code, which is licensed under the **Apache License 2.0**. All modifications retain the original licensing terms.

```
// SPDX-License-Identifier: Apache-2.0
```

## Acknowledgments

- **OpenTitan Project**: For the original UVM infrastructure
- **lowRISC contributors**: For maintaining the OpenTitan project
- **UVM Community**: For the Universal Verification Methodology standard

---

*Note: This library is designed for simplicity and ease of use in smaller verification projects. For complex, production-level verification, consider using the full OpenTitan UVM infrastructure or other comprehensive verification frameworks.*
