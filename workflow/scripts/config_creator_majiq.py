samples = snakemake.params["samples"]
genome = snakemake.params["genome"]

f = open("./metadata/majiq_configs/majiq_config_file.txt","w")
f.write("[info]\n")
f.write("sjdirs=./data/majiq_files\n")
f.write("genome="+genome+"\n")
f.write("[experiments]\n")

for rep in samples:
	f.write(rep+'='+rep+'_Aligned.sortedByCoord.out\n')
