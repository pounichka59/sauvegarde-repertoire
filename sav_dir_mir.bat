@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion

REM POUR PASSER EN MODE INJECTION:  Remplacer /MIR par /E dans les deux commandes robocopy

cls
echo.
echo      w w w . P r e s t a z u r . F r 
echo.							
echo  +---------------------------------------------+   MIR
echo  ¦                                  Sauvegarde ¦
echo  ¦    Emplacement:  Bureau Windows             ¦
echo  ¦                                             ¦
echo  +---------------------------------------------+
echo       touche Entrée = Valider    Q = Quitter 
echo.

REM ----- 1. Choix du repertoire source -----
set "REP="
set /p "REP=¦  Répertoire (Documents) : "

if /I "%REP%"=="Q" exit /b

REM Si rien saisi ? Documents par défaut
if "%REP%"=="" set "REP=Documents"

set "SOURCE=%USERPROFILE%\Desktop\%REP%"
REM set "SOURCE=%USERPROFILE%\Documents XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
REM   ou
REM set "SOURCE=%USERPROFILE%\Documents\%REP%" XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

echo chemin source: %SOURCE%
if not exist "%SOURCE%\" (
    echo ERREUR: ce répertoire à sauvegarder n'existe pas
    pause
    exit /b
)
echo.

REM ----- 2. Lister les lecteurs -----
echo Support de destination:
for /f "skip=1 tokens=1,2" %%A in ('wmic logicaldisk get DeviceID^, VolumeName') do (
    if not "%%A"=="" (
        echo %%A - %%B
    )
)

REM ----- 3. Choix du lecteur -----
:choix_lecteur
set "DRV="
set /p "DRV=¦  Choix : "

if /I "%DRV%"=="Q" exit /b
if "%DRV%"=="" (
    echo ERREUR : lecteur obligatoire.
    goto choix_lecteur
    echo.
)

REM supprimer ":" si l'utilisateur l'a tapé
set "DRV=%DRV::=%"
set "TARGET=%DRV%:\%REP%"

echo Chemin cible: %TARGET%
echo.

REM ---- proposition checkdisk
echo Verifier le support ?     ( Entrée = Non    O = Oui    Q = Quitter )
set "chk="
set /p "chk="

if /I "!chk!"=="Q" (
    echo Operation annulee.
    pause
    exit /b
)
if /I "!chk!"=="O" (
    chkdsk %DRV%: /f
    pause
)

REM ----- 4. Vérifier le Répertoire cible -----
if not exist "%TARGET%" (
    echo.
    echo Le Répertoire n'existe pas sur ce lecteur.
    set /p "create=¦  Presser Entrer pour le creer ? [A pour Annuler] : "
    
    if /I "%create:~0,1%"=="A" (
        echo Operation annulee.
        pause
        exit /b
    )
    :creer
	mkdir "%TARGET%"
	echo Répertoire cree.
)


REM ----- 5. Simulation -----
echo.
echo Analyse des differences...

set "LOG=%TEMP%\analyse_sync.txt"
set "NB_SUPPR=0"
set "NB_COPIE=0"
set "NB_AJOUT=0"
set "NB_MAJ=0"
set "NB_REP_SUPPR=0"
set "NB_REP_AJOUT=0"

robocopy "%SOURCE%" "%TARGET%" ^
  /MIR /FFT /Z /R:2 /W:2 /L ^
  /NJH /NDL /TEE /LOG:"%LOG%"

set "RC=%ERRORLEVEL%"

REM ----- poids total à transférer -----
set "POIDS_AFF=0 octet"

for /f "tokens=4,5" %%A in ('findstr /i /c:"Octets" "%LOG%"') do (
    if /i "%%B"=="k" set "POIDS_AFF=%%A Ko"
    if /i "%%B"=="m" set "POIDS_AFF=%%A Mo"
    if /i "%%B"=="g" set "POIDS_AFF=%%A Go"
)

REM ----- lire les statistiques Robocopy -----
for /f "tokens=3,7" %%A in ('findstr /i /c:"Fichiers" "%LOG%"') do (
    set "NB_COPIE=%%A"
    set "NB_SUPPR=%%B"
)

REM ----- lire les statistiques des répertoires -----
for /f "tokens=3,7" %%A in ('findstr /i /c:"Rép" "%LOG%"') do (
    set "NB_REP_AJOUT=%%A"
    set "NB_REP_SUPPR=%%B"
)

REM ----- compter les nouveaux fichiers -----
findstr /i /c:"Nouveau fichier" "%LOG%" > "%TEMP%\ajouts.txt"

for /f %%A in ('find /c /v "" ^< "%TEMP%\ajouts.txt"') do set "NB_AJOUT=%%A"

REM ----- calculer les fichiers à mettre à jour -----
set /a NB_MAJ=NB_COPIE-NB_AJOUT



REM ----- 6. Contrôle d'absence de résultat -----

if %RC% GEQ 8 (
    echo.
    echo ERREUR pendant l'analyse Robocopy.
    pause
    exit /b
)

if %RC% EQU 0 (
    echo.
    echo Aucun fichier a synchroniser.
    pause
    exit /b
)


REM ----- afficher les changements à venir -----
echo.
echo.  RESUME DES OPERATIONS:
echo.  ----------------------
echo.  SUPPRIMER  Fich   %NB_SUPPR%
echo.              Rép   %NB_REP_SUPPR%
echo.  COPIER     Fich   %NB_AJOUT%
echo.              Rép   %NB_REP_AJOUT%
echo.  MODIFIER          %NB_MAJ%  
echo.
echo.  TOTAL Transfert: %POIDS_AFF%


REM ----- action libre d'execution: oui ou non -----
echo.
set /p "proceed=¦  Exécuter ?     ( Entrée = Oui    A = Annuler )  "

rem Si vide, on force O
if "%proceed%"=="" set "proceed=O"


rem On ne garde que le 1er caractère
set "proceed=%proceed:~0,1%"

rem Si ce n'est pas O (o ou O grâce à /I), on annule
if /I not "%proceed%"=="O" (
    echo Opération annulée.
	echo.
    pause
    exit /b
)

REM ----- 7. Synchronisation -----
echo.
echo Sauvegarde / Synchronisation en cours...
robocopy "%SOURCE%" "%TARGET%" /MIR /FFT /Z /R:2 /W:2 /MT:8

echo.
echo Sauvegarde terminée !
pause
