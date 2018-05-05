PROJ = 2bitvga
PIN_DEF = icestick.pcf
DEVICE = hx1k

SRC = top.v vga.v test_pattern.v clockdiv.v image.v number.v numbers.v fontROM.v debounce.v encoder.v color_sq.v grid.v waveform.v

all: $(PROJ).bin

%.blif: $(SRC)
	yosys -p "synth_ice40 -top top -blif $@" $^

%.asc: $(PIN_DEF) %.blif
	arachne-pnr -d $(subst hx,,$(subst lp,,$(DEVICE))) -o $@ -p $^

%.bin: %.asc
	icepack $< $@

%.rpt: %.asc
	icetime -d $(DEVICE) -mtr $@ $<

debug-debounce:
	iverilog -o debounce debounce.v debounce_tb.v
	vvp debounce -fst
	gtkwave test.vcd gtk-debounce.gtkw

debug-numbers:
	iverilog -o numbers numbers.v fontROM.v image.v numbers_tb.v
	vvp numbers -fst
	gtkwave test.vcd gtk-numbers.gtkw

debug-grid:
	iverilog -o grid grid.v grid_tb.v
	vvp grid -fst
	gtkwave test.vcd gtk-grid.gtkw

debug-waveform:
	iverilog -o waveform fontROM.v waveform.v waveform_tb.v
	vvp waveform -fst
	gtkwave test.vcd gtk-waveform.gtkw

prog: $(PROJ).bin
	iceprog $<

sudo-prog: $(PROJ).bin
	@echo 'Executing prog as root!!!'
	sudo iceprog $<

capture:
	sigrok-cli --driver=fx2lafw -c "samplerate=1M" --samples 1M -O vcd > /tmp/out.vcd
	gtkwave /tmp/out.vcd gtk-saleae.gtkw 

clean:
	rm -f $(PROJ).blif $(PROJ).asc $(PROJ).rpt $(PROJ).bin

.SECONDARY:
.PHONY: all prog clean
