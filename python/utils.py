def rotr(val, r):
	return (val >> r) | ((val & (1<<r)-1) << (64-r))

def print_S(text, S):
	S = [hex(s).replace('0x','') for s in S]
	print(text, ''.join(S))