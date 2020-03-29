/*----------------------------------------------------------------
|	Autor: Pere Mill�n (DEIM, URV)
|	Data:  Febrer 2020					Versi�: 1.0
|-----------------------------------------------------------------|
|	Nom fitxer: test_utils.c
|   Descripci�: declaracions i funcions d'utilitat 
|				 per aplicar jocs de proves.
| ----------------------------------------------------------------*/


#include "test_utils.h"


void verificarJocDeProves(functest jocDeProves[], u8 num_proves, 
									u8 *num_tests_ok, u32 *quins_errors)
	/* Crida a cadascuna de les num_proves contingudes a jocDeProves */
	/* apuntant en num_tests_ok quantes proves han anat b� */
	/* i en quins_errors activa 1 bit per cada prova err�nia */
{
	u8 index_prova;	/* n�mero de prova en curs */
	
	*num_tests_ok = 0;	/* Inicialment, cap prova ok */
	*quins_errors = 0;	/* Inicialment, cap error */

		/* Rec�rrer el vector i aplicar cada prova */
	for (index_prova = 0; index_prova < num_proves; index_prova++)
	{
		if ( jocDeProves[index_prova]() )
		{
			(*num_tests_ok)++;	/* una altra prova ok */
		}
		else
		{
				/* Activar el bit corresponent de prova amb errors */
			*quins_errors = (*quins_errors) | (1 << index_prova);
		}
	}
}



