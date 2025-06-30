#Switch to DPV mode
set_fml_appmode DPV

#Configure host file
set_host_file hostfile


proc compile_spec {} {
  create_design -name spec -top DPV_wrapper
  ## C++ Compile
  cppan -I. ../c/alu_design.cpp 
  compile_design spec 
}


proc compile_impl {} {
  create_design -name impl -top alu -clock clk -reset reset 
  ## RTL file of ALU design to be debugged
  vcs -sverilog ../rtl/multiplier_design.sv ../rtl/alu_design.sv
  compile_design impl
}


proc global_assumes {} {
  # -inputs creates assumes and -outputs create lemmas.
  map_by_name -inputs -specphase 1 -implphase 1

  # Command in cpp is of 1 byte, command in sv is of 3 bits.
  assume command_range = spec.command(1)[7:3] == 0
}

proc ual {} {

  # Passing assumes
  global_assumes
   
  # Passing Lemmas
  lemma result_equal_small = impl.valid(1) && impl.size(1) == 0 -> impl.result(3)[15:0] == spec.result(1)[15:0]
  lemma result_equal_big = impl.valid(1) && impl.size(1) == 1  -> impl.result(3) == spec.result(1)
  lemma signal_equal = impl.valid(1) -> impl.signal(3)[1:0] == spec.signal(1)[1:0]
  lemma result_mul_complex = impl.valid(1) && impl.command(1) > 5 -> impl.result(3) == spec.result(1)

  cover signal_3 = spec.signal(1)[1:0] == 3
}

set_user_assumes_lemmas_procedure "ual"

# fml vacuity should be set before solveNB command as after solveNB there is conclusive status.
# vacuity means the tool was able to hit the antecedant of the expression containing ->, |=>
# witness shows a example where the propert y is true.

proc run_DPV_task {} {
    compile_spec;
    compile_impl;
    compose;
    set_fml_var fml_vacuity_on true
    set_fml_var fml_witness_on true
    solveNB P1
    proofwait;
    redirect -file dpv_report.log "listproofs -verbose"
}

run_DPV_task
