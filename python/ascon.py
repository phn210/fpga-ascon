from utils import rotr, print_S

class Ascon:
	_logging: bool = True

	def __init__(self, logging) -> None:
		self._logging = logging

	def permutation(self, S: [int], number_of_rounds = 1) -> [int]:
		assert(number_of_rounds > 0 and number_of_rounds <= 12)
		if self._logging: print_S("Permutation Input:", S)
		print()
		for r in range(12 - number_of_rounds, 12):
			if self._logging: print("Permutation Round", r + 1 - (12 - number_of_rounds))
			# Constants Addition Layer
			S[2] ^= (0xf0 - r*0x10 + r*0x1)
			if self._logging: print_S("Constants Addition Layer Result:", S)
			
			# Substitution Layer
			S[0] ^= S[4]
			S[4] ^= S[3]
			S[2] ^= S[1]
			T = [(S[i] ^ 0xFFFFFFFFFFFFFFFF) & S[(i+1)%5] for i in range(5)]
			for i in range(5):
					S[i] ^= T[(i+1)%5]
			S[1] ^= S[0]
			S[0] ^= S[4]
			S[3] ^= S[2]
			S[2] ^= 0XFFFFFFFFFFFFFFFF
			if self._logging: print_S("Substitution Layer Result:", S)

			# Linear Diffusion Layer
			S[0] ^= rotr(S[0], 19) ^ rotr(S[0], 28)
			S[1] ^= rotr(S[1], 61) ^ rotr(S[1], 39)
			S[2] ^= rotr(S[2],  1) ^ rotr(S[2],  6)
			S[3] ^= rotr(S[3], 10) ^ rotr(S[3], 17)
			S[4] ^= rotr(S[4],  7) ^ rotr(S[4], 41)
			if self._logging: print_S("Linear Diffusion Layer Result:", S)
		print()
		if(self._logging): print_S("Permutation Output", S)
		print()