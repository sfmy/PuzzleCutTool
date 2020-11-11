#!/bin/bash 

#############################################################
# 剪切整张图片为一块块凹凸的小图，方便拼图游戏使用
# 1.先把整图切割为col x row块小图
# 2.相邻的小图切割含有圆形的方块
# 3.含有圆形的方块，切割成小圆
# 4.随机图块凹凸的信息
# 5.根据图块凹凸信息，拼接方块与小圆，并统一合并后的图块大小与位置
#############################################################

filename=""
col=4; row=4
width=0; height=0
cellwidth=0; cellheight=0
circle=0
imgmsg=()
rect_dir="rect"
circle_dir="circle"
png_sub_dir="png_sub"
png_add_dir="png_add"

function GenImgMsg () {
	for ((j=0; j<row; ++j)); do
		for ((i=0; i<col; ++i)); do
			for ((k=0; k<4; ++k)); do
				# 上 下 左 右
				imgmsg[$(((j*col+i)*4+k))]=0
			done
		done
	done

	for ((j=0; j <row; ++j)); do
		for ((i=0; i<col-1; ++i)); do
			dir=`RandomDir`
			imgmsg[$(((j*col+i)*4+3))]=${dir} # 右 
			imgmsg[$(((j*col+i+1)*4+2))]=$((0-dir)) # 左 
		done
	done
	for ((i=0; i<col; ++i)); do
		for ((j=0; j<row-1; ++j)); do
			dir=`RandomDir`
			imgmsg[$(((j*col+i)*4+1))]=${dir} # 下
			imgmsg[$((((j+1)*col+i)*4))]=$((0-dir)) # 上
		done
	done
}

function Init {
	filename=${1}
	mkdir -p "${rect_dir}" "${circle_dir}" "${png_sub_dir}" "${png_add_dir}"
	wid_and_hei=`identify "${filename}" | awk '{print $3}'`
	height=${wid_and_hei#*x}
	width=${wid_and_hei/x*}
	cellwidth=$((width/col))
	cellheight=$((height/row))
	circle=40
	GenImgMsg
}

function RandomDir {
	num=$((RANDOM%2))
	if [ $num -eq 0 ]; then
		echo "-1" # 凹 
	else
		echo "1" # 凸 
	fi
}


function GenRectImage {
	x=${1}; y=${2}; cutname="${rect_dir}/${x}_${y}.png" 
	if [ ! -e "${cutname}" ]; then
		echo "${filename} ------------>>>> ${cutname}"
		convert "${filename}" -crop "${cellwidth}x${cellheight}+$((x*cellwidth))+$((y*cellheight))" "${cutname}"
	fi
}

function GenCircleImage {
	x1=${1}; y1=${2}; x2=${3}; y2=${4}
	if [ ${x1} -eq ${x2} ]; then
		if [ ${y1} -gt ${y2} ]; then
			y1=${4}; y2=${2}
		fi
		cutname="${circle_dir}/${x1}_${y1}_${x2}_${y2}.png"
		if [ ! -e "${cutname}" ]; then
			echo "${filename} ------------>>>> ${cutname}"
			convert "${filename}" -crop "${circle}x${circle}+$((x1*cellwidth+cellwidth/2-circle/2))+$((y1*cellheight+cellheight-circle/2))" "${cutname}"
			convert -size "${circle}x${circle}" xc:none -fill "${cutname}" -draw "circle $((circle/2)),$((circle/2)) ${circle},$((circle/2))" "${cutname}"
		fi
	else
		if [ ${x1} -gt ${x2} ]; then
			x1=${3}; x2=${1}
		fi
		cutname="${circle_dir}/${x1}_${y1}_${x2}_${y2}.png"
		if [ ! -e "${cutname}" ]; then
			echo "${filename} ------------>>>> ${cutname}"
			convert "${filename}" -crop "${circle}x${circle}+$((x1*cellwidth+cellwidth-circle/2))+$((y1*cellheight+cellheight/2-circle/2))" "${cutname}"
			convert -size "${circle}x${circle}" xc:none -fill "${cutname}" -draw "circle $((circle/2)),$((circle/2)) ${circle},$((circle/2))" "${cutname}"
		fi
	fi
}

function AddLeft {
	echo "AddLeft ${1} ${2}"
	x=${1}; y=${2}
	name1="${png_add_dir}/${x}_${y}.png"
	name2="${png_sub_dir}/${x}_${y}.png"
	name3="${rect_dir}/${x}_${y}.png"
	name4="${circle_dir}/$((x-1))_${y}_${x}_${y}.png"
	if [ -e "${name1}" ]; then
		convert -size "$((cellwidth+circle))x$((cellheight+circle))" xc:none \
			"${name1}" -composite \
			"${name4}" -geometry "+0+$((cellheight/2))" -composite \
			"${name1}"
	elif [ -e "${name2}" ]; then
		convert -size "$((cellwidth+circle))x$((cellheight+circle))" xc:none \
			"${name2}" -geometry "+$((circle/2))+$((circle/2))" -composite \
			"${name4}" -geometry "+0+$((cellheight/2))" -composite \
			"${name1}"
	elif [ -e "${name3}" ]; then
		convert -size "$((cellwidth+circle))x$((cellheight+circle))" xc:none \
			"${name3}" -geometry "+$((circle/2))+$((circle/2))" -composite \
			"${name4}" -geometry "+0+$((cellheight/2))" -composite \
			"${name1}"
	fi
}

function AddRight {
	echo "AddRight ${1} ${2}"
	x=${1}; y=${2}
	name1="${png_add_dir}/${x}_${y}.png"
	name2="${png_sub_dir}/${x}_${y}.png"
	name3="${rect_dir}/${x}_${y}.png"
	name4="${circle_dir}/${x}_${y}_$((x+1))_${y}.png"
	if [ -e "${name1}" ]; then
		convert -size "$((cellwidth+circle))x$((cellheight+circle))" xc:none \
			"${name1}" -composite \
			"${name4}" -geometry "+${cellwidth}+$((cellheight/2))" -composite \
			"${name1}"
	elif [ -e "${name2}" ]; then
		convert -size "$((cellwidth+circle))x$((cellheight+circle))" xc:none \
			"${name2}" -geometry "+$((circle/2))+$((circle/2))" -composite \
			"${name4}" -geometry "+${cellwidth}+$((cellheight/2))" -composite \
			"${name1}"
	elif [ -e "${name3}" ]; then
		convert -size "$((cellwidth+circle))x$((cellheight+circle))" xc:none \
			"${name3}" -geometry "+$((circle/2))+$((circle/2))" -composite \
			"${name4}" -geometry "+${cellwidth}+$((cellheight/2))" -composite \
			"${name1}"
	fi
}

function AddUp {
	echo "AddUp ${1} ${2}"
	x=${1}; y=${2}
	name1="${png_add_dir}/${x}_${y}.png"
	name2="${png_sub_dir}/${x}_${y}.png"
	name3="${rect_dir}/${x}_${y}.png"
	name4="${circle_dir}/${x}_$((y-1))_${x}_${y}.png"
	if [ -e "${name1}" ]; then
		convert -size "$((cellwidth+circle))x$((cellheight+circle))" xc:none \
			"${name1}" -composite \
			"${name4}" -geometry "+$((cellwidth/2))+0" -composite \
			"${name1}"
	elif [ -e "${name2}" ]; then
		convert -size "$((cellwidth+circle))x$((cellheight+circle))" xc:none \
			"${name2}" -geometry "+$((circle/2))+$((circle/2))" -composite \
			"${name4}" -geometry "+$((cellwidth/2))+0" -composite \
			"${name1}"
	elif [ -e "${name3}" ]; then
		convert -size "$((cellwidth+circle))x$((cellheight+circle))" xc:none \
			"${name3}" -geometry "+$((circle/2))+$((circle/2))" -composite \
			"${name4}" -geometry "+$((cellwidth/2))+0" -composite \
			"${name1}"
	fi
}

function AddDown {
	echo "AddDown ${1} ${2}"
	x=${1}; y=${2}
	name1="${png_add_dir}/${x}_${y}.png"
	name2="${png_sub_dir}/${x}_${y}.png"
	name3="${rect_dir}/${x}_${y}.png"
	name4="${circle_dir}/${x}_$((y))_${x}_$((y+1)).png"
	if [ -e "${name1}" ]; then
		convert -size "$((cellwidth+circle))x$((cellheight+circle))" xc:none \
			"${name1}" -composite \
			"${name4}" -geometry "+$((cellwidth/2))+${cellheight}" -composite \
			"${name1}"
	elif [ -e "${name2}" ]; then
		convert -size "$((cellwidth+circle))x$((cellheight+circle))" xc:none \
			"${name2}" -geometry "+$((circle/2))+$((circle/2))" -composite \
			"${name4}" -geometry "+$((cellwidth/2))+${cellheight}" -composite \
			"${name1}"
	elif [ -e "${name3}" ]; then
		convert -size "$((cellwidth+circle))x$((cellheight+circle))" xc:none \
			"${name3}" -geometry "+$((circle/2))+$((circle/2))" -composite \
			"${name4}" -geometry "+$((cellwidth/2))+${cellheight}" -composite \
			"${name1}"
	fi
}

function SubLeft {
	echo "SubLeft ${x} ${y}"
	x=${1}; y=${2}
	name1="${png_sub_dir}/${x}_${y}.png"
	name2="${rect_dir}/${x}_${y}.png"
	choose=${name1}
	if [ ! -e "${name1}" ]; then
		choose=${name2}
	fi
	convert "${choose}" -bordercolor none -border "$((circle/2))x$((circle/2))" "${name1}"
	convert -size "$((cellwidth+circle))x$((cellheight+circle))" \
		"${name1}" \
		\( xc:none -fill red  -draw "circle $((circle/2)),$((circle/2+cellheight/2)) $((circle)),$((circle/2+cellheight/2))" \) \
		-compose Xor -composite "${name1}"
	convert "${name1}" +repage -crop "${cellwidth}x${cellheight}+$((circle/2))+$((circle/2))" "${name1}"
}

function SubRight {
	echo "SubRight ${x} ${y}"
	x=${1}; y=${2}
	name1="${png_sub_dir}/${x}_${y}.png"
	name2="${rect_dir}/${x}_${y}.png"
	choose=${name1}
	if [ ! -e "${name1}" ]; then
		choose=${name2}
	fi
	convert "${choose}" -bordercolor none -border "$((circle/2))x$((circle/2))" "${name1}"
	convert -size "$((cellwidth+circle))x$((cellheight+circle))" \
		"${name1}" \
		\( xc:none -fill red  -draw "circle $((circle/2+cellwidth)),$((circle/2+cellheight/2)) $((circle+cellwidth)),$((circle/2+cellheight/2))" \) \
		-compose Xor -composite "${name1}"
	convert "${name1}" +repage -crop "${cellwidth}x${cellheight}+$((circle/2))+$((circle/2))" "${name1}"
}

function SubUp {
	echo "SubUp ${x} ${y}"
	x=${1}; y=${2}
	name1="${png_sub_dir}/${x}_${y}.png"
	name2="${rect_dir}/${x}_${y}.png"
	choose=${name1}
	if [ ! -e "${name1}" ]; then
		choose=${name2}
	fi
	convert "${choose}" -bordercolor none -border "$((circle/2))x$((circle/2))" "${name1}"
	convert -size "$((cellwidth+circle))x$((cellheight+circle))" \
		"${name1}" \
		\( xc:none -fill red  -draw "circle $((circle/2+cellwidth/2)),$((circle/2)) $((circle/2+cellwidth/2)),$((circle))" \) \
		-compose Xor -composite "${name1}"
	convert "${name1}" +repage -crop "${cellwidth}x${cellheight}+$((circle/2))+$((circle/2))" "${name1}"
}

function SubDown {
	echo "SubDown ${x} ${y}"
	x=${1}; y=${2}
	name1="${png_sub_dir}/${x}_${y}.png"
	name2="${rect_dir}/${x}_${y}.png"
	choose=${name1}
	if [ ! -e "${name1}" ]; then
		choose=${name2}
	fi
	convert "${choose}" -bordercolor none -border "$((circle/2))x$((circle/2))" "${name1}"
	convert -size "$((cellwidth+circle))x$((cellheight+circle))" \
		"${name1}" \
		\( xc:none -fill red  -draw "circle $((circle/2+cellwidth/2)),$((circle/2+cellheight)) $((circle/2+cellwidth/2)),$((circle+cellheight))" \) \
		-compose Xor -composite "${name1}"
	convert "${name1}" +repage -crop "${cellwidth}x${cellheight}+$((circle/2))+$((circle/2))" "${name1}"
}

function Generate {
	Init ${1}

	# 切割大图为col x row 个方块
	for ((i=0; i<col; ++i)); do
		for ((j=0; j<row; ++j)); do
			GenRectImage "${i}" "${j}"
		done
	done

	# 切割出两个小图相邻的圆形区域
	for ((j=0; j<row; ++j)); do
		for ((i=1; i<col; ++i)); do
			GenCircleImage "$((i-1))" "${j}" "${i}" "${j}"
		done
	done
	for ((i=0; i<col; ++i)); do
		for ((j=1; j<row; ++j)); do
			GenCircleImage "${i}" "$((j-1))" "${i}" "${j}"
		done
	done

	for ((j=0; j<row; ++j)); do
		for ((i=0; i<col; ++i)); do
			dir_up=${imgmsg[$(((j*col+i)*4+0))]}
			dir_down=${imgmsg[$(((j*col+i)*4+1))]}
			dir_left=${imgmsg[$(((j*col+i)*4+2))]}
			dir_right=${imgmsg[$(((j*col+i)*4+3))]}
			if [ ${dir_up} -eq -1 ]; then
				SubUp ${i} ${j}
			fi
			if [ ${dir_down} -eq -1 ]; then
				SubDown ${i} ${j}
			fi
			if [ ${dir_left} -eq -1 ]; then
				SubLeft ${i} ${j}
			fi
			if [ ${dir_right} -eq -1 ]; then
				SubRight ${i} ${j}
			fi
		done
	done
	for ((j=0; j<row; ++j)); do
		for ((i=0; i<col; ++i)); do
			dir_up=${imgmsg[$(((j*col+i)*4+0))]}
			dir_down=${imgmsg[$(((j*col+i)*4+1))]}
			dir_left=${imgmsg[$(((j*col+i)*4+2))]}
			dir_right=${imgmsg[$(((j*col+i)*4+3))]}
			if [ ${dir_up} -eq 1 ]; then
				AddUp ${i} ${j}
			fi
			if [ ${dir_down} -eq 1 ]; then
				AddDown ${i} ${j}
			fi
			if [ ${dir_left} -eq 1 ]; then
				AddLeft ${i} ${j}
			fi
			if [ ${dir_right} -eq 1 ]; then
				AddRight ${i} ${j}
			fi
		done
	done

	mkdir -p output
	output_dir="output/${filename/.*}"
	mkdir -p ${output_dir}
	# 整理图片
	for ((i=0; i<col; ++i)); do
		for ((j=0; j<row; ++j)); do
			name="${png_add_dir}/${i}_${j}.png"
			if [ ! -e ${name} ]; then
				name="${png_sub_dir}/${i}_${j}.png"
				if [ ! -e ${name} ]; then
					name="${rect_dir}/${i}_${j}.png"
				fi
				convert "${name}" -bordercolor none -border "$((circle/2))x$((circle/2))" "${name}"
			fi
			cp "${name}" "${output_dir}"
		done
	done
	# 清理
	rm -rf "${rect_dir}" "${circle_dir}" "${png_sub_dir}" "${png_add_dir}"
}

Generate 1.jpg
