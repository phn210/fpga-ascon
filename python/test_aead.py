from ascon import Ascon, AEADVariants

ascon = Ascon(True)

variant = AEADVariants.ASCON_128
key = b'babecafebabecafe'
nonce = b'1234567812345678'
associated_data = b'adl projet'
plaintext = b'bonjour cryptis m1'
[ciphertext, tag] = ascon.encrypt(
	key,
	nonce,
	associated_data,
	plaintext,
	variant
)
[decryption, isAuth] = ascon.decrypt(
	key,
	nonce,
	associated_data,
	ciphertext,
	tag,
	variant
)
print('Encryption verification:', plaintext == decryption)
print('Tag verification:', isAuth)