// Copyright lowRISC contributors (OpenTitan project).
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
//
// Modified by Daniil Kanelsky.
// Simplified for use in small projects without virtual sequences and RAL.

package hdv_pkg;
  // dep package
  import uvm_pkg::*;

  // macro includes
  `include "uvm_macros.svh"
  `include "hdv_macros.svh"

  // package variables
  string msg_id = "hdv_pkg";

  // package sources
  // base agent
  `include "hdv_agent_cfg.svh"
  `include "hdv_agent_cov.svh"
  `include "hdv_monitor.svh"
  `include "hdv_sequencer.svh"
  `include "hdv_driver.svh"
  `include "hdv_agent.svh"

  // base seq
  `include "hdv_sequence.svh"

  // base env
  `include "hdv_env_cfg.svh"
  `include "hdv_env_cov.svh"
  `include "hdv_scoreboard.svh"
  `include "hdv_env.svh"

  // base test
  `include "hdv_test.svh"

endpackage
