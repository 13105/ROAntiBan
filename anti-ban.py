#!/usr/bin/env python
# -*- coding: utf-8 -*-
import socket,sys,select,re

HOST='127.0.0.1'
SOCKET_LIST = []
BOT_LIST = [] #Porta,Nome,Classe
MAX_BUFFER=4096
PORTA=10000
# Flags de request : 
#			1F = Delimitador
#			
#			0x02 = {
#			0x03 = }
#
#			
#			0x12 = Dormiu : FLAG;TEMPO_QUE_ACORDA		\x02\x12\x1F     \x03
#			0x13 = Identificacao : FLAG;Nick_do_bot;
#			
# Flags de response :
#
#		   0x14 = Dormir
#		   
#
def servidor():
	server_socket = socket.socket(socket.AF_INET,socket.SOCK_STREAM)
	server_socket.setsockopt(socket.SOL_SOCKET,socket.SO_REUSEADDR,1)
	server_socket.bind((HOST,PORTA))
	server_socket.listen(10)

	SOCKET_LIST.append(server_socket) #

	print "[...] Servidor escutando na porta",PORTA
	
	while 1:
		#ppl = pronto para ler
		#ppe = pronto para escrever
		#er  = em erro,error
		ppl,ppe,er = select.select(SOCKET_LIST,[],[],0)

		for sock in ppl:
			#Recebeu um novo request de conexao
			if sock == server_socket:
				sockfd,addr = server_socket.accept()
				SOCKET_LIST.append(sockfd)
				BOT_LIST.append([addr[1],'',''])
				
			
			else:

				22
				addr = sock.getpeername() 
				try:
					#dados = sock.recv(MAX_BUFFER)
					dados = sock.recv(MAX_BUFFER)
					
					if dados:
						#Parser
							#print dados+"\n"
							blocos = re.findall(r'\x02([^\x02\x03]+)\x03',dados)
							for i,dat in enumerate(blocos):
								x = dat.split("\x1F")
								
								if x[0] == "\x11": #CALL PARA HIBERNAR
									##{ x11;FLAG2;Mapa;Tempo }
									# FLAG2 Acoes : 
									# x11 : Teleportado
									# x12 : PM,CHAT
									# x13 : TRAVADO
									# x14 : GM na party
									
									
									if x[1] == "\x11": #FLAG;FLAG2;Mapa;ALERTA;TEMPO
										if x[3] == "\x01":
											print "\033[38;5;208m[ ! ] Anti-Ban : \033[0m{}\033[38;5;208m(\033[37m{}\033[38;5;208m) Foi teleportado para '\033[0m{}\033[38;5;208m',Alertando bots que existem BotHunters online...\033[0m".format(getNome(addr[1]),getClasse(addr[1]),x[2].encode('string-escape'))
											dormir(server_socket,x[4],sock) #Tempo
										else:
											print "\033[38;5;208m[ ! ] Anti-Ban : \033[0m{}\033[38;5;208m(\033[37m{}\033[38;5;208m) Foi teleportado para '\033[0m{}\033[38;5;208m'...\033[0m".format(getNome(addr[1]),getClasse(addr[1]),x[2].encode('string-escape'))
										#dormir(server_socket)
									# Broadcast para bots

									elif x[1] == "\x12": #FLAG;FLAG2;Nome_do_GM;TEMPO
										print "\033[38;5;208m[ ! ] Anti-Ban : \033[38;5;201m{}\033[38;5;208m falou com \033[0m{}\033[38;5;208m(\033[37m{}\033[38;5;208m) !\nAlertando bots que existe um GM online...\033[0m".format(x[2].encode('string-escape'),getNome(addr[1]),getClasse(addr[1]))
										dormir(server_socket,x[3],sock) 
								elif x[0] == "\x12": #Hibernado
									#{ x12;seg;min;hora;dia;mes;alerta }
									print "\033[38;5;226m[ ! ] Bot \033[0m{}\033[38;5;226m(\033[37m{}\033[38;5;226m) Dormiu ! Despertara dia {} As {}:{}:{} do Mes {}\033[0m".format( getNome(addr[1]) , getClasse(addr[1]),x[4],x[3],x[2],x[1],x[5])
									
								elif x[0] == "\x13": #Identifica \x02\x13\x1FAVE1111\x1FRogue\x03
									#{ x13;Usuario;Classe }
									for bot in BOT_LIST:
										if bot[0] == addr[1]: # se porta == porta
											bot[1] = x[1].encode('string-escape') # seta nome
											bot[2] = x[2].encode('string-escape') # seta classe
											print "\033[92m[ + ] \033[0m{}\033[92m(\033[37m{}\033[92m) Sincronizado ({}) !\033[0m".format(bot[1],bot[2],addr[1])
											
								else:

									print "\033[38;5;196m[ ! ] Error: Request invalido,desconectando bot...\033[0m"
									
					else:			
						if sock in SOCKET_LIST:
							
							print "\033[38;5;196m[ - ] \033[0m{}\033[38;5;196m(\033[37m{}\033[38;5;196m) Desconectou-se({}) !\033[0m".format(getNome(addr[1]),getClasse(addr[1]),addr[1])
							delBot(addr[1])
							SOCKET_LIST.remove(sock)
							
				except:

					print "\033[38;5;196m[ - ] \033[0m{}\033[38;5;196m(\033[37m{}\033[38;5;196m) Desconectou-se({}) !\033[0m".format(getNome(addr[1]),getClasse(addr[1]),addr[1])
					
					delBot(addr[1])
					if sock in SOCKET_LIST:
						SOCKET_LIST.remove(sock)
					
					continue
	server_socket.close()



def getNome(p):
	for x in BOT_LIST:
		if x[0] == p:		
			if len(x[1]) > 0 : 
				return x[1]
			else:
				return "???"

def getClasse(p):
	
	for x in BOT_LIST:
	
		if x[0] == p:	
			if len(x[2]) > 0 : 
				return x[2]
			else:
				return "???"

def dormir(ss,tempo,ba): #Ativa sleep dos bots
	
	for x in SOCKET_LIST:
		if x != ss and x != ba:
			try:
				x.send("!\x1F{}".format(tempo))
			except:
				x.close()
				if x in SOCKET_LIST:
					SOCKET_LIST.remove(x)		

def delBot(p): #Remove o bot da lista de bots
	for x in BOT_LIST:
		if x[0] == p:
			BOT_LIST.remove(x)
			
sys.exit(servidor())



