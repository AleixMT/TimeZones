/*----------------------------------------------------------------
|	Autor: Pere Millán (DEIM, URV)
|	Data:  Març/2020       		Versió: 1.0
|-----------------------------------------------------------------|
|	Nom fitxer: jocproves_t.c
|   Descripcio: Codi en C d'un possible JOC DE PROVES
|               de les rutines de temps/fus horari (FCtimes.s).
|   Rutina a cridar: void test(void);
| ----------------------------------------------------------------*/

#include "FCtimes.h"	/* Declaracions de rutines dins de FCtimes.s */

#include "test_utils.h"	/* Rutines d'utilitat per a tests/jocs de proves */


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


	/***********************************************/
	/* Macros per crear valors fc_time/fc_timezone */
	/***********************************************/

#define MKT(h,m,s,c,tzs,tzh,tzq) ( \
		  ((((u32)(h))<<TIME_HOURS_LSB) & TIME_HOURS_MASK) \
		| ((((u32)(m))<<TIME_MINUTES_LSB) & TIME_MINUTES_MASK) \
		| ((((u32)(s))<<TIME_SECONDS_LSB) & TIME_SECONDS_MASK) \
		| ((((u32)(c))<<TIME_CENTSEC_LSB) & TIME_CENTSEC_MASK) \
		| ((((u32)(tzs))<<TIMEZONE_SIGN_LSB) & TIMEZONE_SIGN_MASK) \
		| ((((u32)(tzh))<<TIMEZONE_HOURS_LSB) & TIMEZONE_HOURS_MASK) \
		| ((((u32)(tzq))<<TIMEZONE_QUARTS_LSB) & TIMEZONE_QUARTS_MASK) \
	)

#define MKTZ(s,h,q) ( \
		  ((s<<TIMEZONE_SIGN_LSB) & TIMEZONE_SIGN_MASK) \
		| ((h<<TIMEZONE_HOURS_LSB) & TIMEZONE_HOURS_MASK) \
		| ((q<<TIMEZONE_QUARTS_LSB) & TIMEZONE_QUARTS_MASK) \
	)


/* ======================
   Proves rutines FCtimes
   ====================== */

/* Cada rutina de prova retorna un bool (true:ok; false:error) */

	/**************************/
	/* Proves create_UTC_time */
	/**************************/

bool prova_create_UTC_time_dins_rang()
{
	fc_time result = create_UTC_time(12, 34, 56, 78);
	fc_time esperat = MKT(12, 34, 56, 78, 0, 0, 0);
	return ( result == esperat );
}


bool prova_create_UTC_time_fora_rang()
{
	fc_time result = create_UTC_time(123, 123, 123, 123);
	fc_time esperat = MKT(23, 59, 59, 99, 0, 0, 0);
	return ( result == esperat );
}



	/**************************/
	/* Proves create_timezone */
	/**************************/

bool prova_create_timezone_positiu_dins_rang()
{
	fc_timezone result = create_timezone(true, 11, 1);
	fc_timezone esperat = MKTZ(0, 11, 1);
	return ( result == esperat );
}


bool prova_create_timezone_negatiu_dins_rang()
{
	fc_timezone result = create_timezone(false, 11, 1);
	fc_timezone esperat = MKTZ(1, 11, 1);
	return ( result == esperat );
}


bool prova_create_timezone_positiu_fora_rang()
{
	fc_timezone result = create_timezone(true, 23, 45);
	fc_timezone esperat = MKTZ(0, 14, 0);
	return ( result == esperat );
}


bool prova_create_timezone_negatiu_fora_rang()
{
	fc_timezone result = create_timezone(false, 23, 45);
	fc_timezone esperat = MKTZ(1, 12, 0);
	return ( result == esperat );
}



	/****************************/
	/* Proves create_local_time */
	/****************************/

bool prova_create_local_time_dins_rang()
{
	fc_time result = create_local_time(12, 34, 56, MKTZ(1, 2, 3) );
	fc_time esperat = MKT(12, 34, 56, 0, 1, 2, 3);
	return ( result == esperat );
}


bool prova_create_local_time_fora_rang()
{
	fc_time result = create_local_time(123, 123, 123, MKTZ(1, 2, 3) );
	fc_time esperat = MKT(23, 59, 59, 0, 1, 2, 3);
	return ( result == esperat );
}



	/********************/
	/* Proves get_hours */
	/********************/

bool prova_get_hours()
{
	u8 result = get_hours( MKT(12, 34, 56, 78, 1, 2, 3) );
	u8 esperat = 12;
	return ( result == esperat );
}



	/**********************/
	/* Proves get_minutes */
	/**********************/

bool prova_get_minutes()
{
	u8 result = get_minutes( MKT(12, 34, 56, 78, 1, 2, 3) );
	u8 esperat = 34;
	return ( result == esperat );
}



	/**********************/
	/* Proves get_seconds */
	/**********************/

bool prova_get_seconds()
{
	u8 result = get_seconds( MKT(12, 34, 56, 78, 1, 2, 3) );
	u8 esperat = 56;
	return ( result == esperat );
}



	/********************/
	/* Proves get_cents */
	/********************/

bool prova_get_cents()
{
	u8 result = get_cents( MKT(12, 34, 56, 78, 1, 2, 3) );
	u8 esperat = 78;
	return ( result == esperat );
}



	/***********************/
	/* Proves get_timezone */
	/***********************/

bool prova_get_timezone_positive()
{
	fc_timezone result = get_timezone( MKT(12, 34, 56, 78, 0, 1, 2) );
	fc_timezone esperat = MKTZ(0, 1, 2);
	return ( result == esperat );
}


bool prova_get_timezone_negative()
{
	fc_timezone result = get_timezone( MKT(12, 34, 56, 78, 1, 2, 3) );
	fc_timezone esperat = MKTZ(1, 2, 3);
	return ( result == esperat );
}



	/*******************************/
	/* Proves is_timezone_positive */
	/*******************************/

bool prova_is_timezone_positive_true()
{
	bool result = is_timezone_positive( MKTZ(0, 1, 2) );
	bool esperat = true;
	return ( result == esperat );
}


bool prova_is_timezone_positive_false()
{
	bool result = is_timezone_positive( MKTZ(1, 2, 3) );
	bool esperat = false;
	return ( result == esperat );
}



	/*****************************/
	/* Proves get_timezone_hours */
	/*****************************/

bool prova_get_timezone_hours_positive()
{
	u8 result = get_timezone_hours( MKTZ(0, 11, 2) );
	u8 esperat = 11;
	return ( result == esperat );
}


bool prova_get_timezone_hours_negative()
{
	u8 result = get_timezone_hours( MKTZ(1, 11, 3) );
	u8 esperat = 11;
	return ( result == esperat );
}



	/*******************************/
	/* Proves get_timezone_minutes */
	/*******************************/

bool prova_get_timezone_minutes_0()
{
	u8 result = get_timezone_minutes( MKTZ(1, 2, 0) );
	u8 esperat = 0;
	return ( result == esperat );
}


bool prova_get_timezone_minutes_15()
{
	u8 result = get_timezone_minutes( MKTZ(0, 0, 1) );
	u8 esperat = 15;
	return ( result == esperat );
}


bool prova_get_timezone_minutes_30()
{
	u8 result = get_timezone_minutes( MKTZ(0, 1, 2) );
	u8 esperat = 30;
	return ( result == esperat );
}


bool prova_get_timezone_minutes_45()
{
	u8 result = get_timezone_minutes( MKTZ(1, 2, 3) );
	u8 esperat = 45;
	return ( result == esperat );
}



	/****************************/
	/* Proves local_to_UTC_time */
	/****************************/

bool prova_local_to_UTC_time0()
{
	s8 dia;

	fc_time result = local_to_UTC_time( 
						MKT(12, 34, 56, 78, 1, 2, 3),
						&dia
			);
	fc_time esperat_time = MKT(15, 19, 56, 78, 0, 0, 0);
	s8 esperat_day = 0;
	return ( result == esperat_time && dia == esperat_day );
}


bool prova_local_to_UTC_time1()
{
	s8 dia;

	fc_time result = local_to_UTC_time( 
						MKT(21, 15, 56, 78, 0, 5, 3),
						&dia
			);
	fc_time esperat_time = MKT(15, 30, 56, 78, 0, 0, 0);
	s8 esperat_day = 0;
	return ( result == esperat_time && dia == esperat_day );
}


bool prova_local_to_UTC_time_diaAbans()
{
	s8 dia;

	fc_time result = local_to_UTC_time( 
						MKT(0, 10, 20, 30, 0, 0, 1),
						&dia
			);
	fc_time esperat_time = MKT(23, 55, 20, 30, 0, 0, 0);
	s8 esperat_day = -1;
	return ( result == esperat_time && dia == esperat_day );
}



bool prova_local_to_UTC_time_diaDespres()
{
	s8 dia;

	fc_time result = local_to_UTC_time( 
						MKT(23, 45, 30, 40, 1, 0, 2),
						&dia
			);
	fc_time esperat_time = MKT(0, 15, 30, 40, 0, 0, 0);
	s8 esperat_day = 1;
	return ( result == esperat_time && dia == esperat_day );
}






/**********************************************************/
/* "Empaquetar" cada prova individual en un joc de proves */
/**********************************************************/

functest jocDeProvesCreate[] = 
{
	/* Prova 0 */ prova_create_UTC_time_dins_rang,
	/* Prova 1 */ prova_create_UTC_time_fora_rang,
	/* Prova 2 */ prova_create_timezone_positiu_dins_rang,
	/* Prova 3 */ prova_create_timezone_negatiu_dins_rang,
	/* Prova 4 */ prova_create_timezone_positiu_fora_rang,
	/* Prova 5 */ prova_create_timezone_negatiu_fora_rang,
	/* Prova 6 */ prova_create_local_time_dins_rang,
	/* Prova 7 */ prova_create_local_time_fora_rang,
};


functest jocDeProvesGet[] = 
{
	/* Prova 0 */ prova_get_hours,
	/* Prova 1 */ prova_get_minutes,
	/* Prova 2 */ prova_get_seconds,
	/* Prova 3 */ prova_get_cents,
	/* Prova 4 */ prova_get_timezone_positive,
	/* Prova 5 */ prova_get_timezone_negative,
	/* Prova 6 */ prova_is_timezone_positive_true,
	/* Prova 7 */ prova_is_timezone_positive_false,
	/* Prova 8 */ prova_get_timezone_hours_positive,
	/* Prova 9 */ prova_get_timezone_hours_negative,
	/* Prova 10 */ prova_get_timezone_minutes_0,
	/* Prova 11 */ prova_get_timezone_minutes_15,
	/* Prova 12 */ prova_get_timezone_minutes_30,
	/* Prova 13 */ prova_get_timezone_minutes_45,
};


functest jocDeProvesLocalToUTC[] = 
{
	/* Prova 0 */ prova_local_to_UTC_time0,
	/* Prova 1 */ prova_local_to_UTC_time1,
	/* Prova 2 */ prova_local_to_UTC_time_diaAbans,
	/* Prova 3 */ prova_local_to_UTC_time_diaDespres,
};




u8 num_tests_ok_create, num_tests_ok_get, num_tests_ok_local2UTC;	/* comptar quants tests ok */
u32 quins_errors_create, quins_errors_get, quins_errors_local2UTC;	/* per marcar 1 bit per cada test amb error */

void test(void)		/* rutina que comprova tots els tests */
{
	verificarJocDeProves(jocDeProvesCreate, 8, &num_tests_ok_create, &quins_errors_create);
		/* Si tot va bé, num_tests_ok será 8 i quins_errors 0 */
		/* Si hi ha errors, num_tests_ok < 8 i quins_errors tindrà bits a 1 */

	verificarJocDeProves(jocDeProvesGet, 14, &num_tests_ok_get, &quins_errors_get);
		/* Si tot va bé, num_tests_ok será 14 i quins_errors 0 */
		/* Si hi ha errors, num_tests_ok < 14 i quins_errors tindrà bits a 1 */

	verificarJocDeProves(jocDeProvesLocalToUTC, 4, &num_tests_ok_local2UTC, &quins_errors_local2UTC);
		/* Si tot va bé, num_tests_ok será 4 i quins_errors 0 */
		/* Si hi ha errors, num_tests_ok < 4 i quins_errors tindrà bits a 1 */

}

