#!/bin/bash

. menu.sh

header='Dessert, please'

choices=(
    'Tri leće'
    Eurokrem
    'Plazma  '
    Bananica
    Krempita
)

echo "Move cursor: ↓↑ or jk"
echo "Select: space (in checkbox or radiobutton modes)"
echo "Accept selection: enter, or space in the menu mode"
echo

selected=-2 mode=radiobutton menu "$header" dessert "${choices[@]}"
selected=-2 mode=checkbox min_count=1 max_count=1 checkmark='\e[37;1mX\e[39;22m' menu "$header" dessert "${choices[@]}"
selected=-2 mode=checkbox min_count=0 max_count=1 checkmark='\e[37;1mX\e[39;22m' menu "$header" dessert "${choices[@]}"
selected=-2 mode=checkbox min_count=1 max_count=2 checkmark='\e[37;1m*\e[39;22m' style='> \e[7m< %s > %s\e[0m <' menu "$header" dessert "${choices[@]}"
selected=-2 mode=checkbox min_count=1 max_count=2 checkmark='\e[37;1m*\e[39;22m' style='+++ \e[7m< %s > %s\e[0m +++' nonhl_style='⋅⋅⋅ < %s > %s ⋅⋅⋅' margin='' menu "$header" dessert "${choices[@]}"
selected=-2 mode=checkbox min_count=1 max_count=2 checkmark='\e[37;1m*\e[39;22m' style='>>> \e[0m[ %s ] %s\e[0m <<<' menu "$header" dessert "${choices[@]}"
selected=-2 menu "$header" dessert "${choices[@]}"

echo "Last choice: $dessert"
