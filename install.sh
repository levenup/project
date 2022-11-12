#!/bin/bash
set -e
set -o pipefail
# Needed because if it is set, cd may print the path it changed to.
unset CDPATH

root=$(pwd)

# Whether to run the command in a verbose mode
[[ "$*" =~ '--verbose' ]] && v="/dev/stdout" || v="/dev/null"
[[ "$*" =~ '--ci' ]] && isCi=true || isCi=false

echo """
 _        _______           _______  _                 _______ 
( \      (  ____ \|\     /|(  ____ \( (    /||\     /|(  ____ )
| (      | (    \/| )   ( || (    \/|  \  ( || )   ( || (    )|
| |      | (__    | |   | || (__    |   \ | || |   | || (____)|
| |      |  __)   ( (   ) )|  __)   | (\ \) || |   | ||  _____)
| |      | (       \ \_/ / | (      | | \   || |   | || (      
| (____/\| (____/\  \   /  | (____/\| )  \  || (___) || )      
(_______/(_______/   \_/   (_______/|/    )_)(_______)|/       
                                                               
"""

if [[ $isCi == true ]]
then
    v="/dev/stdout"
    echo "> Making root $root/ci"
    root="$root/ci"
    mkdir $root &> /dev/null
    cd $root
fi

if ! levenup -v &> /dev/null
then
    if ! grep -q "LU_ROOT=.*" ~/.bashrc
    then
        printf "> Saving profile..."
        echo "export LU_ROOT=$root" >> ~/.bashrc 
        echo "source $root/tools/commands.sh" >> ~/.bashrc 
        echo "export LU_ROOT=$root" >> ~/.zshrc 
        echo "source $root/tools/commands.sh" >> ~/.zshrc 
        echo "✔"
    fi
fi

printf "> Sourcing profile..."
. ~/.bashrc &> /dev/null
. ~/.zshrc &> /dev/null
echo "✔"

if [[ ! -d ".git" ]]
then
    while [[ -z $email ]]
    do
        read  -r -p  ". Please introduce your @levenup address: " email
    done
    firstname=$(sed -n "s/^(\w)+\." <<< $email)
    firstnameC=$(echo $firstname | cut -c1 | tr "[:lower:]" "[:upper:]")$(echo $firstname | cut -c2-)
    firstnameL=$(echo "$firstname" | tr '[:upper:]' '[:lower:]')
    surname=$(sed -n "s/^.*\.(\w)+\@" <<< $email)
    surnameL=$(echo "$surname" | tr '[:upper:]' '[:lower:]')
    surnameU=$(echo "$surname" | tr '[:lower:]' '[:upper:]')

    fullname="$firstnameC $surnameU"

    printf "> Initialising Git..."
    git init &> $v || {
        echo
        echo "something went wrong!"
        exit 1;
    }
    echo "✔"

    git config --local user.name "$fullname"
    git config --local user.email "$email"
else 
    fullname=$(git config --local user.name)
fi
    
echo 
echo "👋 Welcome $fullname!"
echo 

[[ ! -d "./tools" ]] && freshInstall=true || freshInstall=false

[[ $freshInstall == true ]] && {
    REINSTALL=true
    LUENV=dev
} || {
    REINSTALL=false
    while ! [[ $fresh =~ ^YES|Yes|y|NO|No|n$ ]]
    do
        read  -r -p  "Re-install? (y|n) " fresh
    done
    [[ $fresh =~ ^YES|Yes|yes|y$ ]] && {
        while ! [[ $env =~ ^dev|uat|pro$ ]]
        do
            read  -r -p  "Environment? (dev|uat|pro) " env
        done
        REINSTALL=true
        LUENV=$env
    }
}

[[ -d "./tools" ]] || {
    echo "> Clone Tools..."
        git clone https://github.com/levenup/tools.git &> $v || {
        echo
        echo "something went wrong!"
        exit 1;
    }
}
[[ -d "./frontend" ]] || {
    echo "> Clone Frontend..."
        git clone https://github.com/levenup/frontend.git &> $v || {
        echo
        echo "something went wrong!"
        exit 1;
    }
}
[[ -d "./backend" ]] || {
    echo "> Clone Backend..."
        git clone https://github.com/levenup/backend.git &> $v || {
        echo
        echo "something went wrong!"
        exit 1;
    }
}

echo 
printf "> Moving to /mobile..."
cd frontend/mobile
echo "✔"
. ../../tools/setup_environment.sh "$*"

echo 
printf "> Moving to /firebase..."
cd ../../
cd backend/firebase
echo "✔"
. ../../tools/backend/emulator/setup.sh "$*"

echo 
printf "> Moving to /mobile..."
cd ../../../
cd frontend/mobile
echo "✔"
. ../../tools/setup_mobile.sh "$*"


echo 
printf "> Moving to /emulator..."
cd ../../
cd backend/firebase/emulator
echo "✔"
. ../../../tools/backend/deploy.sh "$*"

echo
echo "LEVENUP succesfully installed!"
echo