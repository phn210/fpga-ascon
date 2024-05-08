#!/usr/bin/python

lfsr = int('babecafe',16)
rep = format(lfsr,"032b")
print(rep)
# compteur = 0
# while 1:
#     compteur += 1;
#     bit = int(rep[31-31],2)^int(rep[31-21],2)^int(rep[31-1],2)^int(rep[31-0],2)
#     # print(str(bit))
#     rep = rep[1:]+str(bit) 
#     # print(rep)
#     if compteur == 32:
#         lfsr = int(rep,2)
#         print(hex(lfsr))
#         break

# compteur = 0
# while 1:
#     compteur += 1;
#     bit = int(rep[31-31],2)^int(rep[31-21],2)^int(rep[31-1],2)^int(rep[31-0],2)
#     # print(str(bit))
#     rep = rep[1:]+str(bit) 
#     # print(rep)
#     if compteur == 32:
#         lfsr = int(rep,2)
#         print(hex(lfsr))
#         break

for i in range(8):
    compteur = 0
    while 1:
        compteur += 1
        bit = int(rep[31-31],2)^int(rep[31-21],2)^int(rep[31-1],2)^int(rep[31-0],2)
        # print(str(bit))
        rep = rep[1:]+str(bit) 
        # print(rep)
        if compteur == 32:
            lfsr = int(rep,2)
            print(hex(lfsr))
            break