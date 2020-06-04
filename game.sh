#!/bin/bash


board=(" " " " " " " " " " " " " " " " " " " ")
blue="\033[34m"
green="\033[32m"
white="\033[0m"

init() {
  FIFO=game_fifo

  if [[ ! -p $FIFO ]]
  then
    player=0
  else
    player=1
  fi

  if [[ $player -ne 0 ]]
  then
    his_sign=$blue'O'$white
    other_player_sign=$green'X'$white
  else
    his_sign=$green'X'$white
    other_player_sign=$blue'O'$white
  fi

  if [[ $player -eq 0 ]]
  then
    mkfifo $FIFO
  fi
}

function draw_board() {
  clear

  #instruction
  echo -e "           _ _ _\n1 2 3     |_|_|_|\n4 5 6  →  |_|_|_|\n7 8 9     |_|_|_|\n\n"
  
  #board
  echo "   --- --- ---"
  echo -e "  | ${board[1]} | ${board[2]} | ${board[3]} |"
  echo "   --- --- ---"
  echo -e "  | ${board[4]} | ${board[5]} | ${board[6]} |"
  echo "   --- --- ---"
  echo -e "  | ${board[7]} | ${board[8]} | ${board[9]} |"
  echo "   --- --- ---"
}

set_board() {
  INDEX=$BASH_REMATCH
  board[$INDEX]=$1
}

function transfer_control () {
  read_cell
  echo "$((INDEX))" > $FIFO
  set_board $his_sign
}

read_cell() {
  if [[ -n $1 ]]
  then
    WHERE=$1
  else
    unset WHERE
  fi

  while true
  do
    if [[ -z $1 ]]
    then
      echo -n "What is your move? "
    fi

    local line

    if [[ -z $1 ]]
    then
      read -r line
    else
      read -r line<"$1"
    fi

    if [[ $line =~ ^([1-9])$ ]]
    then
      INDEX=$BASH_REMATCH
    else
      echo "Enter a number from 1 to 9"
      continue
    fi

    if [[ ${board[INDEX]} != " " ]]
    then
      if [[ -z $WHERE ]]
      then
        echo "This cell is already taken"
      else
        echo "This cell is already taken" >"$WHERE"
      fi
    else
      break
    fi
  done
}

game_loop() {
  if [[ $player -eq 0 ]]
  then
    draw_board
    transfer_control
  fi

  while true
  do
    draw_board
    echo "Wait your turn"
    read_cell $FIFO
    set_board $other_player_sign
    game_over $other_player_sign
    draw_board
    transfer_control
    game_over $his_sign
  done
}

game_over_field() {
  draw_board

  if [[ $1 -eq 2 ]]
  then
    echo "Frindship won!)"
    rm -f $FIFO
    exit 0
  fi

  if [[ $2 == "$his_sign" && $1 -eq 0 ]]
  then
    echo "You win!)"
  else
    echo -e "Player $2 win!"
  fi

  rm -f $FIFO
  exit 0
}

game_over() {
  EMPTY_CELL=0

  #row
  if [[ ${board[1]} == "$1" ]] && [[ ${board[2]} == "$1" ]] && [[ ${board[3]} == "$1" ]]
  then
    game_over_field 0 "$1"
  fi

  if [[ ${board[4]} == "$1" ]] && [[ ${board[5]} == "$1" ]] && [[ ${board[6]} == "$1" ]]
  then
   game_over_field 0 "$1"
  fi

  if [[ ${board[7]} == "$1" ]] && [[ ${board[8]} == "$1" ]] && [[ ${board[9]} == "$1" ]]
  then
    game_over_field 0 "$1"
  fi

  #column
  if [[ ${board[1]} == "$1" ]] && [[ ${board[4]} == "$1" ]] && [[ ${board[7]} == "$1" ]]
  then
    game_over_field 0 "$1"
  fi

  if [[ ${board[2]} == "$1" ]] && [[ ${board[5]} == "$1" ]] && [[ ${board[8]} == "$1" ]]
  then
    game_over_field 0 "$1"
  fi

  if [[ ${board[3]} == "$1" ]] && [[ ${board[6]} == "$1" ]] && [[ ${board[9]} == "$1" ]]
  then
    game_over_field 0 "$1"
  fi
  #diagonals

  if [[ ${board[5]} == "$1" ]] && [[ ${board[3]} == "$1" ]] && [[ ${board[7]} == "$1" ]]
  then
    game_over_field 0 "$1"
  fi

  if [[ ${board[5]} == "$1" ]] && [[ ${board[1]} == "$1" ]]  && [[ ${board[9]} == "$1" ]]
  then
    game_over_field 0 "$1"
  fi

  for i in {1..9}
  do
    if [[ ${board[$i]} == " " ]]
    then
      EMPTY_CELL=$((EMPTY_CELL + 1)) 
    fi
  done

  if [[ $EMPTY_CELL -eq 0 ]]
  then
    game_over_field 2 
  fi
  return 1
}

clear
init
game_loop
