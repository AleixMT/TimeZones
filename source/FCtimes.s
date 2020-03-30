@;----------------------------------------------------------------
@;	Analista: Pere Mill�n
@;	Data:   Mar/2020       			Versi�: 1.0
@;-----------------------------------------------------------------
@;	Nom fitxer: FCtimes.s
@;  Descripcio: implementaci� de les rutines per treballar amb 
@;				temps (hores, minuts, ...) i fusos horaris.
@;-----------------------------------------------------------------
@;   programador/a 1: pedro.espadas@estudiants.urv.cat
@;   programador/a 2: xxx.xxx@estudiants.urv.cat
@;   programador/a 3: xxx.xxx@estudiants.urv.cat
@; ----------------------------------------------------------------


@; Declaraci� de s�mbols per treballar amb m�scares
@;
@; 			Camps: 0hhhhhmmmmmmsssssscccccccsffffqq

@;		M�SCARES :

TIME_HOURS_MASK 	= 0b01111100000000000000000000000000
TIME_MINUTES_MASK	= 0b00000011111100000000000000000000
TIME_SECONDS_MASK	= 0b00000000000011111100000000000000
TIME_CENTSEC_MASK	= 0b00000000000000000011111110000000
TIME_TIMEZONE_MASK	= 0b00000000000000000000000001111111

TIMEZONE_SIGN_MASK	= 0b00000000000000000000000001000000
TIMEZONE_HOURS_MASK = 0b00000000000000000000000000111100
TIMEZONE_QUARTS_MASK= 0b00000000000000000000000000000011


@;		POSICI� DE BITS INICIAL/LSB I FINAL/MSB :

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
@;	  (els par�metres massa grans, queden amb valor v�lid m�xim)
@;  Par�metres:
@;      R0: hores (rang v�lid: 0-23)
@;      R1: minuts (rang v�lid: 0-59)
@;      R2: segons (rang v�lid: 0-59)
@;      R3: cent�simes de segon (rang v�lid: 0-99)
@;	Resultat:
@;		R0: valor fc_time amb els camps inicialitzats segons par�metres
@; CHECKED
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
		
		@; Creaci� del valor de retorn sobre r0
		
		@; 	Moviment  a les pos adequades
		mov r0, r0, lsl #TIME_HOURS_LSB
		mov r1, r1, lsl #TIME_MINUTES_LSB
		mov r2, r2, lsl #TIME_SECONDS_LSB
		mov r3, r3, lsl #TIME_CENTSEC_LSB
		
		@; Acumular tot a r0, on ja hi tenim les hores
		orr r0, r0, r1  @; minuts
		orr r0, r0, r2  @; segons
		orr r0, r0, r3  @; centessimes
		
		@; No t� sentit fer lo del C amb la zona horario ja que es un 0 i ja 
		@; se suposa que hi ha un 0 implicitament al rebre els registres
		
		@; ==^^^^^^^^== FINAL codi assemblador de la rutina ==^^^^^^^^==

		pop {r1-r12, pc}	@; recuperar de pila registres modificats i retornar


@; -------------------------------------------------------- 


@; fc_timezone create_timezone ( bool fusPositiu, u8 hores, u8 quartsHora ) :
@;	  Crea un fus horari en format 1:4:2 amb els valors donats
@;	  (els par�metres massa grans, queden amb valor v�lid m�xim)
@;  Par�metres:
@;      R0: fusPositiu (1: positiu, 0: negatiu)  ATENCIO AIXO ES CONTRADICTORI AMB EL PPT, MANTENIM COHERENCIA AMB CODI C:
@;      R1: hores (rang v�lid: 0..12/14)
@;      R2: quartsHora (rang v�lid: 0-3)
@;	Resultat:
@;		R0: valor fc_timezone amb els camps inicialitzats segons par�metres
		.global create_timezone
create_timezone:
		push {r1-r12, lr}	@; guardar a pila possibles registres modificats 
		
		@; ==vvvvvvvv== INICI codi assemblador de la rutina ==vvvvvvvv==

		@; Ajustem valors del fus (1 o 0)
		cmp r0, #0
		movhi r0, #0  @; Si ens passen fus m�s de 0 fixem a 0 (ens mengem una ins extra per a quan fus = 1)
		moveq r0, #1  @; sino fixem a 1
		
		@; Aprofitem cmp anterior per comen�ar aprocessar hores en relacio al fus horari
		beq .LFusNegatiu
		@; FusPositiu
		cmp r1, #14
		movhi r1, #14  @; Si fus positiu && hores > 14, hores = 14
		movhi r2, #0  @; Si fus positiu && hores > 14, quarts = 0
		b .LFinalAjustarFus
		
		.LFusNegatiu:
		cmp r1, #12
		movhi r1, #12  @; Si fus negatiu && hores > 12, hores = 12
		movhi r2, #0  @; Si fus negatiu && hores > 12, quarts = 0
		
		.LFinalAjustarFus:
		@; Ajustem quarts d'hora
		cmp r2, #3
		movhi r2, #3  @; Si mes de 3 quarts d'hora fixem a 3
		
		@; Generar signe (es pot fer molt mes optim)
		@;cmp r0, #0
		@;moveq r0, #1
		@;movne r0, #0
		
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
@;	  Crea un fc_time amb els valors indicats i 0 cent�simes de segon
@;	  (els par�metres massa grans, queden amb valor v�lid m�xim)
@;  Par�metres:
@;      R0: hores (rang v�lid: 0-23)
@;      R1: minuts (rang v�lid: 0-59)
@;      R2: segons (rang v�lid: 0-59)
@;      R3: fusHorari (suposarem que t� rang v�lid)
@;	Resultat:
@;		R0: valor fc_time amb els camps inicialitzats segons par�metres
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
		@; fusHorari = ((( fusHorari << TIME_TIMEZONE_LSB ) & TIME_TIMEZONE_MASK ) >> TIME_TIMEZONE_LSB );  --> Desplacem, apliquem mask, desfem despla�at
		@; No cal desfer el despla�at, aixi ja el tenim per a quan construim els valors de retorn
		and r3, r3, #TIME_TIMEZONE_MASK  @; Apliquem m�scara per limitar bits
		
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
@;  Par�metres:
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
@;  Par�metres:
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
@;  Par�metres:
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
@;	  Retorna el valor del camp 'cent�simes_segon' del fc_time indicat
@;  Par�metres:
@;      R0: valor fc_time
@;	Resultat:
@;		R0: valor del camp 'cent�simes_segon' del fc_time indicat
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
@;  Par�metres:
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
@;	  Retorna true (1) si el fus horari indicat �s positiu, o 0 en cas contrari
@;  Par�metres:
@;      R0: valor fc_timezone
@;	Resultat:
@;		R0: 1 si el fus horari indicat �s positiu; 0 altrament  @; kkao
		.global is_timezone_positive
is_timezone_positive:
		push {r1-r12, lr}	@; guardar a pila possibles registres modificats 
		
		@; ==vvvvvvvv== INICI codi assemblador de la rutina ==vvvvvvvv==

		and r0, r0, #TIMEZONE_SIGN_MASK  @; Apliquem mascara
		mov r0, r0, lsr #TIMEZONE_SIGN_LSB  @; movem bits per a retornar unicament el valor demanat sense 0s pel mig
		
		@; Neguem bit (es pot fer de forma moltissim mes optima)
		cmp r0, #0
		moveq r0, #1
		movne r0, #0  
		@; El valor a r0 sera sempre o 1 o 0

		@; ==^^^^^^^^== FINAL codi assemblador de la rutina ==^^^^^^^^==

		pop {r1-r12, pc}	@; recuperar de pila registres modificats i retornar


@; -------------------------------------------------------- 


@; u8 get_timezone_hours ( fc_timezone fusHorari ) :
@;	  Retorna el valor del camp 'hores' del fc_timezone indicat
@;  Par�metres:
@;      R0: valor fc_timezone
@;	Resultat:
@;		R0: valor del camp 'cent�simes_segon' del fc_timezone indicat
		.global get_timezone_hours
get_timezone_hours:
		push {r1-r12, lr}	@; guardar a pila possibles registres modificats 
		
		@; ==vvvvvvvv== INICI codi assemblador de la rutina ==vvvvvvvv==

		and r0, r0, #TIMEZONE_HOURS_MASK  @; Apliquem mascara
		mov r0, r0, lsr #TIMEZONE_HOURS_LSB  @; movem bits per a retornar unicament el valor demanat sense 0s pel mig

		@; ==^^^^^^^^== FINAL codi assemblador de la rutina ==^^^^^^^^==

		pop {r1-r12, pc}	@; recuperar de pila registres modificats i retornar


@; -------------------------------------------------------- 


@; u8 get_timezone_minutes ( fc_timezone fusHorari ) :
@;	  Retorna el n�mero de minuts (0, 15, 30, 45) del fc_timezone indicat
@;  Par�metres:
@;      R0: valor fc_timezone
@;	Resultat:
@;		R0: valor del n�mero de minuts (0, 15, 30, 45) del fc_timezone indicat
		.global get_timezone_minutes
get_timezone_minutes:
		push {r1-r12, lr}	@; guardar a pila possibles registres modificats 
		
		@; ==vvvvvvvv== INICI codi assemblador de la rutina ==vvvvvvvv==

		and r0, r0, #TIMEZONE_QUARTS_MASK  @; Apliquem mascara
		mov r0, r0, lsr #TIMEZONE_QUARTS_LSB  @; movem bits per a retornar unicament el valor demanat sense 0s pel mig
		mov r1, #15  @; Carreguem a registre per limitacions de la instrucci� mul
		mul r2, r0, r1  @; Multipliquem amb registre diferent per limitacio amb instruccio mul
		mov r0, r2  @; retornem valor

		@; ==^^^^^^^^== FINAL codi assemblador de la rutina ==^^^^^^^^==

		pop {r1-r12, pc}	@; recuperar de pila registres modificats i retornar


@; =============================================================
@;   Rutina per passar d'hora/temps local a hora/temps UTC
@; =============================================================


@; fc_time local_to_UTC_time ( fc_time localTime, s8 *dayOffset ) :
@;	  Converteix localTime (se suposa que amb fus!=UTC)
@;		a hora UTC (amb fus horari +00:00).
@;		dayOffset �s un valor de sortida, per si amb el canvi d'hora
@;		cal passar al dia anterior (-1), posterior (+1) o l'actual (0).
@;  Par�metres:
@;      R0: valor fc_time
@;		R1: adre�a de mem�ria (refer�ncia) on guardar el valor de dayOffset
@;	Resultat:
@;		R0: valor fc_time de l'hora UTC corresponent a l'hora local indicada
@;		A l'adre�a [R1] s'escriur� el valor de dayOffset en Ca2 (-1, 0, +1)
		.global local_to_UTC_time
local_to_UTC_time:
		push {r1-r12, lr}	@; guardar a pila possibles registres modificats 

		push {r1}		@; guardar @dayOffset

		@; ==vvvvvvvv== INICI codi assemblador de la rutina ==vvvvvvvv==
		
		@; Inicialitzem registre r12
		mov r12, #0
		
		@; Guardem segons i centessimes a la posicio correcta en un registre temporal
		and r10, r0, #TIME_SECONDS_MASK
		and r9, r0, #TIME_CENTSEC_MASK
		
		@; Obtenim Operands
		and r8, r0, #TIME_HOURS_MASK  @; Hora local
		mov r8, r8, lsr #TIME_HOURS_LSB
		
		and r7, r0, #TIME_MINUTES_MASK  @; Minuts Locals
		mov r7, r7, lsr #TIME_MINUTES_LSB
		
		and r6, r0, #TIMEZONE_HOURS_MASK  @; Hores fus
		mov r6, r6, lsr #TIMEZONE_HOURS_LSB
		
		and r5, r0, #TIMEZONE_QUARTS_MASK  @; Minuts fus
		mov r5, r5, lsr #TIMEZONE_QUARTS_LSB
		mov r1, #15  @; Carreguem a registre per limitaci� de la instrucci� mul
		mul r4, r5, r1  @; obtenim minuts a registre temporal per limitacio instruccio mul
		mov r5, r4  @; recoloquem registre
		
		and r4, r0, #TIMEZONE_SIGN_MASK  @; o 0 perque matem tots els bits, o un num raro diferent de 0 (1 no, perque el bit esta a una posicio diferent de la LSB)
		cmp r4, #0
		bne .LFusNegatiuLocal
		
		@; Fus Positiu
		sub r7, r7, r5  @; Nous minuts
		sub r8, r8, r6  @; Noves hores
		cmp r7, #0 
		addlt r7, r7, #60  @; lt perque treballem amb signed
		sublt r8, r8, #1   @; lt perque treballem amb signed
		cmp r8, #0
		addlt r8, r8, #24
		movlt r12, #-1  @; Carreguem un -1
		b .LFusFinal  @; Sortim d'aqui per a no fer el else
		
		.LFusNegatiuLocal:   @; ELSE
		add r7, r7, r5  @; Nous minuts
		add r8, r8, r6  @; Noves hores
		cmp r7, #59  
		subhi r7, r7, #60
		addhi r8, r8, #1
		cmp r8, #23
		subhi r8, r8, #24
		movhi r12, #1  @; Carreguem un 1
		
		.LFusFinal:
		@; r7: minuts
		@; r8: hores
		@; r9: centessimes (a la posicio correcta)
		@; r10: segons  (a la posicio correcta)
		@; Movem minuts i hores a la posicio que toca
		mov r7, r7, lsl #TIME_MINUTES_LSB
		mov r8, r8, lsl #TIME_HOURS_LSB
		
		@; Creem valor de retorn acumulant sobre r0
		mov r0, #0  @; Netegem r0
		orr r0, r0, r7
		orr r0, r0, r8
		orr r0, r0, r9
		orr r0, r0, r10
		@; IMPORTANT: cal desar a R12 el valor de dayOffset (-1, 0, +1)
		
		@; ==^^^^^^^^== FINAL codi assemblador de la rutina ==^^^^^^^^==

		pop {r11}			@; recuperar adre�a de dayOffset
		strb r12, [r11]		@; escriure el valor de dayOffset a l'adre�a indicada

		pop {r1-r12, pc}	@; recuperar de pila registres modificats i retornar



.end
