/*----------------------------------------------------------------
|	Autor: Pere Mill�n (DEIM, URV)
|	Data:  Febrer 2020					Versi�: 1.0
|-----------------------------------------------------------------|
|	Nom fitxer: test_utils.h
|   Descripci�: declaracions i funcions d'utilitat 
|				 per aplicar jocs de proves.
| ----------------------------------------------------------------*/

#ifndef TESTUTILS_H
#define TESTUTILS_H

#include "FCtypes.h"	/* bool, u8, u32 */


typedef bool (*functest)(void);		/* Definir el tipus de funci� de prova */
	/* Si la prova ha estat correcta, retorna true */

extern void verificarJocDeProves(functest jocDeProves[], u8 num_proves, 
									u8 *num_tests_ok, u32 *quins_errors);
	/* Crida a cadascuna de les num_proves contingudes a jocDeProves */
	/* apuntant en num_tests_ok quantes proves han anat b� */
	/* i en quins_errors activa 1 bit per cada prova err�nia */


#endif /* TESTUTILS_H */

