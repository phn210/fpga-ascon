import math
from enum import Enum
from utils import rotr, print_S

class AEADVariants(Enum):
	ASCON_128 = 'Ascon-128'
	ASCON_128A = 'Ascon-128a'	

class HashVariants(Enum):
	ASCON_HASH = 'Ascon-Hash'
	ASCON_HASHA = 'Ascon-Hasha'
	# ASCON_XOF = 'Ascon-Xof'
	# ASCON_XOFA = 'Ascon-Xofa'
class Ascon:
	_logging: bool = True

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

		return [ciphertext, tag]
		
	def decrypt(self, key: bytes, nonce: bytes, associated_data: bytes, ciphertext: bytes, tag = bytes, variant = AEADVariants.ASCON_128):
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
		P = []
		self.process_ciphertext(S, P, r, b, ciphertext)
		plaintext = bytes.fromhex(''.join(P))
		
		# Finalization 
		T = self.finalize_aead(S, k, r, a, key)
		authTag = bytes.fromhex(''.join(T))
		isAuth = (authTag == tag)

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
		IV = (
			hex(r)[2:].rjust(2, '0') + 
			hex(a)[2:].rjust(2, '0') + 
			hex(a-b)[2:].rjust(2, '0') + 
			hex(h)[2:].rjust(8, '0')
		).rjust(16,'0') 
		if self._logging: print('IV:', IV)

		# Assign initial state
		S_hex = IV.ljust(int((80)),'0')
		S = list( int(S_hex[i * 16 : (i + 1) * 16],16) for i in range(5) )
		if self._logging: print('S:', S)

		# Perform permutation
		self.permutation(S, a)
		if self._logging: print('S permuted:', S)

	def absorb(self, S, r, b, message):
		# Pad message
		block_size_in_hex = int(r / 4)
		message_hex = message.hex() + hex(128)[2:]
		message_hex = message_hex.ljust((len(message_hex) // block_size_in_hex + 1) * block_size_in_hex, '0')
		print('Message: ',message_hex)

		# XOR and perform permutation
		s = len(message_hex) // block_size_in_hex \
			if len(message_hex) % block_size_in_hex == 0 \
			else len(message_hex) // block_size_in_hex + 1
		
		for i in range(s - 1):
			S[0] ^= int(message_hex[i * block_size_in_hex : i * block_size_in_hex + 16], 16)
			self.permutation(S,b)
		i = s-1
		S[0] ^= int(message_hex[i * block_size_in_hex : i * block_size_in_hex + 16], 16)

	#TO DO
	def squeeze(self,S,H,h,l,r,a,b):
		if l <= h:
			self.permutation(S,a)
			t = math.ceil(l/r)
			for _ in range(t):
				h_i = hex(S[0])[2:]
				self.permutation(S,b)
				H.append(h_i)
				print ('hash: ',h_i)
		else:
			print('Invalid output length!')

	def initialize_aead(self, S, k, r, a, b, key, nonce):
		# Calculate IV
		IV = (
			hex(k)[2:].rjust(2, '0') + 
			hex(r)[2:].rjust(2, '0') + 
			hex(a)[2:].rjust(2, '0') + 
			hex(b)[2:].rjust(2, '0')
		).ljust(int((320-k-128)/4), '0')
		if self._logging: print('IV:', IV)

		# Assign initial state
		S_hex = IV + key.hex() + nonce.hex()
		S = list( int(S_hex[i * 16 : (i + 1) * 16],16) for i in range(5) )
		if self._logging: print('S:', S)

		# Perform permutation
		self.permutation(S, a)
		if self._logging: print('S permuted:', S)
		
		# Pad and split key
		key_hex = key.hex().rjust(int(320 / 4), '0')
		K = list( int(key_hex[i * 16 : (i + 1) * 16], 16) for i in range(5) )
		if self._logging: print('K:', K)

		# XOR initial state with secret key K
		S = [S[i] ^ K[i] for i in range(5)]
		if self._logging: print('S xor:', S)

	def process_associated_data(self, S, r, b, associated_data):
		if len(associated_data) == 0:
			return
		
		# Pad associate data
		block_size_in_hex = int(r / 4)
		associated_data_hex = associated_data.hex() + hex(128)[2:]
		associated_data_hex = associated_data_hex.ljust((len(associated_data_hex) // block_size_in_hex + 1) * block_size_in_hex, '0')

		# XOR and perform permutation
		s = len(associated_data_hex) // block_size_in_hex - 1 \
			if len(associated_data_hex) % block_size_in_hex == 0 \
			else len(associated_data_hex) // block_size_in_hex
		for i in range(s):
			S[0] ^= int(associated_data_hex[i * block_size_in_hex : i * block_size_in_hex + 16], 16)
			if r > 64:
				S[1] ^= int(associated_data_hex[i * block_size_in_hex + 16 : i * block_size_in_hex + 32], 16)
			self.permutation(S, b)
		S[4] ^= 1

	def process_plaintext(self, S, C, r, b, plaintext):
		# Pad plaintext
		block_size_in_hex = int(r / 4)
		plaintext_hex = plaintext.hex() + hex(128)[2:]
		plaintext_hex = plaintext_hex.ljust((len(plaintext_hex) // block_size_in_hex + 1) * block_size_in_hex, '0')
		print(plaintext_hex)

		# XOR and perform permutation
		t = len(plaintext_hex) // block_size_in_hex \
			if len(plaintext_hex) % block_size_in_hex == 0 \
			else len(plaintext_hex) // block_size_in_hex + 1
		for i in range(t - 1):
			S[0] ^= int(plaintext_hex[i * block_size_in_hex : i * block_size_in_hex + 16], 16)
			c = hex(S[0])[2:].rjust(16, '0')
			if r > 64:
				S[1] ^= int(plaintext_hex[i * block_size_in_hex + 16 : i * block_size_in_hex + 32], 16)
				c += hex(S[1])[2:].rjust(16, '0')
			C.append(c)
			self.permutation(S, b)
		i = t - 1
		print(plaintext_hex[i * block_size_in_hex : i * block_size_in_hex + 16])
		S[0] ^= int(plaintext_hex[i * block_size_in_hex : i * block_size_in_hex + 16], 16)
		c = hex(S[0])[2:].rjust(16, '0')
		if r > 64:
			S[1] ^= int(plaintext_hex[i * block_size_in_hex + 16 : i * block_size_in_hex + 32], 16)
			c += hex(S[1])[2:].rjust(16, '0')
		c = c[:int(len(plaintext) * 8 % r / 4)]
		C.append(c)

	def process_ciphertext(self, S, P, r, b, ciphertext):
		block_size_in_hex = int(r / 4)
		ciphertext_hex = ciphertext.hex()

		# XOR and perform permutation
		t = len(ciphertext_hex) // block_size_in_hex - 1 \
			if len(ciphertext_hex) % block_size_in_hex == 0 \
			else len(ciphertext_hex) // block_size_in_hex
		for i in range(t - 1):
			c = int(ciphertext_hex[i * block_size_in_hex : i * block_size_in_hex + 16], 16)
			p = hex(S[0] ^ c)[2:].rjust(16, '0')
			S[0] = int(ciphertext_hex[i * block_size_in_hex : i * block_size_in_hex + 16], 16)
			if r > 64:
				c = int(ciphertext_hex[i * block_size_in_hex + 16 : i * block_size_in_hex + 32], 16)
				p += hex(S[1] ^ c)[2:].rjust(16, '0')
				S[1] = c
			P.append(p)
			print(len(p))
			self.permutation(S, b)
		i = t - 1
		c = int(ciphertext_hex[(t - 1) * block_size_in_hex : (t - 1) * block_size_in_hex + 16], 16)
		if r == 64:
			p = hex(int(hex(S[0])[2:][:int(len(ciphertext) * 8 % r / 4)], 16) ^ c)[2:].rjust(16, '0')
			P.append(p)
			S[0] ^= int((p + '80').ljust(int(64 / 4), '0'), 16)
		if r > 64:
			p = hex(S[0] ^ c)[2:].rjust(16, '0')
			S[0] ^= p
			c = int(ciphertext_hex[i * block_size_in_hex + 16 : i * block_size_in_hex + 32], 16)
			p += hex(int(hex(S[1])[2:][:int(len(ciphertext) * 8 % r / 4)], 16) ^ c)[2:].rjust(16, '0')
			P.append(p)
			S[1] ^= int(hex(int(hex(S[1])[2:][:int(len(ciphertext) * 8 % r / 4)], 16) ^ c)[2:].rjust(16, '0'), 16)
		
	def finalize_aead(self, S, k, r, a, key):
		# Prepare xor
		padded_key_hex = '0' * int(r/4) + key.hex() + '0' * int((320-r-k)/4)
		PADK = list( int(padded_key_hex[i * 16 : (i + 1) * 16], 16) for i in range(5) )

		# XOR
		S = [S[i] ^ PADK[i] for i in range(5)]
		self.permutation(S, a)

		# Pad and split key
		key_hex = key.hex().rjust(int(320 / 4), '0')
		K = list( int(key_hex[i * 16 : (i + 1) * 16], 16) for i in range(5) )

		# Compute tag
		return [
			hex(S[0] ^ K[0])[2:].rjust(16, '0'), 
			hex(S[1] ^ K[1])[2:].rjust(16, '0')
		]

	def permutation(self, S, number_of_rounds = 1):
		assert(number_of_rounds > 0 and number_of_rounds <= 12)
		if self._logging:
			print_S('Permutation Input:', S)
			print()
		for r in range(12 - number_of_rounds, 12):
			if self._logging: print('Permutation Round', r + 1 - (12 - number_of_rounds))
			# Constants Addition Layer
			S[2] ^= (0xf0 - r*0x10 + r*0x1)
			if self._logging: print_S('Constants Addition Layer Result:', S)
			
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
			if self._logging: print_S('Substitution Layer Result:', S)

			# Linear Diffusion Layer
			S[0] ^= rotr(S[0], 19) ^ rotr(S[0], 28)
			S[1] ^= rotr(S[1], 61) ^ rotr(S[1], 39)
			S[2] ^= rotr(S[2],  1) ^ rotr(S[2],  6)
			S[3] ^= rotr(S[3], 10) ^ rotr(S[3], 17)
			S[4] ^= rotr(S[4],  7) ^ rotr(S[4], 41)
			if self._logging:
				print_S('Linear Diffusion Layer Result:', S)
				print()
		if(self._logging):
			print_S('Permutation Output', S)
			print()

ascon = Ascon(True)
# print('Encryption result:', ascon.encrypt(
# 	b'babecafebabecafe',
# 	b'1234567812345678',
# 	b'this message comes from me',
# 	b'bonjour cryptis adl',
# 	AEADVariants.ASCON_128
# ))
# print('Decryption result:', ascon.decrypt(
# 	b'babecafebabecafe',
# 	b'1234567812345678',
# 	b'this message comes from me',
# 	b'X\x85\xac\x00\x19h6}&\x8b\xe3',
# 	b'\x0fn\xa4,\xdc\x11Ag6\x17b\xb2\xbf+\x1a\xf7',
# 	AEADVariants.ASCON_128
# ))

print('Hash result: ', ascon.hash(
	b'Hello this is our prj ADL',
	256,
	HashVariants.ASCON_HASH
))
