#!/bin/bash
# BY: LingYi
# DATE: 2016.02.23


#place temporary files
tmpdir='/tmp'

#u:up d:down l:left r:right
boundary_u=2
boundary_d=26
boundary_l=3
boundary_r=80

boundary_color=45
smallboundary_color=34
#

#about time (second)
#about color (x0:black x1:red  x2:green x3:Orange x4:blue x5:pink x6:light blue) x=[3|4]

#about tank
#if enemy_tank_color is empty, it will be random value of enemy_tank_color_type.
enemy_tank_color_type=( 41 43 43 45 44 46 )
enemy_tank_color=''

#level: 0    1  ..  8   9   10   11   ..  18  19 (20)
#time : 1.0 0.9 .. 0.2 0.1 0.09 0.08  .. 0.01 0 
game_level=9

my_tank_color=42

#about bullet
enemy_bullet_color=41
enemy_bullet_speed=0.02

my_bullet_color=41
my_bullet_speed=0

#after tank dead, next will appear
next_tank_interval_time=0.5

#about death symbol 
symbol_keep_time=1


#game PID
MYPID=$$

#
#SIGNAL: [20-31] [35-36]
#stop enemy tank signal: 20 (PID: $run_enemytank_pid)
#enemy tank be hitted: 22 (PID: $run_enemytank_pid)
#enemy tank pause: 23 (PID: $run_enemytank_pid)
#enemy tank continue after pause: 24 (PID: $run_enemytank_pid)
#enemy tank level/speed up: 28 (PID: $run_enemytank_pid)
#enemy tank level/slow down: 29 (PID: $run_enemytank_pid)
#stealth mode: 35 (PID: $run_enemytank_pid)
#cancel stealth mode: 36 (PID: $run_enemytank_pid)

#game over: 21 (PID: $MYPID)
#mytank pause: 25 (PID: $MYPID)
#mytank continue: 26 (PID: $MYPID)

#for "LingYi" components: 27 (PID: run_print_mywords_pid)
#for "infor" components: 30 (PID: run_print_infors_pid)
#for "Dtime" components: 31 (PID: run_print_dtime_pid)

#components [ true|false ]
print_mode=true
print_infor=true
print_LingYi=true
print_dtime=true
print_roll=true


expressions=('o(-"-)o' '^*(- -)*^' '($ _ $)' '(^O^)' 'Y(^_^)Y')
string1="you are so smart !"
string2="you are really talented !"
string3="Come on, boy !"
string4="I believe you will win !"
string5="Keep up the good work !"
strings=("$string1" "$string2" "$string3" "$string4" "$string5")
gameover_string="Stupid guy ~~ ha-ha !!!"
#

infor1="The game is running !"
infor2='Press "C" to continue !'
infor3='Press "P" to pause game !'
infor4='Press "U" to level up !'
infor5='Press "L" to slow down ! '
infor6='Press "Q" to end the game !'
infor7='Press "F" to kill one tank !'
infor8='Press "G" to open/close Stealth Mode !'
infor9='Press "V" to open/close God Mode '
infor10='press "N" to kill all tanks !'
infor11='if pressed "N", press M to close it !'
infor12='Press Space or Enter key to shoot !'
infors=("$infor1" "$infor2" "$infor3" "$infor4" "$infor5" "$infor6" "$infor7"\
	${infors[@]} "$infor7" "$infor9" "$infor10" "$infor11" "$infor12")

roll_words="Tank Game  LingYi 2016.03.01 Y(^_^)Y"
# Positions of Enemytanks:
# =============================
# | 0           4           2 |
# |      9(random)            |
# | 7           8           5 |
# |                           |
# | 1           6           3 |
# =============================
#Define random positions, if allow using.
#value [ yes|no ]
random_9_position="yes"
random_8_position="no"
random_7_position="yes"
random_6_position="yes"
random_5_position="yes"
random_4_position="yes"
random_3_position="yes"
random_2_position="yes"
random_1_position="yes"
random_0_position="yes"

#get random direction.
GetRandDirect()
{
	case $[RANDOM%4] in 
		0) echo u;; 
		1) echo d;;
		2) echo l;; 
		3) echo r;; 
	esac; 
}

#display and record in the file.
#HandleTank {-d|-c} "x;y" {u|d|l|r} enemy/my
HandleTank()
{
	local hp=($(echo "$2" | awk -F';' '{print $1,$2}'))
	local body body_col
	body[0]="$2"
	case $3 in
	'u')
		body[1]="$((hp[0]+1));$((hp[1]-1))" 
		body[2]="$((hp[0]+1));$((hp[1]+1))" 
		body[3]="$((hp[0]+2));$((hp[1]-1))" 
		body[4]="$((hp[0]+2));$((hp[1]+1))" 
		;;
	'd')
		body[1]="$((hp[0]-1));$((hp[1]+1))"
		body[2]="$((hp[0]-1));$((hp[1]-1))"
		body[3]="$((hp[0]-2));$((hp[1]+1))"
		body[4]="$((hp[0]-2));$((hp[1]-1))"
		;;
	'l')
		body[1]="$((hp[0]+1));$((hp[1]+1))"
		body[2]="$((hp[0]-1));$((hp[1]+1))"
		body[3]="$((hp[0]+1));$((hp[1]+2))"
		body[4]="$((hp[0]-1));$((hp[1]+2))"
		;;
	'r')
		body[1]="$((hp[0]-1));$((hp[1]-1))"
		body[2]="$((hp[0]+1));$((hp[1]-1))"
		body[3]="$((hp[0]-1));$((hp[1]-2))"
		body[4]="$((hp[0]+1));$((hp[1]-2))"
		;;
	esac
	if [[ $1 == '-c' ]]; then
		local i
		for((i=0; i<5; i++)); do
			echo -ne "\033[${body[i]}H \033[0m"
		done
		return 
	fi
	case $4 in
	"enemy")
		body_col=$seted_enemy_tank_color 
		body_symbol=(' ' ' ' ' ' ' ' ' ')
		echo "${body[@]}" >${tmpdir}/enemybody ;;
	"my" )
		body_col=$my_tank_color 
		body_symbol=('*' '*' '*' '*' '*')
		echo "${body[@]}" >${tmpdir}/mybody    ;;
	*    )  : ;;
	esac
	for((i=0; i<5; i++)); do
		echo -ne "\033[${body[i]}H\033[${body_col}m${body_symbol[i]}\033[0m"
	done
}

DisplayRandTank()
{
	local positions='0123456789'
	[[ ${random_9_position} == "no" ]] && positions=$(echo $positions | sed "s/9//")
	[[ ${random_8_position} == "no" ]] && positions=$(echo $positions | sed "s/8//")
	[[ ${random_7_position} == "no" ]] && positions=$(echo $positions | sed "s/7//")
	[[ ${random_6_position} == "no" ]] && positions=$(echo $positions | sed "s/6//")
	[[ ${random_5_position} == "no" ]] && positions=$(echo $positions | sed "s/5//")
	[[ ${random_4_position} == "no" ]] && positions=$(echo $positions | sed "s/4//")
	[[ ${random_3_position} == "no" ]] && positions=$(echo $positions | sed "s/3//")
	[[ ${random_2_position} == "no" ]] && positions=$(echo $positions | sed "s/2//")
	[[ ${random_1_position} == "no" ]] && positions=$(echo $positions | sed "s/1//")
	[[ ${random_0_position} == "no" ]] && positions=$(echo $positions | sed "s/0//")
	local rand_direct=$(GetRandDirect)
	local rand_pos
	while :
	do 
		rand_pos=$[RANDOM%10]
		echo $positions | grep -q $rand_pos && break
	done

	#set enemy tank body color
	if [[ -z $enemy_tank_color ]]; then
		seted_enemy_tank_color=${enemy_tank_color_type[$(( RANDOM % ${#enemy_tank_color_type[@]} ))]}
	else
		seted_enemy_tank_color=$enemy_tank_color
	fi

	PositionNine(){
		local hand_1 hand_2
		while :
		do 
			head_1=$((RANDOM%boundary_d))
			[[ $head_1 -ge $(( boundary_u+3)) ]] && [[ $head_1 -le $(( boundary_d-3 )) ]] && break
		done
		while :
		do 
			head_2=$((RANDOM%boundary_r))
			[[ $head_2 -ge $(( boundary_l+3)) ]] && [[ $head_2 -le $(( boundary_r-3 )) ]] && break
		done
		hp="${head_1};${head_2}"
	}
	case $rand_direct in
	'u')
		case $rand_pos in 
		0) hp="$(( boundary_u+1 ));$(( boundary_l+2 ))" ;;
		1) hp="$(( boundary_d-3 ));$(( boundary_l+2 ))" ;;
		2) hp="$(( boundary_u+1 ));$(( boundary_r-2 ))" ;;
		3) hp="$(( boundary_d-3 ));$(( boundary_r-2 ))" ;;
		4) hp="$(( boundary_u+1 ));$(( (boundary_r-boundary_l)/2+boundary_l ))" ;;
		5) hp="$(( (boundary_d-boundary_u)/2+boundary_u ));$(( boundary_r-2 ))" ;;
		6) hp="$(( boundary_d-3 ));$(( (boundary_r-boundary_l)/2+boundary_l ))" ;;
		7) hp="$(( (boundary_d-boundary_u)/2+boundary_u ));$(( boundary_l+2 ))" ;;
		8) hp="$(( (boundary_d-boundary_u)/2+boundary_u));$(( (boundary_r-boundary_l)/2+boundary_l ))" ;;
		9) PositionNine ;;
		esac ;;
	'd')
		case $rand_pos in 
		0) hp="$(( boundary_u+3 ));$(( boundary_l+2 ))" ;;
		1) hp="$(( boundary_d-1 ));$(( boundary_l+2 ))" ;;
		2) hp="$(( boundary_u+3 ));$(( boundary_r-2 ))" ;;
		3) hp="$(( boundary_d-1 ));$(( boundary_r-2 ))" ;;
		4) hp="$(( boundary_u+3 ));$(( (boundary_r-boundary_l)/2+boundary_l  ))" ;;
		5) hp="$(( (boundary_d-boundary_u)/2+boundary_u ));$(( boundary_r-2 ))" ;;
		6) hp="$(( boundary_d-1 ));$(( (boundary_r-boundary_l)/2+boundary_l ))" ;;
		7) hp="$(( (boundary_d-boundary_u)/2+boundary_u ));$(( boundary_l+2 ))" ;;
		8) hp="$(( (boundary_d-boundary_u)/2+boundary_u ));$(( (boundary_r-boundary_l)/2+boundary_l ))" ;;
		9) PositionNine ;;
		esac ;;
	'l')
		case $rand_pos in 
		0) hp="$(( boundary_u+2 ));$(( boundary_l+1 ))" ;;
		1) hp="$(( boundary_d-2 ));$(( boundary_l+1 ))" ;;
		2) hp="$(( boundary_u+2 ));$(( boundary_r-3 ))" ;;
		3) hp="$(( boundary_d-2 ));$(( boundary_r-3 ))" ;;
		4) hp="$(( boundary_u+2 ));$(( (boundary_r-boundary_l)/2+boundary_l ))" ;;
		5) hp="$(( (boundary_d-boundary_u)/2+boundary_u ));$(( boundary_r-3 ))" ;;
		6) hp="$(( boundary_d-2 ));$(( (boundary_r-boundary_l)/2+boundary_l ))" ;;
		7) hp="$(( (boundary_d-boundary_u)/2+boundary_u ));$(( boundary_l+1 ))" ;;
		8) hp="$(( (boundary_d-boundary_u)/2+boundary_u ));$(( (boundary_r-boundary_l)/2+boundary_l ))" ;;
		9) PositionNine ;;
		esac ;;
	'r')
		case $rand_pos in
		0) hp="$(( boundary_u+2 ));$(( boundary_l+3 ))" ;;
		1) hp="$(( boundary_d-2 ));$(( boundary_l+3 ))" ;;
		2) hp="$(( boundary_u+2 ));$(( boundary_r-1 ))" ;;
		3) hp="$(( boundary_d-2 ));$(( boundary_r-1 ))" ;;
		4) hp="$(( boundary_u+2 ));$(( (boundary_r-boundary_l)/2+boundary_l ))" ;;
		5) hp="$(( (boundary_d-boundary_u)/2 ));$(( boundary_r-1 ))" ;;
		6) hp="$(( boundary_d-2 ));$(( (boundary_r-boundary_l)/2+boundary_l ))" ;;
		7) hp="$(( (boundary_d-boundary_u)/2+boundary_u ));$(( boundary_l+3 ))" ;;
		8) hp="$(( (boundary_d-boundary_u)/2+boundary_ ));$(( (boundary_r-boundary_l)/2+boundary_l ))" ;;
		9) PositionNine ;;
		esac ;;
	esac
	
	enemytank_direct=$rand_direct
	first_moving=true
	
	#clean up the small boundary
	local n m
	for n in 1 2 3 4 5 
	do
		for m in 4 5 6 7 8 9 10
		do 
			echo -ne "\033[$((boundary_u+n));$((boundary_r+m))H*\033[0m"	
		done
	done 	
	#display a tank model in small boundary
	case $enemytank_direct in
	'u') small_boundary_tank_head="$((boundary_u+2));$((boundary_r+7))" ;;
	'd') small_boundary_tank_head="$((boundary_u+4));$((boundary_r+7))" ;;
	'l') small_boundary_tank_head="$((boundary_u+3));$((boundary_r+6))" ;;
	'r') small_boundary_tank_head="$((boundary_u+3));$((boundary_r+8))" ;;
	esac
	HandleTank -d "$small_boundary_tank_head" $enemytank_direct enemy
	
	HandleTank -d "$hp" $enemytank_direct enemy
	
}


#get a new position from new, old direction and an old position.
#GetNewPos $newdirect $olddirect $headpoint(x y)
GetNewPos(){
	local new_head=($3 $4)
	
	case $1 in
	'u')
		case $2 in
		'u') [[ new_head[0] -gt $((boundary_u+1)) ]] && (( new_head[0]-=1 ));;
		'd') (( new_head[0]-=2 ));;
		'l') (( new_head[0]-=1 )); (( new_head[1]+=1 ));;
		'r') (( new_head[0]-=1 )); (( new_head[1]-=1 ));;
		esac
		;;
	'd')
		case $2 in
		'u') (( new_head[0]+=2 ));;
		'd') [[ new_head[0] -lt $((boundary_d-1)) ]] && (( new_head[0]+=1 ));;
		'l') (( new_head[0]+=1 )); (( new_head[1]+=1 ));;
		'r') (( new_head[0]+=1 )); (( new_head[1]-=1 ));;
		esac
		;;
	'l')
		case $2 in
		'u') (( new_head[0]+=1 )); (( new_head[1]-=1 ));;
		'd') (( new_head[0]-=1 )); (( new_head[1]-=1 ));;
		'l') [[ new_head[1] -gt $((boundary_l+1)) ]] && (( new_head[1]-=1 ));;
		'r') (( new_head[1]-=2 ));;
		esac
		;;
	'r')
		case $2 in
		'u') (( new_head[0]+=1 )); (( new_head[1]+=1 ));;
		'd') (( new_head[0]-=1 )); (( new_head[1]+=1 ));;
		'l') (( new_head[1]+=2 ));;
		'r') [[ new_head[1] -lt $((boundary_r-1)) ]] && (( new_head[1]+=1 ));;
		esac
		;;
	esac
	echo "${new_head[@]}"
}

#it run in background
MoveEnemyTank(){

	local upgrade_count=10   
	local bullet_interval=10   #default value
	local bullet_interval_range=20
	local StopEnemyTank=false
	local BeHitted=false
	local PauseEnemyTank=false
	local game_score=0 
	local old_game_score=0
	local ignore_other_tank=false
	local kill_myself=false
	local kill_myself_always=false
	local god_mode=false
	local kill_once_by_god=false

	trap 'StopEnemyTank=true' 20
	trap 'BeHitted=true' 22
	trap 'PauseEnemyTank=true' 23
	trap 'PauseEnemyTank=false; print_running' 24
	trap '[[ $game_level -lt 19 ]] && (( game_level+=1)); print_level' 28
	trap '[[ $game_level -gt 0  ]] && (( game_level-=1)); print_level' 29
	trap 'ignore_other_tank=true' 35
	trap 'ignore_other_tank=false' 36
	trap 'kill_myself=true' 37
	trap 'kill_myself_always=true' 38
	trap 'kill_myself_always=false' 39
	trap 'god_mode=true' 40
	trap 'god_mode=false' 41
	trap 'kill_once_by_god=true' 42
	
	GetTimeFromLevel(){
		[[ $game_level -ge 1  ]] && [[ $game_level -le 9 ]] && echo "0.$((10-game_level))"
		[[ $game_level -ge 10 ]] && echo "0.0$((19-game_level))"
		[[ $game_level -eq 0  ]] && echo "1"
	}
	
	print_running(){
		echo -ne "\033[$((boundary_u+12));$((boundary_r+3))\
		H\033[41m\033[33mState\033[0m  \033[1;34mrunning\033[0m"
	}
	print_level(){
		echo -ne "\033[$((boundary_u+10));$((boundary_r+3))\
		H\033[42m\033[31mLevel\033[0m  \033[1;34m$game_level \033[0m"
	}
	while ! $StopEnemyTank 
	do

		echo -ne "\033[$((boundary_u+8));$((boundary_r+3))\
		H\033[43m\033[31mScore\033[0m  \033[1;34m$game_score\033[0m"
		[[ $old_game_score -ne $game_score ]] && [[ $((game_score%upgrade_count)) -eq 0 ]] && {
			[[ game_level -lt 19 ]] && (( game_level+=1 )) && old_game_score=$game_score
		}
		print_level
		
		current_direct=$enemytank_direct
		if $first_moving; then
			while :
			do 
				future_direct=$( GetRandDirect )
				[[ $future_direct != $current_direct ]] && { first_moving=false; break; }
			done
				
		else
			future_direct=$( GetRandDirect )
		fi
		enemytank_direct=$future_direct
		if [[ $current_direct != $future_direct ]]; then
			current_tank_head=( `awk '{print $1}' ${tmpdir}/enemybody | tr ';' ' '` )
			tank_head=( `GetNewPos $future_direct $current_direct ${current_tank_head[@]}` )
			HandleTank -c "${current_tank_head[0]};${current_tank_head[1]}" $current_direct enemy
			HandleTank -d "${tank_head[0]};${tank_head[1]}" $future_direct enemy
		fi
		
		#$ignore_other_tank || $god_mode && true_false_value=true || true_false_value=false
		#Bullet $enemytank_direct ${tank_head[@]} enemy $true_false_value &
		
		#get the random distance
		case $future_direct in
		'u') allow_distance=$(( tank_head[0]-boundary_u-1 )) ;;
		'd') allow_distance=$(( boundary_d-tank_head[0]-1 )) ;;
		'l') allow_distance=$(( tank_head[1]-boundary_l-1 )) ;;
		'r') allow_distance=$(( boundary_r-tank_head[1]-1 )) ;;
		esac
		[[ allow_distance -eq 0 ]] && continue
		rand_distance=$(( RANDOM % allow_distance + 1 ))
		
		for ((j=1; j<=$rand_distance; j++))
		do	
			$StopEnemyTank && break

			if [[ $bullet_interval -eq 0 ]]; then
				$ignore_other_tank || $god_mode && true_false_value=true || true_false_value=false
				Bullet $enemytank_direct ${tank_head[@]} enemy $true_false_value &
				bullet_interval=$(( RANDOM % bullet_interval_range + 1 ))
			fi

			#pause and continue
			while $PauseEnemyTank
			do 
				echo -ne "\033[$((boundary_u+12));$((boundary_r+3))\
				H\033[41m\033[33mState\033[0m  \033[1;34mPause  \033[0m"
			done

			# if be hitted, make another one
			$kill_myself && BeHitted=true 
			$kill_once_by_god && BeHitted=true
			$kill_myself_always && BeHitted=true
			if $BeHitted; then
				DisplayDeathSymbol $future_direct ${tank_head[@]} enemy &
				sleep $next_tank_interval_time
				DisplayRandTank

				#old_game_socre is for upgrade count.
				old_game_score=$game_score
				(( game_score+=1 ))
				
				(( bullet_interval-=1 ))

				BeHitted=false
				$kill_myself && kill_myself=false
				$kill_once_by_god && BeHitted=false
				break
			fi

			old_tank_head=(${tank_head[@]})
			case $future_direct in
			'u') (( tank_head[0]-=1 )) ;;
			'd') (( tank_head[0]+=1 )) ;;
			'l') (( tank_head[1]-=1 )) ;;
			'r') (( tank_head[1]+=1 )) ;;
			esac
			HandleTank -c "${old_tank_head[0]};${old_tank_head[1]}" $future_direct enemy
			HandleTank -d "${tank_head[0]};${tank_head[1]}" $future_direct enemy

			#judge if collision
			if $(CollisJudge); then
				$god_mode && {
					DisplayDeathSymbol $future_direct ${tank_head[@]} enemy &
					sleep $next_tank_interval_time
					DisplayRandTank
					old_game_score=$game_score
					(( game_score+=1 ))
					(( bullet_interval-=1 ))
					break
				}
 				! ${ignore_other_tank} && {
					DisplayDeathSymbol $future_direct ${tank_head[@]} enemy &
					kill -21 $MYPID
					StopEnemyTank=true
				}
			fi
			(( bullet_interval-=1 ))
			sleep $(GetTimeFromLevel)
		done
	done
}

MoveMyTank()
{
	old_mytank_direct=$mytank_direct
	old_mytank_head=(${mytank_head[@]})
	mytank_direct=$1
	mytank_head=( `GetNewPos $1 $old_mytank_direct ${old_mytank_head[@]}` )
	HandleTank -c "${old_mytank_head[0]};${old_mytank_head[1]}" $old_mytank_direct my
	HandleTank -d "${mytank_head[0]};${mytank_head[1]}" $mytank_direct my

	#collision judgement
	if $(CollisJudge); then
		if $if_god_mode; then
			kill -42 $$run_enemytank_pid &>/dev/null
			HandleTank -d "${mytank_head[0]};${mytank_head[1]}" $mytank_direct my	
		else
			kill -20 $run_enemytank_pid &>/dev/null
			kill -21 $MYPID
		fi
	fi
}

#Bullet $direct $headpoint(x y) { my | enemy [true|false] }
Bullet()
{
	#tank head point / bullet distance [thp/bdis]
	local thp=($2 $3) bdis n
	local myfile=${tmpdir}/mybody
	local enemyfile=${tmpdir}/enemybody

	case $4 in 
	"my") 
		bullet_color=$my_bullet_color
		bullet_symbol='@'
		bullet_speed=$my_bullet_speed ;;
	"enemy") 
		bullet_color=$enemy_bullet_color
		bullet_symbol=' '
		bullet_speed=$enemy_bullet_speed ;;
	esac
	
	case $1 in 
	'u') bdis=$(( thp[0]-boundary_u-2 )); (( thp[0]-=1 )) ;;
	'd') bdis=$(( boundary_d-thp[0]-2 )); (( thp[0]+=1 )) ;;
	'l') bdis=$(( thp[1]-boundary_l-2 )); (( thp[1]-=1 )) ;;
	'r') bdis=$(( boundary_r-thp[1]-2 )); (( thp[1]+=1 ));;
	esac

	
	for((n=1; n<=bdis; n++))
	do
		case $1 in 
		'u') (( thp[0]-=1 )) ;;
		'd') (( thp[0]+=1 )) ;;
		'l') (( thp[1]-=1 )) ;;
		'r') (( thp[1]+=1 )) ;;
		esac
		
		#if the files not exist, means game over.
		#[[ ! -f $myfile ]] || [[ ! -f $enemyfile ]] && break

		case $4 in
		"my")
			if echo " $(cat $enemyfile) " | grep -q " ${thp[0]};${thp[1]} "; then
				kill -22 `cat ${tmpdir}/run_enemytank_pid` &>/dev/null
				break
			fi ;;
		"enemy")
			if ! $5 && echo " $(cat $myfile) " | grep -q " ${thp[0]};${thp[1]} "; then
				kill -21 $MYPID
				break
			fi ;;
		esac
		echo -ne "\033[${thp[0]};${thp[1]}H\033[${bullet_color}m${bullet_symbol}\033[0m"
		sleep $bullet_speed
		echo -ne "\033[${thp[0]};${thp[1]}H \033[0m"
	done
}

#Collision judgment
CollisJudge()
{	
	local k ifcoll=false
	enemy_points=$(cat ${tmpdir}/enemybody)
	my_points=( `cat ${tmpdir}/mybody` )
	for((k=0; k<=4; k++))
	do
		echo " ${enemy_points} " | grep -q " ${my_points[k]} " && { ifcoll=true; break; }
	done
	echo $ifcoll
} 

#DisplayDeathSymbol $direct $tank_head_point(x y) my/enemy [notclean]
#it should be run in background !!
#SYMBOL MODEL
#   1
#  234
# 56789  # [ dead!]
#  012   # 10 11 12
#   3    # 13
#so, we just need to make sure 1,5,9,13 four point.

DisplayDeathSymbol()
{
	local center_point mnt_tank_head=($2 $3)
	local logfile char
	local points="2 3 4 6 7 8 10 11 12"
	case $4 in
	"my") 
		symbol_color=$my_tank_color 
		symbol_symbol='#';;
	"enemy")
		symbol_color=$seted_enemy_tank_color 
		symbol_symbol=' ';;
	esac
	#get the center point of the sysbol
	case $1 in 
	'u') 
		center_point[0]=$(( mnt_tank_head[0]+1 ))
		center_point[1]=${mnt_tank_head[1]} ;;
	'd') 	
		center_point[0]=$(( mnt_tank_head[0]-1 ))
		center_point[1]=${mnt_tank_head[1]} ;;
	'l') 
		center_point[0]=${mnt_tank_head[0]}
		center_point[1]=$(( mnt_tank_head[1]+1 )) ;;
	'r')	
		center_point[0]=${mnt_tank_head[0]}
		center_point[1]=$(( mnt_tank_head[1]-1 )) ;;
	esac
	
	#get the thirteen point
	point_2="$[center_point[0]-1];$[center_point[1]-1]"
	point_3="$[center_point[0]-1];${center_point[1]}"
	point_4="$[center_point[0]-1];$[center_point[1]+1]"
	point_6="${center_point[0]};$[center_point[1]-1]"
	point_7="${center_point[0]};${center_point[1]}"
	point_8="${center_point[0]};$[center_point[1]+1]"
	point_10="$[center_point[0]+1];$[center_point[1]-1]"
	point_11="$[center_point[0]+1];${center_point[1]}"
	point_12="$[center_point[0]+1];$[center_point[1]+1]"
	if [[ $((center_point[0]-boundary_u)) -ge 3 ]]; then
		point_1="$[center_point[0]-2];${center_point[1]}"
		points="${points} 1"
	fi
	if [[ $((center_point[1]-boundary_l)) -ge 3 ]]; then
		point_5="${center_point[0]};$[center_point[1]-2]"
		points="${points} 5"
	fi
	if [[ $((boundary_r-center_point[1])) -ge 3 ]]; then
		point_9="${center_point[0]};$[center_point[1]+2]"
		points="${points} 9"
	fi
	if [[ $((boundary_d-center_point[0])) -ge 3 ]]; then
		point_13="$[center_point[0]+2];${center_point[1]}"
		points="${points} 13"
	fi
	for pn in $points
	do	
		case $pn in
		5) char='d' ;;
		6) char='e' ;;
		7) char='a' ;;
		8) char='d' ;;
		9) char='!' ;;
		*) char=" " ;;
		esac	
		eval echo -ne "\\\033\[\${point_${pn}}H\\\033\[${symbol_color}m\\\033\[31m${char}\\\033\[0m"
	done

	sleep $symbol_keep_time

	#clean up the symbol
	if [[ -z $5 ]]; then
		for pn in $points
		do
			eval echo -ne "\\\033\[\${point_${pn}}H \\\033\[0m"
		done
	fi
}

game_over()
{
	StopKeyboardInput=true
	kill -20 $run_enemytank_pid &>/dev/null
	$print_LingYi && kill -27 $run_print_mywords_pid &>/dev/null
	$print_infor  && kill -30 $run_print_infors_pid &>/dev/null
	$print_dtime  && kill -31 $run_print_dtime_pid &>/dev/null
	$print_mode   && kill -20 $run_print_mode_pid &>/dev/null
	$print_roll   && kill -10 $run_print_roll_words_pid &>/dev/null
	echo -ne "\033[$((boundary_u+12));$((boundary_r+3))H\033[41m\033[33mState\033[0m  \033[1;34mGame Over !!\033[0m"
	local line_posi=$(( (boundary_d-boundary_u)/2+boundary_u-2 ))
	local col_posi=$(( (boundary_r-boundary_l)/2+boundary_l-18 ))
	DisplayDeathSymbol $mytank_direct ${mytank_head[@]} my notclean
	echo -e "\033[$((line_posi + 0 ));${col_posi}H\033[1;31m-----------------------------------\033[0m"
	echo -e "\033[$((line_posi + 1 ));${col_posi}H\033[1;31m|                                 |\033[0m"
	echo -e "\033[$((line_posi + 2 ));${col_posi}H\033[1;31m|      Shit , You Are Dead !      |\033[0m"
	echo -e "\033[$((line_posi + 3 ));${col_posi}H\033[1;31m|                                 |\033[0m"
 	echo -e "\033[$((line_posi + 4 ));${col_posi}H\033[1;31m-----------------------------------\033[0m"
	tput cnorm
	echo -ne "\033[$((boundary_d+1));$((boundary_r+1))H\n\033[0m"
	#read -s -t 1 -n 100 
}

print_mywords()
{
	[[ -z $strings ]] || [[ -z $expressions ]] && return
	StopSaying=false
	trap 'StopSaying=true' 27
	local oldwords space_sum="" i mywords="example" 
	local myexpress="" oldexpress
	
	echo -ne "\033[$((boundary_u+20));$((boundary_r+3))H\033[45m\033[1;39mLingYi\033[0m:"
	while ! $StopSaying 
	do 	
		space_sum=" "
		
		#print the words and expression.
		mywords="${strings[$((RANDOM%${#strings[@]}))]}"
		myexpress="${expressions[$((RANDOM%${#expressions[@]}))]}"
		c1=3$((RANDOM%6+1))
		c2=3$((RANDOM%6+1))
		echo -ne "\033[$((boundary_u+21));$((boundary_r+3))H\033[1;${c1}m${mywords} \033[${c2}m${myexpress}\033[0m"
		sleep $((RANDOM%2))

		#clean up the words and expression
		for((i=1; i<=$((${#mywords}+${#myexpress})); i++))
		do
			space_sum="${space_sum} "
		done
		echo -ne "\033[$((boundary_u+21));$((boundary_r+3))H${space_sum}\033[0m"
	done
	c3=3$((RANDOM%6+1))
	echo -ne "\033[$((boundary_u+21));$((boundary_r+3))H\033[${c3}m${gameover_string}\033[0m"
}

print_infors()
{	
	[[ -z $infors ]] && return
	StopPrinting=false
	trap 'StopPrinting=true' 30
	local space_sum infor i

	echo -ne "\033[$((boundary_u+17));$((boundary_r+3))H\033[46m\033[1;39mInfor\033[0m: "
	while ! $StopPrinting
	do 
		space_sum=""
		infor="${infors[$((RANDOM%${#infors[@]}))]}"
		echo -ne "\033[$((boundary_u+18));$((boundary_r+3))H${infor}\033[0m"
		sleep $((RANDOM%2))
		
		for((i=1; i<=${#infor}; i++))
		do
			space_sum="${space_sum} "
		done
		echo -ne "\033[$((boundary_u+18));$((boundary_r+3))H${space_sum}\033[0m"
	done
	echo -ne "\033[$((boundary_u+18));$((boundary_r+3))HGame is over, bye !\033[0m"
}

print_dtime()
{
	StopDate=false
	trap 'StopDate=true' 31
	echo -ne "\033[$((boundary_u+23));$((boundary_r+3))H\033[42m\033[1;33mDtime\033[0m"
	while ! $StopDate
	do 
		echo -ne "\033[$((boundary_u+24));$((boundary_r+3))H$(date +'%Y.%m.%d %H:%M:%S')\033[0m"
		sleep 1
	done
}

print_mode()
{
	StopMode=false
	
	StealthModeState="off"
	SMc=31
	GodModeState="off"
	GMc=31
	KillAlwaysModeState="off"
	KMc=31
	trap 'StealthModeState="on "; SMc=32' 21
	trap 'StealthModeState="off"; SMc=31' 22
	trap 'GodModeState="on "; GMc=32' 23
	trap 'GodModeState="off"; GMc=31' 24
	trap 'KillAlwaysModeState="on "; KMc=32' 25
	trap 'KillAlwaysModeState="off"; KMc=31' 26
	trap 'StopMode=true' 20

	echo -ne "\033[$((boundary_u+14));$((boundary_r+3))H\033[43m\033[1;33mMode \033[0m"
	while ! $StopMode
	do
		STRING1="Stealth: $StealthModeState God: $GodModeState Kills: $KillAlwaysModeState"
		echo -ne "\033[$((boundary_u+15));$((boundary_r+3))\
		H\033[1;34mStealth: \033[${SMc}m$StealthModeState\033[0m"
		echo -ne "\033[$((boundary_u+15));$((boundary_r+17))\
		H\033[1;34mGod: \033[${GMc}m$GodModeState\033[0m"
		echo -ne "\033[$((boundary_u+15));$((boundary_r+26))\
		H\033[1;34mKills: \033[${KMc}m$KillAlwaysModeState\033[0m"
		sleep 1
	done
}

print_roll_words()
{
	local stop_roll=false
	local strings=$roll_words
	local line=$boundary_u
	local col_s=$((boundary_l+1))
	local col_e=$((boundary_r-1))
	local sleep_time=0.1
	local i
	local rull_pids=()

	trap 'stop_roll=true' 10

	print_char()
	{	local j old_j=$col_e
		local stop_print=false
		trap 'stop_print=true' 10
		for((j=$col_e; j>=col_s; j--))
		do	$stop_print && break
			[[ $i -eq $((${#strings}-1)) ]] && echo -ne "\033[${line};${old_j}H\033[${boundary_color}m \033[0m"
			echo -ne "\033[${line};${j}H\033[${boundary_color}m\033[1;37m${strings:i:1}\033[0m"
			old_j=$j	
			sleep $sleep_time
		done
	}
	while :
	do
		for((i=0; i<${#strings}; i++))
		do
			$stop_roll && break
			print_char &
			roll_pids=(${roll_pids[@]} $!)
			sleep $sleep_time
		done
		echo -ne "\033[${line};${col_s}H\033[${boundary_color}m \033[0m"
		$stop_roll && {
			for((i=0; i<${#roll_pids[@]}; i++))
			do
				kill -10 ${roll_pids[i]} &>/dev/null
			done
			break
		} 
		for((t=1; t<=12; t++))
		do
			$stop_roll && break || sleep 0.5
		done
		
	done
	for((i=boundary_l; i<=boundary_r; i++))
	do
		echo -ne "\033[${boundary_u};${i}H\033[${boundary_color}m \033[0m"
	done
}

#StealthMode true/false
StealthMode()
{
	[[ -n $if_god_mode ]] && $if_god_mode && return
	if_opened=${if_opened:-false}
	stealth_opened_times=${stealth_opened_times:-0}
	! $if_opened && [[ $stealth_opened_times -eq 0 ]]&& {
		kill -35 $run_enemytank_pid &>/dev/null
		kill -21 $run_print_mode_pid &>/dev/null
		if_opened=true
		let stealth_opened_times++
		old_my_tank_color1=$my_tank_color
		my_tank_color=$boundary_color
		HandleTank -d "${mytank_head[0]};${mytank_head[1]}" $mytank_direct my
		return 
	}
	$if_opened && [[ $stealth_opened_times -ne 0 ]] && {
		kill -36 $run_enemytank_pid &>/dev/null
		kill -22 $run_print_mode_pid &>/dev/null
		if_opened=false
		let stealth_opened_times--
		my_tank_color=$old_my_tank_color1
		HandleTank -d "${mytank_head[0]};${mytank_head[1]}" $mytank_direct my
	}
}

GodMode()
{
	if_god_mode=${if_god_mode:-false}
	god_opened_times=${god_opened_times:-0}
	! $if_god_mode && [[ $god_opened_times -eq 0 ]] && {
		kill -40 $run_enemytank_pid &>/dev/null
		kill -23 $run_print_mode_pid &>/dev/null
		if_god_mode=true
		let god_opened_times++
		old_my_tank_color2=$my_tank_color
		my_tank_color=41
		HandleTank -d "${mytank_head[0]};${mytank_head[1]}" $mytank_direct my
		return
	}
	$if_god_mode && [[ $god_opened_times -ne 0 ]] && {
		kill -41 $run_enemytank_pid &>/dev/null
		kill -24 $run_print_mode_pid &>/dev/null
		if_god_mode=false
		let god_opened_times--
		my_tank_color=$old_my_tank_color2
		HandleTank -d "${mytank_head[0]};${mytank_head[1]}" $mytank_direct my
	}
}

#-------------------------------------
#|         executable code           |
#-------------------------------------

DisFrame()
{ 
	stop=false
	trap "stop=true" 10
	while ! $stop
	do 
		for ((i=1; i<=cols;    i++)); do 
			echo -ne "\033[1;${i}H\033[4$((RANDOM%6+1))m \033[0m"
		done
		for ((i=2; i<=lines;   i++)); do 
			echo -ne "\033[${i};${cols}H\033[4$((RANDOM%6+1))m \033[0m"
		done
		for ((i=cols-1; i>=1 ; i--)); do 
			echo -ne "\033[${lines};${i}H\033[4$((RANDOM%6+1))m \033[0m"
		done
		for ((i=lines-1; i>=2; i--)); do 
			echo -ne "\033[${i};1H\033[4$((RANDOM%6+1))m \033[0m"
		done
		for ((i=2; i<=cols-1;  i++)); do 
			echo -ne "\033[2;${i}H\033[4$((RANDOM%6+1))m \033[0m"
		done
		for ((i=2; i<=lines-1; i++)); do 
			echo -ne "\033[${i};$[cols-1]H\033[4$((RANDOM%6+1))m \033[0m"
		done
		for ((i=cols-2; i>=2;  i--)); do 
			echo -ne "\033[$[lines-1];${i}H\033[4$((RANDOM%6+1))m \033[0m"
		done
		for ((i=lines-2; i>=2; i--)); do 
			echo -ne "\033[${i};2H\033[4$((RANDOM%6+1))m \033[0m"
		done
		sleep 0.1
	done
}

# $0 char sleep_time start_line end_line start_col  upper/low  upper/low  left/right
PrintChar2(){
	aa='echo -ne "\033[${i};${5}H\033[1;${6}m$1\033[0m"; sleep $2'
	bb='[[ $i -ne $4 ]] && echo -ne "\033[${i};${5}H\033[1;${6}m \033[0m"'
	if [[ ${8} == "left" ]]; then
		[[ ${7} == "upper" ]] && for((i=$3; i<=$4; i++)); do eval "$aa; $bb"; done
		[[ ${7} == "low"   ]] && for((i=$3; i>=$4; i--)); do eval "$aa; $bb"; done
	fi
}

cols=`tput cols`
lines=`tput lines`
clear

DisFrame &
DisFramePid=$!

#DisSymbol $[lines/2-6] $[cols/2-34] 32 
a='&&&&&    &     &    &&  &   &      &        &        &     &     &&&&&&'
b='  &     & &    &   & &  & &       & & &    & &      & &   &      &     '
c='  &    &&&&&   &  &  &  &&       &  &&&   &&&&&    &   & &   &&  &&&&&&'
d='  &   &     &  & &   &  & &       &   &  &     &  &     &     &  &     '
e='  &  &       & &&    &  &   &       & & &       &&             & &&&&&&'
abcde=(a b c d e)
for((i=0; i<5; i++)); do
	eval echo -ne "\"\033[$(($[lines/2-6]+$i));$[cols/2-34]H\033[1;5;32m\$${abcde[i]}\033[0m\""
	sleep 0.1
done 

echo -ne "\033[$[lines/2];$[cols/2-3]H\(==)/"

i=1
col=$[cols/2-17]
while [[ $i -le 35 ]]; do
	echo -ne "\033[$[lines/2+1];${col}H\033[45m \e[0m"
	echo -ne "\033[$[lines/2+3];${col}H\033[45m \e[0m"
	sleep 0
	(( i+=1 ))
	(( col+=1 ))
done

strings="Made by LingYi"
col=$[cols/2-6]
for ((a=0;a<=${#strings}-1;a++)); do
	for((i=$[cols-2]; i>=$col; i--)); do
		echo -ne "\033[$[lines/2+2];${i}H\033[1;33m${strings:a:1}\033[0m"
		[[ $i -ne $col ]] && echo -ne "\033[$[lines/2+2];${i}H\033[1;$33m \033[0m"
	done	
	let col++
done

strings='Are You Ready ? [Y/N]'
col=$[cols/2-10]
for ((a=0;a<=${#strings}-1;a++)); do
	[[ $[RANDOM%2] -eq 0 ]] && {
		PrintChar2 "${strings:a:1}" 0 $[lines/2+4] $[lines/2+5] $col  31 upper left
	} || PrintChar2 "${strings:a:1}" 0 $[lines-2] $[lines/2+5] $col  31 low left 
	let col++
done

while :; do
	echo "ynq" | grep -q ${ch:-H} && {
		kill -10 ${DisFramePid} &>/dev/null
		break
	}
	echo -ne "\033[$[lines/2+5];$[cols/2-10]H\033[1;31mAre You Ready ? [Y/N]"
	read -s -n 1 ch
	ch=$(echo ${ch} | tr 'A-Z' 'a-z')
done

#======

[[ -z $ch ]] || [[ $ch == 'y' ]] && : || { clear; exit; }


check_invironment(){
	
	local n=0 m=0 q=0 i j k long 
	if [[ $((boundary_d-boundary_u)) -lt 24 ]]; then
		echo windows [ lines ] too small !
		exit
	fi
	for((i=0; i<${#expressions[@]}; i++))
	do 
		[[ ${#expressions[i]} -gt n ]] && n=${#expressions[i]}
	done
	for((j=0; j<${#strings[@]}; j++))
	do 
		[[ ${#strings[j]} -gt m ]] && m=${#strings[j]}
	done
	for((k=0; k<${#infors[@]}; k++))
	do	
		[[ ${#infors[k]} -gt q ]] && q=${#infors[k]}
	done
	[[ $((n+m)) -gt q ]] && long=$((n+m)) || long=$q
	[[ ${#gameover_string} -gt $long ]] && long=${#gameover_string}
	if [[ $((`tput cols`-boundary_r)) -le $((long+2)) ]]; then
		echo windows [ cols ] too small !
		exit
	fi
}

check_invironment

StopKeyboardInput=false
PauseMyTank=false

trap '' 2
trap 'game_over' 21

#pause and continue
trap 'PauseMyTank=true; kill -23 $run_enemytank_pid &>/dev/null' 25
trap 'PauseMyTank=false; kill -24 $run_enemytank_pid &>/dev/null' 26

sleep 0.5
clear
tput civis
		
#draw boundary
for((i=boundary_l-1; i<=boundary_r+1; i++))
do
	echo -ne "\033[${boundary_u};${i}H\033[${boundary_color}m "
	echo -ne "\033[${boundary_d};${i}H\033[${boundary_color}m "
done
for((i=boundary_u+1; i<boundary_d; i++))
do
	echo -ne "\033[${i};$((boundary_l-1))H\033[${boundary_color}m "
	echo -ne "\033[${i};${boundary_l}H\033[${boundary_color}m "
	echo -ne "\033[${i};${boundary_r}H\033[${boundary_color}m "
	echo -ne "\033[${i};$((boundary_r+1))H\033[${boundary_color}m "
done
echo -ne "\033[0m"
echo -ne "\033[$((boundary_u+0));$((boundary_r+3))H\033[1;${smallboundary_color}m---------"
echo -ne "\033[$((boundary_u+6));$((boundary_r+3))H\033[1;${smallboundary_color}m---------"
echo -ne "\033[$((boundary_u+1));$((boundary_r+3))H\033[1;${smallboundary_color}m|       |"
echo -ne "\033[$((boundary_u+2));$((boundary_r+3))H\033[1;${smallboundary_color}m|       |"
echo -ne "\033[$((boundary_u+3));$((boundary_r+3))H\033[1;${smallboundary_color}m|       |"
echo -ne "\033[$((boundary_u+4));$((boundary_r+3))H\033[1;${smallboundary_color}m|       |"
echo -ne "\033[$((boundary_u+5));$((boundary_r+3))H\033[1;${smallboundary_color}m|       |"
echo -ne "\033[0m"
echo -ne "\033[$((boundary_u+12));$((boundary_r+3))H\033[41m\033[33mState\033[0m  \033[1;34mrunning\033[0m"

$print_LingYi && {
	print_mywords &
	run_print_mywords_pid=$!
}

$print_infor && {
	print_infors &
	run_print_infors_pid=$!
}

$print_dtime && {
	print_dtime &
	run_print_dtime_pid=$!
}

$print_mode && {
	print_mode &
	run_print_mode_pid=$!
}

$print_roll && {
	print_roll_words &
	run_print_roll_words_pid=$!
}

#display enemy tank
DisplayRandTank

#display mytank
mytank_direct='u'
mytank_head=($[(boundary_d-boundary_u)/2+boundary_u] $[(boundary_r-boundary_l)/2+boundary_l])
HandleTank -d "${mytank_head[0]};${mytank_head[1]}" $mytank_direct my

#make enemy tank move
MoveEnemyTank &
run_enemytank_pid=$!
#MoveEnemyTank cann't get the value of $run_enemytank_pid, so record it in file.
echo $run_enemytank_pid >${tmpdir}/run_enemytank_pid 

#accept keyboard input
ESC=`echo -e '\033'`
stty -echo
while ! $StopKeyboardInput
do
	while $PauseMyTank
	do
		read -s -n 1 kk
		[[ $kk == 'c' ]] || [[ $kk == 'C' ]] && kill -26 $MYPID
	done
	read -s -n 1 key
	
	# this judging is necessary, to stop this loop.
	$StopKeyboardInput && break

	key=`echo $key | tr 'a-z' 'A-Z'`

	[[ $key == 'W' ]] && MoveMyTank u
	[[ $key == 'S' ]] && MoveMyTank d
	[[ $key == 'D' ]] && MoveMyTank r
	[[ $key == 'A' ]] && MoveMyTank l

    	[[ $key == 'U' ]] && kill -28  $run_enemytank_pid
	[[ $key == 'L' ]] && kill -29  $run_enemytank_pid
	[[ $key == 'F' ]] && kill -37 $run_enemytank_pid 
	[[ $key == 'N' ]] && kill -38 $run_enemytank_pid && $print_mode && kill -25 $run_print_mode_pid
	[[ $key == 'M' ]] && kill -39 $run_enemytank_pid && $print_mode && kill -26 $run_print_mode_pid

	[[ $key == 'G' ]] && StealthMode
	[[ $key == 'V' ]] && GodMode
	
	[[ $key == 'P' ]] && kill -25 $MYPID
	[[ $key == 'Q' ]] && kill -21 $MYPID
	
	[[ -z $key ]] && Bullet  $mytank_direct ${mytank_head[@]} my &
	
	[[ $key == $ESC ]] && {
		for (( i=0; i<=1; i++ )); do read -s -n 1  KEY[$i]; done
		[[ ${KEY[0]} == '['   ]] && {
			[[ ${KEY[1]} == 'A' ]] &&  MoveMyTank u
			[[ ${KEY[1]} == 'B' ]] &&  MoveMyTank d
			[[ ${KEY[1]} == 'C' ]] &&  MoveMyTank r
			[[ ${KEY[1]} == 'D' ]] &&  MoveMyTank l
		}
	}
done 

stty echo
echo -e "\033[$((boundary_d+2));1H\033[0m"

