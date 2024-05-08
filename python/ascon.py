import math
from enum import Enum
from utils import *

class AEADVariants(Enum):
	ASCON_128 = 'Ascon-128'
	ASCON_128A = 'Ascon-128a'	

class HashVariants(Enum):
	ASCON_HASH = 'Ascon-Hash'
	ASCON_HASHA = 'Ascon-Hasha'
	# ASCON_XOF = 'Ascon-Xof'
	# ASCON_XOFA = 'Ascon-Xofa'
class Ascon:
	_logging: bool

	def __init__(self, logging=False) -> None:
		self._logging = logging

	def get_aead_parameters(self, variant):
		k = 0
		r = 0
		a = 12
		b = 0
		if (variant is AEADVariants.ASCON_128):
			k = 128
			r = 64
			b = 6
		elif (variant is AEADVariants.ASCON_128A):
			k = 128
			r = 128
			b = 8
		assert  k > 0 and r > 0 and b > 0
		return [k, r, a, b]
	
	def get_hash_parameters(self, variant):
		h = 256
		r = 64
		a = 12
		b = 0
		if (variant is HashVariants.ASCON_HASH):
			b = 12
		elif (variant is HashVariants.ASCON_HASHA):
			b = 8
		assert b > 0 
		return [h,r,a,b]

	def encrypt(self, key: bytes, nonce: bytes, associated_data: bytes, plaintext: bytes, variant = AEADVariants.ASCON_128):
		if self._logging:
			print('INPUT:')
			print('  - Algo:', variant)
			print('  - Key:', key.hex())
			print('  - Nonce:', nonce.hex())
			print('  - Plaintext:', plaintext.hex())
			print('  - Associated data:', associated_data.hex())
		
		# Assign parameters
		[k, r, a, b] = self.get_aead_parameters(variant)
		assert len(nonce) == 16
		assert len(key) == (k/8)
		
		# Initialization
		S = [0, 0, 0, 0, 0]
		self.initialize_aead(S, k, r, a, b, key, nonce)

		# Process associated data
		self.process_associated_data(S, r, b, associated_data)

		# Process plaintext
		C = []
		self.process_plaintext(S, C, r, b, plaintext)
		ciphertext = bytes.fromhex(''.join(C))
		
		# Finalization 
		T = self.finalize_aead(S, k, r, a, key)
		tag = bytes.fromhex(''.join(T))

		assert len(plaintext) == len(ciphertext)
		assert len(tag) == 16
		
		if self._logging:
			print('OUTPUT:')
			print('  - Encrypted ciphertext:', ciphertext.hex())
			print('  - Tag:', tag.hex())

		return [ciphertext, tag]
		
	def decrypt(self, key: bytes, nonce: bytes, associated_data: bytes, ciphertext: bytes, tag = bytes, variant = AEADVariants.ASCON_128):
		if self._logging:
			print('INPUT:')
			print('  - Algo:', variant)
			print('  - Key:', key.hex())
			print('  - Nonce:', nonce.hex())
			print('  - Ciphertext:', ciphertext.hex())
			print('  - Associated data:', associated_data.hex())
		
		# Assign parameters
		[k, r, a, b] = self.get_aead_parameters(variant)
		assert len(nonce) == 16
		assert len(key) == (k/8)
		assert len(tag) == 16

		# Initialization
		S = [0, 0, 0, 0, 0]
		self.initialize_aead(S, k, r, a, b, key, nonce)

		# Process associated data
		self.process_associated_data(S, r, b, associated_data)

		# Process plaintext
		P = []
		self.process_ciphertext(S, P, r, b, ciphertext)
		# print(P)
		plaintext = bytes.fromhex(''.join(P))
		
		# Finalization 
		T = self.finalize_aead(S, k, r, a, key)
		authTag = bytes.fromhex(''.join(T))
		isAuth = (authTag == tag)

		assert len(plaintext) == len(ciphertext)
		
		if self._logging:
			print('OUTPUT:')
			print('  - Decrypted plaintext:', plaintext.hex())
			print('  - Tag:', tag.hex())

		return [plaintext, isAuth]

	def hash(self, message: bytes,l: int, variant = HashVariants.ASCON_HASH):
		# Assign parameters
		[h,r,a,b] = self.get_hash_parameters(variant)

		# Initialization
		S = [0,0,0,0,0]
		self.initialize_hash(S,h,r,a,b)

		# Absorbing message
		self.absorb(S,r,b,message)

		# Squeezing
		H = []
		self.squeeze(S,H,h,l,r,a,b)
		hashValue = bytes.fromhex(''.join(H))

		return hashValue
	
	def initialize_hash(self,S,h,r,a,b):
		# Calculate IV
		if self._logging: print_info('Initialize Hash...')

		IV = pad_hex(
				int_to_hex(r, 2) + 
				int_to_hex(a, 2) + 
				int_to_hex(a-b, 2) + 
				int_to_hex(h, 8),
				int(16),
				False
			)
		if self._logging: print('IV:', IV)

		# Assign initial state
		S_hex = pad_hex(IV, int(80), True)
		S = list( int(S_hex[i * 16 : (i + 1) * 16],16) for i in range(5) )
		if self._logging: print('S:', S)

		# Perform permutation
		self.permutation(S, a)
		if self._logging: print('S permuted:', S)
		if self._logging: print_info('Initialize Hash --> DONE')

	def absorb(self, S, r, b, message):
		if self._logging: print_info('Absorbing...')

		# Number of r-bit blocks of M || 1 || 0*
		block_size_in_hex = int(r / 4)
		message_hex = message.hex() + int_to_hex(128)

		num_blocks = len(message_hex) // block_size_in_hex \
					if len(message_hex) % block_size_in_hex == 0 \
					else len(message_hex) // block_size_in_hex + 1
		
		# Pad message
		padding_size = num_blocks * block_size_in_hex
		message_hex = pad_hex(message_hex, padding_size, True)

		# XOR and perform permutation
		for i in range(num_blocks - 1):
			m = message_hex[i * block_size_in_hex : i * block_size_in_hex + 16]
			S[0] ^= hex_to_int(m)
			self.permutation(S,b)
		i = num_blocks - 1
		S[0] ^= hex_to_int(m)
		if self._logging: print_info('Absorb --> DONE')

	def squeeze(self,S,H,h,l,r,a,b):
		if self._logging: print_info('Squeezing...')
		# Perform permutation 
		self.permutation(S,a)

		# Extracting hash output
		if l <= h:
			t = math.ceil(l/r)
			for i in range(t):
				H_i = int_to_hex(S[0],16)
				# print ('hash: ',H_i)
				self.permutation(S,b)
				if i < t-1:
					H.append(H_i)
			mod_in_hex = l%r
			print('l mod r:', mod_in_hex)
			H_t = int_to_hex(S[0], 16)[:mod_in_hex]
			H.append(H_t)
		else:
			if self._logging: print('Invalid output length!')

		if self._logging: print_info('Squeeze --> DONE')

	def initialize_aead(self, S, k, r, a, b, key: bytes, nonce):
		# Calculate IV
		if self._logging: print('Initialize AEAD...')
		IV = pad_hex(
			int_to_hex(k, 2) + 
			int_to_hex(r, 2) + 
			int_to_hex(a, 2) + 
			int_to_hex(b, 2),
			int((320-k-128)/4),
			True
		)
		if self._logging: print('IV:', IV)

		# Assign initial state
		S_hex = IV + key.hex() + nonce.hex()
		S = list( int(S_hex[i * 16 : (i + 1) * 16],16) for i in range(5) )
		if self._logging: print_S('Initial S:', S)

		# Perform permutation
		self.permutation(S, a)
		
		# Pad and split key
		key_hex = pad_hex(key.hex(), int(320 / 4))
		K = list( hex_to_int(key_hex[i * 16 : (i + 1) * 16]) for i in range(5) )

		# XOR initial state with secret key K
		S = [S[i] ^ K[i] for i in range(5)]
		if self._logging: print('Initialize AEAD --> DONE!')

	def process_associated_data(self, S, r, b, associated_data):
		if self._logging: print('Process associated data...')
		if len(associated_data) == 0:
			return
		
		# Number of r-bit blocks of A || 1 || 0*
		block_size_in_hex = int(r / 4)
		associated_data_hex = associated_data.hex() + int_to_hex(128)
		num_blocks = len(associated_data_hex) // block_size_in_hex \
					if len(associated_data_hex) % block_size_in_hex == 0 \
					else len(associated_data_hex) // block_size_in_hex + 1

		# Pad associate data
		padding_size = num_blocks * block_size_in_hex
		associated_data_hex = pad_hex(associated_data_hex, padding_size, True)

		# XOR and perform permutation
		for i in range(num_blocks):
			S[0] ^= hex_to_int(associated_data_hex[i * block_size_in_hex : i * block_size_in_hex + 16])
			if r == 128:
				S[1] ^= hex_to_int(associated_data_hex[i * block_size_in_hex + 16 : i * block_size_in_hex + 32])
			self.permutation(S, b)
		S[4] ^= 1
		if self._logging: print('Process associated data --> DONE!')

	def process_plaintext(self, S, C, r, b, plaintext: bytes):
		if self._logging: print('Process plaintext...')
		# Number of r-bit blocks of P || 1 || 0*
		block_size_in_hex = int(r / 4)
		plaintext_hex = plaintext.hex() + int_to_hex(128)
		num_blocks = len(plaintext_hex) // block_size_in_hex \
					if len(plaintext_hex) % block_size_in_hex == 0 \
					else len(plaintext_hex) // block_size_in_hex + 1
		
		# Pad plaintext
		padding_size = num_blocks * block_size_in_hex
		plaintext_hex = pad_hex(plaintext_hex, padding_size, True)

		# XOR and perform permutation
		for i in range(num_blocks - 1):
			p = plaintext_hex[i * block_size_in_hex : i * block_size_in_hex + 16]
			S[0] ^= hex_to_int(p)
			c = int_to_hex(S[0], 16)
			if r == 128:
				p = plaintext_hex[i * block_size_in_hex + 16 : i * block_size_in_hex + 32]
				S[1] ^= hex_to_int(p)
				c += int_to_hex(S[1], 16)
			C.append(c)
			self.permutation(S, b)
		
		i = num_blocks - 1
		p = plaintext_hex[i * block_size_in_hex : i * block_size_in_hex + 16]
		S[0] ^= hex_to_int(p)
		mod_in_hex = int(len(plaintext) * 2) % block_size_in_hex
		if mod_in_hex == 0: return
		if r == 64:
			c = int_to_hex(S[0], 16)[:mod_in_hex]
		if r == 128:
			p = plaintext_hex[i * block_size_in_hex + 16 : i * block_size_in_hex + 32]
			S[1] ^= hex_to_int(p)
			c = (int_to_hex(S[0], 16) + int_to_hex(S[1], 16))[:mod_in_hex]
		C.append(c)
		if self._logging: print('Process plaintext --> DONE!')

	def process_ciphertext(self, S, P, r, b, ciphertext):
		if self._logging: print('Process ciphertext...')
		# Number of r-bit blocks of C
		block_size_in_hex = int(r / 4)
		ciphertext_hex = ciphertext.hex()

		num_blocks = (len(ciphertext_hex) + 2) // block_size_in_hex \
					if (len(ciphertext_hex) + 2) % block_size_in_hex == 0 \
					else (len(ciphertext_hex) + 2) // block_size_in_hex + 1

		# XOR and perform permutation
		for i in range(num_blocks - 1):
			c = ciphertext_hex[i * block_size_in_hex : i * block_size_in_hex + 16]
			p = int_to_hex(S[0] ^ hex_to_int(c), 16)
			S[0] = hex_to_int(c)
			if r == 128:
				c = ciphertext_hex[i * block_size_in_hex + 16 : i * block_size_in_hex + 32]
				p += int_to_hex(S[1] ^ hex_to_int(c), 16)
				S[1] = hex_to_int(c)
			P.append(p)
			self.permutation(S, b)
		
		i = num_blocks - 1
		c = ciphertext_hex[i * block_size_in_hex : i * block_size_in_hex + 16]
		mod_in_hex = int(len(ciphertext) * 2) % block_size_in_hex
		if mod_in_hex == 0:
			S[0] ^= hex_to_int(pad_hex('80', 16, True))
			return
		if r == 64:
			p = int_to_hex(hex_to_int(int_to_hex(S[0])[:mod_in_hex]) ^ hex_to_int(c))
			S[0] ^= hex_to_int(pad_hex(p + '80', 16, True))
		if r == 128:
			if mod_in_hex < 16:
				Sr = hex_to_int(int_to_hex(S[0], 16)[:mod_in_hex])
				p = int_to_hex(Sr ^ hex_to_int(c))
				S[0] ^= hex_to_int(pad_hex(p + '80', 16, True))
			elif mod_in_hex == 16:
				p = int_to_hex(S[0] ^ hex_to_int(c))
				print(p)
				S[0] ^= hex_to_int(p)
				S[1] ^= hex_to_int(pad_hex('80', 16, True))
			else:
				p = int_to_hex(S[0] ^ hex_to_int(c))
				S[0] ^= hex_to_int(p)
				c = ciphertext_hex[i * block_size_in_hex + 16 : i * block_size_in_hex + 32]
				tmp_p = int_to_hex(hex_to_int(int_to_hex(S[1])[:mod_in_hex - 16]) ^ hex_to_int(c))
				S[1] ^= hex_to_int(pad_hex(tmp_p + '80', 16, True))
				p += tmp_p
		P.append(p)
		if self._logging: print('Process ciphertext --> DONE!')
		
	def finalize_aead(self, S, k, r, a, key: bytes):
		if self._logging: print('Finalize AEAD...')
		# Prepare xor
		padded_key_hex = '0' * int(r/4) + key.hex() + '0' * int((320-r-k)/4)
		PADK = list( hex_to_int(padded_key_hex[i * 16 : (i + 1) * 16]) for i in range(5) )

		# XOR
		S = [S[i] ^ PADK[i] for i in range(5)]
		self.permutation(S, a)

		# Pad and split key
		key_hex = pad_hex(key.hex(), int(320 / 4))
		K = list( hex_to_int(key_hex[i * 16 : (i + 1) * 16]) for i in range(5) )
		
		# Compute tag
		if self._logging: print('Finalize AEAD --> DONE!')
		return [
			pad_hex(int_to_hex(S[3] ^ K[3]), 16), 
			pad_hex(int_to_hex(S[4] ^ K[4]), 16)
		]

	def permutation(self, S, number_of_rounds = 1):
		assert(number_of_rounds > 0 and number_of_rounds <= 12)
		if self._logging: print_S('Permutation Input:', S)
		for r in range(12 - number_of_rounds, 12):
			# Constants Addition Layer
			S[2] ^= (0xf0 - r*0x10 + r*0x1)
			
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

			# Linear Diffusion Layer
			S[0] ^= rotr(S[0], 19) ^ rotr(S[0], 28)
			S[1] ^= rotr(S[1], 61) ^ rotr(S[1], 39)
			S[2] ^= rotr(S[2],  1) ^ rotr(S[2],  6)
			S[3] ^= rotr(S[3], 10) ^ rotr(S[3], 17)
			S[4] ^= rotr(S[4],  7) ^ rotr(S[4], 41)
		if(self._logging): print_S('Permutation Output:', S)
