#!/bin/sh
##
## Batocera.PLUS
##
## Código escrito por: Sérgio de Carvalho Júnior
## 
## Linha de comando:
## fpinball_launcher.sh [ROM] [RESOLUTION] [RATIO] [P1GUID] [P!NAME]
##
## ROM = Caminho do jogo até a .fpt
## RESULUTION = auto ou algo que respeite a regra XXXXxXXXX ex: [1920x1080]
## RATIO = 4/3|1/1|16/15|3/2|3/4|4/4|5/4|6/5|7/9|8/7|16/9|19/12|19/14|2/1|21/9|30/17|32/9|4/1|8/3|auto|custom|squarepixel
## PIGUID = parâmetro do emulatorlauncher.sh (OPICIONAL)
## P1NAME = parâmetro do emulatorlauncher.sh (OPICIONAL)
##
################################################################################

### PARÂMETROS

JOGO="${1}"
RESOLUTION="${2}"
RATIO="${3}"
P1GUID="${4}"
P1NAME="${5}"

################################################################################

### CAMINHOS

FP_DIR='/opt/Future_Pinball'
FP_STDIR="$HOME/configs/Future Pinball"
FP_SVDIR="$HOME/../saves/Future Pinball"
RES_START="$(batocera-resolution currentMode)"
OPT_WINE="$(stat -t '/opt/Wine/wine-lutris/share/wine/wine.inf' | awk '{print $12}')"
SVDIR_VERSION="$(cat -e "${FP_SVDIR}/wine/.update-timestamp" | cut -d '^' -f 1)"

################################################################################

### EXPORTS

export WINEPREFIX="${FP_SVDIR}/wine"
export INSTALL_EXTRAS=1

################################################################################

### HELP

function help()
{
    echo " "
    echo " Future Pinball launcher for Batocera.PLUS"
    echo " "
    echo " Codigo escrito por: Sergio de Carvalho Junior"
    echo " "
    echo " Linha de comando:"
    echo " fpinball_launcher.sh [ROM] [RESOLUTION] [RATIO] [P1GUID] [P1NAME]"
    echo " "
    echo " ROM = Caminho do jogo até a .fpt"
    echo " RESULUTION = auto ou algo que respeite a regra XXXXxXXXX ex: [1920x1080]"
    echo " RATIO = 4/3|1/1|16/15|3/2|3/4|4/4|5/4|6/5|7/9|8/7|16/9|19/12|19/14|2/1|21/9|30/17|32/9|4/1|8/3|auto|custom|squarepixel"
    echo " PIGUID = parâmetro do emulatorlauncher.sh (OPICIONAL)"
    echo " P1NAME = parâmetro do emulatorlauncher.sh (OPICIONAL)"
    echo " "
}

if [ "${1}" == '--help' ]; then
    help
    exit 0
fi

################################################################################

### NÃO EXECUTA O EMULADOR DUAS VEZES

if [ "$(pidof wineserver)" ]; then
    echo " Future Pinball launcher ja esta sendo executado"
    exit 1
fi

################################################################################

### LAUNCHER INFO

echo " "
echo " Future Pinball launcher for Batocera.PLUS"
echo " Codigo escrito por: Sergio de Carvalho Junior"
echo " "

################################################################################

### INSTALAÇÃO DO FUTURE PINBALL

function createFolders()
{
    ### Cria work dir
    mkdir -p "${FP_STDIR}"                                       
    cp -rf "${FP_DIR}/emulator/Feeds"               "${FP_STDIR}"
    cp -f  "${FP_DIR}/emulator/devil.dll"           "${FP_STDIR}"
    cp -f  "${FP_DIR}/emulator/fmod.dll"            "${FP_STDIR}"
    cp -f  "${FP_DIR}/emulator/Future Pinball.exe"  "${FP_STDIR}"
    cp -f  "${FP_DIR}/emulator/ilu.dll"             "${FP_STDIR}"
    cp -f  "${FP_DIR}/emulator/ilut.dll"            "${FP_STDIR}"
    cp -f  "${FP_DIR}/emulator/libcurl.dll"         "${FP_STDIR}"
    cp -f  "${FP_DIR}/emulator/NewTable.fpt"        "${FP_STDIR}"
    cp -f  "${FP_DIR}/emulator/Newton.dll"          "${FP_STDIR}"
    cp -f  "${FP_DIR}/emulator/SciLexer.dll"        "${FP_STDIR}"

    ### Cria save dir
    mkdir -p "${FP_SVDIR}/DmdFonts" "${FP_SVDIR}/fpRAM" "${FP_SVDIR}/wine"
    cp -rf "${FP_DIR}/emulator/Libraries" "${FP_SVDIR}"
    ln -sf "${FP_SVDIR}/DmdFonts"         "${FP_STDIR}"
    ln -sf "${FP_SVDIR}/fpRAM"            "${FP_STDIR}"
    ln -sf "${FP_SVDIR}/Libraries"        "${FP_STDIR}"
}

function applyConfig()
{
    ### Aplica a config padrão
    wine-lutris regedit "${FP_DIR}/emulator/config.reg"

    ### install deps for future pinball
    batocera-load-screen -t 600 -i '/opt/Wine/wine.png' &

    cp -rf "${FP_DIR}/dll/"* "$WINEPREFIX/drive_c/windows/syswow64" && cp -rf "${FP_DIR}/dll/"* "$WINEPREFIX/drive_c/windows/system32"

    DLLS='dispex.dll jscript.dll scrobj.dll scrrun.dll vbscript.dll wshcon.dll wshext.dll'

    for i in $DLLS; do
        wine-lutris regsvr32 "$WINEPREFIX/drive_c/windows/syswow64/$i" 2>&1&> /dev/null
        wine-lutris regsvr32 "$WINEPREFIX/drive_c/windows/system32/$i" 2>&1&> /dev/null
        echo "$i Registrada com sucesso!"
    done

    if [ "$(pidof yad)" ]; then
        killall yad
    fi

    wait
}

################################################################################

### CHECK FOLDERS

if [ "${OPT_WINE}" != "${SVDIR_VERSION}" ] && [ -e "${FP_SVDIR}/wine" ]; then # se a versão do wine mudou
    rm -r "${FP_SVDIR}/wine"
fi

if [ ! "$(ls -A "${FP_STDIR}" 2> /dev/null)" ] || [ ! "$(ls -A "${FP_SVDIR}" 2> /dev/null)" ]; then # configura do zero
    createFolders
    applyConfig
elif [ ! "$(ls -A "${FP_SVDIR}/wine" 2> /dev/null)" ]; then # configura somente o prefixo do wine se ele for apagado
    mkdir -p "${FP_SVDIR}/wine"
    applyConfig
fi

sync

################################################################################

### RESOLUTION

if [ "${RESOLUTION}" == 'auto' ] || [ -z "${RESOLUTION}" ] ; then
    XRES="$(echo "${RES_START}" | cut -d 'x' -f 1)"
    YRES="$(echo "${RES_START}" | cut -d 'x' -f 2)"
    XRES="$( printf "%x\n" "${XRES}")"
    YRES="$( printf "%x\n" "${YRES}")"
    sed -i s'/"Width"=.*/"Width"=dword:00000'"${XRES}"'/'   "${FP_SVDIR}/wine/user.reg"
    sed -i s'/"Height"=.*/"Height"=dword:00000'"${YRES}"'/' "${FP_SVDIR}/wine/user.reg"
else
    batocera-resolution setMode "${RESOLUTION}"
    XRES="$(echo "${RESOLUTION}" | cut -d 'x' -f 1)"
    YRES="$(echo "${RESOLUTION}" | cut -d 'x' -f 2)"
    XRES="$( printf "%x\n" "${XRES}")"
    YRES="$( printf "%x\n" "${YRES}")"
    sed -i s'/"Width"=.*/"Width"=dword:00000'"${XRES}"'/'   "${FP_SVDIR}/wine/user.reg"
    sed -i s'/"Height"=.*/"Height"=dword:00000'"${YRES}"'/' "${FP_SVDIR}/wine/user.reg"
fi

sync

################################################################################

### RATIO

case "${RATIO}" in
    4/3|1/1|16/15|3/2|3/4|4/4|5/4|6/5|7/9|8/7|auto|custom|squarepixel)
    sed -i s'/"AspectRatio"=.*/"AspectRatio"=dword:0000002b/' "${FP_SVDIR}/wine/user.reg"
    ;;
    16/9|19/12|19/14|2/1|21/9|30/17|32/9|4/1|8/3)
    sed -i s'/"AspectRatio"=.*/"AspectRatio"=dword:000000a9/' "${FP_SVDIR}/wine/user.reg"
    ;;
    *)
    sed -i s'/"AspectRatio"=.*/"AspectRatio"=dword:0000002b/' "${FP_SVDIR}/wine/user.reg"
    ;;
esac

sync

################################################################################

### CONTROLES

sed -i s'/\[Software\\\\Future Pinball\\\\GamePlayer\\\\Joypads\\\\.*/\[Software\\\\Future Pinball\\\\GamePlayer\\\\Joypads\\\\'"${P1NAME}"' (js)\]/' "${FP_SVDIR}/wine/user.reg"

sync

################################################################################

### HOTKEY

BOTOES="$(/opt/Wine/getHotkeyStart "${P1GUID}")"
BOTAO_HOTKEY="$(echo "${BOTOES}" | cut -d ' ' -f 1)"
BOTAO_START="$(echo "${BOTOES}"  | cut -d ' ' -f 2)"

if [ "${BOTAO_HOTKEY}" ] && [ "${BOTAO_START}" ]; then
    # Impede que o xjoykill seja encerrado enquanto o jogo está em execução.
    while : ; do
        nice -n 20 xjoykill -hotkey "${BOTAO_HOTKEY}" -start "${BOTAO_START}" -kill /opt/Future_Pinball/killfpinball
        if ! [ "$(pidof Future Pinball.exe)" ]; then
              break
        fi
        sleep 5
    done &
fi

################################################################################

### CAPTURA O JOGO
JOGO="$(echo "Z:${JOGO}" | sed -e 's#/#\\#g')"

################################################################################

### EXECUTA O JOGO OU O CONFIGURADOR

export VIRTUAL_DESKTOP=1

if [ "${JOGO}" == '' ]; then
    wine-lutris "${FP_STDIR}/Future Pinball.exe"
else
    wine-lutris "${FP_STDIR}/Future Pinball.exe" /open "${JOGO}" /play /exit
fi

################################################################################

### FINALIZA A EXECUÇÃO DO JOGO

# Aguarda o Cemu encerrar a execução
while [ "$(pidof wineserver)" ]; do
    sleep 1
done

# Restaura a resolução do jogo caso tenha mudado
RES_STOP="$(batocera-resolution currentResolution)"
if [ "${RES_START}" != "${RES_STOP}" ]; then
    batocera-resolution setMode "${RES_START}"
fi

exit 0
