from utils import rotr, print_S
def permutation(S, number_of_rounds):
    assert(number_of_rounds > 0 and number_of_rounds <= 12)
    
    for r in range(12 - number_of_rounds, 12):
        print('Permutation Round', r + 1 - (12 - number_of_rounds))
        
        # Constants Addition Layer
        S[2] ^= (0xf0 - r*0x10 + r*0x1)
        print_S('Constants Addition Layer Result:', S)
        
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
        print_S('Substitution Layer Result:', S)

        # Linear Diffusion Layer
        S[0] ^= rotr(S[0], 19) ^ rotr(S[0], 28)
        S[1] ^= rotr(S[1], 61) ^ rotr(S[1], 39)
        S[2] ^= rotr(S[2],  1) ^ rotr(S[2],  6)
        S[3] ^= rotr(S[3], 10) ^ rotr(S[3], 17)
        S[4] ^= rotr(S[4],  7) ^ rotr(S[4], 41)
        print_S('Linear Diffusion Layer Result:', S)
        print()
        
    print_S('Permutation Output', S)
    print()

r = 64
a = 12
b = 12
h = 256
# k = 128
# key = b'this message comes from me'
# nonce = b'bonjour cryptis adl'
IV = (
    hex(r)[2:].rjust(2, '0') + 
    hex(a)[2:].rjust(2, '0') + 
    hex(a-b)[2:].rjust(2, '0') + 
    hex(h)[2:].rjust(8, '0')
).rjust(16,'0') 
print('IV:', IV)

S_hex = IV.ljust(int((80)),'0')
S = list(int(S_hex[i * 16 : (i + 1) * 16],16) for i in range(5))
print('S_hex:', S_hex)
print('S:', S)
permutation(S, a)
print('S permuted:', S)

print('S[0] is: ',hex(S[0])[2:])
# message = b'Hello iam from VN'

# block_size_in_hex = int(r / 4)
# message_hex = message.hex() + hex(128)[2:]
# block_num = len(message_hex) // block_size_in_hex + 1
# message_hex = message_hex.ljust(block_num * block_size_in_hex, '0')
# print(message_hex)

# for i in range(5):
#     print(i)

# import math

# t = math.ceil(253/64)
# print(t)
# value = bytes.fromhex(''.join(S))


