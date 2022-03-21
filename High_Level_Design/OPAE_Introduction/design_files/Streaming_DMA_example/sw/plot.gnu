red = "#FF0000"; green = "#00FF00"; blue = "#0000FF";
set terminal jpeg
set output 'test.jpeg'
set yrange [0:10000]
set style data histogram
#set style histogram cluster gap 1
set style fill solid
set boxwidth 0.8
set xtics format ""

#set xtics 1
#set ytics 1
set style line 12 lc rgb '#808080' lt 0 lw 2
set grid back ls 12
set grid ytics
set title "Measured Bandwidth (MB/s)"
set xlabel "Payload size"
set ylabel "Bandwidth"
set xtics rotate 30
plot "bw.dat" using 2:xtic(1) title "Memory to stream" linecolor rgb red, \
	'' using 3 title "Stream to memory" linecolor rgb blue, \
	'' using 4 title "Full duplex" linecolor rgb green \
