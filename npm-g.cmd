@echo off
SETLOCAL ENABLEDELAYEDEXPANSION

@REM Capture the true script directory before any 'shift' commands can corrupt %0
SET "BASE_DIR=%~dp0"
@REM The baseline global manifest (fallback)
SET "MANIFEST=!BASE_DIR!npm-g.manifest"

if exist "!MANIFEST!" goto START_ROUTING
echo # Global Packages Manifest> "!MANIFEST!"
echo # Add one global package per line like nodemon or typescript@5.4.2>> "!MANIFEST!"
echo # Blank lines and lines starting with # are ignored.>> "!MANIFEST!"
echo [npm-g] Created empty global manifest configuration at: !MANIFEST!

:START_ROUTING
if "%~1" == "" goto ROUTINE_HELP

set "CMD_ARG=%~1"

if /i "%CMD_ARG%" == "help" goto ROUTINE_HELP
if /i "%CMD_ARG%" == "-h" goto ROUTINE_HELP
if /i "%CMD_ARG%" == "--help" goto ROUTINE_HELP
if /i "%CMD_ARG%" == "h" goto ROUTINE_HELP
if /i "%CMD_ARG%" == "?" goto ROUTINE_HELP
if /i "%CMD_ARG%" == "/?" goto ROUTINE_HELP
if /i "%CMD_ARG%" == "-" goto ROUTINE_HELP

if /i "%CMD_ARG%" == "version" goto ROUTINE_VERSION
if /i "%CMD_ARG%" == "-v" goto ROUTINE_VERSION
if /i "%CMD_ARG%" == "v" goto ROUTINE_VERSION
if /i "%CMD_ARG%" == "-version" goto ROUTINE_VERSION
if /i "%CMD_ARG%" == "--version" goto ROUTINE_VERSION

if /i "%CMD_ARG%" == "list" goto ROUTINE_LIST
if /i "%CMD_ARG%" == "-l" goto ROUTINE_LIST
if /i "%CMD_ARG%" == "l" goto ROUTINE_LIST
if /i "%CMD_ARG%" == "-list" goto ROUTINE_LIST
if /i "%CMD_ARG%" == "--list" goto ROUTINE_LIST

if /i "%CMD_ARG%" == "diff" goto ROUTINE_DIFF
if /i "%CMD_ARG%" == "-d" goto ROUTINE_DIFF
if /i "%CMD_ARG%" == "d" goto ROUTINE_DIFF
if /i "%CMD_ARG%" == "-diff" goto ROUTINE_DIFF
if /i "%CMD_ARG%" == "--diff" goto ROUTINE_DIFF

if /i "%CMD_ARG%" == "install" goto ROUTINE_INSTALL
if /i "%CMD_ARG%" == "-i" goto ROUTINE_INSTALL
if /i "%CMD_ARG%" == "i" goto ROUTINE_INSTALL
if /i "%CMD_ARG%" == "-install" goto ROUTINE_INSTALL
if /i "%CMD_ARG%" == "--install" goto ROUTINE_INSTALL
if /i "%CMD_ARG%" == "--i" goto ROUTINE_INSTALL

if /i "%CMD_ARG%" == "uninstall" goto ROUTINE_UNINSTALL
if /i "%CMD_ARG%" == "-u" goto ROUTINE_UNINSTALL
if /i "%CMD_ARG%" == "u" goto ROUTINE_UNINSTALL
if /i "%CMD_ARG%" == "-uninstall" goto ROUTINE_UNINSTALL
if /i "%CMD_ARG%" == "--uninstall" goto ROUTINE_UNINSTALL
if /i "%CMD_ARG%" == "--u" goto ROUTINE_UNINSTALL

if /i "%CMD_ARG%" == "add" goto ROUTINE_ADD
if /i "%CMD_ARG%" == "-a" goto ROUTINE_ADD
if /i "%CMD_ARG%" == "a" goto ROUTINE_ADD
if /i "%CMD_ARG%" == "-add" goto ROUTINE_ADD
if /i "%CMD_ARG%" == "--add" goto ROUTINE_ADD
if /i "%CMD_ARG%" == "--a" goto ROUTINE_ADD

if /i "%CMD_ARG%" == "remove" goto ROUTINE_REMOVE
if /i "%CMD_ARG%" == "-r" goto ROUTINE_REMOVE
if /i "%CMD_ARG%" == "r" goto ROUTINE_REMOVE
if /i "%CMD_ARG%" == "-remove" goto ROUTINE_REMOVE
if /i "%CMD_ARG%" == "--remove" goto ROUTINE_REMOVE
if /i "%CMD_ARG%" == "--r" goto ROUTINE_REMOVE
if /i "%CMD_ARG%" == "rem" goto ROUTINE_REMOVE
if /i "%CMD_ARG%" == "-rem" goto ROUTINE_REMOVE
if /i "%CMD_ARG%" == "--rem" goto ROUTINE_REMOVE

if /i "%CMD_ARG%" == "edit" goto ROUTINE_EDIT
if /i "%CMD_ARG%" == "-e" goto ROUTINE_EDIT
if /i "%CMD_ARG%" == "e" goto ROUTINE_EDIT
if /i "%CMD_ARG%" == "-edit" goto ROUTINE_EDIT
if /i "%CMD_ARG%" == "--edit" goto ROUTINE_EDIT
if /i "%CMD_ARG%" == "--e" goto ROUTINE_EDIT

goto ROUTINE_INSTALL_SPECIAL


:: ==============================================================================
:: ROUTINES
:: ==============================================================================

:ROUTINE_HELP
echo Usage: npm-g [action] [packages...]
echo.
echo Actions:
echo   help, -h, --help          Show this usage information
echo   version, -v, --version    Show npm-g tool, node, and npm versions
echo   list, -l, --list          List all manifest vs currently installed packages
echo                             (Optional: pass a version number to inspect an alternate NVM node environment)
echo   diff, -d, --diff          Show only environment discrepancies
echo   install, -i, --install    Install missing/mismatched manifest packages,
echo                             or pass arguments to run a targeted global install
echo   uninstall, -u, --uninstall Purge all untracked global packages from system,
echo                             or pass arguments to explicitly remove target modules
echo   add, -a, --add            Add package entries directly into the manifest
echo   remove, -r, --remove      Remove package entries from the manifest
echo                             (Optional: pass . or .NN to purge a version-specific manifest file completely)
echo   edit, -e, --edit          Open manifest in Notepad (creates it if missing).
echo                             (Optional: pass a major version like 22 to edit/create a specific manifest)
echo.
echo Special Case:
echo   npm-g [package1] ...      Implicit fallback to sequential global installation
goto :EOF


:ROUTINE_VERSION
echo npm-g version: 1.0.0
for /f "tokens=*" %%V in ('node -v 2^>nul') do echo node version:  %%V
for /f "tokens=*" %%V in ('npm -v 2^>nul') do echo npm version:   %%V
goto :EOF


:ROUTINE_EDIT
set "EDIT_ARG=%~2"
@REM Ensure the argument is purely numeric to prevent creation of invalid manifest names
set "IS_NUMERIC=1"
if not "!EDIT_ARG!" == "" (
    for /f "delims=0123456789" %%i in ("!EDIT_ARG!") do set "IS_NUMERIC=0"
)

if "!EDIT_ARG!" == "" (
    set "TARGET_FILE=!BASE_DIR!npm-g.manifest"
    set "N_TYPE=Global"
) else if "!IS_NUMERIC!" == "0" (
    echo [npm-g] Error: Manifest version must be a major version number.
    set "TARGET_FILE=!BASE_DIR!npm-g.manifest"
    set "N_TYPE=Global"
) else (
    set "TARGET_FILE=!BASE_DIR!npm-g-!EDIT_ARG!.manifest"
    set "N_TYPE=v!EDIT_ARG!"
)
if not exist "!TARGET_FILE!" (
    echo # Global Packages Manifest> "!TARGET_FILE!"
    echo # Add one global package per line like nodemon or typescript@5.4.2>> "!TARGET_FILE!"
    echo # Blank lines and lines starting with # are ignored.>> "!TARGET_FILE!"
    echo [npm-g] Created new !N_TYPE! manifest configuration.
)
echo [npm-g] Opening !N_TYPE! manifest in editor...
start notepad.exe "!TARGET_FILE!"
goto :EOF


:ROUTINE_LIST
if not "%~2" == "" (
    set "TARGET_VER=%~2"
    goto ROUTINE_LIST_TARGET
)

call :ResolveManifest
call :HydrateInstalledMap
echo.
echo Manifest vs Global Environment List:
echo ----------------------------------------------------------------------------
for /f "usebackq tokens=*" %%L in ("!MANIFEST!") do (
    set "LINE=%%L"
    if not "!LINE!" == "" (
        set "FIRST_CHAR=!LINE:~0,1!"
        if not "!FIRST_CHAR!" == "#" (
            call :ParsePackage "!LINE!" M_NAME M_VER
            call :ToLower "!M_NAME!" LM_NAME
            set "MANIFEST_!LM_NAME!=1"

            set "CUR_VER="
            for /f "tokens=2 delims==" %%V in ('set INSTALLED_!LM_NAME! 2^>nul') do set "CUR_VER=%%V"

            if not "!CUR_VER!" == "" (
                if "!M_VER!" == "" (
                    echo [OK]        !M_NAME! ^(@!CUR_VER!^)
                ) else (
                    if "!M_VER!" == "!CUR_VER!" (
                        echo [OK]        !M_NAME! ^(@!CUR_VER!^)
                    ) else (
                        echo [MISMATCH]  !M_NAME! ^(Manifest: !M_VER!, Current: !CUR_VER!^)
                    )
                )
            ) else (
                echo [MISSING]   !M_NAME!
            )
        )
    )
)
for /f "tokens=1,2 delims==" %%A in ('set INSTALLED_ 2^>nul') do (
    set "VAR_NAME=%%A"
    set "CUR_VER=%%B"
    set "L_NAME=!VAR_NAME:INSTALLED_=!"
    if not defined MANIFEST_!L_NAME! (
        echo [UNTRACKED] !L_NAME! ^(@!CUR_VER!^)
    )
)
goto :EOF


:ROUTINE_LIST_TARGET
call :ResolveManifest "%TARGET_VER%"
@REM Auto-detect NVM_HOME if not already bound
if not defined NVM_HOME (
    for /f "delims=" %%i in ('where nvm 2^>nul') do set "NVM_HOME=%%~dpi"
)
if not defined NVM_HOME (
    echo [npm-g] ERROR: NVM_HOME not defined. Cannot scan alternate Node versions.
    goto :EOF
)

set "MATCH_COUNT=0"
set "TARGET_PATH="
set "TARGET_NAME="

@REM Resolve target version directory - Alphabetical sort guarantees highest patch version
for /d %%d in ("%NVM_HOME%\v%TARGET_VER%*") do (
    if exist "%%d\node.exe" (
        set /a MATCH_COUNT+=1
        set "TARGET_PATH=%%d"
        set "TARGET_NAME=%%~nxd"
    )
)

if not defined TARGET_PATH (
    echo [npm-g] ERROR: Node version matching "v%TARGET_VER%" is not installed locally.
    goto :EOF
)

set "TARGET_NODE_MODULES=!TARGET_PATH!\node_modules"
if not exist "!TARGET_NODE_MODULES!" (
    echo [npm-g] ERROR: node_modules folder missing in !TARGET_NAME!
    goto :EOF
)

@REM Step 1: Pre-hydrate the INSTALLED_ map strictly from the target node_modules
for /f "tokens=1 delims==" %%A in ('set INSTALLED_ 2^>nul') do set "%%A="
for /d %%F in ("!TARGET_NODE_MODULES!\*") do (
    call :ProcessPackageFolder "%%~nxF" "%%~fF"
)

@REM Step 2: Traverse Manifest and compare
echo.
echo Manifest vs Global Environment List ^(!TARGET_NAME!^):
echo ----------------------------------------------------------------------------
for /f "tokens=1 delims==" %%A in ('set MANIFEST_ 2^>nul') do set "%%A="

for /f "usebackq tokens=*" %%L in ("!MANIFEST!") do (
    set "LINE=%%L"
    if not "!LINE!" == "" (
        set "FIRST_CHAR=!LINE:~0,1!"
        if not "!FIRST_CHAR!" == "#" (
            call :ParsePackage "!LINE!" M_NAME M_VER
            call :ToLower "!M_NAME!" LM_NAME
            set "MANIFEST_!LM_NAME!=1"

            set "CUR_VER="
            for /f "tokens=2 delims==" %%V in ('set INSTALLED_!LM_NAME! 2^>nul') do set "CUR_VER=%%V"

            if not "!CUR_VER!" == "" (
                if "!M_VER!" == "" (
                    echo [OK]        !M_NAME! ^(@!CUR_VER!^)
                ) else (
                    if "!M_VER!" == "!CUR_VER!" (
                        echo [OK]        !M_NAME! ^(@!CUR_VER!^)
                    ) else (
                        echo [MISMATCH]  !M_NAME! ^(Manifest: !M_VER!, Target: !CUR_VER!^)
                    )
                )
            ) else (
                echo [MISSING]   !M_NAME!
            )
        )
    )
)

@REM Step 3: Print Untracked target packages
for /f "tokens=1,2 delims==" %%A in ('set INSTALLED_ 2^>nul') do (
    set "VAR_NAME=%%A"
    set "CUR_VER=%%B"
    set "L_NAME=!VAR_NAME:INSTALLED_=!"
    if not defined MANIFEST_!L_NAME! (
        echo [UNTRACKED] !L_NAME! ^(@!CUR_VER!^)
    )
)
goto :EOF


:ROUTINE_DIFF
call :ResolveManifest
call :HydrateInstalledMap
echo.
echo Environment Discrepancies (Diff):
echo ----------------------------------------------------------------------------
for /f "usebackq tokens=*" %%L in ("!MANIFEST!") do (
    set "LINE=%%L"
    if not "!LINE!" == "" (
        set "FIRST_CHAR=!LINE:~0,1!"
        if not "!FIRST_CHAR!" == "#" (
            call :ParsePackage "!LINE!" M_NAME M_VER
            call :ToLower "!M_NAME!" LM_NAME
            set "MANIFEST_!LM_NAME!=1"

            set "CUR_VER="
            for /f "tokens=2 delims==" %%V in ('set INSTALLED_!LM_NAME! 2^>nul') do set "CUR_VER=%%V"

            if not "!CUR_VER!" == "" (
                if not "!M_VER!" == "" (
                    if not "!M_VER!" == "!CUR_VER!" (
                        echo [MISMATCH]  !M_NAME! ^(Manifest: !M_VER!, Current: !CUR_VER!^)
                    )
                )
            ) else (
                echo [MISSING]   !M_NAME!
            )
        )
    )
)
for /f "tokens=1,2 delims==" %%A in ('set INSTALLED_ 2^>nul') do (
    set "VAR_NAME=%%A"
    set "CUR_VER=%%B"
    set "L_NAME=!VAR_NAME:INSTALLED_=!"
    if not defined MANIFEST_!L_NAME! (
        echo [UNTRACKED] !L_NAME! ^(@!CUR_VER!^)
    )
)
goto :EOF


:ROUTINE_INSTALL
shift
if not "%~1" == "" goto ROUTINE_INSTALL_ARGS

call :ResolveManifest
call :HydrateInstalledMap
set "PASSED_LIST="
set "FAILED_LIST="
set "ANY_WORK=0"
set "COREPACK_HOOK=0"

for /f "usebackq tokens=*" %%L in ("!MANIFEST!") do (
    set "LINE=%%L"
    if not "!LINE!" == "" (
        set "FIRST_CHAR=!LINE:~0,1!"
        if not "!FIRST_CHAR!" == "#" (
            call :ParsePackage "!LINE!" M_NAME M_VER
            call :ToLower "!M_NAME!" LM_NAME

            if "!LM_NAME!" == "corepack" set "COREPACK_HOOK=1"

            set "CUR_VER="
            for /f "tokens=2 delims==" %%V in ('set INSTALLED_!LM_NAME! 2^>nul') do set "CUR_VER=%%V"

            set "NEED_INSTALL=0"
            if "!CUR_VER!" == "" (
                set "NEED_INSTALL=1"
            ) else (
                if not "!M_VER!" == "" (
                    if not "!M_VER!" == "!CUR_VER!" set "NEED_INSTALL=1"
                )
            )

            if "!NEED_INSTALL!" == "1" (
                set "ANY_WORK=1"
                set "TARGET_PKG=!M_NAME!"
                if not "!M_VER!" == "" set "TARGET_PKG=!M_NAME!@!M_VER!"

                echo.
                echo Installing !TARGET_PKG! globally...
                call npm install -g !TARGET_PKG!
                if !errorlevel! equ 0 (
                    set "PASSED_LIST=!PASSED_LIST! !TARGET_PKG!"
                ) else (
                    set "FAILED_LIST=!FAILED_LIST! !TARGET_PKG!"
                )
            )
        )
    )
)

if "!COREPACK_HOOK!" == "1" (
    echo.
    echo [HOOK] Activating Corepack shims...
    call corepack enable
    if !errorlevel! equ 0 (
        echo [HOOK] Corepack shims enabled successfully.
    ) else (
        echo [HOOK] Warning: Failed to enable Corepack shims.>&2
    )
)

if "!ANY_WORK!" == "0" (
    echo All global packages are synchronized and matching your manifest perfectly.
    goto :EOF
)
goto EXECUTION_SUMMARY


:ROUTINE_INSTALL_ARGS
set "PASSED_LIST="
set "FAILED_LIST="
:INSTALL_ARGS_LOOP
if "%~1" == "" goto EXECUTION_SUMMARY
set "TARGET_PKG=%~1"
echo.
echo Installing !TARGET_PKG! globally...
call npm install -g !TARGET_PKG!
if !errorlevel! equ 0 (
    set "PASSED_LIST=!PASSED_LIST! !TARGET_PKG!"
) else (
    set "FAILED_LIST=!FAILED_LIST! !TARGET_PKG!"
)
shift
goto INSTALL_ARGS_LOOP


:ROUTINE_INSTALL_SPECIAL
set "PASSED_LIST="
set "FAILED_LIST="
:INSTALL_SPECIAL_LOOP
if "%~1" == "" goto EXECUTION_SUMMARY
set "TARGET_PKG=%~1"
echo.
echo [npm-g] Installing !TARGET_PKG! globally...
call npm install -g !TARGET_PKG!
if !errorlevel! equ 0 (
    set "PASSED_LIST=!PASSED_LIST! !TARGET_PKG!"
) else (
    set "FAILED_LIST=!FAILED_LIST! !TARGET_PKG!"
)
shift
goto INSTALL_SPECIAL_LOOP


:ROUTINE_UNINSTALL
shift
if not "%~1" == "" goto ROUTINE_UNINSTALL_ARGS

call :ResolveManifest
call :HydrateInstalledMap
set "PASSED_LIST="
set "FAILED_LIST="
set "ANY_WORK=0"

for /f "usebackq tokens=*" %%L in ("!MANIFEST!") do (
    set "LINE=%%L"
    if not "!LINE!" == "" (
        set "FIRST_CHAR=!LINE:~0,1!"
        if not "!FIRST_CHAR!" == "#" (
            call :ParsePackage "!LINE!" M_NAME M_VER
            call :ToLower "!M_NAME!" LM_NAME
            set "MANIFEST_!LM_NAME!=1"
        )
    )
)

for /f "tokens=1,2 delims==" %%A in ('set INSTALLED_ 2^>nul') do (
    set "VAR_NAME=%%A"
    set "L_NAME=!VAR_NAME:INSTALLED_=!"
    if not defined MANIFEST_!L_NAME! (
        set "ANY_WORK=1"
        echo.
        echo Uninstalling untracked package !L_NAME! globally...
        call npm uninstall -g !L_NAME!
        if !errorlevel! equ 0 (
            set "PASSED_LIST=!PASSED_LIST! !L_NAME!"
        ) else (
            set "FAILED_LIST=!FAILED_LIST! !L_NAME!"
        )
    )
)

if "!ANY_WORK!" == "0" (
    echo Your environment is clean! No untracked global packages found to purge.
    goto :EOF
)
goto EXECUTION_SUMMARY


:ROUTINE_UNINSTALL_ARGS
set "PASSED_LIST="
set "FAILED_LIST="
:UNINSTALL_ARGS_LOOP
if "%~1" == "" goto EXECUTION_SUMMARY
set "TARGET_PKG=%~1"
echo.
echo Uninstalling !TARGET_PKG! globally...
call npm uninstall -g !TARGET_PKG!
if !errorlevel! equ 0 (
    set "PASSED_LIST=!PASSED_LIST! !TARGET_PKG!"
) else (
    set "FAILED_LIST=!FAILED_LIST! !TARGET_PKG!"
)
shift
goto UNINSTALL_ARGS_LOOP


:EXECUTION_SUMMARY
echo.
echo ============================================================================
echo Operational Summary Details
echo ============================================================================
if not "!PASSED_LIST!" == "" echo Successfully Installed: !PASSED_LIST!
if not "!FAILED_LIST!" == "" echo Critical Operational Faults: !FAILED_LIST!
goto :EOF


:ROUTINE_ADD
shift
if "%~1" == "" (
    echo [npm-g] Error: Specify at least one package name to append to your manifest.
    goto :EOF
)

call :ResolveManifest
if "!MANIFEST_TYPE!" == "Global" (
    if not "!ACTIVE_MAJOR!" == "" (
        echo [npm-g] ^(Hint: run 'npm-g edit !ACTIVE_MAJOR!' to create a version-specific manifest^)
    )
)

for /f "usebackq tokens=*" %%L in ("!MANIFEST!") do (
    set "LINE=%%L"
    if not "!LINE!" == "" (
        set "FIRST_CHAR=!LINE:~0,1!"
        if not "!FIRST_CHAR!" == "#" (
            call :ParsePackage "!LINE!" M_NAME M_VER
            call :ToLower "!M_NAME!" LM_NAME
            set "MANIFEST_!LM_NAME!=1"
        )
    )
)
:ADD_LOOP
if "%~1" == "" goto :EOF
set "ADD_RAW=%~1"
call :ParsePackage "!ADD_RAW!" A_NAME A_VER
call :ToLower "!A_NAME!" LA_NAME
if defined MANIFEST_!LA_NAME! (
    echo [npm-g] SKIPPED !A_NAME! as it already exists in !MANIFEST_TYPE! manifest.
) else (
    echo !ADD_RAW!>>"!MANIFEST!"
    echo [npm-g] ADDED !ADD_RAW! to the !MANIFEST_TYPE! manifest file.
)
shift
goto ADD_LOOP


:ROUTINE_REMOVE
shift
if "%~1" == "" (
    echo [npm-g] Error: Specify at least one package definition to strip from configuration.
    goto :EOF
)

set "FIRST_ARG=%~1"
if "!FIRST_ARG:~0,1!" == "." (
    set "T_MANIFEST_ARG=!FIRST_ARG:~1!"
    if "!T_MANIFEST_ARG!" == "" (
        call :ResolveManifest
        if "!MANIFEST_TYPE!" == "Global" (
            echo [npm-g] Error: The Global manifest is protected and cannot be purged.
            goto :EOF
        )
        set "FILE_TO_DEL=!MANIFEST!"
        set "DEL_TYPE=!MANIFEST_TYPE!"
    ) else (
        set "FILE_TO_DEL=!BASE_DIR!npm-g-!T_MANIFEST_ARG!.manifest"
        set "DEL_TYPE=v!T_MANIFEST_ARG!"
        if not exist "!FILE_TO_DEL!" (
            echo [npm-g] Error: Manifest for !DEL_TYPE! does not exist.
            goto :EOF
        )
    )
    del "!FILE_TO_DEL!"
    echo [npm-g] PURGED !DEL_TYPE! manifest file successfully.
    goto :EOF
)

call :ResolveManifest

for /f "tokens=1 delims==" %%A in ('set REMOVE_ 2^>nul') do set "%%A="

:REM_PATTERNS_LOOP
if "%~1" == "" goto REM_EXECUTE
set "TARGET=%~1"
call :ParsePackage "!TARGET!" T_NAME T_VER
call :ToLower "!T_NAME!" L_TARGET
set "REMOVE_!L_TARGET!=1"
echo [npm-g] REMOVED !TARGET! from the !MANIFEST_TYPE! manifest file.
shift
goto REM_PATTERNS_LOOP

:REM_EXECUTE
set "TEMP_MANIFEST=!MANIFEST!.tmp"
if exist "!TEMP_MANIFEST!" del "!TEMP_MANIFEST!"

for /f "usebackq tokens=*" %%L in ("!MANIFEST!") do (
    set "LINE=%%L"
    if not "!LINE!" == "" (
        set "FIRST_CHAR=!LINE:~0,1!"
        if "!FIRST_CHAR!" == "#" (
            echo !LINE!>>"!TEMP_MANIFEST!"
        ) else (
            call :ParsePackage "!LINE!" M_NAME M_VER
            call :ToLower "!M_NAME!" LM_NAME
            if not defined REMOVE_!LM_NAME! (
                echo !LINE!>>"!TEMP_MANIFEST!"
            )
        )
    )
)
if exist "!TEMP_MANIFEST!" move /y "!TEMP_MANIFEST!" "!MANIFEST!" >nul
goto :EOF


:: ==============================================================================
:: INTERNAL UTILITY SUBROUTINES
:: ==============================================================================

:ResolveManifest
set "TARGET_M=%~1"
if "!TARGET_M!" == "" (
    for /f "tokens=1 delims=." %%V in ('node -v 2^>nul') do set "RAW_V=%%V"
    set "TARGET_M=!RAW_V:v=!"
)
if "!TARGET_M!" == "" (
    set "MANIFEST=!BASE_DIR!npm-g.manifest"
    set "MANIFEST_TYPE=Global"
    set "ACTIVE_MAJOR="
    echo [npm-g] Operating against Global manifest.
    goto :EOF
)
set "SPECIFIC_MANIFEST=!BASE_DIR!npm-g-!TARGET_M!.manifest"
if exist "!SPECIFIC_MANIFEST!" (
    set "MANIFEST=!SPECIFIC_MANIFEST!"
    set "MANIFEST_TYPE=v!TARGET_M!"
) else (
    set "MANIFEST=!BASE_DIR!npm-g.manifest"
    set "MANIFEST_TYPE=Global"
    set "ACTIVE_MAJOR=!TARGET_M!"
)
echo [npm-g] Operating against !MANIFEST_TYPE! manifest.
goto :EOF


:ProcessPackageFolder
set "FOLDER_NAME=%~1"
set "FOLDER_PATH=%~2"
set "FIRST_CHAR=!FOLDER_NAME:~0,1!"

if "!FIRST_CHAR!" == "@" (
    @REM Scoped package directory routing
    for /d %%S in ("!FOLDER_PATH!\*") do (
        call :EvaluatePackage "!FOLDER_NAME!/%%~nxS" "%%~fS"
    )
) else (
    @REM Standard package directory routing
    call :EvaluatePackage "!FOLDER_NAME!" "!FOLDER_PATH!"
)
goto :EOF


:EvaluatePackage
set "PKG_NAME=%~1"
set "PKG_PATH=%~2"
set "PKG_JSON=!PKG_PATH!\package.json"

if exist "!PKG_JSON!" (
    call :ReadPackageVariable "!PKG_JSON!" "version" PKG_VER
    if not "!PKG_VER!" == "" (
        call :ToLower "!PKG_NAME!" L_NAME
        set "INSTALLED_!L_NAME!=!PKG_VER!"
    )
)
goto :EOF


:ReadPackageVariable
set "JSON_PATH=%~1"
set "VAR_NAME=%~2"
@REM Ensure backslashes are escaped so the node require string works natively
set "NODE_S_PATH=!JSON_PATH:\=\\!"
set "EXTRACTED_VAL="

@REM We use node -p natively so we avoid messy try/catch bracket escaping in batch
for /f "delims=" %%V in ('node -p "require('!NODE_S_PATH!').%VAR_NAME%" 2^>nul') do (
    set "EXTRACTED_VAL=%%V"
)

@REM Handle the raw undefined string that node -p outputs if property is missing
if "!EXTRACTED_VAL!" == "undefined" set "EXTRACTED_VAL="
set "%~3=!EXTRACTED_VAL!"
goto :EOF


:ParsePackage
set "RAW=%~1"
set "PKG_NAME=%RAW%"
set "PKG_VER="

if "%RAW:~0,1%" == "@" (
    set "REST=%RAW:~1%"
    for /f "tokens=1,2 delims=@" %%A in ("!REST!") do (
        if not "%%B" == "" (
            set "PKG_NAME=@%%A"
            set "PKG_VER=%%B"
        ) else (
            set "PKG_NAME=%RAW%"
            set "PKG_VER="
        )
    )
) else (
    for /f "tokens=1,2 delims=@" %%A in ("%RAW%") do (
        set "PKG_NAME=%%A"
        set "PKG_VER=%%B"
    )
)
set "%~2=%PKG_NAME%"
set "%~3=%PKG_VER%"
goto :EOF


:HydrateInstalledMap
for /f "tokens=1 delims==" %%A in ('set INSTALLED_ 2^>nul') do set "%%A="
for /f "tokens=1 delims==" %%A in ('set MANIFEST_ 2^>nul') do set "%%A="

for /f "tokens=*" %%P in ('npm list -g --depth=0 2^>nul') do (
    call :CleanTreeLine "%%P" CLEANED_LINE

    set "TEST_PATH=!CLEANED_LINE:\\=!"
    if "!TEST_PATH!" == "!CLEANED_LINE!" (
        set "TEST_AT=!CLEANED_LINE:@=!"
        if not "!TEST_AT!" == "!CLEANED_LINE!" (
            call :ParsePackage "!CLEANED_LINE!" INST_NAME INST_VER
            call :ToLower "!INST_NAME!" L_NAME
            set "INSTALLED_!L_NAME!=!INST_VER!"
        )
    )
)
goto :EOF

:CleanTreeLine
set "TLINE=%~1"
set "TLINE=!TLINE:+-- =!"
set "TLINE=!TLINE:`-- =!"
set "TLINE=!TLINE:├── =!"
set "TLINE=!TLINE:└── =!"
set "TLINE=!TLINE:|=!"
set "TLINE=!TLINE: =!"
set "%~2=!TLINE!"
goto :EOF

:ToLower
set "STR=%~1"
set "STR=!STR:A=a!"
set "STR=!STR:B=b!"
set "STR=!STR:C=c!"
set "STR=!STR:D=d!"
set "STR=!STR:E=e!"
set "STR=!STR:F=f!"
set "STR=!STR:G=g!"
set "STR=!STR:H=h!"
set "STR=!STR:I=i!"
set "STR=!STR:J=j!"
set "STR=!STR:K=k!"
set "STR=!STR:L=l!"
set "STR=!STR:M=m!"
set "STR=!STR:N=n!"
set "STR=!STR:O=o!"
set "STR=!STR:P=p!"
set "STR=!STR:Q=q!"
set "STR=!STR:R=r!"
set "STR=!STR:S=s!"
set "STR=!STR:T=t!"
set "STR=!STR:U=u!"
set "STR=!STR:V=v!"
set "STR=!STR:W=w!"
set "STR=!STR:X=x!"
set "STR=!STR:Y=y!"
set "STR=!STR:Z=z!"
set "%~2=!STR!"
goto :EOF