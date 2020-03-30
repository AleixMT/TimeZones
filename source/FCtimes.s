@;----------------------------------------------------------------
@;	Analista: Pere Millán
@;	Data:   Mar/2020       			Versió: 1.0
@;-----------------------------------------------------------------
@;	Nom fitxer: FCtimes.s
@;  Descripcio: implementació de les rutines per treballar amb 
@;				temps (hores, minuts, ...) i fusos horaris.
@;-----------------------------------------------------------------
@;   programador/a 1: pedro.espadas@estudiants.urv.cat
@;   programador/a 2: xxx.xxx@estudiants.urv.cat
@;   programador/a 3: xxx.xxx@estudiants.urv.cat
@; ----------------------------------------------------------------


@; Declaració de símbols per treballar amb màscares
@;
@; 			Camps: 0hhhhhmmmmmmsssssscccccccsffffqq

@;		MÀSCARES :

TIME_HOURS_MASK 	= 0b01111100000000000000000000000000
TIME_MINUTES_MASK	= 0b00000011111100000000000000000000
TIME_SECONDS_MASK	= 0b00000000000011111100000000000000
TIME_CENTSEC_MASK	= 0b00000000000000000011111110000000
TIME_TIMEZONE_MASK	= 0b00000000000000000000000001111111

TIMEZONE_SIGN_MASK	= 0b00000000000000000000000001000000
TIMEZONE_HOURS_MASK = 0b00000000000000000000000000111100
TIMEZONE_QUARTS_MASK= 0b00000000000000000000000000000011


@;		POSICIÓ DE BITS INICIAL/LSB I FINAL/MSB :

TIME_HOURS_MSB 		= 30
TIME_HOURS_LSB 		= 26
TIME_MINUTES_MSB	= 25
TIME_MINUTES_LSB	= 20
TIME_SECONDS_MSB	= 19
TIME_SECONDS_LSB	= 14
TIME_CENTSEC_MSB	= 13
TIME_CENTSEC_LSB	=  7
TIME_TIMEZONE_MSB	=  6
TIME_TIMEZONE_LSB	=  0

TIMEZONE_SIGN_MSB	= 6
TIMEZONE_SIGN_LSB	= 6
TIMEZONE_HOURS_MSB 	= 5
TIMEZONE_HOURS_LSB 	= 2
TIMEZONE_QUARTS_MSB	= 1
TIMEZONE_QUARTS_LSB	= 0



@;-- .text. codi de les rutinas ---
.text	
		.align 2
		.arm


@; ========================================================
@;   Crear valors a partir dels seus components
@; ========================================================

@; fc_time create_UTC_time ( u8 hores, u8 minuts, u8 segons, u8 centseg ) :
@;	  Crea un fc_time amb fus horari +00:00
@;	  (els paràmetres massa grans, queden amb valor vàlid màxim)
@;  Paràmetres:
@;      R0: hores (rang vàlid: 0-23)
@;      R1: minuts (rang vàlid: 0-59)
@;      R2: segons (rang vàlid: 0-59)
@;      R3: centèsimes de segon (rang vàlid: 0-99)
@;	Resultat:
@;		R0: valor fc_time amb els camps inicialitzats segons paràmetres
		.global create_UTC_time
create_UTC_time:
		push {r1-r12, lr}	@; guardar a pila possibles registres modificats 
		
		@; ==vvvvvvvv== INICI codi assemblador de la rutina ==vvvvvvvv==
		
		@; Ajustat de valors
		cmp r0, #23
		movhi r0, #23  @; Si hores > 23 , hores = 23
		
		cmp r1, #59  
		movhi r1, #59  @; Si minuts > 59, minuts = 59
		
		cmp r2, #59
		movhi r2, #59  @; Si segons > 59, segons = 59
		
		cmp r3, #99
		movhi r3, #99  @; Si centessimes > 99, centessimes = 99
		
		@; Creació del valor de retorn sobre r0
		
		@; 	Moviment  a les pos adequades
		mov r0, r0, lsl #TIME_HOURS_LSB
		mov r1, r1, lsl #TIME_MINUTES_LSB
		mov r2, r2, lsl #TIME_SECONDS_LSB
		mov r3, r3, lsl #TIME_CENTSEC_LSB
		
		@; Moure tot a r0, on ja hi tenim les hores
		orr r0, r0, r1  @; minuts
		orr r0, r0, r2  @; segons
		orr r0, r0, r3  @; centessimes
		
		@; No té sentit fer allodel C amb la zona horario ja que es un 0 i ja 
		@; se suposa que hi ha un 0 implicitament al rebre els registres
		
		@; ==^^^^^^^^== FINAL codi assemblador de la rutina ==^^^^^^^^==

		pop {r1-r12, pc}	@; recuperar de pila registres modificats i retornar


@; -------------------------------------------------------- 


@; fc_timezone create_timezone ( bool fusPositiu, u8 hores, u8 quartsHora ) :
@;	  Crea un fus horari en format 1:4:2 amb els valors donats
@;	  (els paràmetres massa grans, queden amb valor vàlid màxim)
@;  Paràmetres:
@;      R0: fusPositiu (1: positiu, 0: negatiu)  ATENCIO AIXO ES CONTRADICTORI AMB EL PPT, MANTENIM COHERENCIA AMB CODI C:
@;      R1: hores (rang vàlid: 0..12/14)
@;      R2: quartsHora (rang vàlid: 0-3)
@;	Resultat:
@;		R0: valor fc_timezone amb els camps inicialitzats segons paràmetres
		.global create_timezone
create_timezone:
		push {r1-r12, lr}	@; guardar a pila possibles registres modificats 
		
		@; ==vvvvvvvv== INICI codi assemblador de la rutina ==vvvvvvvv==
		
		@; Ajustem valors del fus (1 o 0)
		cmp r0, #0
		movhi r0, #1  @; Si ens passen fus més de 0 fixem a 1 (ens mengem una ins extra per a quan fus = 1)
		
		@; Aprofitem cmp anterior per començar aprocessar hores en relacio al fus horari
		beq .LFusNegatiu
		@; FusPositiu
		cmp r1, #14
		movhi r1, #14  @; Si fus positiu && hores > 14, hores = 14
		movhi r2, #0  @; Si fus positiu && hores > 14, quarts = 0
		b .LFinalAjustarFus  @; Sortim d'aqui sino ens mengem el else
		.LFusNegatiu:
		cmp r1, #12
		movhi r1, #12  @; Si fus negatiu && hores > 12, hores = 12
		movhi r2, #0  @; Si fus negatiu && hores > 12, quarts = 0
		
		.LFinalAjustarFus:
		@; Ajustem quarts d'hora
		cmp r2, #3
		movhi r2, #3  @; Si mes de 3 quarts d'hora fixem a 3
		
		@; El signe ja esta generat, no cal fer lo del C
		
		@; 	Moviment  a les pos adequades
		mov r0, r0, lsl #TIMEZONE_SIGN_LSB
		mov r1, r1, lsl #TIMEZONE_HOURS_LSB
		mov r2, r2, lsl #TIMEZONE_QUARTS_LSB
		
		@; Moure tot a r0, on ja hi tenim el signe
		orr r0, r0, r1
		orr r0, r0, r2

		@; ==^^^^^^^^== FINAL codi assemblador de la rutina ==^^^^^^^^==

		pop {r1-r12, pc}	@; recuperar de pila registres modificats i retornar


@; -------------------------------------------------------- 


@; fc_time create_local_time ( u8 hores, u8 minuts, u8 segons, fc_timezone fusHorari ) :
@;	  Crea un fc_time amb els valors indicats i 0 centèsimes de segon
@;	  (els paràmetres massa grans, queden amb valor vàlid màxim)
@;  Paràmetres:
@;      R0: hores (rang vàlid: 0-23)
@;      R1: minuts (rang vàlid: 0-59)
@;      R2: segons (rang vàlid: 0-59)
@;      R3: fusHorari (suposarem que té rang vàlid)
@;	Resultat:
@;		R0: valor fc_time amb els camps inicialitzats segons paràmetres
		.global create_local_time
create_local_time:
		push {r1-r12, lr}	@; guardar a pila possibles registres modificats 
		
		@; ==vvvvvvvv== INICI codi assemblador de la rutina ==vvvvvvvv==

		@; Ajustat de valors
		cmp r0, #23
		movhi r0, #23  @; Si hores > 23 , hores = 23
		
		cmp r1, #59  
		movhi r1, #59  @; Si minuts > 59, minuts = 59
		
		cmp r2, #59
		movhi r2, #59  @; Si segons > 59, segons = 59
		
		@; 	Moviment  a les pos adequades
		mov r0, r0, lsl #TIME_HOURS_LSB
		mov r1, r1, lsl #TIME_MINUTES_LSB
		mov r2, r2, lsl #TIME_SECONDS_LSB
		mov r3, r3, lsl #TIME_TIMEZONE_LSB
		
		@; Limitar bits del fus horari
		@; fusHorari = ((( fusHorari << TIME_TIMEZONE_LSB ) & TIME_TIMEZONE_MASK ) >> TIME_TIMEZONE_LSB );  --> Desplacem, apliquem mask, desfem desplaçat
		@; No cal desfer el desplaçat, aixi ja el tenim per a quan construim els valors de retorn
		and r3, r3, #TIME_TIMEZONE_MASK  @; Apliquem máscara per limitar bits
		
		@; Moure tot a r0, on ja hi tenim les hores
		orr r0, r0, r1  @; minuts
		orr r0, r0, r2  @; segons
		orr r0, r0, r3  @; fus horari

		@; No fare lo del 0 del C perque no li veig el sentit, ja que estem dins un or per tant no fa re
		
		@; ==^^^^^^^^== FINAL codi assemblador de la rutina ==^^^^^^^^==

		pop {r1-r12, pc}	@; recuperar de pila registres modificats i retornar



@; ========================================================
@;   Rutines de consulta de valors de camps
@; ========================================================

@; u8 get_hours ( fc_time temps_complet ) :
@;	  Retorna el valor del camp 'hores' del fc_time indicat
@;  Paràmetres:
@;      R0: valor fc_time
@;	Resultat:
@;		R0: valor del camp 'hores' del fc_time indicat
		.global get_hours
get_hours:
		push {r1-r12, lr}	@; guardar a pila possibles registres modificats 
		
		@; ==vvvvvvvv== INICI codi assemblador de la rutina ==vvvvvvvv==
		
		and r0, r0, #TIME_HOURS_MASK  @; Apliquem mascara
		mov r0, r0, lsr #TIME_HOURS_LSB  @; movem bits per a retornar unicament el valor demanat sense 0s pel mig

		@; ==^^^^^^^^== FINAL codi assemblador de la rutina ==^^^^^^^^==

		pop {r1-r12, pc}	@; recuperar de pila registres modificats i retornar


@; -------------------------------------------------------- 


@; u8 get_minutes ( fc_time temps_complet ) :
@;	  Retorna el valor del camp 'minuts' del fc_time indicat
@;  Paràmetres:
@;      R0: valor fc_time
@;	Resultat:
@;		R0: valor del camp 'minuts' del fc_time indicat
		.global get_minutes
get_minutes:
		push {r1-r12, lr}	@; guardar a pila possibles registres modificats 
		
		@; ==vvvvvvvv== INICI codi assemblador de la rutina ==vvvvvvvv==

		and r0, r0, #TIME_MINUTES_MASK  @; Apliquem mascara
		mov r0, r0, lsr #TIME_MINUTES_LSB  @; movem bits per a retornar unicament el valor demanat sense 0s pel mig

		@; ==^^^^^^^^== FINAL codi assemblador de la rutina ==^^^^^^^^==

		pop {r1-r12, pc}	@; recuperar de pila registres modificats i retornar


@; -------------------------------------------------------- 


@; u8 get_seconds ( fc_time temps_complet ) :
@;	  Retorna el valor del camp 'segons' del fc_time indicat
@;  Paràmetres:
@;      R0: valor fc_time
@;	Resultat:
@;		R0: valor del camp 'segons' del fc_time indicat
		.global get_seconds
get_seconds:
		push {r1-r12, lr}	@; guardar a pila possibles registres modificats 
		
		@; ==vvvvvvvv== INICI codi assemblador de la rutina ==vvvvvvvv==

		and r0, r0, #TIME_SECONDS_MASK  @; Apliquem mascara
		mov r0, r0, lsr #TIME_SECONDS_LSB  @; movem bits per a retornar unicament el valor demanat sense 0s pel mig

		@; ==^^^^^^^^== FINAL codi assemblador de la rutina ==^^^^^^^^==

		pop {r1-r12, pc}	@; recuperar de pila registres modificats i retornar


@; -------------------------------------------------------- 


@; u8 get_cents ( fc_time temps_complet ) :
@;	  Retorna el valor del camp 'centèsimes_segon' del fc_time indicat
@;  Paràmetres:
@;      R0: valor fc_time
@;	Resultat:
@;		R0: valor del camp 'centèsimes_segon' del fc_time indicat
		.global get_cents
get_cents:
		push {r1-r12, lr}	@; guardar a pila possibles registres modificats 
		
		@; ==vvvvvvvv== INICI codi assemblador de la rutina ==vvvvvvvv==

		and r0, r0, #TIME_CENTSEC_MASK  @; Apliquem mascara
		mov r0, r0, lsr #TIME_CENTSEC_LSB  @; movem bits per a retornar unicament el valor demanat sense 0s pel mig

		@; ==^^^^^^^^== FINAL codi assemblador de la rutina ==^^^^^^^^==

		pop {r1-r12, pc}	@; recuperar de pila registres modificats i retornar


@; -------------------------------------------------------- 


@; fc_timezone get_timezone ( fc_time temps_complet ) :
@;	  Retorna el fus horari complet contingut al fc_time indicat
@;  Paràmetres:
@;      R0: valor fc_time
@;	Resultat:
@;		R0: valor del fus horari complet contingut al fc_time indicat
		.global get_timezone
get_timezone:
		push {r1-r12, lr}	@; guardar a pila possibles registres modificats 
		
		@; ==vvvvvvvv== INICI codi assemblador de la rutina ==vvvvvvvv==

		and r0, r0, #TIME_TIMEZONE_MASK  @; Apliquem mascara
		mov r0, r0, lsr #TIME_TIMEZONE_LSB  @; movem bits per a retornar unicament el valor demanat sense 0s pel mig

		@; ==^^^^^^^^== FINAL codi assemblador de la rutina ==^^^^^^^^==

		pop {r1-r12, pc}	@; recuperar de pila registres modificats i retornar


@; -------------------------------------------------------- 


@; bool is_timezone_positive ( fc_timezone fusHorari ) :
@;	  Retorna true (1) si el fus horari indicat és positiu, o 0 en cas contrari
@;  Paràmetres:
@;      R0: valor fc_timezone
@;	Resultat:
@;		R0: 1 si el fus horari indicat és positiu; 0 altrament
		.global is_timezone_positive
is_timezone_positive:
		push {r1-r12, lr}	@; guardar a pila possibles registres modificats 
		
		@; ==vvvvvvvv== INICI codi assemblador de la rutina ==vvvvvvvv==


		@; ==^^^^^^^^== FINAL codi assemblador de la rutina ==^^^^^^^^==

		pop {r1-r12, pc}	@; recuperar de pila registres modificats i retornar


@; -------------------------------------------------------- 


@; u8 get_timezone_hours ( fc_timezone fusHorari ) :
@;	  Retorna el valor del camp 'hores' del fc_timezone indicat
@;  Paràmetres:
@;      R0: valor fc_timezone
@;	Resultat:
@;		R0: valor del camp 'centèsimes_segon' del fc_timezone indicat
		.global get_timezone_hours
get_timezone_hours:
		push {r1-r12, lr}	@; guardar a pila possibles registres modificats 
		
		@; ==vvvvvvvv== INICI codi assemblador de la rutina ==vvvvvvvv==


		@; ==^^^^^^^^== FINAL codi assemblador de la rutina ==^^^^^^^^==

		pop {r1-r12, pc}	@; recuperar de pila registres modificats i retornar


@; -------------------------------------------------------- 


@; u8 get_timezone_minutes ( fc_timezone fusHorari ) :
@;	  Retorna el número de minuts (0, 15, 30, 45) del fc_timezone indicat
@;  Paràmetres:
@;      R0: valor fc_timezone
@;	Resultat:
@;		R0: valor del número de minuts (0, 15, 30, 45) del fc_timezone indicat
		.global get_timezone_minutes
get_timezone_minutes:
		push {r1-r12, lr}	@; guardar a pila possibles registres modificats 
		
		@; ==vvvvvvvv== INICI codi assemblador de la rutina ==vvvvvvvv==


		@; ==^^^^^^^^== FINAL codi assemblador de la rutina ==^^^^^^^^==

		pop {r1-r12, pc}	@; recuperar de pila registres modificats i retornar


@; =============================================================
@;   Rutina per passar d'hora/temps local a hora/temps UTC
@; =============================================================


@; fc_time local_to_UTC_time ( fc_time localTime, s8 *dayOffset ) :
@;	  Converteix localTime (se suposa que amb fus!=UTC)
@;		a hora UTC (amb fus horari +00:00).
@;		dayOffset és un valor de sortida, per si amb el canvi d'hora
@;		cal passar al dia anterior (-1), posterior (+1) o l'actual (0).
@;  Paràmetres:
@;      R0: valor fc_time
@;		R1: adreça de memòria (referència) on guardar el valor de dayOffset
@;	Resultat:
@;		R0: valor fc_time de l'hora UTC corresponent a l'hora local indicada
@;		A l'adreça [R1] s'escriurà el valor de dayOffset en Ca2 (-1, 0, +1)
		.global local_to_UTC_time
local_to_UTC_time:
		push {r1-r12, lr}	@; guardar a pila possibles registres modificats 

		push {r1}		@; guardar @dayOffset

		@; ==vvvvvvvv== INICI codi assemblador de la rutina ==vvvvvvvv==
		
		
			@; IMPORTANT: cal desar a R12 el valor de dayOffset (-1, 0, +1)
		@; ==^^^^^^^^== FINAL codi assemblador de la rutina ==^^^^^^^^==

		pop {r11}			@; recuperar adreça de dayOffset
		strb r12, [r11]		@; escriure el valor de dayOffset a l'adreça indicada

		pop {r1-r12, pc}	@; recuperar de pila registres modificats i retornar



.end
