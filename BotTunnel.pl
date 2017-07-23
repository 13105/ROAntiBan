package BotTunnel;

use strict;
use Plugins;
use Actor;
use Globals;
use Utils;
use Misc qw/relog chatLog/;
use Translation qw/T TF/;
use Actor::Player;
use IO::Socket;
use bigint;
use Time::HiRes qw ( time );
use POSIX qw(strftime);
use Log qw/message error/;
use Data::Dumper;
our $path;


# 	antiMap sec_pri {
#		sleep 1		; 0 = Nao faz nada ; 1 = Dorme X segundos ; 2 = Fecha o jogo
#		sleepTime	; se sleep eq 1,Segundos
#		alert		; 1 = avisa outros bots  no tunel ; 0 =  Nao alerta
#

Plugins::register("BotTunnel","Plugin para se comunicar com outros bots via socket.",\&unload,\&reload);
my $hooks = Plugins::addHooks(
	#['packet_mapChange',\&on_map],
	['packet/sendMapLoaded',\&on_map],
	['mainLoop_pre', \&loop],
	['postloadfiles',\&csock],
	['in_game', \&identif],
	['avoidGM_talk',\&on_gm],
	);
#my $datadir = $Plugins::current_plugin_folder;

my $dormindo=0;	# Bots alteram essa flag;se 1 ,bots fazem o que seu sleep ordena
my @acorda;
my $tempo=0;
my $tunnel=0;
my $socket;
my $sync=0;
#my $mw;




sub unload {
	
	Plugins::delHook("AI_pre", $hooks);
}

sub reload {
	&unload;
}

sub identif {
	return if $config{"BotTunnel"}+0 <= 0;
	if (!$sync){
		print $socket "\x02\x13\x1F$char->{name}\x1F$jobs_lut{$char->{jobID}}\x03";
		$sync=1;
	}
}

sub cs_err {
	error("*** Nao foi possivel conectar-se ao servidor BotTunnel,finalizando Kore... ***\n");
	$quit=1;

}


sub csock { #conecta no servidor  ; conecta sock
		return if $config{"BotTunnel"}+0 <= 0 or $tunnel > 0;

		#relog 86400, 'SILENT';
		
		my $porta=10000;
		$porta=$config{"BotTunnelPort"}+0 if ($config{"BotTunnelPort"}+0 >= 0);

		message("Tentando conectar-se ao servidor BotTunnel na porta $porta..");

	$socket = IO::Socket::INET->new(
	   PeerAddr => 'localhost',
	   PeerPort => $porta,
	   Proto    => 'tcp',
	   Blocking => 0
	);
		#defined $socket or cs_err();
		
		
		print $socket "?" or cs_err();
		message('conexao com o servidor BotTunnel efetuada com sucesso !');
		$tunnel=1;
		
		
		
		
		
		
		#\x02\x11\x1F\x11\x1Fprontera\x1F3\x03
		#relog 0, 'SILENT';
	
}

sub on_gm{
	return if $config{"BotTunnel"}+0 <= 0;
	my (undef,$gm) = @_;
	$tempo = $config{avoidGM_reconnect}+0;
	#x11;x12;Nome_do_GM;TEMPO
	print $socket "\x02\x11\x1F\x12\x1F$gm->{name}\x1F$tempo\x03";
	
	return if $config{avoidGM_reconnect}+0 <= 0;
	dormir();
}
sub loop{
	
	my ($seg, $min, $hora,$dia,$mes) = localtime;

	my $t = time;
	my $xtempo = strftime "%S", localtime $t;
	$xtempo .= sprintf ".%03d", ($t-int($t))*1000;
	
	if ( $xtempo == 30.000 ){ # A cada 1 minuto verifica
		
			my $buff = $socket->getline();
			
			if (length($buff) >= 1){
				
				
				#print("Buffer : @dados[0]\n")
				#for (my $i=0;$i < length(@dados);$i++)
					#@dados[0] eq ""
					#dormir();
				
				my @cbuff = split("\x1F", $buff);
				if ($cbuff[0] eq "!"){ # Verifica se existem alertas
					$tempo = $cbuff[1];
					

					dormir();
					error ("***  Alerta anti-bot recebida.  ***\nAcordarei dia $acorda[3] As $acorda[2]:$acorda[1]:$acorda[0] do Mes $acorda[4]\n");
					
				}
			}
	}
	
	if ($dormindo){

		
		

			
			
			
			if ($mes+1 >= $acorda[4] && $dia >= $acorda[3] && $hora >= $acorda[2] && $min >= $acorda[1] && $seg >= $acorda[0]){  # SE $AGORA >= $TEMPO_ACORDAR : ACORDA()
				message("Acordei !, Voltando a processar atividades...\n");

				$dormindo=0;
				relog 1, 'SILENT';
			}else{

				if ($net && $net->getState != Network::NOT_CONNECTED) {  #se ainda conectado,dc 
					relog $tempo, 'SILENT'; #DC POR 1 DIA;EVITAR BUGS
				}

			}



	}

	#message("Hora : $hora \- $acorda[2] \| Minutos : $min \- $acorda[1] \| Segundos: $seg \- \n");
	
	
}


sub dormir {	#ATIVADO POR CALL_DORMIR;	0 = N_ALERTAR    1 = ALERTAR
	
	if (!$dormindo){

		#$Seg $min $horas $Dias
		($acorda[0],$acorda[1],$acorda[2],$acorda[3],$acorda[4], undef, undef) = localtime;
		$acorda[4]+=1;
		$acorda[0] += $tempo; #1 DIA
		
		#$acorda[0] += 30;
		#Calendario cristao
		while ($acorda[0] >= 60){$acorda[0]-=60;$acorda[1]+=1;}	#Formata Minutos
		while ($acorda[1] >= 60){$acorda[1]-=60;$acorda[2]+=1;}  #Formata Horas
		while ($acorda[2] >= 24){$acorda[2]-=24;$acorda[3]+=1;}  #Formata Dias
		
		while ($acorda[3] >= 28){ 
			if($acorda[4]+1 == 2){ #28 fev;2419200
				$acorda[3]=1;
				$acorda[4]+=1;
			}elsif($acorda[4] == 4 || $acorda[4] == 6 || $acorda[4] == 9 || $acorda[4] == 11){ # 30 abril,junho,setembro,novembro;2592000
				$acorda[3]=1;
				$acorda[4]+=1;
			}else{ #outros,max = 31
				$acorda[3]=1;
				$acorda[4]+=1;
			}


		}  #Formata Meses

		print $socket "\x02\x12\x1F$acorda[0]\x1F$acorda[1]\x1F$acorda[2]\x1F$acorda[3]\x1F$acorda[4]\x03";
		$dormindo=1; #inicia loop verificador

		
		 #{ x12;seg;min;hora;dia;mes;alerta }
		
		#print $socket "\x02\x11\x1F\x11\x1Fprontera\x1F\x00\x03";
		
		

	}


	
}



sub on_map {
	#my ($self, $args) = @_;
	my $i = 0;
	
	while (exists $config{"antiMap_".$i}) {
		

		if($field->{name} eq $config{"antiMap_".$i}){
			
				
				

				if ( $config{"antiMap_".$i."_sleep"}+0 eq 1 ){

					

					$tempo = $config{"antiMap_".$i."_sleepTime"}+0;

					if ($config{"antiMap_".$i."_alert"}+0){
						print $socket "\x02\x11\x1F\x11\x1F$config{\"antiMap_\".$i}\x1F\x01\x1F$tempo\x03";
					}else{
						print $socket "\x02\x11\x1F\x11\x1F$config{\"antiMap_\".$i}\x1F\x00\x03";
					}

					dormir();
					error ("***  Teleportado para $config{\"antiMap_\".$i}, Dormindo...  ***\nAcordarei dia $acorda[3] As $acorda[2]:$acorda[1]:$acorda[0] do Mes $acorda[4]\n");

				}elsif ( $config{"antiMap_".$i."_sleep"}+0 >= 2 ){					

					error ("***  Teleportado para $config{\"antiMap_\".$i}, desconectando para evitar ban ***\n");
					$quit = 1;
					
				}

			
			
			

			
		}

		$i++;

	
	}

	
	
   
	
	
}






1;