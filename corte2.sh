echo "Digite o Nome do Arquivo da live"
read input
echo "Digita o tempo que o vídeo vai ter! (00:00:00)"
read time
echo "Coloca o nome da saída"
read saida
ffmpeg \
  -i $input \
  -c copy \
  -map 0 \
  -segment_time $time \
  -f segment \
  -reset_timestamps 1 \
  $saida%03d.mp4
