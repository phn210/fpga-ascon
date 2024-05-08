def rotr(val, r):
	return (val >> r) | ((val & (1<<r)-1) << (64-r))

def pad_hex(hex: str, len_in_hex: int, is_right=False):
	if is_right:
		return hex.ljust(len_in_hex, '0')
	else:
		return hex.rjust(len_in_hex, '0')

def int_to_hex(val: int, length = -1):
	hex_string = hex(val)[2:]
	if length < 0: return hex_string
	assert length >= len(hex_string)
	return hex_string.rjust(length, '0')

def hex_to_int(hex: str):
	return int(hex, 16)

def print_S(text, S):
	S = [pad_hex(hex(s).replace('0x',''), 16) for s in S]
	print(text, ''.join(S))