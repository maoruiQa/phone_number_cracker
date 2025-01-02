@echo off
setlocal enabledelayedexpansion

:: Check for help command
if "%~1"=="--help" (
    echo Usage: %~nx0 [hash_file.hc22000] [--region code]
    echo.
    echo Available regions:
    echo   cn    China ^(11 digits^)
    echo   us    United States ^(10 digits^)
    echo   de    Germany ^(11 digits^)
    echo   tw    Taiwan ^(10 digits^)
    echo.
    echo Examples:
    echo   %~nx0 test.hc22000                                      use the default region --- China
    echo   %~nx0 test.hc22000 --region us
    echo   %~nx0 --regions                                            list all supported regions
    exit /b 0
)

:: Check for regions list command
if "%~1"=="--regions" (
    echo Supported regions:
    echo   cn - China
    echo   us - United States
    echo   de - Germany
    echo   tw - Taiwan
    exit /b 0
)

:: Validate input file
if "%~1"=="" (
    echo Error: No hash file specified
    echo Use --help for usage information
    exit /b 1
)

set "hash_file=%~1"
if not exist "%hash_file%" (
    echo Error: File %hash_file% not found
    exit /b 1
)

:: Set default region and check for region parameter
set "region=cn"
if "%~2"=="--region" (
    if "%~3"=="" (
        echo Error: No region specified after --region
        exit /b 1
    )
    set "region=%~3"
)

:: Define prefixes for each region
set "prefixes_cn=139 138 137 136 135 134 147 150 151 152 157 158 159 182 183 187 188 198 130 131 132 155 156 185 186 166 133 153 180 181 189 191 199"
set "prefixes_us=201 202 203 212 213 214 310 312 315 516 617 718 805 818 909"
set "prefixes_de=151 152 153 160 162 163 170 171 172 173 175 176 177 178"
set "prefixes_tw=02 07 04 03 05"

:: Set mask length based on region
set "mask_length=8"
if "%region%"=="cn" set "mask_length=8"
if "%region%"=="us" set "mask_length=7"
if "%region%"=="de" set "mask_length=8"
if "%region%"=="tw" set "mask_length=8"

:: Validate region
set "valid_region=0"
for %%r in (cn us de tw) do (
    if "%region%"=="%%r" set "valid_region=1"
)
if %valid_region%==0 (
    echo Error: Invalid region code: %region%
    echo Use --regions to see available region codes
    exit /b 1
)

:: Set active prefixes based on region
set "active_prefixes=!prefixes_%region%!"

echo Testing %region% phone numbers...
echo Using prefixes: !active_prefixes!

set "temp_result=result.txt"
if exist %temp_result% del %temp_result%

:: Process each prefix
for %%p in (!active_prefixes!) do (
    echo Testing prefix: %%p
    set "mask=%%p"
    for /l %%i in (1,1,%mask_length%) do set "mask=!mask!?d"
    
    hashcat -a 3 -m 22000 "%hash_file%" "!mask!" --potfile-disable -o %temp_result% -w 3
    
    if exist %temp_result% (
        for /f "tokens=*" %%a in (%temp_result%) do (
            echo Found password: %%a
            goto :success
        )
    )
    if exist %temp_result% del %temp_result%
)

:notfound
echo Password not found for region: %region%
exit /b 1

:success
echo Test completed successfully
exit /b 0