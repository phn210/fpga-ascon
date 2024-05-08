from ascon import Ascon, AEADVariants

ascon = Ascon()

key = b'babecafebabecafe'
nonce = b'1234567812345678'
associated_data = b'adl projet'
plaintext = b'bonjour cryptis m1'
[ciphertext, tag] = ascon.encrypt(
	key,
	nonce,
	associated_data,
	plaintext,
	AEADVariants.ASCON_128
)
[decryption, isAuth] = ascon.decrypt(
	key,
	nonce,
	associated_data,
	ciphertext,
	tag,
	AEADVariants.ASCON_128
)
print('Encryption verification:', plaintext == decryption)
print('Tag verification:', isAuth)
[ciphertext, tag] = ascon.encrypt(
	key,
	nonce,
	associated_data,
	plaintext,
	AEADVariants.ASCON_128A
)
[decryption, isAuth] = ascon.decrypt(
	key,
	nonce,
	associated_data,
	ciphertext,
	tag,
	AEADVariants.ASCON_128A
)
print('Encryption verification:', plaintext == decryption)
print('Tag verification:', isAuth)
	