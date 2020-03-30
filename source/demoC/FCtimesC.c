/*----------------------------------------------------------------
|	Autor:	Pere Millán
|	Data:	Mar/2020       			Versió: 1.0
|-----------------------------------------------------------------|
|	Nom fitxer: FCtimesC.c
|   Descripcio: exemple d'implementació en C de les rutines per 
|			treballar amb temps (hores, ...) i fusos horaris.
|-----------------------------------------------------------------|
|   programador/a 1: pere.millan@urv.cat
| ----------------------------------------------------------------*/

#include "FCtimes.h"	/* declaració de tipus i rutines de temps */



/****************************************************/
/* Declaració de símbols per treballar amb màscares */
/*                                                  */
/*		Camps: 0hhhhhmmmmmmsssssscccccccsffffqq		*/
/****************************************************/

	/************/
	/* MÀSCARES */
	/************/

#define TIME_HOURS_MASK 	 0b01111100000000000000000000000000
#define TIME_MINUTES_MASK	 0b00000011111100000000000000000000
#define TIME_SECONDS_MASK	 0b00000000000011111100000000000000
#define TIME_CENTSEC_MASK	 0b00000000000000000011111110000000
#define TIME_TIMEZONE_MASK	 0b00000000000000000000000001111111

#define TIMEZONE_SIGN_MASK	 0b00000000000000000000000001000000
#define TIMEZONE_HOURS_MASK  0b00000000000000000000000000111100
#define TIMEZONE_QUARTS_MASK 0b00000000000000000000000000000011


	/*******************************************/
	/* POSICIÓ DE BITS INICIAL/LSB I FINAL/MSB */
	/*******************************************/

#define TIME_HOURS_MSB 		30
#define TIME_HOURS_LSB 		26
#define TIME_MINUTES_MSB	25
#define TIME_MINUTES_LSB	20
#define TIME_SECONDS_MSB	19
#define TIME_SECONDS_LSB	14
#define TIME_CENTSEC_MSB	13
#define TIME_CENTSEC_LSB	 7
#define TIME_TIMEZONE_MSB	 6
#define TIME_TIMEZONE_LSB	 0

#define TIMEZONE_SIGN_MSB	6
#define TIMEZONE_SIGN_LSB	6
#define TIMEZONE_HOURS_MSB 	5
#define TIMEZONE_HOURS_LSB 	2
#define TIMEZONE_QUARTS_MSB	1
#define TIMEZONE_QUARTS_LSB	0


/*********************/
/* RUTINES PÚBLIQUES */
/*********************/

	/* Crear valors a partir dels seus components */
		/* Si algun paràmetre/camp és massa gran, es posarà el màxim vàlid */

fc_time create_UTC_time ( u8 hores, u8 minuts, u8 segons, u8 centseg )
		/* Crea un fc_time amb fus horari +00:00 */
{
	fc_time resultat;
	u8 UTC0 = 0;	/* UTC+00:00 */

		/* Comprovar rangs */
	if (hores > 23) hores = 23;
	if (minuts > 59) minuts = 59;
	if (segons > 59) segons = 59;
	if (centseg > 99) centseg = 99;

		/* combinar camps fc_time */
	resultat = (hores << TIME_HOURS_LSB)
	         | (minuts << TIME_MINUTES_LSB)
			 | (segons << TIME_SECONDS_LSB)
			 | (centseg << TIME_CENTSEC_LSB)
			 | (UTC0 << TIME_TIMEZONE_LSB) 	/* No caldria afegir zeros*/
			 ;

	return resultat;
}

/* -------------------------------------------------------- */

fc_timezone create_timezone ( bool fusPositiu, u8 hores, u8 quartsHora )
		/* Crea un fus horari en format 1:4:2 amb els valors donats */
{
	fc_timezone resultat, signe;

		/* Comprovar rangs: UTC-12:00 ... UTC+14:00 */
	if ( fusPositiu && hores > 14 ) 
	{
		hores = 14;
		quartsHora = 0;
	}
	if ( !fusPositiu && hores > 12 ) 
	{
		hores = 12;
		quartsHora = 0;
	}
	
	if ( quartsHora > 3 )  
		quartsHora = 3;

	/* Generar signe: 0 positiu, 1 negatiu */
	if ( fusPositiu )
		signe = 0;
	else
		signe = 1;

		/* combinar camps fc_timezone */
	resultat = (signe << TIMEZONE_SIGN_LSB)
			 | (hores << TIMEZONE_HOURS_LSB)
	         | (quartsHora << TIMEZONE_QUARTS_LSB)
			 ;

	return resultat;
}

/* -------------------------------------------------------- */

fc_time create_local_time ( u8 hores, u8 minuts, u8 segons, fc_timezone fusHorari )
		/* Crea un fc_time amb els valors indicats i 0 centèsimes de segon */
{
	fc_time resultat;

		/* Comprovar rangs */
	if (hores > 23) hores = 23;
	if (minuts > 59) minuts = 59;
	if (segons > 59) segons = 59;

		/* Limitar bits del fus horari */
	fusHorari = ((( fusHorari << TIME_TIMEZONE_LSB )
				& TIME_TIMEZONE_MASK )
				>> TIME_TIMEZONE_LSB );

		/* combinar camps fc_time */
	resultat = (hores << TIME_HOURS_LSB)
	         | (minuts << TIME_MINUTES_LSB)
			 | (segons << TIME_SECONDS_LSB)
			 | (0 << TIME_CENTSEC_LSB)		/* No caldria afegir zeros*/
			 | (fusHorari << TIME_TIMEZONE_LSB) 	
			 ;

	return resultat;
}

/* -------------------------------------------------------- */

	/* rutines de consulta de valors de camps */
u8 get_hours ( fc_time temps_complet )
{
	u8 resultat;
	resultat = ( temps_complet & TIME_HOURS_MASK ) >> TIME_HOURS_LSB;
	return resultat;
}

/* -------------------------------------------------------- */

u8 get_minutes ( fc_time temps_complet )
{
	u8 resultat;
	resultat = ( temps_complet & TIME_MINUTES_MASK ) >> TIME_MINUTES_LSB;
	return resultat;
}


/* -------------------------------------------------------- */

u8 get_seconds ( fc_time temps_complet )
{
	u8 resultat;
	resultat = ( temps_complet & TIME_SECONDS_MASK ) >> TIME_SECONDS_LSB;
	return resultat;
}

/* -------------------------------------------------------- */

u8 get_cents ( fc_time temps_complet )
{
	u8 resultat;
	resultat = ( temps_complet & TIME_CENTSEC_MASK ) >> TIME_CENTSEC_LSB;
	return resultat;
}

/* -------------------------------------------------------- */

fc_timezone get_timezone ( fc_time temps_complet )
{
	fc_timezone resultat;
	resultat = ( temps_complet & TIME_TIMEZONE_MASK ) >> TIME_TIMEZONE_LSB;
	return resultat;
}


/* -------------------------------------------------------- */

bool is_timezone_positive ( fc_timezone fusHorari )
{
	bool resultat;
	resultat = ( (fusHorari & TIMEZONE_SIGN_MASK) == 0 );
	return resultat;
}


/* -------------------------------------------------------- */

u8 get_timezone_hours ( fc_timezone fusHorari)
{
	u8 resultat;
	resultat = ( fusHorari & TIMEZONE_HOURS_MASK ) >> TIMEZONE_HOURS_LSB;
	return resultat;
}


/* -------------------------------------------------------- */

u8 get_timezone_minutes (fc_timezone fusHorari)	/* 0, 15, 30 o 45 */
{
	u8 resultat;
	resultat = ( fusHorari & TIMEZONE_QUARTS_MASK ) >> TIMEZONE_QUARTS_LSB;
		/* convertir quarts 0/1/2/3 a minuts 0/15/30/45 */
	resultat = resultat * 15;
	return resultat;
}

/* -------------------------------------------------------- */

	/* Rutina per passar d'hora/temps local a hora/temps UTC */
fc_time local_to_UTC_time (fc_time localTime, s8 *dayOffset)
		/* Converteix localTime (se suposa que amb fus!=UTC)
			a hora UTC (amb fus horari +00:00).
			dayOffset és un valor de sortida, per si amb el canvi d'hora
			cal passar al dia anterior (-1), posterior (+1) o l'actual (0).
		*/
{
	s8 canviDia, novaHora, nousMinuts;
	u8 horaLocal, minutsLocals, horesFus, minutsFus;
	fc_time resultat_UTC;
	
		/* L'hora UTC tindrà els mateixos segons i centèsimes i Fus +00:00 */
	resultat_UTC = ( localTime & TIME_SECONDS_MASK ) 
				 | ( localTime & TIME_CENTSEC_MASK );
		/* Obtenir operands */
	canviDia = 0;	/* suposem que UTC està al mateix dia */
	horaLocal = ( localTime & TIME_HOURS_MASK ) >> TIME_HOURS_LSB;
	minutsLocals = ( localTime & TIME_MINUTES_MASK ) >> TIME_MINUTES_LSB;
	
	horesFus = ( localTime & TIMEZONE_HOURS_MASK ) >> TIMEZONE_HOURS_LSB;
	minutsFus = 15 * (( localTime & TIMEZONE_QUARTS_MASK ) >> TIMEZONE_QUARTS_LSB);
	
	if ( (localTime & TIMEZONE_SIGN_MASK) == 0 )
	{	/* Fus positiu, cal restar-lo */
		nousMinuts = ((s8)minutsLocals) - minutsFus;
		novaHora = ((s8)horaLocal) - horesFus;
		if (nousMinuts < 0)
		{
			nousMinuts = nousMinuts + 60;
			novaHora--;
		}
		if (novaHora < 0)
		{
			novaHora = novaHora + 24;
			canviDia = -1;
		}
	}
	else
	{	/* Fus negatiu, cal sumar-lo */
		nousMinuts = minutsLocals + minutsFus;
		novaHora = horaLocal + horesFus;
		if (nousMinuts > 59)
		{
			nousMinuts = nousMinuts - 60;
			novaHora++;
		}
		if (novaHora > 23)
		{
			novaHora = novaHora - 24;
			canviDia = +1;
		}
	}
	
		/* afegir hores i minuts */
	resultat_UTC = resultat_UTC	/* Ja conté segons, centèsimes i fus +00:00 */
				 | (novaHora << TIME_HOURS_LSB)
				 | (nousMinuts << TIME_MINUTES_LSB)
				 ;

	*dayOffset = canviDia;
	
	return resultat_UTC;
}




