### --------------------------------------------------------------------
### gtkwave.tcl
### Author: William Ughetta
### --------------------------------------------------------------------

# Resources:
# Manual: http://gtkwave.sourceforge.net/gtkwave.pdf#Appendix-E-Tcl-Command-Syntax
# Also see the GTKWave source code file: examples/des.tcl

# Add all signals
set nfacs [ gtkwave::getNumFacs ]
set all_facs [list]
for {set i 0} {$i < $nfacs } {incr i} {
    set facname [ gtkwave::getFacName $i ]
    # puts "Signal : $facname"
    set dut [string first ".dut" $facname]
    if {$dut > -1} {
      # puts "=> Signal : $facname"
      # set clock [string first "clock" $facname]
      # set clk [string first "clk" $facname]

      if {[string first "clock" $facname] > -1 || [string first "clk" $facname] > -1 } { 
        # puts "insert $facname"
        set all_facs [linsert $all_facs 0 "$facname"]
      } else {
        # puts "ajout $facname"
       lappend all_facs "$facname"
     }
    }
}
set num_added [ gtkwave::addSignalsFromList $all_facs ]
puts "num signals added: $num_added"

# zoom full
gtkwave::/Time/Zoom/Zoom_Full

# Print
set dumpname [ gtkwave::getDumpFileName ]
gtkwave::/File/Print_To_File PDF {A4 (11.68" x 8.26")} Minimal $dumpname.pdf
