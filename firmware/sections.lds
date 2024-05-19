MEMORY {
	mem : ORIGIN = 0x00000000, LENGTH = 0x00003400
}

SECTIONS {
	.memory : {
		. = 0x000000;
		start*(.text);
		*(.text);
		*(*);
		end = .;
		. = ALIGN(4);
	} > mem
    .fill : {
    FILL(0x00);
    . = ORIGIN(mem) + 7312;
    BYTE(0xFF);
    } >mem
}
