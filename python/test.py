import math
from utils import *
def permutation(S, number_of_rounds):
    assert(number_of_rounds > 0 and number_of_rounds <= 12)
    print_S('Permutation Input:', S)
    for r in range(12 - number_of_rounds, 12):
        # print('Permutation Round', r + 1 - (12 - number_of_rounds))
        
        # Constants Addition Layer
        S[2] ^= (0xf0 - r*0x10 + r*0x1)
        # print_S('Constants Addition Layer Result:', S)
        
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
        # print_S('Substitution Layer Result:', S)

        # Linear Diffusion Layer
        S[0] ^= rotr(S[0], 19) ^ rotr(S[0], 28)
        S[1] ^= rotr(S[1], 61) ^ rotr(S[1], 39)
        S[2] ^= rotr(S[2],  1) ^ rotr(S[2],  6)
        S[3] ^= rotr(S[3], 10) ^ rotr(S[3], 17)
        S[4] ^= rotr(S[4],  7) ^ rotr(S[4], 41)
        # print_S('Linear Diffusion Layer Result:', S)
        
    print_S('Permutation Output', S)

# ASCON_HASH
r = 64
a = 12
b = 12
h = 256
# k = 128
# key = b'this message comes from me'
# nonce = b'bonjour cryptis adl'
# message = b'Hello iam from VN'

def hash(message: bytes,l: int):

    # Initialization
    S = [0,0,0,0,0]
    initialize_hash(S,h,r,a,b)

    # Absorbing message
    absorb(S,r,b,message)

    # Squeezing
    H = []
    squeeze(S,H,h,l,r,a,b)
    hashValue = bytes.fromhex(''.join(H))

    return hashValue

def initialize_hash(S,h,r,a,b):
    # Calculate IV
    print_info('Initialize Hash...')

    IV = pad_hex(
			int_to_hex(r, 2) + 
			int_to_hex(a, 2) + 
			int_to_hex(a-b, 2) + 
			int_to_hex(h, 8),
            int(16),
			False
		)
    print('IV:', IV)

    # Assign initial state
    S_hex = pad_hex(IV, int(80), True)
    S = list( int(S_hex[i * 16 : (i + 1) * 16],16) for i in range(5) )
    print('S:', S)

    # Perform permutation
    permutation(S, a)
    print('S permuted:', S)
    print_info('Initialize Hash --> DONE')

def absorb(S, r, b, message):
    print_info('Absorbing...')

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
        permutation(S,b)
    i = num_blocks - 1
    S[0] ^= hex_to_int(m)
    print_info('Absorb --> DONE')

def squeeze(S,H,h,l,r,a,b):
    print_info('Squeezing...')
    # Perform permutation 
    permutation(S,a)

    # Extracting hash output
    if l <= h:
        t = math.ceil(l/r)
        for i in range(t):
            H_i = int_to_hex(S[0],16)
            print ('hash: ',H_i)
            permutation(S,b)
            if i < t-1:
                H.append(H_i)
        mod_in_hex = l%r
        print('l mod r:', mod_in_hex)
        H_t = int_to_hex(S[0], 16)[:mod_in_hex]
        print('H_t~ :',H_t)
        H.append(H_t)
    else:
        print('Invalid output length!')

    print_info('Squeeze --> DONE')

print('Hash result: ', hash(
	b'Hello this is our prj ADL',
	200
))