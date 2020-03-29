/*----------------------------------------------------------------
|	Autor: Pere Mill�n (DEIM, URV)
|	Data:  Mar� 2020					Versi�: 1.1
|-----------------------------------------------------------------|
|	Nom fitxer: FCtimes.h
|   Descripci�: declaraci� de tipus i rutines per treballar 
|			    amb temps (hores, minuts, ...) i zones hor�ries.
| ----------------------------------------------------------------*/

#ifndef FCTIMES_H
#define FCTIMES_H

#include "FCtypes.h"	/* u8, s8, u32, bool ... */


	/* declaraci� dels tipus fc_time i fc_timezone */
typedef u32 fc_time;		/* hh:mm:ss,cc i fus horari */
typedef u8  fc_timezone;	/* fus horari, coma fixa 1:4:2 */

	/* rutines a desenvolupar/disponibles (quan s'implementin) */

	/* Crear valors a partir dels seus components */
		/* Si algun par�metre/camp �s massa gran, es posar� el m�xim v�lid */

extern fc_time create_UTC_time ( u8 hores, u8 minuts, u8 segons, u8 centseg );
		/* Crea un fc_time amb fus horari +00:00 */

extern fc_timezone create_timezone ( bool fusPositiu, u8 hores, u8 quartsHora );
		/* Crea un fus horari en format 1:4:2 amb els valors donats */

extern fc_time create_local_time ( u8 hores, u8 minuts, u8 segons, fc_timezone fusHorari );
		/* Crea un fc_time amb els valors indicats i 0 cent�simes de segon */


	/* rutines de consulta de valors de camps */
extern u8 get_hours ( fc_time temps_complet );
extern u8 get_minutes ( fc_time temps_complet );
extern u8 get_seconds ( fc_time temps_complet );
extern u8 get_cents ( fc_time temps_complet );
extern fc_timezone get_timezone ( fc_time temps_complet );

extern bool is_timezone_positive ( fc_timezone fusHorari );
extern u8 get_timezone_hours ( fc_timezone fusHorari );
extern u8 get_timezone_minutes ( fc_timezone fusHorari );	/* 0, 15, 30 o 45 */


	/* Rutina per passar d'hora/temps local a hora/temps UTC */
extern fc_time local_to_UTC_time ( fc_time localTime, s8 *dayOffset );
		/* Converteix localTime (se suposa que amb fus!=UTC)
			a hora UTC (amb fus horari +00:00).
			dayOffset �s un valor de sortida, per si amb el canvi d'hora
			cal passar al dia anterior (-1), posterior (+1) o l'actual (0).
		*/


#endif /* FCTIMES_H */

