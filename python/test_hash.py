from ascon import Ascon, HashVariants

ascon = Ascon(True)

variant = HashVariants.ASCON_HASH
message = b'bonjour cryptis m1'
digest = ascon.hash(
	message,
	256,
	variant
)