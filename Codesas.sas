

/*Affichage de la base de donn�es*/
proc contents data= WORK.PROJET;run;

/* Cr�ez une nouvelle variable binaire nomm�e "Conso_alcool_encoded" */
data work.PROJET_encoded;
set work.PROJET;
if Conso_alcool_O_N = "Occasionnellement (en soir�e, le week-end...)" then Conso_alcool_encoded =1;
else if Conso_alcool_O_N = "Souvent (3 � 5 fois par semaine)" then Conso_alcool_encoded =1 ;
else if Conso_alcool_O_N = "Tous les jours" then Conso_alcool_encoded =1;
else if Conso_alcool_O_N = "Jamais" then Conso_alcool_encoded =0;run;


proc contents data=work.PROJET_encoded; run;

proc freq data=work.PROJET_encoded;table Conso_alcool_encoded; run;

/*Cr�ation de l'indicatrice de r�ponse*/

/*impossible d'utiliser ceci
data work.PROJET_encoded1;
set work.PROJET_encoded;
if Conso_alcool_encoded =1 then nonrep = 0;
else if Conso_alcool_encoded= 0 then nonrep= 0; 
else  nonrep=1;
run;*/

/*Donc on utilise la variable r�pondants qu'il y a dans la base*/

data work.PROJET_encoded1;
set work.PROJET_encoded;
if Repondants ="Oui" then nonrep = 0;/* Car il a r�pondu*/
else nonrep= 1; /* Car il n'a pas r�pondu */
run;

proc freq data=work.PROJET_encoded1;table nonrep; run;

/*V�rification de la corr�lation entre l'indicatrice de r�ponse et la variable d'int�ret*/
/*Test de chi-carr�*/

PROC FREQ DATA=work.PROJET_encoded1;
TABLES nonrep*Conso_alcool_encoded / CHISQ;
RUN;

/*Corr�lation non n�gligeable donc biais non n�gligeable
recherche d'une variable de strate li�e � la non r�ponse en exploitant l'information auxiliaire
Mod�lisationde de la probabilit�  de non r�ponse � l'aide d'un proc probit*/

/*Encodage des informations auxiliares*/


data work.PROJET_encoded2;
set work.PROJET_encoded1; 

if Age_A < 23 then Age_Aencoded=1;
else if Age_A < 28 then Age_Aencoded=2;
else  Age_Aencoded=3; 

if Nationalite="FRANCAISE" then Natcoded=1;
else Natcoded=0;run;



/*Mod�le PROBIT*/
proc probit data=work.PROJET_encoded2;
model nonrep = Age_Aencoded Natcoded Type_bac_A ;run;

/*Les deux variables sont li�es � la bon r�ponse.  On va stratifier par nationalit�*/


/*R�cup�re l'echantillon de la base initiale.  Si on consid�re la population de r�pondants comme al�atoire*/

DATA work.echantillonOVE;
    SET work.PROJET_encoded2;
    IF Conso_alcool_encoded= 1 OR Conso_alcool_encoded = 0;
RUN;

proc freq data=work.echantillonOVE;
table Conso_alcool_encoded; run;

/*on r�pertorie l'echantillon par strate.  On stratifie par nationalit�*/

data work.CL2;	/* nouvelle base de donnees */
set work.echantillonOVE;		/* base d'origine */  
if Natcoded=1 then strate=1;
else strate=2;run;
; /* strate est "h" du cours h=1,...5 */

proc freq data=work.CL2;	             /* tableau de fr�quences */
table strate;
run;


/*Il faut d�abord commencer par trier les donn�es par strate comme ca il va avoir la variable de strate bien tri�.  
 on trie les donnees */
proc sort data=work.CL2;by strate;run; 

/*Moyenne par cat�gorie*/
proc means data=work.CL2;
by strate;
var Conso_alcool_encoded;run;
/*moyenne dans l'�chantillon on peut calculer manuellement aussi*/

proc means data=work.CL2;
var Conso_alcool_encoded;run;

/* Cr�ation de la strate dans la po^pulation pour caler sur les effectifs de la population*/

data work.PROJETSTRATE;	/* nouvelle base de donnees */
set work.PROJET_encoded2;		/* base d'origine */  
if Natcoded=1 then strate=1;
else strate=2;run;


/*R�cup�ration des effectifs*/
proc freq data=PROJETSTRATE;
table strate;run;



/*Calage de l'echantillon*/
proc surveymeans data=work.CL2;
poststrata strate/PSTOTAL=(37877,5282) outpswgt=echantillon_red1;
var Conso_alcool_encoded ;
run;

proc freq data=work.echantillon_red1;
tables _PSWt_;
run;


