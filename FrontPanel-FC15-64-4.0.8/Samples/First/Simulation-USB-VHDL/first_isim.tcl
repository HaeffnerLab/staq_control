onerror {resume}

divider add "FrontPanel Control"
wave add /FIRST_TEST/hi_in(0)

divider add "First"
wave add -radix hex /FIRST_TEST/dut/ep01wire
wave add -radix hex /FIRST_TEST/dut/ep02wire
wave add -radix hex /FIRST_TEST/dut/ep21wire

run 8us;
