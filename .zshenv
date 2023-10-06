switchdesktop() {
    typeset -A desktophash
    desktophash[0]=29
    desktophash[1]=18
    desktophash[2]=19
    desktophash[3]=20
    desktophash[4]=21
    desktophash[5]=23
    desktophash[6]=22
    desktophash[7]=26
    desktophash[8]=28
    desktophash[9]=25
    desktopkey=${desktophash[$1]}
    osascript -e "tell application \"System Events\" to key code $desktopkey using control down"
}
alias switchdesktop=switchdesktop
. "$HOME/.cargo/env"
