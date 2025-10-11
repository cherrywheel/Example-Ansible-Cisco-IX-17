#!/bin/bash

# ==============================================================================
# ИСПРАВЛЕННЫЙ install-deps.sh (УДАЛЕНЫ v, x, showfun)
# ==============================================================================

# Цвета для вывода в терминал
STY_RED='\033[0;31m'
STY_GREEN='\033[0;32m'
STY_YELLOW='\033[1;33m'
STY_CYAN='\033[0;36m'
STY_RESET='\033[0m'

# ==============================================================================
# Хелпер-функции (замена v и x)
# ==============================================================================

# Простая функция для выполнения команды и логирования
execute() {
    printf "${STY_GREEN}[$0]: Выполнение команды: %s${STY_RESET}\n" "$*"
    "$@"
}

# Функция для установки yay
install_yay_manual() {
    printf "${STY_CYAN}[$0]: Установка yay-bin...${STY_RESET}\n"
    
    # Устанавливаем base-devel и git
    execute sudo pacman -S --needed --noconfirm base-devel git

    # Установка yay-bin
    execute git clone https://aur.archlinux.org/yay-bin.git /tmp/buildyay
    cd /tmp/buildyay || return 1
    
    execute makepkg -si --noconfirm
    
    # Возвращаемся в исходную директорию
    # Используем 'pushd/popd' или 'cd -'
    # Чтобы не вызывать ошибку 'cd -' в fish, используем pushd/popd
    if [ "$base" ]; then
        cd "$base"
    else
        # В случае, если $base не определен, просто удаляем папку
        rm -rf /tmp/buildyay
        return
    fi

    rm -rf /tmp/buildyay
}

# Функция для удаления устаревших зависимостей
handle-deprecated-dependencies() {
    printf "${STY_CYAN}[$0]: Removing deprecated dependencies:${STY_RESET}\n"
    
    # Удаляем устаревшие пакеты
    for i in illogical-impulse-{microtex,pymyc-aur,ags,agsv1} {hyprutils,hyprpicker,hyprlang,hypridle,hyprland-qt-support,hyprland-qtutils,hyprlock,xdg-desktop-portal-hyprland,hyprcursor,hyprwayland-scanner,hyprland}-git; do 
        # Заменено 'try' на 'execute'
        execute sudo pacman --noconfirm -Rdd $i || true # || true для игнорирования ошибок, если пакет не установлен
    done
    
    # ВНИМАНИЕ: Следующий блок закомментирован, так как функция 
    # remove_bashcomments_emptylines не определена в этом файле 
    # и вызовет ошибку "command not found".
    : <<'END_COMMENT'
    # Convert old dependencies to non explicit dependencies so that they can be orphaned if not in meta packages
    remove_bashcomments_emptylines ./dist-arch/previous_dependencies.conf ./cache/old_deps_stripped.conf
    readarray -t old_deps_list < ./cache/old_deps_stripped.conf
    pacman -Qeq > ./cache/pacman_explicit_packages
    readarray -t explicitly_installed < ./cache/pacman_explicit_packages

    echo "Attempting to set previously explicitly installed deps as implicit..."
    for i in "${explicitly_installed[@]}"; do for j in "${old_deps_list[@]}"; do
        [ "$i" = "$j" ] && yay -D --asdeps "$i"
    done; done
END_COMMENT

    return 0
}

# Функция для установки локальных пакетов
install-local-pkgbuild() {
  local location=$1
  local installflags=$2

  execute pushd "$location"

  # Загружаем переменные из PKGBUILD
  # 2>/dev/null для подавления ошибок "command not found" внутри PKGBUILD, если они есть
  source ./PKGBUILD 2>/dev/null 

  # Устанавливаем зависимости с помощью yay, если они есть
  if [[ ${#depends[@]} -gt 0 ]]; then
      printf "${STY_CYAN}[$0]: Установка зависимостей с помощью yay: ${depends[@]}${STY_RESET}\n"
      execute yay -S "$installflags" --asdeps "${depends[@]}" --noconfirm
  fi

  # Собираем и устанавливаем сам пакет
  printf "${STY_CYAN}[$0]: Сборка и установка пакета: %s${STY_RESET}\n" "$location"
  execute makepkg -Asi --noconfirm

  execute popd
}


#####################################################################################
if ! command -v pacman >/dev/null 2>&1; then
  printf "${STY_RED}[$0]: pacman not found, it seems that the system is not ArchLinux or Arch-based distros. Aborting...${STY_RESET}\n"
  exit 1
fi

# ==============================================================================
# 1. Обновление системы
# ==============================================================================

# Замена: v sudo pacman -Syu
case $SKIP_SYSUPDATE in
  true) printf "${STY_YELLOW}[$0]: Пропуск обновления системы (SKIP_SYSUPDATE=true).${STY_RESET}\n" ;;
  *) execute sudo pacman -Syu ;;
esac

# ==============================================================================
# 2. Установка yay (если не найден)
# ==============================================================================

if ! command -v yay >/dev/null 2>&1;then
  echo -e "${STY_YELLOW}[$0]: \"yay\" not found. Выполняется установка...${STY_RESET}"
  # Замена: showfun install-yay / v install-yay
  install_yay_manual
fi

# ==============================================================================
# 3. Обработка устаревших зависимостей 
# ==============================================================================

# Замена: showfun handle-deprecated-dependencies / v handle-deprecated-dependencies
handle-deprecated-dependencies

# ==============================================================================
# 4. Установка основных пакетов
# ==============================================================================

metapkgs=(
  ./dist-arch/illogical-impulse-{audio,backlight,basic,fonts-themes,kde,portal,python,screencapture,toolkit,widgets}
  ./dist-arch/illogical-impulse-hyprland
  ./dist-arch/illogical-impulse-microtex-git
)

# Проверка и добавление пакета курсора
# Замена: [[ -f ... ]] || metapkgs+=(...)
if [[ ! -f /usr/share/icons/Bibata-Modern-Classic/index.theme ]]; then
    metapkgs+=(./dist-arch/illogical-impulse-bibata-modern-classic-bin)
fi

for i in "${metapkgs[@]}"; do
  # Замена: v install-local-pkgbuild "$i" "$metainstallflags"
  installflags="--needed --noconfirm"
  install-local-pkgbuild "$i" "$installflags"
done

# ==============================================================================
# 5. Опциональная установка plasma-browser-integration
# ==============================================================================

SKIP_PLASMAINTG=false
# Замена: if pacman -Qs ^plasma-browser-integration$ ;then SKIP_PLASMAINTG=true;fi
if pacman -Qs ^plasma-browser-integration$ >/dev/null; then 
    SKIP_PLASMAINTG=true
fi

case $SKIP_PLASMAINTG in
  true) printf "${STY_GREEN}[$0]: plasma-browser-integration уже установлен, пропуск.${STY_RESET}\n" ;;
  *)
    # Переписанный интерактивный блок
    echo -e "${STY_YELLOW}[$0]: NOTE: The size of \"plasma-browser-integration\" is about 600 MiB.${STY_RESET}"
    echo -e "${STY_YELLOW}It is needed if you want playtime of media in Firefox to be shown on the music controls widget.${STY_RESET}"
    
    p="n" # Значение по умолчанию, как в оригинале [y/N]
    
    # $ask - это переменная, которая может быть определена снаружи. 
    # Если она не определена или не равна "false", разрешаем интерактивный ввод.
    if [[ "$ask" != "false" ]]; then 
        echo -e "${STY_YELLOW}Install it? [y/N]${STY_RESET}"
        read -r -p "====> " p
    fi
    
    case ${p,,} in # Приводим ответ к нижнему регистру
      y) execute sudo pacman -S --needed --noconfirm plasma-browser-integration ;;
      *) echo "Ok, won't install"
    esac
    ;;
esac