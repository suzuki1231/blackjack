#!/bin/bash

Playerの先攻

Playerのターン
----------
2 sum:2
カードを引きますか?(d/p):^C
Afami-MacBook-Pro:src h.takahashi$ ll
total 16
-rwxrwxrwx@ 1 h.takahashi  staff  5064  9 20 12:51 main.sh
Afami-MacBook-Pro:src h.takahashi$ cat main.sh
#!/bin/bash

# Playerの引いたカード（配列）
pCards=();

# CPの引いたカード（配列）
cCards=();

# ドローをパスしたかどうかのフラグ
pPass=false
cPass=false

# 1~13の数字が入った山札（配列）を生成
cards=();
for((i=0; i < 13; i++));
do
	cards[$i]=$(($i + 1));
done

# シャッフル関数
shuffle() {
	local i tmp size max rand

	size=${#cards[*]}
	max=$(( 32768 / size * size ))

	for ((i=size-1; i>0; i--)); do
		while (( (rand=$RANDOM) >= max )); do :; done
		rand=$(( rand % (i+1) ))
		tmp=${cards[i]} cards[i]=${cards[rand]} cards[rand]=$tmp
	done
}

# 山札（配列）のシャッフル
shuffle

# ゲーム開始時にお互い山札から1枚引く
pCards=(${pCards[@]} ${cards[0]}) # 山札の1枚目をPlayerの手持ちに追加
cards=(${cards[@]:1}) # 山札の1枚目を削除
cCards=(${cCards[@]} ${cards[0]}) # 山札の1枚目をCPの手持ちに追加
cards=(${cards[@]:1}) # 山札の1枚目を削除

# Playerの引いたカードの合計値
pSum(){
	sum=0
	for((i=0; i < ${#pCards[@]}; i++));
	do
		sum=$(($sum + ${pCards[i]}));
	done
	echo $sum
}

# CPの引いたカードの合計値
cSum(){
	sum=0
	for((i=0; i < ${#cCards[@]}; i++));
	do
		sum=$(($sum + ${cCards[i]}));
	done
	echo $sum

}

# プレイヤー側のメイン処理
Player(){
		echo 'Playerのターン'
		echo '----------'
		echo ${pCards[@]} 'sum:'`pSum`

		# カードのドロー or パス処理
		read -p 'カードを引きますか?(d/p):' a
		if [ 'd' = $a ];then
				# カードを1枚引く
				echo ${cards[0]}'を引いた'
				pCards=(${pCards[@]} ${cards[0]})
				cards=(${cards[@]:1})
				echo 'sum:'`pSum`;
				pPass=false
			else
				echo 'パス';
				pPass=true
			fi
}

# CPのAI
# カードを引く(true)かパス(false)するかを判断する
AI(){

	# これまでのドローされたカードをリスト化
	# ただしPlayerの1枚目は含まない
	list=(${cCards[@]} ${pCards[@]:1})

	# ドローしたカードからまだ引かれてないカードを求める
	newList=(); # まだ引かれてないカードリスト
	drowCheck=false # ドローされたかどうか
	for ((i=1; i < 14; i++));
	do
		drowCheck=true
		for ((t=0; t < ${#list[@]}; t++));
		do
			# 既に引かれたカードは無視
			if [ $i = ${list[$t]} ];then
						# echo "$i は既に引かれている"
						drowCheck=false
						break
					fi
				done

				if $drowCheck ;then
					# echo "$i はまだ引かれてないのでリストに追加"
					newList=(${newList[@]} $i)
				fi
			done

			pd=0 # ドローしても21を超えないパターン数
			pp=0 # ドローしたらバーストするパターン数
			for((i=0; i < ${#newList[@]}; i++));
			do
				if [ $((`cSum` + ${newList[$i]})) -lt 22 ];then
						pd=$((++pd))
				else
						pp=$((++pp))
				fi
			done

			# バーストする確率 < ドローできる確率
			if [ $pp -lt $pd ];then
					# ドローと判断
						echo true
			else
					# パスと判断
						echo false
			fi
}

# CP側のメイン処理
CP(){
	echo 'CPのターン'
	echo '----------'

	# 1枚目を?で表示し、残りの引いたカードをそのまま表示する処理
	text='?';
	sum=0;
	for((i=1; i < ${#cCards[@]}; i++));
	do
		text="$text ${cCards[i]}"
		sum=$(($sum + ${cCards[i]}));
	done
	echo "$text sum:? + $sum"

	# カードのドロー or パス処理
	if `AI` ;then	
		# カードを1枚引く
		c=${cards[0]}
		echo $c'を引いた'
		cCards=(${cCards[@]} ${cards[0]})
		cards=(${cards[@]:1})
		echo 'sum:? + '$(($sum + $c));
		cPass=false
	else
		echo 'パス';
		cPass=true
	fi
}

#先攻後攻決め 0=Player 1=CP
first=$(($RANDOM % 2));
if [ $first = 0 ];then
	echo 'Playerの先攻'
else
	echo 'CPの先攻'
fi

# メイン処理
while true
do
	echo ''

	# 先攻処理
		if [ 0 != ${#cards[@]} ];then
			if [ $first = 0 ];then
				Player
		else
				CP
		fi
	else
			#終了
			break;
	fi

	echo ''

	# 後攻処理
		if [ 0 != ${#cards[@]} ];then
			if [ $first = 1 ];then
					Player
			else
			CP
		fi
		else
			#終了
			break;
		fi
		# お互いがパスしたのでゲーム終了
		if $pPass && $cPass ;then
				break;
		fi

done

# 合計値取得
resultP=`pSum`
resultC=`cSum`

# 判定
echo 'ゲーム終了'
echo '--------------------'
echo '結果発表'
echo '----------'
if [ $resultP -lt 22 ] && [ $resultC -lt 22 ];then
	# 両方ともバースしてない
	if [ $resultP = $resultC ];then
		echo "引き分け  Player=$resultP CP=$resultC";
	elif [ $resultP -lt $resultC ];then
		echo "CPの勝ち $resultC"
		echo "Playerの負け $resultP";
	else
		echo "Playerの勝ち $resultP"
		echo "CPの負け $resultC";
	fi

elif [ 21 -lt $resultP ] && [ 21 -lt $resultC ];then	
	# 両方ともバースした
	echo "引き分け（両者バースト）  Player=$resultP CP=$resultC";
elif [ 21 -lt $resultP ];then	
	# Playerのみがバースした
	echo "CPの勝ち $resultC";
	echo "Playerのバースト負け $resultP";
elif [ 21 -lt $resultC ];then	
	# CPのみがバースした
	echo "Playerの勝ち $resultP";
	echo "CPのバースト負け $resultC";
fi	
